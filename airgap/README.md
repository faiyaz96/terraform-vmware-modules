# VMware Terraform air-gap bundle

This directory builds and documents a self-contained package for running the VMware vSphere modules without internet access.

The generated binary payload is stored in `airgap/bundle/` and deliberately ignored by Git. Binary archives should be transferred through the organization's approved removable-media or cross-domain process, not committed to the source repository.

## Included software

Versions are pinned in `versions.env`:

- Terraform CLI 1.15.8.
- VMware vSphere provider 2.16.1.
- Terraform VMware module source release v1.1.0.
- Terraform binaries and provider packages for Linux AMD64, Linux ARM64, macOS AMD64, macOS ARM64, and Windows AMD64.

No credentials, private keys, vCenter certificates, state files, VM images, or operating-system packages are included.

## Beginner process: connected machine to air-gapped environment

The simple end-to-end process is:

```text
Build on an internet-connected machine
              ↓
Verify and security-scan the bundle
              ↓
Copy the bundle using approved transfer media or tooling
              ↓
Verify the bundle again inside the air-gapped environment
              ↓
Install Terraform and configure the local provider mirror
              ↓
Extract the VMware modules and add environment values
              ↓
Run terraform init, validate and plan
              ↓
Review the plan before any terraform apply
```

The commands below use Linux as the main example. Run them from the repository root on the connected machine and as a normal user unless `sudo` is shown.

### Step 1: Build the bundle on the connected machine

```bash
chmod +x airgap/scripts/*.sh
./airgap/scripts/build-bundle.sh
./airgap/scripts/verify-bundle.sh
```

This creates `airgap/bundle/`. It contains Terraform, the VMware provider, module source, configuration examples, tests, documentation, and checksums.

Confirm that the folder exists:

```bash
ls airgap/bundle
du -sh airgap/bundle
```

### Step 2: Scan and copy the bundle

First, run the security and malware scanning required by your organization. Then copy the complete contents of `airgap/bundle/` to approved transfer media or an approved cross-domain transfer location.

Example using mounted transfer media:

```bash
mkdir -p /media/approved-transfer/terraform-vmware-airgap
cp -R airgap/bundle/. /media/approved-transfer/terraform-vmware-airgap/
```

Do not copy only the Terraform executable. The `provider-mirror`, `config`, `modules`, `scripts`, and `SHA256SUMS` files are also required.

### Step 3: Copy it into the air-gapped environment

After the transfer has been approved and imported, copy the complete folder onto the Terraform runner:

```bash
sudo mkdir -p /opt/terraform/airgap-bundle
sudo cp -R /media/approved-transfer/terraform-vmware-airgap/. /opt/terraform/airgap-bundle/
cd /opt/terraform/airgap-bundle
```

Your organization may use a managed file-transfer system instead of removable media. The important point is that the entire bundle arrives unchanged.

### Step 4: Verify the transferred files

Run verification before installing or executing Terraform:

```bash
sudo chmod +x scripts/*.sh
./scripts/verify-bundle.sh
```

Every file should report `OK`, followed by:

```text
All air-gap bundle checksums are valid.
```

Stop if a file is missing or a checksum fails. Do not continue with a damaged or modified bundle.

### Step 5: Test offline provider installation

This test uses the Terraform binary and provider mirror inside the bundle. It does not require vCenter credentials:

```bash
./scripts/test-offline-init.sh
```

The expected final message is similar to:

```text
Offline provider initialization succeeded for linux_amd64.
```

### Step 6: Install the correct Terraform binary

Check the runner architecture:

```bash
uname -m
```

- Use `linux_amd64` when the result is `x86_64`.
- Use `linux_arm64` when the result is `aarch64` or `arm64`.

For a common x86-64 Linux runner:

```bash
sudo install -m 0755 bin/linux_amd64/terraform /usr/local/bin/terraform
terraform version
```

For an ARM64 runner, replace `linux_amd64` with `linux_arm64`.

### Step 7: Install the provider mirror configuration

```bash
sudo mkdir -p /opt/terraform/provider-mirror /etc/terraform
sudo cp -R provider-mirror/. /opt/terraform/provider-mirror/
sudo cp config/terraform-airgap.tfrc.example /etc/terraform/terraform.tfrc

export TF_CLI_CONFIG_FILE=/etc/terraform/terraform.tfrc
export CHECKPOINT_DISABLE=1
```

Add these environment variables to the Terraform runner or CI job configuration so they are present for every Terraform command. The configuration contains no public Registry fallback.

### Step 8: Extract the VMware modules

Create a user-owned working directory so Terraform does not need to run as root:

```bash
mkdir -p ~/terraform-workspace/terraform-vmware-modules
tar -xzf modules/terraform-vmware-modules-v1.1.0.tar.gz \
  -C ~/terraform-workspace/terraform-vmware-modules
```

The examples use relative module paths, so keep the `modules` and `examples` folders together.

