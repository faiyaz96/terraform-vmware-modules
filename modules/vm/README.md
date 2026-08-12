# VM module

Clones one VM from an existing vSphere template. Deploy multiple VMs with `for_each` at the calling module level so each VM has an independent lifecycle and clear state address.

The module accepts resource-pool, datastore, network, tag, and storage-policy IDs from other modules or data sources. Pass `tags_by_resource_name[<vm-name>]` from the tagging module to apply the standard tags. It supports both Linux and Windows guest customization, template disk growth, additional disks, Secure Boot, vTPM, and VBS.

Keep VMware Tools installed and current in both Linux and Windows templates. Set exactly one of `linux_customization` or `windows_customization`:

- Linux customization configures hostname, domain, DNS and IP settings.
- Windows customization uses Sysprep and supports a workgroup or Active Directory domain join, per-interface DNS, run-once commands, product keys and local Administrator settings.

Windows passwords and product keys are sensitive inputs, but Terraform still stores them in state. Use an encrypted, access-controlled remote state backend and supply secrets through a protected secret workflow. Secure Boot requires an EFI-compatible guest; vTPM requires a configured key provider.
