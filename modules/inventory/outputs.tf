output "datacenter_id" {
  description = "Managed object ID of the selected datacenter."
  value       = data.vsphere_datacenter.this.id
}

output "folder_ids" {
  description = "Folder managed object IDs keyed by the input folder keys."
  value       = { for key, folder in vsphere_folder.this : key => folder.id }
}

output "folder_paths" {
  description = "Folder paths keyed by the input folder keys."
  value       = { for key, folder in vsphere_folder.this : key => folder.path }
}
