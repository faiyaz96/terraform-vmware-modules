resource "vsphere_compute_cluster_vm_affinity_rule" "affinity" {
  for_each = var.vm_affinity_rules

  name                = each.value.name
  compute_cluster_id  = var.compute_cluster_id
  virtual_machine_ids = sort(tolist(each.value.virtual_machine_ids))
  enabled             = each.value.enabled
  mandatory           = each.value.mandatory
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "anti_affinity" {
  for_each = var.vm_anti_affinity_rules

  name                = each.value.name
  compute_cluster_id  = var.compute_cluster_id
  virtual_machine_ids = sort(tolist(each.value.virtual_machine_ids))
  enabled             = each.value.enabled
  mandatory           = each.value.mandatory
}

resource "vsphere_compute_cluster_vm_group" "this" {
  for_each = var.vm_groups

  name                = each.value.name
  compute_cluster_id  = var.compute_cluster_id
  virtual_machine_ids = sort(tolist(each.value.virtual_machine_ids))
}

resource "vsphere_compute_cluster_host_group" "this" {
  for_each = var.host_groups

  name               = each.value.name
  compute_cluster_id = var.compute_cluster_id
  host_system_ids    = sort(tolist(each.value.host_system_ids))
}

resource "vsphere_compute_cluster_vm_host_rule" "this" {
  for_each = var.vm_host_rules

  name                          = each.value.name
  compute_cluster_id            = var.compute_cluster_id
  vm_group_name                 = vsphere_compute_cluster_vm_group.this[each.value.vm_group_key].name
  affinity_host_group_name      = each.value.affinity_host_group_key == null ? null : vsphere_compute_cluster_host_group.this[each.value.affinity_host_group_key].name
  anti_affinity_host_group_name = each.value.anti_affinity_host_group_key == null ? null : vsphere_compute_cluster_host_group.this[each.value.anti_affinity_host_group_key].name
  enabled                       = each.value.enabled
  mandatory                     = each.value.mandatory
}
