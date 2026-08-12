resource "vsphere_role" "this" {
  for_each = var.roles

  name            = each.value.name
  role_privileges = sort(tolist(each.value.privileges))
}

resource "vsphere_entity_permissions" "this" {
  for_each = var.entity_permissions

  entity_id   = each.value.entity_id
  entity_type = each.value.entity_type

  dynamic "permissions" {
    for_each = {
      for index, permission in each.value.permissions :
      format("%04d-%s", index, lower(permission.user_or_group)) => permission
    }
    content {
      user_or_group = permissions.value.user_or_group
      is_group      = permissions.value.is_group
      propagate     = permissions.value.propagate
      role_id = permissions.value.role_key != null ? (
        vsphere_role.this[permissions.value.role_key].id
      ) : permissions.value.role_id
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for permission in each.value.permissions :
        permission.role_key == null || contains(keys(var.roles), permission.role_key)
      ])
      error_message = "Each role_key must refer to a role declared in roles."
    }
  }
}
