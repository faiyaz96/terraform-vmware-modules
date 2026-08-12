variable "name" {
  description = "Name of the NAS datastore."
  type        = string
}

variable "host_system_ids" {
  description = "Managed object IDs of all ESXi hosts on which to mount the datastore."
  type        = set(string)
  validation {
    condition     = length(var.host_system_ids) > 0
    error_message = "At least one host_system_id is required."
  }
}

variable "type" {
  description = "NAS protocol: NFS for v3 or NFS41 for v4.1."
  type        = string
  default     = "NFS41"
  validation {
    condition     = contains(["NFS", "NFS41"], var.type)
    error_message = "type must be NFS or NFS41."
  }
}

variable "remote_hosts" {
  description = "NFS server hostnames or IP addresses. NFS v3 accepts one; NFS 4.1 supports multiple endpoints."
  type        = list(string)
  validation {
    condition     = length(var.remote_hosts) > 0
    error_message = "At least one remote host is required."
  }
}

variable "remote_path" {
  description = "Exported NFS path."
  type        = string
}

variable "access_mode" {
  description = "Datastore access mode."
  type        = string
  default     = "readWrite"
}

variable "security_type" {
  description = "NFS 4.1 security mode."
  type        = string
  default     = "AUTH_SYS"
}

variable "folder" {
  description = "Optional datastore folder; conflicts with datastore_cluster_id."
  type        = string
  default     = null
}

variable "datastore_cluster_id" {
  description = "Optional datastore-cluster ID to join."
  type        = string
  default     = null
}

variable "tags" {
  description = "vSphere tag IDs to attach to the datastore."
  type        = set(string)
  default     = []
}

variable "custom_attributes" {
  description = "Map of custom attribute IDs to values."
  type        = map(string)
  default     = {}
}
