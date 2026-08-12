output "vm_affinity_rule_ids" {
  description = "VM affinity rule IDs keyed by input key."
  value       = { for key, rule in vsphere_compute_cluster_vm_affinity_rule.affinity : key => rule.id }
}

output "vm_anti_affinity_rule_ids" {
  description = "VM anti-affinity rule IDs keyed by input key."
  value       = { for key, rule in vsphere_compute_cluster_vm_anti_affinity_rule.anti_affinity : key => rule.id }
}

output "vm_host_rule_ids" {
  description = "VM-to-host rule IDs keyed by input key."
  value       = { for key, rule in vsphere_compute_cluster_vm_host_rule.this : key => rule.id }
}
