output "id" {
  description = "Managed object ID of the virtual machine."
  value       = vsphere_virtual_machine.this.id
}

output "uuid" {
  description = "BIOS UUID of the virtual machine."
  value       = vsphere_virtual_machine.this.uuid
}

output "default_ip_address" {
  description = "Default IP address reported by VMware Tools."
  value       = vsphere_virtual_machine.this.default_ip_address
}

output "network_interface_macs" {
  description = "MAC addresses assigned to VM network interfaces."
  value       = [for nic in vsphere_virtual_machine.this.network_interface : nic.mac_address]
}
