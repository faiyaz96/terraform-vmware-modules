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
variable "folder_name" { type = string }

module "tagging" {
  source = "../../modules/tagging"

  project        = var.project
  resource_names = [var.folder_name]
}

module "inventory" {
  source = "../../modules/inventory"

  datacenter_name = var.datacenter_name
  folders = {
    application = {
      path = var.folder_name
      type = "vm"
      tags = module.tagging.tags_by_resource_name[var.folder_name]
    }
  }
}

output "folder_ids" {
  value = module.inventory.folder_ids
}
