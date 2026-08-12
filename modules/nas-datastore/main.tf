resource "vsphere_nas_datastore" "this" {
  name                 = var.name
  host_system_ids      = sort(tolist(var.host_system_ids))
  type                 = var.type
  remote_hosts         = var.remote_hosts
  remote_path          = var.remote_path
  access_mode          = var.access_mode
  security_type        = var.security_type
  folder               = var.datastore_cluster_id == null ? var.folder : null
  datastore_cluster_id = var.datastore_cluster_id
  tags                 = sort(tolist(var.tags))
  custom_attributes    = var.custom_attributes

  lifecycle {
    precondition {
      condition     = var.type != "NFS" || length(var.remote_hosts) == 1
      error_message = "NFS v3 requires exactly one remote host; use NFS41 for multiple endpoints."
    }
    precondition {
      condition     = var.type == "NFS41" || var.security_type == "AUTH_SYS"
      error_message = "Kerberos security modes are supported only with NFS41."
    }
  }
}
