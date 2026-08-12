variable "name" {
  description = "Name of the ESXi standard virtual switch."
  type        = string
}

variable "host_system_id" {
  description = "Managed object ID of the ESXi host."
  type        = string
}

variable "mtu" {
  description = "Maximum transmission unit."
  type        = number
  default     = 1500
  validation {
    condition     = var.mtu >= 1280 && var.mtu <= 9000
    error_message = "mtu must be between 1280 and 9000."
  }
}

variable "number_of_ports" {
  description = "Number of switch ports. Changing this setting may require an ESXi reboot."
  type        = number
  default     = 128
}

variable "network_adapters" {
  description = "Physical NIC device names bridged to the switch."
  type        = list(string)
  default     = []
}

variable "active_nics" {
  description = "Active physical NIC device names."
  type        = list(string)
  default     = []
}

variable "standby_nics" {
  description = "Standby physical NIC device names."
  type        = list(string)
  default     = []
}

variable "teaming_policy" {
  description = "NIC teaming policy."
  type        = string
  default     = "failover_explicit"
}

variable "security_policy" {
  description = "Default layer-2 security policy."
  type = object({
    allow_promiscuous      = optional(bool, false)
    allow_forged_transmits = optional(bool, false)
    allow_mac_changes      = optional(bool, false)
  })
  default = {}
}

variable "traffic_shaping" {
  description = "Outbound traffic-shaping settings in bits/bytes as expected by vSphere."
  type = object({
    enabled           = optional(bool, false)
    average_bandwidth = optional(number, 0)
    peak_bandwidth    = optional(number, 0)
    burst_size        = optional(number, 0)
  })
  default = {}
}

variable "port_groups" {
  description = "Standard port groups keyed by stable Terraform identifiers."
  type = map(object({
    name                   = string
    vlan_id                = optional(number, 0)
    allow_promiscuous      = optional(bool, false)
    allow_forged_transmits = optional(bool, false)
    allow_mac_changes      = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for group in values(var.port_groups) : group.vlan_id >= 0 && group.vlan_id <= 4095])
    error_message = "Port-group VLAN IDs must be between 0 and 4095."
  }
}
