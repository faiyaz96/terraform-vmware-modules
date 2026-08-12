output "vm_policy" {
  description = "VM security settings accepted by the vm module."
  value = {
    firmware                = local.vm_requires_efi ? "efi" : null
    efi_secure_boot_enabled = var.enable_secure_boot
    vtpm_enabled            = var.enable_vtpm
    vtpm_version            = var.vtpm_version
    vbs_enabled             = var.enable_vbs
    vvtd_enabled            = var.enable_vbs
    nested_hv_enabled       = var.enable_vbs
    enable_logging          = true
  }

  precondition {
    condition     = !var.enable_vbs || (var.enable_secure_boot && var.enable_vtpm)
    error_message = "VBS requires both Secure Boot and vTPM to be enabled."
  }
}

output "network_policy" {
  description = "Distributed switch and port-group security settings accepted by the networking module."
  value = {
    allow_promiscuous      = var.allow_promiscuous
    allow_forged_transmits = var.allow_forged_transmits
    allow_mac_changes      = var.allow_mac_changes
  }
}
