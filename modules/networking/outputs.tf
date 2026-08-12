output "distributed_switch_id" {
  description = "Managed object ID/UUID of the distributed switch."
  value       = vsphere_distributed_virtual_switch.this.id
}

output "port_group_ids" {
  description = "Managed object IDs of distributed port groups keyed by input keys."
  value       = { for key, group in vsphere_distributed_port_group.this : key => group.id }
}

output "port_group_keys" {
  description = "Generated distributed port group keys keyed by input keys."
  value       = { for key, group in vsphere_distributed_port_group.this : key => group.key }
}
