output "id" {
  description = "Managed object ID of the NAS datastore."
  value       = vsphere_nas_datastore.this.id
}

output "accessible" {
  description = "Whether the datastore is currently accessible."
  value       = vsphere_nas_datastore.this.accessible
}
