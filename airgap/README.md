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
2. Copy `bundle/provider-mirror` to `/opt/terraform/provider-mirror`.
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
