variable "datacenter_name" {
  description = "Name of the existing vSphere datacenter."
  type        = string
}

variable "datastore_cluster" {
  description = "Optional datastore cluster configuration. Storage DRS requires the appropriate vSphere license."
  type = object({
    name                        = string
    folder                      = optional(string)
    sdrs_enabled                = optional(bool, false)
    sdrs_automation_level       = optional(string, "manual")
    space_utilization_threshold = optional(number, 80)
    free_space_difference       = optional(number, 5)
    tags                        = optional(set(string), [])
    custom_attributes           = optional(map(string), {})
  })
  default = null
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
