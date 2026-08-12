mock_provider "vsphere" {
  mock_data "vsphere_datacenter" {
    defaults = { id = "datacenter-1" }
  }
}

variables {
  name                    = "app-01"
  datacenter_name         = "dc-01"
  content_library_item_id = "11111111-1111-1111-1111-111111111111"
  guest_id                = "ubuntu64Guest"
  resource_pool_id        = "resgroup-1"
  datastore_id            = "datastore-1"
  network_interfaces      = [{ network_id = "network-1" }]
  content_library_disks = [{
    label       = "disk0"
    size_gb     = 40
    unit_number = 0
  }]
}

run "content_library_source" {
  command = plan

  assert {
    condition     = vsphere_virtual_machine.this.clone[0].template_uuid == "11111111-1111-1111-1111-111111111111"
    error_message = "The content-library item must be used as the clone source."
  }

  assert {
    condition     = vsphere_virtual_machine.this.force_power_off == false
    error_message = "Force power-off must remain opt-in."
  }
}

run "existing_customization_spec" {
  command = plan

  variables {
    customization_spec_id = "linux-production"
  }

  assert {
    condition     = vsphere_virtual_machine.this.clone[0].customization_spec[0].id == "linux-production"
    error_message = "The existing guest customization specification was not passed to the clone."
  }
}

run "reject_conflicting_customization" {
  command = plan

  variables {
    customization_spec_id = "linux-production"
    linux_customization = {
      host_name = "app-01"
      domain    = "example.com"
    }
  }

  expect_failures = [vsphere_virtual_machine.this]
}

run "reject_duplicate_disk_units" {
  command = plan

  variables {
    additional_disks = [{
      label       = "data"
      size_gb     = 20
      unit_number = 0
    }]
  }

  expect_failures = [vsphere_virtual_machine.this]
}
