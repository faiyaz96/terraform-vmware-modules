mock_provider "vsphere" {
  mock_data "vsphere_datacenter" {
    defaults = { id = "datacenter-1" }
  }
}

variables {
  datacenter_name = "dc-01"
}

run "optional_datastore_cluster" {
  command = plan

  assert {
    condition     = length(vsphere_datastore_cluster.this) == 0
    error_message = "The storage module must not create a datastore cluster unless configured."
  }
}

run "storage_drs_thresholds" {
  command = plan

  variables {
    datastore_cluster = {
      name                                 = "storage-application"
      sdrs_enabled                         = true
      sdrs_automation_level                = "automated"
      sdrs_io_load_balance_enabled         = true
      sdrs_io_reservable_threshold_mode    = "manual"
      sdrs_io_reservable_iops_threshold    = 5000
      sdrs_io_reservable_percent_threshold = 70
      sdrs_free_space_threshold_mode       = "freeSpace"
      sdrs_free_space_threshold            = 100
    }
  }

  assert {
    condition = (
      vsphere_datastore_cluster.this[0].sdrs_enabled &&
      vsphere_datastore_cluster.this[0].sdrs_io_reservable_iops_threshold == 5000 &&
      vsphere_datastore_cluster.this[0].sdrs_io_reservable_percent_threshold == 70 &&
      vsphere_datastore_cluster.this[0].sdrs_free_space_threshold == 100
    )
    error_message = "Storage DRS threshold settings were not passed through."
  }
}

run "reject_manual_iops_without_threshold" {
  command = plan

  variables {
    datastore_cluster = {
      name                              = "storage-application"
      sdrs_io_reservable_threshold_mode = "manual"
    }
  }

  expect_failures = [var.datastore_cluster]
}
