# VMware vSphere Terraform modules

This repository contains small, composable Terraform modules for provisioning VMware vSphere infrastructure.

The modules target existing vCenter environments and are designed to be composed by environment-specific root configurations. They do not store provider credentials or configure a Terraform state backend.

## Modules

| Capability | Module |
|---|---|
| Virtual machines cloned from inventory templates or content-library items | `modules/vm` |
| Distributed switches, advanced policies, port groups and VLANs | `modules/networking` |
| ESXi standard switches and port groups | `modules/standard-networking` |
| vCenter roles and entity permissions | `modules/iam` |
| Secure Boot, vTPM, VBS and port-group security defaults | `modules/security` |
| Standard `Name`, `project` and `Terraform=True` tags | `modules/tagging` |
| Inventory folders | `modules/inventory` |
| CPU and memory resource pools | `modules/resource-pool` |
| Compute clusters with DRS, DPM and HA | `modules/compute-cluster` |
| Datastore clusters, Storage DRS and VM storage policies | `modules/storage` |
| NFS v3 and NFS 4.1 datastores | `modules/nas-datastore` |
| VM affinity, anti-affinity and VM-to-host rules | `modules/placement` |
| vSphere content libraries | `modules/content-library` |

Distributed port-group security controls MAC behavior. Workload firewalling and micro-segmentation require VMware NSX and its separate Terraform provider.

## Repository layout

```text
.
├── modules/
│   ├── content-library/
│   ├── compute-cluster/
│   ├── iam/
│   ├── inventory/
│   ├── nas-datastore/
│   ├── networking/
│   ├── placement/
│   ├── resource-pool/
│   ├── security/
│   ├── standard-networking/
│   ├── storage/
│   ├── tagging/
│   └── vm/
└── examples/
    ├── content-library/
    ├── compute-cluster/
    ├── iam/
    ├── inventory/
    ├── nas-datastore/
    ├── networking/
    ├── placement/
    ├── resource-pool/
    ├── security/
    ├── standard-networking/
    ├── storage/
    ├── tagging/
    └── vm/
        ├── content-library/
        ├── linux/
        └── windows/
```

Each child module owns one infrastructure concern and exposes IDs for composition. Provider configuration, credentials, remote state, and environment values stay in the calling root module. Instantiate the tagging module once per deployment and pass its tag sets to resources that support vSphere tags.

Standard tags are wired into the VM, distributed networking, inventory-folder, resource-pool, compute-cluster, NAS datastore, and datastore-cluster modules. The vSphere provider does not expose tag assignment on standard host networking, placement rules, roles, entity permissions, security-policy outputs, VM storage policies, or content-library resources.

## Using the modules

Clone the repository when developing or evaluating the modules locally:

```bash
git clone git@github.com:faiyaz96/terraform-vmware-modules.git
cd terraform-vmware-modules
```

Call a local module from a root configuration:

```hcl
module "vm" {
  source = "./modules/vm"

  # Required VM settings...
}
```

The public repository can also be used directly as a Git module source:

```hcl
module "vm" {
  source = "git::https://github.com/faiyaz96/terraform-vmware-modules.git//modules/vm?ref=v1.1.0"

  # Required VM settings...
}
```

Pin `ref` to a release tag or commit SHA for production use instead of following `main`.

## Quick start

```bash
cd examples/vm/linux
cp terraform.example.tfvars terraform.tfvars
# Edit terraform.tfvars with non-secret environment values.
export TF_VAR_vsphere_user='terraform@vsphere.local'
export TF_VAR_vsphere_password='use-a-secret-manager-in-production'
terraform init
terraform plan
```

Each example contains a committed `terraform.example.tfvars` template. It ends with `.tfvars`, but Terraform does not load it automatically because only `terraform.tfvars` and `*.auto.tfvars` are auto-loaded. Copy it to the ignored `terraform.tfvars` before use.

The example files use placeholder infrastructure names and must be updated for the target vCenter. Do not add passwords to committed `.tfvars` files.

Review plans with the vSphere networking, storage, and security owners before applying them. Attaching physical host NICs to a new distributed switch can interrupt connectivity if the uplink design is wrong.

## Air-gapped environments

The [`airgap`](airgap/README.md) package builds a self-contained set of Terraform executables, a pinned `vmware/vsphere` provider filesystem mirror, module source, checksums, offline CLI configuration, backend examples, verification scripts, and an operator runbook. Generated binary payloads stay under the ignored `airgap/bundle/` directory and should be transferred through the organization's approved cross-domain process.

Build it on a connected staging host, verify it, and then test provider initialization without public Registry access:

```bash
./airgap/scripts/build-bundle.sh
./airgap/scripts/verify-bundle.sh
./airgap/scripts/test-offline-init.sh
```

## Provisioning scope and order

Adopt the modules in this order: tagging and inventory, networking, compute placement, storage, templates, then VMs and placement rules. Manage compute clusters, host uplinks, datastores, HA/DRS, and content libraries only when those areas are explicitly owned by the applying team.

The actual Terraform apply order follows resource dependencies rather than the documentation order. Existing or newly managed networking, compute placement, storage, templates, and tags must be available before a VM can be created. Terraform derives that order from module output references.

The examples support both existing and Terraform-managed compute clusters. Import existing production objects before enabling their lifecycle modules. Content-library, standard-switch, NAS-datastore, and placement modules are optional and should be used only when those concerns are in scope.

## Design and security practices

- Child modules do not configure providers or contain credentials.
- Each deployable example pins the provider family and commits its generated `.terraform.lock.hcl`.
- Use a remote state backend with encryption, locking, versioning, and tightly controlled access.
- Use a dedicated least-privilege vCenter service account. The vSphere provider also needs tag-read, event-read, storage-profile-view, and VM swap-placement privileges for common operations.
- Use an enterprise identity provider for users and groups; this repository grants permissions to existing principals rather than managing user passwords.
- Import existing vSphere objects before bringing them under Terraform. Do not recreate production switches, folders, or roles with the same names.
- Run `terraform fmt -check -recursive`, `terraform validate`, and `terraform test` before merging.
- Keep one VM per module call and use caller-side `for_each` with stable keys for fleets.
- Keep `force_power_off`, mandatory placement rules, and forced cluster evacuation disabled unless an approved operational requirement needs them.
- Keep NIOC bandwidth reservations within verified physical uplink capacity and enable only traffic classes supported by the target VDS version.
- VMFS lifecycle is intentionally not managed until the storage owner confirms responsibility for LUN formatting and destruction.
- Pin module sources to a semantic release tag or commit SHA and review the changelog before upgrading.

## Version assumptions

The modules require Terraform `>= 1.6, < 2.0` and VMware vSphere provider `>= 2.16, < 3.0`. Mocked module tests require Terraform 1.7 or newer. Provider `2.16.x` supports vSphere versions covered by Broadcom's active product lifecycle; confirm the exact vCenter/ESXi compatibility for your estate before rollout.

This project is licensed under the MIT License. See `LICENSE`. Release notes are maintained in `CHANGELOG.md`.
