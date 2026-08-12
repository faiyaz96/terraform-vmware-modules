output "tags_by_resource_name" {
  description = "Standard Name, project and Terraform tag IDs keyed by resource name."
  value = {
    for name, tag in vsphere_tag.name : name => toset([
      tag.id,
      vsphere_tag.project.id,
      vsphere_tag.terraform.id,
    ])
  }
}

output "category_ids" {
  description = "IDs of the standard tag categories."
  value = {
    Name      = vsphere_tag_category.name.id
    project   = vsphere_tag_category.project.id
    Terraform = vsphere_tag_category.terraform.id
  }
}

output "project_tag_id" {
  description = "ID of the shared project tag."
  value       = vsphere_tag.project.id
}

output "terraform_tag_id" {
  description = "ID of the shared Terraform=True tag."
  value       = vsphere_tag.terraform.id
}
