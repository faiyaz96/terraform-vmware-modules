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

variable "contact_name" {
  description = "Operational owner of the distributed switch."
  type        = string
  default     = null
}

variable "contact_detail" {
  description = "Contact details for the distributed-switch owner."
  type        = string
  default     = null
}

variable "ipv4_address" {
  description = "Optional IPv4 address used to identify the switch."
  type        = string
  default     = null
}

variable "lacp_api_version" {
  description = "LACP API version for the VDS."
  type        = string
  default     = "singleLag"
}

variable "link_discovery_operation" {
  description = "Link-discovery operation."
  type        = string
  default     = "listen"
}

variable "link_discovery_protocol" {
  description = "Link-discovery protocol: cdp or lldp."
  type        = string
  default     = "cdp"
}

variable "multicast_filtering_mode" {
  description = "Multicast filtering mode."
  type        = string
  default     = "snooping"
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

variable "custom_attributes" {
  description = "Map of custom attribute IDs to values."
  type        = map(string)
  default     = {}
}

variable "lacp" {
  description = "Default LACP policy for VDS uplinks."
  type = object({
    enabled = optional(bool, false)
    mode    = optional(string, "active")
  })
  default = {}
}

variable "netflow" {
  description = "VDS NetFlow collector configuration."
  type = object({
    collector_ip_address  = optional(string)
    collector_port        = optional(number)
    active_flow_timeout   = optional(number, 60)
    idle_flow_timeout     = optional(number, 15)
    internal_flows_only   = optional(bool, false)
    observation_domain_id = optional(number, 0)
    sampling_rate         = optional(number, 0)
  })
  default = {}
}

variable "network_io_control" {
  description = "Network I/O Control configuration."
  type = object({
    enabled = optional(bool, false)
    version = optional(string, "version3")
  })
  default = {}
}

variable "ingress_traffic_shaping" {
  description = "Default ingress traffic-shaping policy."
  type = object({
    enabled           = optional(bool, false)
    average_bandwidth = optional(number, 0)
    peak_bandwidth    = optional(number, 0)
    burst_size        = optional(number, 0)
  })
  default = {}
}

variable "egress_traffic_shaping" {
  description = "Default egress traffic-shaping policy."
  type = object({
    enabled           = optional(bool, false)
    average_bandwidth = optional(number, 0)
    peak_bandwidth    = optional(number, 0)
    burst_size        = optional(number, 0)
  })
  default = {}
}

variable "pvlan_mappings" {
  description = "Private VLAN mappings keyed by stable Terraform identifiers."
  type = map(object({
    primary_vlan_id   = number
    secondary_vlan_id = number
    pvlan_type        = string
  }))
  default = {}
}

variable "ignore_other_pvlan_mappings" {
  description = "Preserve PVLAN mappings not declared by this module."
  type        = bool
  default     = true
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
    name                      = string
    description               = optional(string, "Managed by Terraform")
    type                      = optional(string, "earlyBinding")
    vlan_id                   = optional(number)
    vlan_ranges               = optional(list(object({ min_vlan = number, max_vlan = number })), [])
    number_of_ports           = optional(number)
    auto_expand               = optional(bool, true)
    active_uplinks            = optional(list(string))
    standby_uplinks           = optional(list(string))
    teaming_policy            = optional(string, "loadbalance_srcid")
    block_all_ports           = optional(bool, false)
    netflow_enabled           = optional(bool, false)
    private_secondary_vlan_id = optional(number)
    ingress_traffic_shaping = optional(object({
      enabled           = optional(bool, false)
      average_bandwidth = optional(number, 0)
      peak_bandwidth    = optional(number, 0)
      burst_size        = optional(number, 0)
    }), {})
    egress_traffic_shaping = optional(object({
      enabled           = optional(bool, false)
      average_bandwidth = optional(number, 0)
      peak_bandwidth    = optional(number, 0)
      burst_size        = optional(number, 0)
    }), {})
    tx_uplink                        = optional(bool, false)
    directpath_gen2_allowed          = optional(bool, false)
    security_policy_override_allowed = optional(bool, false)
    shaping_override_allowed         = optional(bool, false)
    uplink_teaming_override_allowed  = optional(bool, false)
    netflow_override_allowed         = optional(bool, false)
    vlan_override_allowed            = optional(bool, false)
    tags                             = optional(set(string), [])
    custom_attributes                = optional(map(string), {})
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
