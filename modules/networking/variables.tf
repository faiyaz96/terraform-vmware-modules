variable "datacenter_name" {
  description = "Name of the existing vSphere datacenter."
  type        = string
}

variable "name" {
  description = "Name of the vSphere Distributed Switch."
  type        = string
}

variable "folder" {
  description = "Optional network folder path relative to the datacenter."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the distributed switch."
  type        = string
  default     = "Managed by Terraform"
}

variable "max_mtu" {
  description = "Maximum transmission unit for the distributed switch."
  type        = number
  default     = 1500

  validation {
    condition     = var.max_mtu >= 1280 && var.max_mtu <= 9000
    error_message = "max_mtu must be between 1280 and 9000."
  }
}

variable "uplinks" {
  description = "Logical uplink names on the distributed switch."
  type        = list(string)
  default     = ["uplink1", "uplink2"]
}

variable "active_uplinks" {
  description = "Default active uplinks."
  type        = list(string)
  default     = ["uplink1"]
}

variable "standby_uplinks" {
  description = "Default standby uplinks."
  type        = list(string)
  default     = ["uplink2"]
}

variable "host_uplinks" {
  description = "ESXi hosts and ordered physical NIC devices to attach to the distributed switch. Empty means no hosts are attached."
  type        = map(list(string))
  default     = {}
}

variable "tags" {
  description = "vSphere tag IDs to attach to the distributed switch."
  type        = set(string)
  default     = []
}

variable "network_policy" {
  description = "Security settings for the switch and its port groups. Pass the security module's network_policy output."
  type = object({
    allow_promiscuous      = bool
    allow_forged_transmits = bool
    allow_mac_changes      = bool
  })
  default = {
    allow_promiscuous      = false
    allow_forged_transmits = false
    allow_mac_changes      = false
  }
}

variable "port_groups" {
  description = "Distributed port groups keyed by a stable Terraform identifier."
  type = map(object({
    name                             = string
    description                      = optional(string, "Managed by Terraform")
    type                             = optional(string, "earlyBinding")
    vlan_id                          = optional(number)
    vlan_ranges                      = optional(list(object({ min_vlan = number, max_vlan = number })), [])
    number_of_ports                  = optional(number)
    auto_expand                      = optional(bool, true)
    active_uplinks                   = optional(list(string))
    standby_uplinks                  = optional(list(string))
    teaming_policy                   = optional(string, "loadbalance_srcid")
    block_all_ports                  = optional(bool, false)
    netflow_enabled                  = optional(bool, false)
    security_policy_override_allowed = optional(bool, false)
    vlan_override_allowed            = optional(bool, false)
    tags                             = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for group in values(var.port_groups) :
      group.vlan_id == null || (group.vlan_id >= 0 && group.vlan_id <= 4094)
    ])
    error_message = "Each vlan_id must be between 0 and 4094."
  }

  validation {
    condition = alltrue([
      for group in values(var.port_groups) :
      !(group.vlan_id != null && length(group.vlan_ranges) > 0)
    ])
    error_message = "A port group cannot set both vlan_id and vlan_ranges."
  }
}
