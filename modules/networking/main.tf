data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

data "vsphere_host" "this" {
  for_each = var.host_uplinks

  name          = each.key
  datacenter_id = data.vsphere_datacenter.this.id
}

resource "vsphere_distributed_virtual_switch" "this" {
  name                     = var.name
  datacenter_id            = data.vsphere_datacenter.this.id
  folder                   = var.folder
  description              = var.description
  contact_name             = var.contact_name
  contact_detail           = var.contact_detail
  ipv4_address             = var.ipv4_address
  lacp_api_version         = var.lacp_api_version
  link_discovery_operation = var.link_discovery_operation
  link_discovery_protocol  = var.link_discovery_protocol
  multicast_filtering_mode = var.multicast_filtering_mode
  max_mtu                  = var.max_mtu
  tags                     = sort(tolist(var.tags))
  custom_attributes        = var.custom_attributes

  uplinks         = var.uplinks
  active_uplinks  = var.active_uplinks
  standby_uplinks = var.standby_uplinks
  lacp_enabled    = var.lacp.enabled
  lacp_mode       = var.lacp.mode

  ingress_shaping_enabled           = var.ingress_traffic_shaping.enabled
  ingress_shaping_average_bandwidth = var.ingress_traffic_shaping.average_bandwidth
  ingress_shaping_peak_bandwidth    = var.ingress_traffic_shaping.peak_bandwidth
  ingress_shaping_burst_size        = var.ingress_traffic_shaping.burst_size
  egress_shaping_enabled            = var.egress_traffic_shaping.enabled
  egress_shaping_average_bandwidth  = var.egress_traffic_shaping.average_bandwidth
  egress_shaping_peak_bandwidth     = var.egress_traffic_shaping.peak_bandwidth
  egress_shaping_burst_size         = var.egress_traffic_shaping.burst_size

  netflow_active_flow_timeout      = var.netflow.active_flow_timeout
  netflow_collector_ip_address     = var.netflow.collector_ip_address
  netflow_collector_port           = var.netflow.collector_port
  netflow_idle_flow_timeout        = var.netflow.idle_flow_timeout
  netflow_internal_flows_only      = var.netflow.internal_flows_only
  netflow_observation_domain_id    = var.netflow.observation_domain_id
  netflow_sampling_rate            = var.netflow.sampling_rate
  network_resource_control_enabled = var.network_io_control.enabled
  network_resource_control_version = var.network_io_control.version
  ignore_other_pvlan_mappings      = var.ignore_other_pvlan_mappings

  dynamic "pvlan_mapping" {
    for_each = var.pvlan_mappings
    content {
      primary_vlan_id   = pvlan_mapping.value.primary_vlan_id
      secondary_vlan_id = pvlan_mapping.value.secondary_vlan_id
      pvlan_type        = pvlan_mapping.value.pvlan_type
    }
  }

  allow_promiscuous      = var.network_policy.allow_promiscuous
  allow_forged_transmits = var.network_policy.allow_forged_transmits
  allow_mac_changes      = var.network_policy.allow_mac_changes

  dynamic "host" {
    for_each = var.host_uplinks
    content {
      host_system_id = data.vsphere_host.this[host.key].id
      devices        = host.value
    }
  }

  lifecycle {
    precondition {
      condition     = alltrue([for uplink in concat(var.active_uplinks, var.standby_uplinks) : contains(var.uplinks, uplink)])
      error_message = "All active and standby uplinks must be present in uplinks."
    }
  }
}

resource "vsphere_distributed_port_group" "this" {
  for_each = var.port_groups

  name                              = each.value.name
  description                       = each.value.description
  distributed_virtual_switch_uuid   = vsphere_distributed_virtual_switch.this.id
  type                              = each.value.type
  vlan_id                           = each.value.vlan_id
  number_of_ports                   = each.value.number_of_ports
  auto_expand                       = each.value.auto_expand
  active_uplinks                    = each.value.active_uplinks
  standby_uplinks                   = each.value.standby_uplinks
  teaming_policy                    = each.value.teaming_policy
  block_all_ports                   = each.value.block_all_ports
  netflow_enabled                   = each.value.netflow_enabled
  tags                              = sort(tolist(each.value.tags))
  custom_attributes                 = each.value.custom_attributes
  port_private_secondary_vlan_id    = each.value.private_secondary_vlan_id
  ingress_shaping_enabled           = each.value.ingress_traffic_shaping.enabled
  ingress_shaping_average_bandwidth = each.value.ingress_traffic_shaping.average_bandwidth
  ingress_shaping_peak_bandwidth    = each.value.ingress_traffic_shaping.peak_bandwidth
  ingress_shaping_burst_size        = each.value.ingress_traffic_shaping.burst_size
  egress_shaping_enabled            = each.value.egress_traffic_shaping.enabled
  egress_shaping_average_bandwidth  = each.value.egress_traffic_shaping.average_bandwidth
  egress_shaping_peak_bandwidth     = each.value.egress_traffic_shaping.peak_bandwidth
  egress_shaping_burst_size         = each.value.egress_traffic_shaping.burst_size
  tx_uplink                         = each.value.tx_uplink
  directpath_gen2_allowed           = each.value.directpath_gen2_allowed

  allow_promiscuous      = var.network_policy.allow_promiscuous
  allow_forged_transmits = var.network_policy.allow_forged_transmits
  allow_mac_changes      = var.network_policy.allow_mac_changes

  security_policy_override_allowed = each.value.security_policy_override_allowed
  shaping_override_allowed         = each.value.shaping_override_allowed
  uplink_teaming_override_allowed  = each.value.uplink_teaming_override_allowed
  netflow_override_allowed         = each.value.netflow_override_allowed
  vlan_override_allowed            = each.value.vlan_override_allowed

  dynamic "vlan_range" {
    for_each = each.value.vlan_ranges
    content {
      min_vlan = vlan_range.value.min_vlan
      max_vlan = vlan_range.value.max_vlan
    }
  }

  lifecycle {
    precondition {
      condition     = !each.value.netflow_enabled || (var.netflow.collector_ip_address != null && var.netflow.collector_port != null)
      error_message = "A NetFlow-enabled port group requires a collector IP address and port on the VDS."
    }
  }
}
