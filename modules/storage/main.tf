data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

resource "vsphere_datastore_cluster" "this" {
  count = var.datastore_cluster == null ? 0 : 1

  name          = try(var.datastore_cluster.name, null)
  datacenter_id = data.vsphere_datacenter.this.id
  folder        = try(var.datastore_cluster.folder, null)
  sdrs_enabled  = try(var.datastore_cluster.sdrs_enabled, false)

  sdrs_automation_level                  = try(var.datastore_cluster.sdrs_automation_level, "manual")
  sdrs_space_utilization_threshold       = try(var.datastore_cluster.space_utilization_threshold, 80)
  sdrs_free_space_utilization_difference = try(var.datastore_cluster.free_space_difference, 5)

  tags              = sort(tolist(try(var.datastore_cluster.tags, [])))
  custom_attributes = try(var.datastore_cluster.custom_attributes, {})
}

resource "vsphere_vm_storage_policy" "this" {
  for_each = var.storage_policies

  name        = each.value.name
  description = each.value.description

  dynamic "tag_rules" {
    for_each = each.value.tag_rules
    content {
      tag_category                 = tag_rules.value.tag_category
      tags                         = sort(tolist(tag_rules.value.tags))
      include_datastores_with_tags = tag_rules.value.include_datastores_with_tags
    }
  }
}
