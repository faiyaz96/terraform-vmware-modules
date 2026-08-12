resource "vsphere_content_library" "this" {
  name            = var.name
  description     = var.description
  storage_backing = sort(tolist(var.datastore_ids))

  dynamic "publication" {
    for_each = var.publication == null ? [] : [var.publication]
    content {
      published             = publication.value.published
      authentication_method = publication.value.authentication_method
      username              = publication.value.username
      password              = var.publication_password
    }
  }

  dynamic "subscription" {
    for_each = var.subscription == null ? [] : [var.subscription]
    content {
      subscription_url      = subscription.value.subscription_url
      authentication_method = subscription.value.authentication_method
      username              = subscription.value.username
      password              = var.subscription_password
      automatic_sync        = subscription.value.automatic_sync
      on_demand             = subscription.value.on_demand
    }
  }

  lifecycle {
    precondition {
      condition     = var.publication == null || var.subscription == null
      error_message = "A content library cannot be both published and subscribed."
    }
  }
}

resource "vsphere_content_library_item" "this" {
  for_each = var.items

  name        = each.value.name
  description = each.value.description
  type        = each.value.type
  file_url    = each.value.file_url
  source_uuid = each.value.source_uuid
  library_id  = vsphere_content_library.this.id
}
