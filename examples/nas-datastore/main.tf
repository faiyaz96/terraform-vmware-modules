terraform {
  required_version = ">= 1.6, < 2.0"
  required_providers {
    vsphere = { source = "vmware/vsphere", version = "~> 2.16" }
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
variable "datastore_name" { type = string }
variable "host_names" { type = set(string) }
variable "remote_hosts" { type = list(string) }
variable "remote_path" { type = string }

data "vsphere_datacenter" "this" { name = var.datacenter_name }
data "vsphere_host" "this" {
  for_each      = var.host_names
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

module "tagging" {
  source         = "../../modules/tagging"
  project        = var.project
  resource_names = [var.datastore_name]
}

module "nas_datastore" {
  source = "../../modules/nas-datastore"

  name            = var.datastore_name
  host_system_ids = [for host in data.vsphere_host.this : host.id]
  type            = "NFS41"
  remote_hosts    = var.remote_hosts
  remote_path     = var.remote_path
  tags            = module.tagging.tags_by_resource_name[var.datastore_name]
}

output "datastore_id" { value = module.nas_datastore.id }
