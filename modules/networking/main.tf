data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

data "vsphere_host" "this" {
  for_each = var.host_uplinks

  name          = each.key
  datacenter_id = data.vsphere_datacenter.this.id
}

resource "vsphere_distributed_virtual_switch" "this" {
  name          = var.name
  datacenter_id = data.vsphere_datacenter.this.id
  folder        = var.folder
  description   = var.description
  max_mtu       = var.max_mtu
  tags          = sort(tolist(var.tags))

  uplinks         = var.uplinks
  active_uplinks  = var.active_uplinks
  standby_uplinks = var.standby_uplinks

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

  name                            = each.value.name
  description                     = each.value.description
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.this.id
  type                            = each.value.type
  vlan_id                         = each.value.vlan_id
  number_of_ports                 = each.value.number_of_ports
  auto_expand                     = each.value.auto_expand
  active_uplinks                  = each.value.active_uplinks
  standby_uplinks                 = each.value.standby_uplinks
  teaming_policy                  = each.value.teaming_policy
  block_all_ports                 = each.value.block_all_ports
  netflow_enabled                 = each.value.netflow_enabled
  tags                            = sort(tolist(each.value.tags))

  allow_promiscuous      = var.network_policy.allow_promiscuous
  allow_forged_transmits = var.network_policy.allow_forged_transmits
  allow_mac_changes      = var.network_policy.allow_mac_changes

  security_policy_override_allowed = each.value.security_policy_override_allowed
  vlan_override_allowed            = each.value.vlan_override_allowed

  dynamic "vlan_range" {
    for_each = each.value.vlan_ranges
    content {
      min_vlan = vlan_range.value.min_vlan
      max_vlan = vlan_range.value.max_vlan
    }
  }
}
