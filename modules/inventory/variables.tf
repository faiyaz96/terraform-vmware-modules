variable "datacenter_name" {
  description = "Name of the existing vSphere datacenter in which folders are created."
  type        = string
}

variable "folders" {
  description = "Inventory folders keyed by a stable Terraform identifier. Paths are relative to their inventory type root."
  type = map(object({
    path              = string
    type              = string
    tags              = optional(set(string), [])
    custom_attributes = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for folder in values(var.folders) : contains(["host", "vm", "datastore", "network"], folder.type)])
    error_message = "Folder type must be host, vm, datastore, or network."
  }
}
