output "role_ids" {
  description = "Custom vCenter role IDs keyed by the input role keys."
  value       = { for key, role in vsphere_role.this : key => role.id }
}

output "permission_ids" {
  description = "Entity permission resource IDs keyed by the input permission keys."
  value       = { for key, permission in vsphere_entity_permissions.this : key => permission.id }
}
