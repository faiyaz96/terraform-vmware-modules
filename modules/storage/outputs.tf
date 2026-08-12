output "datastore_cluster_id" {
  description = "Managed object ID of the datastore cluster, or null when none is created."
  value       = try(vsphere_datastore_cluster.this[0].id, null)
}

output "storage_policy_ids" {
  description = "Storage policy IDs keyed by the input policy keys."
  value       = { for key, policy in vsphere_vm_storage_policy.this : key => policy.id }
}
