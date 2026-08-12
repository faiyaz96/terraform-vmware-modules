variable "roles" {
  description = "Custom vCenter roles keyed by a stable identifier. Privilege IDs must be valid for the target vCenter version."
  type = map(object({
    name       = string
    privileges = set(string)
  }))
  default = {}
}

variable "entity_permissions" {
  description = "Permissions keyed by a stable identifier. Each permission uses either role_key for a role created here or role_id for an existing role."
  type = map(object({
    entity_id   = string
    entity_type = string
    permissions = list(object({
      user_or_group = string
      is_group      = bool
      propagate     = optional(bool, true)
      role_key      = optional(string)
      role_id       = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for entity in values(var.entity_permissions) : [
        for permission in entity.permissions :
        (permission.role_key != null) != (permission.role_id != null)
      ]
    ]))
    error_message = "Each permission must set exactly one of role_key or role_id."
  }
}
