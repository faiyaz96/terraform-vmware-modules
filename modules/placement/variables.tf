variable "compute_cluster_id" {
  description = "Managed object ID of the target compute cluster."
  type        = string
}

variable "vm_affinity_rules" {
  description = "Rules that prefer or require VMs to run together."
  type = map(object({
    name                = string
    virtual_machine_ids = set(string)
    enabled             = optional(bool, true)
    mandatory           = optional(bool, false)
  }))
  default = {}
}

variable "vm_anti_affinity_rules" {
  description = "Rules that prefer or require VMs to run on different hosts."
  type = map(object({
    name                = string
    virtual_machine_ids = set(string)
    enabled             = optional(bool, true)
    mandatory           = optional(bool, false)
  }))
  default = {}
}

variable "vm_groups" {
  description = "Named VM groups used by VM-to-host rules."
  type = map(object({
    name                = string
    virtual_machine_ids = set(string)
  }))
  default = {}
}

variable "host_groups" {
  description = "Named ESXi host groups used by VM-to-host rules."
  type = map(object({
    name            = string
    host_system_ids = set(string)
  }))
  default = {}
}

variable "vm_host_rules" {
  description = "VM-group to host-group affinity or anti-affinity rules, referencing the map keys above."
  type = map(object({
    name                         = string
    vm_group_key                 = string
    affinity_host_group_key      = optional(string)
    anti_affinity_host_group_key = optional(string)
    enabled                      = optional(bool, true)
    mandatory                    = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.vm_host_rules) :
      (rule.affinity_host_group_key != null) != (rule.anti_affinity_host_group_key != null)
    ])
    error_message = "Every vm_host_rule must set exactly one affinity or anti-affinity host-group key."
  }
}
