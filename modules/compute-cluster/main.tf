data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

resource "vsphere_compute_cluster" "this" {
  name          = var.name
  datacenter_id = data.vsphere_datacenter.this.id
  folder        = var.folder

  host_system_ids           = sort(tolist(var.host_system_ids))
  host_managed              = var.host_managed
  host_cluster_exit_timeout = var.host_cluster_exit_timeout
  force_evacuate_on_destroy = var.force_evacuate_on_destroy

  drs_enabled                  = var.drs.enabled
  drs_automation_level         = var.drs.automation_level
  drs_migration_threshold      = var.drs.migration_threshold
  drs_enable_vm_overrides      = var.drs.enable_vm_overrides
  drs_enable_predictive_drs    = var.drs.enable_predictive_drs
  drs_scale_descendants_shares = var.drs.scale_descendants_shares
  drs_advanced_options         = var.drs.advanced_options

  dpm_enabled          = var.dpm.enabled
  dpm_automation_level = var.dpm.automation_level
  dpm_threshold        = var.dpm.threshold

  ha_enabled                                  = var.ha.enabled
  ha_host_monitoring                          = var.ha.host_monitoring
  ha_vm_restart_priority                      = var.ha.vm_restart_priority
  ha_host_isolation_response                  = var.ha.host_isolation_response
  ha_vm_component_protection                  = var.ha.vm_component_protection
  ha_datastore_pdl_response                   = var.ha.datastore_pdl_response
  ha_datastore_apd_response                   = var.ha.datastore_apd_response
  ha_vm_monitoring                            = var.ha.vm_monitoring
  ha_admission_control_policy                 = var.ha.admission_control_policy
  ha_admission_control_host_failure_tolerance = var.ha.host_failure_tolerance
  ha_admission_control_performance_tolerance  = var.ha.performance_tolerance
  ha_heartbeat_datastore_policy               = var.ha.heartbeat_datastore_policy
  ha_heartbeat_datastore_ids                  = sort(tolist(var.ha.heartbeat_datastore_ids))
  ha_advanced_options                         = var.ha.advanced_options

  tags              = sort(tolist(var.tags))
  custom_attributes = var.custom_attributes

  lifecycle {
    precondition {
      condition     = !var.dpm.enabled || var.drs.enabled
      error_message = "DPM requires DRS to be enabled."
    }
    precondition {
      condition     = var.host_managed || length(var.host_system_ids) > 0
      error_message = "Provide host_system_ids or set host_managed when hosts are managed separately."
    }
  }
}