### Step 9: Prepare an example

The following uses the Linux VM example. It prepares configuration but does not create a VM:

```bash
cd ~/terraform-workspace/terraform-vmware-modules/examples/vm/linux
cp terraform.example.tfvars terraform.tfvars
```

Edit `terraform.tfvars` and replace every placeholder with the real air-gapped vCenter values, such as the datacenter, cluster, datastore, network, template, project, and VM name.

Supply credentials through an approved internal secret system or protected shell session:

```bash
export TF_VAR_vsphere_user='terraform@vsphere.local'
export TF_VAR_vsphere_password='retrieve-from-approved-secret-system'
```

Do not write the password into `terraform.tfvars`.

### Step 10: Initialize, validate and review

For initial configuration validation without configuring production state:

```bash
terraform init -backend=false
terraform providers
terraform validate
terraform plan -var-file=terraform.tfvars
```

At this point:

- `terraform init` should install `vmware/vsphere` from the local mirror.
- `terraform validate` should confirm that the configuration is valid.
- `terraform plan` should show what Terraform intends to create or change.
- Do not run `terraform apply` yet.

Before production use, configure the approved internal state backend, run `terraform init` again with that backend, save the plan through the approved process, and have the VMware owner review it. Only run `terraform apply` after the plan and change have been approved.

### Windows runner summary

For Windows, copy the bundle to a location such as `C:\terraform\airgap-bundle` and run PowerShell:

```powershell
Set-Location C:\terraform\airgap-bundle
.\scripts\verify-bundle.ps1
.\scripts\test-offline-init.ps1

Copy-Item .\bin\windows_amd64\terraform.exe C:\terraform\terraform.exe
Copy-Item .\provider-mirror C:\terraform\provider-mirror -Recurse
Copy-Item .\config\terraform-airgap-windows.tfrc.example C:\terraform\terraform.tfrc

$env:TF_CLI_CONFIG_FILE = "C:\terraform\terraform.tfrc"
$env:CHECKPOINT_DISABLE = "1"
C:\terraform\terraform.exe version
```

Configure the same environment variables permanently in the Windows runner or CI service before using Terraform.

## Build on a connected staging host

The connected build host must have Bash, `curl`, `tar`, `unzip`, and either `sha256sum` or `shasum`.

```bash
chmod +x airgap/scripts/*.sh
./airgap/scripts/build-bundle.sh
./airgap/scripts/verify-bundle.sh
```

The builder downloads Terraform only from `releases.hashicorp.com`, verifies every archive against HashiCorp's published SHA256 list, and retains the detached signature for independent PGP verification. Terraform then downloads the pinned `vmware/vsphere` provider through its registry protocol, authenticates its partner signature, and constructs the provider mirror. The generated bundle `SHA256SUMS` covers every transferred file.

Before moving the bundle, apply organizational malware scanning, software-composition analysis, approval, and removable-media controls. Preserve the generated manifest alongside the files.

## Bundle contents

```text
airgap/bundle/
├── bin/                         Terraform executables by OS and architecture
├── config/                      CLI and backend examples
├── docs/AIRGAP.md               This runbook
├── downloads/                   Original Terraform archives and checksums
├── modules/                     Module and example source archive
├── provider-mirror/             Offline vmware/vsphere provider mirror
├── scripts/                     Linux/macOS and Windows verification tests
├── SHA256SUMS                   Bundle integrity manifest
└── versions.env                 Approved component versions
```

## Verify after transfer

Run checksum verification immediately after importing the files into the isolated network:

```bash
cd /transfer/terraform-vmware-airgap
./scripts/verify-bundle.sh
```

If the scripts were not transferred, verify directly from the bundle directory:

```bash
sha256sum --check SHA256SUMS
```

On macOS:

```bash
shasum -a 256 --check SHA256SUMS
```

Do not install or execute the bundle if any checksum differs.

On Windows PowerShell:

```powershell
Set-Location C:\transfer\terraform-vmware-airgap
.\scripts\verify-bundle.ps1
```

## Install on an isolated Linux runner

The following paths are examples; use organization-approved installation locations and permissions.

1. Copy the Terraform executable for the runner architecture to `/usr/local/bin/terraform` and make it executable.
2. Copy `provider-mirror` to `/opt/terraform/provider-mirror`.
3. Copy `config/terraform-airgap.tfrc.example` to `/etc/terraform/terraform.tfrc`.
4. Extract the module archive into an internal Git repository or a controlled local module directory.

Configure the shell or CI runner:

```bash
export TF_CLI_CONFIG_FILE=/etc/terraform/terraform.tfrc
export CHECKPOINT_DISABLE=1
terraform version
```

The CLI configuration intentionally contains only a filesystem mirror. Do not add a `direct` block: it would allow Terraform to contact the public Registry.

The provider source in Terraform configuration remains unchanged:

