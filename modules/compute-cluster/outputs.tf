output "id" {
  description = "Managed object ID of the compute cluster."
  value       = vsphere_compute_cluster.this.id
}

output "resource_pool_id" {
  description = "Managed object ID of the cluster root resource pool."
  value       = vsphere_compute_cluster.this.resource_pool_id
}
