data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

resource "vsphere_folder" "this" {
  for_each = var.folders

  path              = each.value.path
  type              = each.value.type
  datacenter_id     = data.vsphere_datacenter.this.id
  tags              = sort(tolist(each.value.tags))
  custom_attributes = each.value.custom_attributes
}
