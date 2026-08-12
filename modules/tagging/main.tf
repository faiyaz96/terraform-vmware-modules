resource "vsphere_tag_category" "name" {
  name             = "Name"
  description      = "Resource name managed by Terraform"
  cardinality      = "SINGLE"
  associable_types = sort(tolist(var.associable_types))
}

resource "vsphere_tag_category" "project" {
  name             = "project"
  description      = "Owning project"
  cardinality      = "SINGLE"
  associable_types = sort(tolist(var.associable_types))
}

resource "vsphere_tag_category" "terraform" {
  name             = "Terraform"
  description      = "Identifies resources created by Terraform"
  cardinality      = "SINGLE"
  associable_types = sort(tolist(var.associable_types))
}

resource "vsphere_tag" "name" {
  for_each = var.resource_names

  name        = each.value
  description = "Name=${each.value}"
  category_id = vsphere_tag_category.name.id
}

resource "vsphere_tag" "project" {
  name        = var.project
  description = "project=${var.project}"
  category_id = vsphere_tag_category.project.id
}

resource "vsphere_tag" "terraform" {
  name        = "True"
  description = "Terraform=True"
  category_id = vsphere_tag_category.terraform.id
}
