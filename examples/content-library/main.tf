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
variable "datacenter_name" { type = string }
variable "datastore_name" { type = string }
variable "library_name" { type = string }

data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

data "vsphere_datastore" "this" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.this.id
}

module "content_library" {
  source = "../../modules/content-library"

  name          = var.library_name
  datastore_ids = [data.vsphere_datastore.this.id]
}

output "content_library_id" {
  value = module.content_library.id
}
