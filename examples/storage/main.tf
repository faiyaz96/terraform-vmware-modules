terraform {
  required_version = ">= 1.6, < 2.0"
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.16"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
}

variable "vsphere_server" { type = string }
variable "vsphere_user" {
  type      = string
  sensitive = true
}
variable "vsphere_password" {
  type      = string
  sensitive = true
}
variable "allow_unverified_ssl" {
  type    = bool
  default = false
}
variable "project" { type = string }
variable "datacenter_name" { type = string }
variable "datastore_cluster_name" { type = string }

module "tagging" {
  source = "../../modules/tagging"

  project        = var.project
  resource_names = [var.datastore_cluster_name]
}

module "storage" {
  source = "../../modules/storage"

  datacenter_name = var.datacenter_name
  datastore_cluster = {
    name         = var.datastore_cluster_name
    sdrs_enabled = true
    tags         = module.tagging.tags_by_resource_name[var.datastore_cluster_name]
  }
}

output "datastore_cluster_id" {
  value = module.storage.datastore_cluster_id
}