```hcl
terraform {
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "= 2.16.1"
    }
  }
}
```

The mirror changes where Terraform installs the provider from; it does not change the provider's identity.

## Consume modules without GitHub

Extract the module archive:

```bash
mkdir -p /opt/terraform/terraform-vmware-modules
tar -xzf modules/terraform-vmware-modules-v1.1.0.tar.gz -C /opt/terraform/terraform-vmware-modules
```

Place the environment root beside the extracted repository and use relative local module sources. Terraform local module paths must begin with `./` or `../`:

```hcl
module "tagging" {
  source = "../terraform-vmware-modules/modules/tagging"

  project        = var.project
  resource_names = [var.vm_name]
}

module "vm" {
  source = "../terraform-vmware-modules/modules/vm"

  # Environment-specific VM inputs...
  tags = module.tagging.tags_by_resource_name[var.vm_name]
}
```

Alternatively, publish the extracted repository to an internal GitLab server and use a pinned internal Git source. Do not leave public GitHub source addresses in isolated root configurations.

## Initialize and validate offline

The included test proves that the current host can initialize from the mirror. From the generated bundle, run:

```bash
./scripts/test-offline-init.sh
```

On Windows PowerShell:

```powershell
.\scripts\test-offline-init.ps1
```

For an environment root configuration:

```bash
terraform init -backend=false
terraform providers
terraform validate
terraform plan -var-file=terraform.tfvars
```

`terraform init` must show installation from the local mirror and must not attempt to reach `registry.terraform.io`.

Terraform may display the mirrored provider as `unauthenticated` because a filesystem mirror does not expose the public Registry's signing metadata during installation. The bundle builder authenticated the provider while downloading it, and the committed lock file plus `SHA256SUMS` enforce the approved package hashes. A checksum error must be treated as a failed installation.

## State backend

Production use requires an internal backend with encryption, locking, access control, backups, and tested recovery. The bundle includes Consul examples because Consul can operate entirely inside the isolated network. Use them only when the organization operates Consul:

```bash
cp config/backend-consul.tf.example backend.tf
export CONSUL_HTTP_TOKEN='supplied-by-the-internal-secret-system'
terraform init -backend-config=config/backend-consul.hcl.example
```

Do not commit backend tokens. The local backend example is for a single-user lab only and is not suitable for shared production state.

If the organization uses Terraform Enterprise or another approved internal backend, replace the example with that platform's configuration. Backend services and their licenses are not included in this bundle.

## vCenter connectivity and certificates

The Terraform runner still requires internal connectivity to:

- vCenter HTTPS port 443.
- Internal DNS and NTP.
- The chosen state backend.
- Internal Git, registry, Vault, or CI services when used.
- Internal artifact servers referenced by content-library `file_url` values.

Install the internal CA chain in the runner's operating-system trust store and keep `allow_unverified_ssl = false`. The vCenter service account must already exist and have the least privileges required by the managed resources.

Supply credentials through an internal secret manager or protected CI variables:

```bash
export TF_VAR_vsphere_user='terraform@vsphere.local'
export TF_VAR_vsphere_password='retrieve-from-approved-secret-system'
```

Never store credentials in the bundle, committed `.tfvars`, CLI configuration, or backend files. Terraform state can contain sensitive values, so protect it as confidential data.

## Templates and content libraries

VM templates, ISO files, OVF/OVA packages, guest customization specifications, and OS repositories are environment artifacts and are not included. Place them in vCenter or on an approved internal artifact server before applying VM or content-library configurations.

For a content-library item, `file_url` must be reachable by vCenter itself:

```hcl
file_url = "https://artifacts.internal.example.com/vmware/rhel9.ova"
```

Templates should contain VMware Tools and the required Linux cloud-init or Windows guest customization components. Guest update operations should use internal YUM, APT, WSUS, DNS, and NTP services.

## Controlled updates

Treat every Terraform or provider update as a new approved bundle:

1. Change the versions in `versions.env` and `provider-config/main.tf` together.
2. Build on a connected staging host.
3. Review publisher checksums and provider signing information.
4. Run formatting, validation, contract tests, and a non-production vCenter plan.
5. Scan the payload and obtain approval.
6. Transfer and verify `SHA256SUMS` inside the air gap.
7. Retain the previous approved bundle for rollback of tooling. Do not roll state backward.

Do not use `terraform init -upgrade` in the isolated network. Only versions present in the approved mirror can be installed.

## Items supplied by the environment owner

The following cannot be safely pre-packaged and must be provided for the target environment:

- vCenter URL, datacenter, cluster, datastore, network, and template identifiers.
- A least-privilege vCenter service account.
- Internal CA certificates.
- Remote backend endpoint and credentials.
- Internal DNS, NTP, artifact, package, and secret-management endpoints.
- VM templates and guest customization specifications.
- Environment `.tfvars` values and approved import mappings.
- Firewall rules between the Terraform runner and internal services.
