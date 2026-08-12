# Changelog

All notable changes to this project are documented here. Releases follow Semantic Versioning.

## 1.1.0 - 2026-08-12

- Add shares, limits, and reservations for all ten provider-supported Network I/O Control traffic classes.
- Add Storage DRS reservable IOPS, percentage, and threshold-mode settings with range and dependency validation.
- Add mocked contract tests for compute cluster, distributed and standard networking, storage, NAS datastore, and placement modules.
- Add NFS protocol safety checks and correct mutually exclusive compute-cluster host-management arguments.
- Keep VMFS datastore creation explicitly out of scope pending confirmed storage ownership.

## 1.0.0 - 2026-08-12

- Add composable vSphere VM, networking, IAM, security, tagging, inventory, resource-pool, storage, and content-library modules.
- Add content-library VM cloning and existing guest customization specifications.
- Add VM allocation, disk, controller, waiter, and shutdown controls.
- Add compute-cluster, NAS datastore, standard networking, and placement modules.
- Add mocked Terraform contract tests and validation CI.
