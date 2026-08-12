resource "vsphere_host_virtual_switch" "this" {
  name           = var.name
  host_system_id = var.host_system_id

  mtu              = var.mtu
  number_of_ports  = var.number_of_ports
  network_adapters = var.network_adapters
  active_nics      = var.active_nics
  standby_nics     = var.standby_nics
  teaming_policy   = var.teaming_policy

  allow_promiscuous      = var.security_policy.allow_promiscuous
  allow_forged_transmits = var.security_policy.allow_forged_transmits
  allow_mac_changes      = var.security_policy.allow_mac_changes

  shaping_enabled           = var.traffic_shaping.enabled
  shaping_average_bandwidth = var.traffic_shaping.average_bandwidth
  shaping_peak_bandwidth    = var.traffic_shaping.peak_bandwidth
  shaping_burst_size        = var.traffic_shaping.burst_size
}

resource "vsphere_host_port_group" "this" {
  for_each = var.port_groups

  name                = each.value.name
  host_system_id      = var.host_system_id
  virtual_switch_name = vsphere_host_virtual_switch.this.name
  vlan_id             = each.value.vlan_id

  allow_promiscuous      = each.value.allow_promiscuous
  allow_forged_transmits = each.value.allow_forged_transmits
  allow_mac_changes      = each.value.allow_mac_changes
}
