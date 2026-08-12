output "switch_id" {
  description = "Terraform ID of the standard virtual switch."
  value       = vsphere_host_virtual_switch.this.id
}

output "port_group_ids" {
  description = "Port-group IDs keyed by the input keys."
  value       = { for key, group in vsphere_host_port_group.this : key => group.id }
}
