variable "project" {
  description = "Project value applied to every tagged resource."
  type        = string

  validation {
    condition     = trimspace(var.project) != ""
    error_message = "project must not be empty."
  }
}

variable "resource_names" {
  description = "Resource names for which Name tag values and standard tag sets are created."
  type        = set(string)

  validation {
    condition     = length(var.resource_names) > 0 && alltrue([for name in var.resource_names : trimspace(name) != ""])
    error_message = "resource_names must contain at least one non-empty resource name."
  }
}

variable "associable_types" {
  description = "vSphere managed object types to which the standard tag categories may be attached. Types cannot be removed later."
  type        = set(string)
  default = [
    "DistributedVirtualPortgroup",
    "DistributedVirtualSwitch",
    "Folder",
    "ResourcePool",
    "StoragePod",
    "VirtualMachine",
    "VmwareDistributedVirtualSwitch",
  ]
}
