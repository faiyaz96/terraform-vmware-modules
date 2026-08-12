variable "name" {
  description = "Name of the virtual machine."
  type        = string
}

variable "datacenter_name" {
  description = "Name of the existing vSphere datacenter."
  type        = string
}

variable "template_name" {
  description = "Inventory path or name of the source virtual machine template."
  type        = string
}

variable "resource_pool_id" {
  description = "Managed object ID of the target resource pool."
  type        = string
}

variable "datastore_id" {
  description = "Managed object ID of the target datastore. Set exactly one of datastore_id or datastore_cluster_id."
  type        = string
  default     = null
}

variable "datastore_cluster_id" {
  description = "Managed object ID of the target Storage DRS datastore cluster. Set exactly one storage destination."
  type        = string
  default     = null
}

variable "folder" {
  description = "VM folder path relative to the datacenter VM inventory root."
  type        = string
  default     = null
}

variable "annotation" {
  description = "Description or operational annotation for the virtual machine."
  type        = string
  default     = "Managed by Terraform"
}

variable "num_cpus" {
  description = "Number of virtual CPUs."
  type        = number
  default     = 2

  validation {
    condition     = var.num_cpus >= 1
    error_message = "num_cpus must be at least 1."
  }
}

variable "num_cores_per_socket" {
  description = "Number of cores per virtual CPU socket. Must divide num_cpus evenly."
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memory assigned to the VM in MB."
  type        = number
  default     = 4096

  validation {
    condition     = var.memory_mb >= 256
    error_message = "memory_mb must be at least 256."
  }
}

variable "cpu_hot_add_enabled" {
  description = "Allow supported guests to hot-add CPUs."
  type        = bool
  default     = false
}

variable "memory_hot_add_enabled" {
  description = "Allow supported guests to hot-add memory."
  type        = bool
  default     = false
}

variable "network_interfaces" {
  description = "Ordered VM network interfaces. Customization entries use the same order; omitted IP addresses use DHCP. Windows DNS settings are configured per interface."
  type = list(object({
    network_id      = string
    adapter_type    = optional(string)
    ipv4_address    = optional(string)
    ipv4_netmask    = optional(number)
    ipv6_address    = optional(string)
    ipv6_netmask    = optional(number)
    dns_server_list = optional(list(string), [])
    dns_domain      = optional(string)
    use_static_mac  = optional(bool, false)
    mac_address     = optional(string)
  }))

  validation {
    condition     = length(var.network_interfaces) > 0
    error_message = "At least one network interface is required."
  }

  validation {
    condition = alltrue([
      for nic in var.network_interfaces :
      nic.ipv4_address == null || nic.ipv4_netmask != null
    ])
    error_message = "Every static IPv4 address requires ipv4_netmask."
  }

  validation {
    condition = alltrue([
      for nic in var.network_interfaces :
      !nic.use_static_mac || nic.mac_address != null
    ])
    error_message = "mac_address is required when use_static_mac is true."
  }
}

variable "linux_customization" {
  description = "Optional Linux guest customization. VMware Tools must be installed in the template."
  type = object({
    host_name       = string
    domain          = string
    dns_server_list = optional(list(string), [])
    dns_suffix_list = optional(list(string), [])
    ipv4_gateway    = optional(string)
    ipv6_gateway    = optional(string)
    timeout         = optional(number, 10)
  })
  default = null
}

variable "windows_customization" {
  description = "Optional Windows Sysprep customization. Set exactly one of workgroup or join_domain. VMware Tools must be installed in the template."
  type = object({
    computer_name         = string
    workgroup             = optional(string)
    join_domain           = optional(string)
    domain_ou             = optional(string)
    domain_admin_user     = optional(string)
    full_name             = optional(string, "Administrator")
    organization_name     = optional(string, "Managed by Terraform")
    run_once_command_list = optional(list(string), [])
    auto_logon            = optional(bool, false)
    auto_logon_count      = optional(number, 1)
    time_zone             = optional(number, 85)
    dns_server_list       = optional(list(string), [])
    dns_suffix_list       = optional(list(string), [])
    ipv4_gateway          = optional(string)
    ipv6_gateway          = optional(string)
    timeout               = optional(number, 10)
  })
  default = null

  validation {
    condition = var.windows_customization == null ? true : (
      (var.windows_customization.workgroup != null) != (var.windows_customization.join_domain != null)
    )
    error_message = "windows_customization must set exactly one of workgroup or join_domain."
  }

  validation {
    condition = var.windows_customization == null ? true : (
      length(var.windows_customization.computer_name) >= 1 && length(var.windows_customization.computer_name) <= 15
    )
    error_message = "Windows computer_name must contain between 1 and 15 characters."
  }
}

variable "windows_admin_password" {
  description = "Optional local Administrator password used during Windows customization. Stored in Terraform state."
  type        = string
  default     = null
  sensitive   = true
}

variable "windows_domain_admin_password" {
  description = "Password for the domain account used to join Windows to Active Directory. Stored in Terraform state."
  type        = string
  default     = null
  sensitive   = true
}

variable "windows_product_key" {
  description = "Optional Windows product key used by Sysprep. Stored in Terraform state."
  type        = string
  default     = null
  sensitive   = true
}

variable "disk_overrides" {
  description = "Overrides for disks inherited from the template, keyed by the exact template disk label. Disk size cannot shrink."
  type = map(object({
    size_gb           = optional(number)
    thin_provisioned  = optional(bool)
    eagerly_scrub     = optional(bool)
    storage_policy_id = optional(string)
  }))
  default = {}
}

variable "additional_disks" {
  description = "Additional virtual disks. Unit numbers must not conflict with template disks."
  type = list(object({
    label             = string
    size_gb           = number
    unit_number       = number
    thin_provisioned  = optional(bool, true)
    eagerly_scrub     = optional(bool, false)
    storage_policy_id = optional(string)
  }))
  default = []
}

variable "storage_policy_id" {
  description = "Default storage policy ID for the VM home and disks without a per-disk override."
  type        = string
  default     = null
}

variable "tags" {
  description = "vSphere tag IDs to attach to the virtual machine."
  type        = set(string)
  default     = []
}

variable "custom_attributes" {
  description = "Map of custom attribute IDs to values."
  type        = map(string)
  default     = {}
}

variable "extra_config" {
  description = "Reviewed VMX advanced settings. Avoid unverified hardening keys because support varies by guest and vSphere version."
  type        = map(string)
  default     = {}
}

variable "security_policy" {
  description = "VM security settings. Pass the security module's vm_policy output."
  type = object({
    firmware                = optional(string)
    efi_secure_boot_enabled = optional(bool, false)
    vtpm_enabled            = optional(bool, false)
    vtpm_version            = optional(string, "2.0")
    vbs_enabled             = optional(bool, false)
    vvtd_enabled            = optional(bool, false)
    nested_hv_enabled       = optional(bool, false)
    enable_logging          = optional(bool, true)
  })
  default = {}
}

variable "linked_clone" {
  description = "Use a linked clone. Disk settings must exactly match the source template."
  type        = bool
  default     = false
}

variable "clone_timeout_minutes" {
  description = "Maximum time to wait for cloning to finish."
  type        = number
  default     = 30
}

variable "wait_for_guest_net_timeout" {
  description = "Minutes to wait for VMware Tools to report guest networking; use 0 to disable."
  type        = number
  default     = 10
}
