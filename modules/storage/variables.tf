variable "datacenter_name" {
  description = "Name of the existing vSphere datacenter."
  type        = string
}

variable "datastore_cluster" {
  description = "Optional datastore cluster configuration. Storage DRS requires the appropriate vSphere license."
  type = object({
    name                                     = string
    folder                                   = optional(string)
    sdrs_enabled                             = optional(bool, false)
    sdrs_automation_level                    = optional(string, "manual")
    sdrs_space_balance_automation_level      = optional(string, "manual")
    sdrs_io_balance_automation_level         = optional(string, "manual")
    sdrs_rule_enforcement_automation_level   = optional(string, "manual")
    sdrs_policy_enforcement_automation_level = optional(string, "manual")
    sdrs_vm_evacuation_automation_level      = optional(string, "manual")
    sdrs_io_load_balance_enabled             = optional(bool, false)
    sdrs_default_intra_vm_affinity           = optional(bool, true)
    sdrs_io_latency_threshold                = optional(number, 15)
    sdrs_io_load_imbalance_threshold         = optional(number, 5)
    sdrs_io_reservable_iops_threshold        = optional(number)
    sdrs_io_reservable_percent_threshold     = optional(number, 60)
    sdrs_io_reservable_threshold_mode        = optional(string, "automated")
    sdrs_load_balance_interval               = optional(number, 480)
    sdrs_free_space_threshold_mode           = optional(string, "utilization")
    sdrs_free_space_threshold                = optional(number, 50)
    space_utilization_threshold              = optional(number, 80)
    free_space_difference                    = optional(number, 5)
    sdrs_advanced_options                    = optional(map(string), {})
    tags                                     = optional(set(string), [])
    custom_attributes                        = optional(map(string), {})
  })
  default = null

  validation {
    condition = var.datastore_cluster == null ? true : (
      contains(["manual", "automated"], var.datastore_cluster.sdrs_automation_level) &&
      contains(["manual", "automated"], var.datastore_cluster.sdrs_space_balance_automation_level) &&
      contains(["manual", "automated"], var.datastore_cluster.sdrs_io_balance_automation_level) &&
      contains(["manual", "automated"], var.datastore_cluster.sdrs_rule_enforcement_automation_level) &&
      contains(["manual", "automated"], var.datastore_cluster.sdrs_policy_enforcement_automation_level) &&
      contains(["manual", "automated"], var.datastore_cluster.sdrs_vm_evacuation_automation_level)
    )
    error_message = "Storage DRS automation levels must be manual or automated."
  }

  validation {
    condition = var.datastore_cluster == null ? true : (
      var.datastore_cluster.sdrs_io_latency_threshold >= 5 &&
      var.datastore_cluster.sdrs_io_latency_threshold <= 100 &&
      var.datastore_cluster.sdrs_io_load_imbalance_threshold >= 1 &&
      var.datastore_cluster.sdrs_io_load_imbalance_threshold <= 100 &&
      (var.datastore_cluster.sdrs_io_reservable_iops_threshold == null ? true : var.datastore_cluster.sdrs_io_reservable_iops_threshold >= 0) &&
      var.datastore_cluster.sdrs_io_reservable_percent_threshold >= 30 &&
      var.datastore_cluster.sdrs_io_reservable_percent_threshold <= 100
    )
    error_message = "Storage DRS I/O thresholds are outside provider-supported ranges."
  }

  validation {
    condition = var.datastore_cluster == null ? true : (
      contains(["manual", "automated"], var.datastore_cluster.sdrs_io_reservable_threshold_mode) &&
      (var.datastore_cluster.sdrs_io_reservable_threshold_mode != "manual" || var.datastore_cluster.sdrs_io_reservable_iops_threshold != null)
    )
    error_message = "Manual reservable-IOPS mode requires sdrs_io_reservable_iops_threshold."
  }

  validation {
    condition = var.datastore_cluster == null ? true : (
      contains(["utilization", "freeSpace"], var.datastore_cluster.sdrs_free_space_threshold_mode) &&
      var.datastore_cluster.sdrs_load_balance_interval >= 60 &&
      var.datastore_cluster.sdrs_free_space_threshold >= 1 &&
      var.datastore_cluster.space_utilization_threshold >= 1 &&
      var.datastore_cluster.free_space_difference >= 1 &&
      var.datastore_cluster.free_space_difference <= 50
    )
    error_message = "Storage DRS space thresholds or load-balance interval are outside provider-supported ranges."
  }
}

variable "storage_policies" {
  description = "Tag-based VM storage policies keyed by a stable Terraform identifier."
  type = map(object({
    name        = string
    description = optional(string, "Managed by Terraform")
    tag_rules = list(object({
      tag_category                 = string
      tags                         = set(string)
      include_datastores_with_tags = optional(bool, true)
    }))
  }))
  default = {}
}
