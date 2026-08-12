mock_provider "vsphere" {}

variables {
  compute_cluster_id = "domain-c1"
}

run "advisory_anti_affinity" {
  command = plan

  variables {
    vm_anti_affinity_rules = {
      application = {
        name                = "application-spread"
        virtual_machine_ids = ["vm-1", "vm-2"]
      }
    }
  }

  assert {
    condition = (
      vsphere_compute_cluster_vm_anti_affinity_rule.anti_affinity["application"].enabled &&
      !vsphere_compute_cluster_vm_anti_affinity_rule.anti_affinity["application"].mandatory
    )
    error_message = "Placement rules must be enabled but advisory by default."
  }
}

run "vm_to_host_affinity" {
  command = plan

  variables {
    vm_groups = {
      application = {
        name                = "application-vms"
        virtual_machine_ids = ["vm-1", "vm-2"]
      }
    }
    host_groups = {
      application = {
        name            = "application-hosts"
        host_system_ids = ["host-1", "host-2"]
      }
    }
    vm_host_rules = {
      application = {
        name                    = "application-placement"
        vm_group_key            = "application"
        affinity_host_group_key = "application"
      }
    }
  }

  assert {
    condition = (
      vsphere_compute_cluster_vm_host_rule.this["application"].vm_group_name == "application-vms" &&
      vsphere_compute_cluster_vm_host_rule.this["application"].affinity_host_group_name == "application-hosts"
    )
    error_message = "VM-to-host rule dependencies were not composed from the declared groups."
  }
}

run "reject_ambiguous_vm_host_rule" {
  command = plan

  variables {
    vm_host_rules = {
      application = {
        name                         = "application-placement"
        vm_group_key                 = "application"
        affinity_host_group_key      = "host-group-a"
        anti_affinity_host_group_key = "host-group-b"
      }
    }
  }

  expect_failures = [var.vm_host_rules]
}
