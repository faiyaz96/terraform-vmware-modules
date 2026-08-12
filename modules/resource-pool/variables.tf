variable "name" {
  description = "Name of the resource pool."
  type        = string
}

variable "parent_resource_pool_id" {
  description = "Managed object ID of the parent resource pool or cluster root resource pool."
  type        = string
}

variable "cpu" {
  description = "CPU allocation settings in MHz and shares."
  type = object({
    share_level = optional(string, "normal")
    shares      = optional(number)
    reservation = optional(number, 0)
    expandable  = optional(bool, true)
    limit       = optional(number, -1)
  })
  default = {}
}

variable "memory" {
  description = "Memory allocation settings in MB and shares."
  type = object({
    share_level = optional(string, "normal")
    shares      = optional(number)
    reservation = optional(number, 0)
    expandable  = optional(bool, true)
    limit       = optional(number, -1)
  })
  default = {}
}

variable "tags" {
  description = "vSphere tag IDs to attach to the resource pool."
  type        = set(string)
  default     = []
}
