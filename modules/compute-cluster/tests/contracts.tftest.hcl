mock_provider "vsphere" {
  mock_data "vsphere_datacenter" {
    defaults = { id = "datacenter-1" }
  }
}

variables {
  name            = "cluster-application"
  datacenter_name = "dc-01"
  host_system_ids = ["host-1", "host-2"]
}

run "safe_defaults" {
  command = plan

  assert {
    condition     = vsphere_compute_cluster.this.force_evacuate_on_destroy == false
    error_message = "Forced host evacuation must remain disabled by default."
  }

  assert {
    condition     = vsphere_compute_cluster.this.drs_enabled == false && vsphere_compute_cluster.this.ha_enabled == false
    error_message = "DRS and HA must remain opt-in."
  }
}

run "ha_drs_and_dpm" {
  command = plan

  variables {
    drs = {
      enabled          = true
      automation_level = "fullyAutomated"
    }
    dpm = {
      enabled          = true
      automation_level = "automated"
    }
    ha = {
      enabled                = true
      host_failure_tolerance = 1
    }
  }

  assert {
    condition     = vsphere_compute_cluster.this.drs_enabled && vsphere_compute_cluster.this.dpm_enabled && vsphere_compute_cluster.this.ha_enabled
    error_message = "HA, DRS, and DPM settings were not passed to the cluster resource."
  }
}

run "reject_dpm_without_drs" {
  command = plan

  variables {
    dpm = { enabled = true }
  }

  expect_failures = [vsphere_compute_cluster.this]
}
