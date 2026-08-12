variable "enable_secure_boot" {
  description = "Enable EFI Secure Boot in the VM baseline. The source template and guest OS must support EFI."
  type        = bool
  default     = true
}

variable "enable_vtpm" {
  description = "Add a virtual TPM to VMs. This requires a configured vSphere key provider."
  type        = bool
  default     = false
}

variable "vtpm_version" {
  description = "Virtual TPM version to use when vTPM is enabled."
  type        = string
  default     = "2.0"

  validation {
    condition     = contains(["1.2", "2.0"], var.vtpm_version)
    error_message = "vtpm_version must be either 1.2 or 2.0."
  }
}

variable "enable_vbs" {
  description = "Enable Virtualization Based Security for supported Windows guests."
  type        = bool
  default     = false
}

variable "allow_promiscuous" {
  description = "Allow promiscuous mode on distributed port groups. Keep false unless a reviewed appliance requires it."
  type        = bool
  default     = false
}

variable "allow_forged_transmits" {
  description = "Allow a guest to transmit frames using a MAC address different from its assigned address."
  type        = bool
  default     = false
}

variable "allow_mac_changes" {
  description = "Allow a guest to change the effective MAC address of its virtual NIC."
  type        = bool
  default     = false
}
