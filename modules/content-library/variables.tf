variable "name" {
  description = "Name of the content library."
  type        = string
}

variable "description" {
  description = "Description of the content library."
  type        = string
  default     = "Managed by Terraform"
}

variable "datastore_ids" {
  description = "Datastore managed object IDs used as content-library storage backing."
  type        = set(string)
}

variable "publication" {
  description = "Optional publication settings for a local content library."
  type = object({
    published             = optional(bool, true)
    authentication_method = optional(string, "NONE")
    username              = optional(string)
  })
  default = null
}

variable "publication_password" {
  description = "Password used by subscribers when BASIC publication authentication is enabled."
  type        = string
  default     = null
  sensitive   = true
}

variable "subscription" {
  description = "Optional subscription settings. A library cannot be both published and subscribed."
  type = object({
    subscription_url      = string
    authentication_method = optional(string, "NONE")
    username              = optional(string)
    automatic_sync        = optional(bool, false)
    on_demand             = optional(bool, true)
  })
  default = null
}

variable "subscription_password" {
  description = "Password used for BASIC subscription authentication."
  type        = string
  default     = null
  sensitive   = true
}

variable "items" {
  description = "Content library items keyed by a stable identifier. Set exactly one of file_url or source_uuid."
  type = map(object({
    name        = string
    description = optional(string, "Managed by Terraform")
    type        = optional(string, "ovf")
    file_url    = optional(string)
    source_uuid = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for item in values(var.items) :
      (item.file_url != null) != (item.source_uuid != null)
    ])
    error_message = "Each content library item must set exactly one of file_url or source_uuid."
  }
}
