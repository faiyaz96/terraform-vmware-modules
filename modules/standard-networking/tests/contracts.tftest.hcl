mock_provider "vsphere" {}

variables {
  name             = "vSwitch-application"
  host_system_id   = "host-1"
  network_adapters = ["vmnic2", "vmnic3"]
  active_nics      = ["vmnic2"]
  standby_nics     = ["vmnic3"]
  port_groups = {
    application = {
      name    = "pg-application"
      vlan_id = 120
    }
  }
}

run "standard_switch_contract" {
  command = plan

  assert {
    condition = (
      vsphere_host_virtual_switch.this.host_system_id == "host-1" &&
      !vsphere_host_virtual_switch.this.allow_promiscuous &&
      !vsphere_host_virtual_switch.this.allow_forged_transmits
    )
    error_message = "The standard-switch host or security settings are incorrect."
  }

  assert {
    condition = (
      vsphere_host_port_group.this["application"].virtual_switch_name == "vSwitch-application" &&
      vsphere_host_port_group.this["application"].vlan_id == 120
    )
    error_message = "The standard port group was not attached to the expected switch and VLAN."
  }
}
