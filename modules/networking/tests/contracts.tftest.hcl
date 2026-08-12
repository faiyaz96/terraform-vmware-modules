mock_provider "vsphere" {
  mock_data "vsphere_datacenter" {
    defaults = { id = "datacenter-1" }
  }
}

variables {
  name            = "vds-application"
  datacenter_name = "dc-01"
  port_groups = {
    application = {
      name    = "dvpg-application"
      vlan_id = 120
    }
  }
}

run "secure_defaults" {
  command = plan

  assert {
    condition = (
      !vsphere_distributed_virtual_switch.this.allow_promiscuous &&
      !vsphere_distributed_virtual_switch.this.allow_forged_transmits &&
      !vsphere_distributed_virtual_switch.this.allow_mac_changes
    )
    error_message = "The distributed-switch security baseline must deny permissive MAC behavior."
  }

  assert {
    condition     = vsphere_distributed_port_group.this["application"].vlan_id == 120
    error_message = "The port-group VLAN was not passed through."
  }
}

run "nioc_traffic_allocations" {
  command = plan

  variables {
    network_io_control = {
      enabled = true
      version = "version3"
      traffic_classes = {
        virtualmachine = {
          share_level      = "custom"
          share_count      = 150
          maximum_mbit     = 2000
          reservation_mbit = 500
        }
        vmotion = {
          share_level      = "high"
          maximum_mbit     = 1000
          reservation_mbit = 200
        }
      }
    }
  }

  assert {
    condition = (
      vsphere_distributed_virtual_switch.this.network_resource_control_enabled &&
      vsphere_distributed_virtual_switch.this.virtualmachine_share_count == 150 &&
      vsphere_distributed_virtual_switch.this.virtualmachine_reservation_mbit == 500 &&
      vsphere_distributed_virtual_switch.this.vmotion_maximum_mbit == 1000
    )
    error_message = "NIOC traffic-class allocations were not passed to the VDS."
  }
}

run "reject_custom_shares_without_count" {
  command = plan

  variables {
    network_io_control = {
      enabled = true
      traffic_classes = {
        management = { share_level = "custom" }
      }
    }
  }

  expect_failures = [var.network_io_control]
}

run "reject_netflow_without_collector" {
  command = plan

  variables {
    port_groups = {
      application = {
        name            = "dvpg-application"
        vlan_id         = 120
        netflow_enabled = true
      }
    }
  }

  expect_failures = [vsphere_distributed_port_group.this["application"]]
}
