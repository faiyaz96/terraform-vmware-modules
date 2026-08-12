# VM module

Clones one VM from an existing vSphere inventory template or content-library item. Deploy multiple VMs with `for_each` at the calling module level so each VM has an independent lifecycle and clear state address.

The module accepts resource-pool, datastore, network, tag, and storage-policy IDs from other modules or data sources. Pass `tags_by_resource_name[<vm-name>]` from the tagging module to apply the standard tags. It supports inline Linux and Windows customization, existing guest customization specifications, allocation controls, per-disk placement and I/O settings, Secure Boot, vTPM, and VBS.

Set exactly one VM source:

- `template_name` for an inventory template. Hardware and inherited disks are discovered automatically.
- `content_library_item_id` for a content-library item. Also provide `guest_id` and `content_library_disks` because the item data source does not expose VM hardware metadata.

Keep VMware Tools installed and current in both Linux and Windows templates. Set only one of `linux_customization`, `windows_customization`, or `customization_spec_id`:

- Linux customization configures hostname, domain, DNS and IP settings.
- Windows customization uses Sysprep and supports a workgroup or Active Directory domain join, per-interface DNS, run-once commands, product keys and local Administrator settings.

Windows passwords and product keys are sensitive inputs, but Terraform still stores them in state. Use an encrypted, access-controlled remote state backend and supply secrets through a protected secret workflow. Secure Boot requires an EFI-compatible guest; vTPM requires a configured key provider.

`force_power_off` defaults to `false`; enabling it permits vSphere to power off an unresponsive guest after the shutdown timeout. Attached VMDKs and host pinning should be used only with explicit operational ownership.
