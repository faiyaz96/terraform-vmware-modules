variable "name" {
  description = "Name of the compute cluster."
  type        = string
}

variable "datacenter_name" {
  description = "Name of the existing vSphere datacenter."
  type        = string
}

variable "folder" {
  description = "Optional host-folder path relative to the datacenter."
  type        = string
  default     = null
}

variable "host_system_ids" {
  description = "Managed object IDs of ESXi hosts assigned to the cluster."
  type        = set(string)
  default     = []
}

variable "host_managed" {
  description = "Manage membership through separate vsphere_host resources instead of this cluster resource."
  type        = bool
  default     = false
}

variable "host_cluster_exit_timeout" {
  description = "Seconds allowed for each host maintenance-mode operation during removal."
  type        = number
  default     = 3600
}

variable "force_evacuate_on_destroy" {
  description = "Force hosts out of the cluster during destroy. Keep false for production safety."
  type        = bool
  default     = false
}

variable "drs" {
  description = "Distributed Resource Scheduler settings."
  type = object({
    enabled                  = optional(bool, false)
    automation_level         = optional(string, "manual")
    migration_threshold      = optional(number, 3)
    enable_vm_overrides      = optional(bool, true)
    enable_predictive_drs    = optional(bool, false)
    scale_descendants_shares = optional(string, "disabled")
    advanced_options         = optional(map(string), {})
  })
  default = {}

  validation {
    condition     = contains(["manual", "partiallyAutomated", "fullyAutomated"], var.drs.automation_level)
    error_message = "drs.automation_level must be manual, partiallyAutomated, or fullyAutomated."
  }
}

variable "dpm" {
  description = "Distributed Power Management settings."
  type = object({
    enabled          = optional(bool, false)
    automation_level = optional(string, "manual")
    threshold        = optional(number, 3)
  })
  default = {}
}

variable "ha" {
  description = "vSphere High Availability and admission-control settings."
  type = object({
    enabled                    = optional(bool, false)
    host_monitoring            = optional(string, "enabled")
    vm_restart_priority        = optional(string, "medium")
    host_isolation_response    = optional(string, "none")
    vm_component_protection    = optional(string, "enabled")
    datastore_pdl_response     = optional(string, "disabled")
    datastore_apd_response     = optional(string, "disabled")
    vm_monitoring              = optional(string, "vmMonitoringDisabled")
    admission_control_policy   = optional(string, "resourcePercentage")
    host_failure_tolerance     = optional(number, 1)
    performance_tolerance      = optional(number, 100)
    heartbeat_datastore_policy = optional(string, "allFeasibleDsWithUserPreference")
    heartbeat_datastore_ids    = optional(set(string), [])
    advanced_options           = optional(map(string), {})
  })
  default = {}
}

variable "tags" {
  description = "vSphere tag IDs to attach to the cluster."
  type        = set(string)
  default     = []
}

variable "custom_attributes" {
  description = "Map of custom attribute IDs to values."
  type        = map(string)
  default     = {}
}
