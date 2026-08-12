# VMware vSphere Terraform modules

This repository contains small, composable Terraform modules for provisioning VMware vSphere infrastructure.

The modules target existing vCenter environments and are designed to be composed by environment-specific root configurations. They do not store provider credentials or configure a Terraform state backend.

## Modules

| Capability | Module |
|---|---|
| Virtual machines cloned from templates | `modules/vm` |
| Distributed switches, port groups and VLANs | `modules/networking` |
| vCenter roles and entity permissions | `modules/iam` |
| Secure Boot, vTPM, VBS and port-group security defaults | `modules/security` |
| Standard `Name`, `project` and `Terraform=True` tags | `modules/tagging` |
| Inventory folders | `modules/inventory` |
| CPU and memory resource pools | `modules/resource-pool` |
| Datastore clusters and VM storage policies | `modules/storage` |
| vSphere content libraries | `modules/content-library` |

Distributed port-group security controls MAC behavior. Workload firewalling and micro-segmentation require VMware NSX and its separate Terraform provider.

## Repository layout

```text
.
├── modules/
│   ├── content-library/
│   ├── iam/
│   ├── inventory/
│   ├── networking/
│   ├── resource-pool/
│   ├── security/
│   ├── storage/
│   ├── tagging/
│   └── vm/
└── examples/
    ├── content-library/
    ├── iam/
    ├── inventory/
    ├── networking/
    ├── resource-pool/
    ├── security/
    ├── storage/
    ├── tagging/
    └── vm/
        ├── linux/
        └── windows/
```

Each child module owns one infrastructure concern and exposes IDs for composition. Provider configuration, credentials, remote state, and environment values stay in the calling root module. Instantiate the tagging module once per deployment and pass its tag sets to resources that support vSphere tags.

Standard tags are wired into the VM, networking, inventory-folder, resource-pool, and datastore-cluster modules. The vSphere provider does not expose tag assignment on roles, entity permissions, security-policy outputs, VM storage policies, or content libraries.

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
  source = "git::https://github.com/faiyaz96/terraform-vmware-modules.git//modules/vm?ref=main"

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

## Provisioning scope and order

Develop and approve the modules in this order: VM provisioning, networking, compute clusters/resource pools, storage/datastores, and tagging. Add HA/DRS placement rules and content-library/template management only when those areas are owned by the team using this repository.

The actual Terraform apply order follows resource dependencies rather than the documentation order. Existing or newly managed networking, compute placement, storage, templates, and tags must be available before a VM can be created. Terraform derives that order from module output references.

The current examples read an existing compute cluster and create resource pools beneath it. Compute-cluster lifecycle and HA/DRS placement rules are not managed yet. The content-library module is optional and should be used only if template-library ownership is in scope.

## Design and security practices

- Child modules do not configure providers or contain credentials.
- Each deployable example pins the provider family and commits its generated `.terraform.lock.hcl`.
- Use a remote state backend with encryption, locking, versioning, and tightly controlled access.
- Use a dedicated least-privilege vCenter service account. The vSphere provider also needs tag-read, event-read, storage-profile-view, and VM swap-placement privileges for common operations.
- Use an enterprise identity provider for users and groups; this repository grants permissions to existing principals rather than managing user passwords.
- Import existing vSphere objects before bringing them under Terraform. Do not recreate production switches, folders, or roles with the same names.
- Run `terraform fmt -check -recursive` and `terraform validate` before merging.

## Version assumptions

The modules require Terraform `>= 1.6, < 2.0` and VMware vSphere provider `>= 2.16, < 3.0`. Provider `2.16.x` supports vSphere versions covered by Broadcom's active product lifecycle; confirm the exact vCenter/ESXi compatibility for your estate before rollout.
