output "id" {
  description = "Content library ID."
  value       = vsphere_content_library.this.id
}

output "item_ids" {
  description = "Content library item IDs keyed by input item keys."
  value       = { for key, item in vsphere_content_library_item.this : key => item.id }
}
