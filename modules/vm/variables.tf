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
  default     = null
}

variable "content_library_item_id" {
  description = "UUID of a content-library item to clone. Set exactly one of template_name or content_library_item_id."
  type        = string
  default     = null
}

variable "guest_id" {
  description = "Optional guest OS identifier override. Required for content-library items."
  type        = string
  default     = null
}

variable "scsi_type" {
  description = "Optional SCSI controller type override. Inventory templates inherit their controller type."
  type        = string
  default     = null

  validation {
    condition     = var.scsi_type == null ? true : contains(["lsilogic", "lsilogic-sas", "pvscsi"], var.scsi_type)
    error_message = "scsi_type must be lsilogic, lsilogic-sas, or pvscsi."
  }
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

variable "cpu_hot_remove_enabled" {
  description = "Allow supported guests to hot-remove CPUs."
  type        = bool
  default     = false
}

variable "cpu_allocation" {
  description = "CPU allocation controls in MHz and shares. A limit of -1 means unlimited."
  type = object({
    reservation = optional(number, 0)
    limit       = optional(number, -1)
    share_level = optional(string, "normal")
    share_count = optional(number)
  })
  default = {}

  validation {
    condition     = contains(["low", "normal", "high", "custom"], var.cpu_allocation.share_level)
    error_message = "cpu_allocation.share_level must be low, normal, high, or custom."
  }

  validation {
    condition     = var.cpu_allocation.share_level != "custom" || var.cpu_allocation.share_count != null
    error_message = "cpu_allocation.share_count is required when share_level is custom."
  }
}

variable "memory_hot_add_enabled" {
  description = "Allow supported guests to hot-add memory."
  type        = bool
  default     = false
}

variable "memory_allocation" {
  description = "Memory allocation controls in MB and shares. A limit of -1 means unlimited."
  type = object({
    reservation        = optional(number, 0)
    reservation_locked = optional(bool, false)
    limit              = optional(number, -1)
    share_level        = optional(string, "normal")
    share_count        = optional(number)
  })
  default = {}

  validation {
    condition     = contains(["low", "normal", "high", "custom"], var.memory_allocation.share_level)
    error_message = "memory_allocation.share_level must be low, normal, high, or custom."
  }

  validation {
    condition     = var.memory_allocation.share_level != "custom" || var.memory_allocation.share_count != null
    error_message = "memory_allocation.share_count is required when share_level is custom."
  }
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
    datastore_id      = optional(string)
    storage_policy_id = optional(string)
    disk_mode         = optional(string)
    disk_sharing      = optional(string)
    io_reservation    = optional(number)
    io_share_level    = optional(string, "normal")
    io_share_count    = optional(number)
  }))
  default = {}
}

variable "content_library_disks" {
  description = "Disk declarations required when cloning a content-library item."
  type = list(object({
    label             = string
    size_gb           = number
    unit_number       = number
    thin_provisioned  = optional(bool, true)
    eagerly_scrub     = optional(bool, false)
    datastore_id      = optional(string)
    storage_policy_id = optional(string)
    disk_mode         = optional(string)
    disk_sharing      = optional(string)
    io_reservation    = optional(number)
    io_share_level    = optional(string, "normal")
    io_share_count    = optional(number)
  }))
  default = []
}

variable "additional_disks" {
  description = "Additional virtual disks. Unit numbers must not conflict with template disks."
  type = list(object({
    label             = string
    size_gb           = optional(number)
    unit_number       = number
    thin_provisioned  = optional(bool, true)
    eagerly_scrub     = optional(bool, false)
    datastore_id      = optional(string)
    storage_policy_id = optional(string)
    disk_mode         = optional(string)
    disk_sharing      = optional(string)
    io_reservation    = optional(number)
    io_share_level    = optional(string, "normal")
    io_share_count    = optional(number)
    attach            = optional(bool, false)
    path              = optional(string)
    keep_on_remove    = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for disk in var.additional_disks :
      disk.attach ? disk.path != null : disk.size_gb != null
    ])
    error_message = "Each created disk requires size_gb; each attached disk requires path."
  }

  validation {
    condition = alltrue([
      for disk in var.additional_disks :
      disk.attach ? endswith(lower(disk.path), ".vmdk") : true
    ])
    error_message = "Every attached disk path must end with .vmdk."
  }
}


variable "scsi_controller_count" {
  description = "Number of SCSI controllers presented to the VM."
  type        = number
  default     = 1

  validation {
    condition     = var.scsi_controller_count >= 1 && var.scsi_controller_count <= 4
    error_message = "scsi_controller_count must be between 1 and 4."
  }
}

variable "scsi_bus_sharing" {
  description = "SCSI bus-sharing mode."
  type        = string
  default     = "noSharing"

  validation {
    condition     = contains(["noSharing", "virtualSharing", "physicalSharing"], var.scsi_bus_sharing)
    error_message = "scsi_bus_sharing must be noSharing, virtualSharing, or physicalSharing."
  }
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

variable "customization_spec_id" {
  description = "Name/ID of an existing vCenter guest customization specification. Conflicts with inline Linux or Windows customization."
  type        = string
  default     = null
}

variable "customization_spec_timeout" {
  description = "Minutes to wait for an existing guest customization specification."
  type        = number
  default     = 10
}

variable "ovf_network_map" {
  description = "Optional OVF network-name to vSphere network-ID mapping for content-library items."
  type        = map(string)
  default     = {}
}

variable "ovf_storage_map" {
  description = "Optional OVF storage-name to datastore-ID mapping for content-library items."
  type        = map(string)
  default     = {}
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

variable "wait_for_guest_ip_timeout" {
  description = "Minutes to wait for VMware Tools to report a guest IP; use 0 to disable."
  type        = number
  default     = 0
}

variable "wait_for_guest_net_routable" {
  description = "Require a routable guest IP before the network waiter completes."
  type        = bool
  default     = true
}

variable "ignored_guest_ips" {
  description = "Guest IP addresses or CIDRs ignored by the network waiter."
  type        = list(string)
  default     = []
}

variable "shutdown_wait_timeout" {
  description = "Minutes to wait for a graceful guest shutdown before applying force_power_off behavior."
  type        = number
  default     = 3
}

variable "force_power_off" {
  description = "Allow vSphere to force power off the VM after the shutdown timeout."
  type        = bool
  default     = false
}

variable "host_system_id" {
  description = "Optional ESXi host managed object ID. Leave null to allow DRS placement."
  type        = string
  default     = null
}

variable "hardware_version" {
  description = "Optional VM hardware version. Hardware versions cannot be downgraded."
  type        = number
  default     = null
}

variable "enable_disk_uuid" {
  description = "Expose virtual disk UUIDs to the guest operating system."
  type        = bool
  default     = false
}

variable "cpu_performance_counters_enabled" {
  description = "Expose virtual CPU performance counters to the guest."
  type        = bool
  default     = false
}

variable "latency_sensitivity" {
  description = "VM latency-sensitivity setting."
  type        = string
  default     = "normal"
}

variable "swap_placement_policy" {
  description = "VM swap-file placement policy."
  type        = string
  default     = "inherit"
}
