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
variable "cluster_name" { type = string }
variable "resource_pool_name" { type = string }

data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "this" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.this.id
}

module "tagging" {
  source = "../../modules/tagging"

  project        = var.project
  resource_names = [var.resource_pool_name]
}

module "resource_pool" {
  source = "../../modules/resource-pool"

  name                    = var.resource_pool_name
  parent_resource_pool_id = data.vsphere_compute_cluster.this.resource_pool_id
  tags                    = module.tagging.tags_by_resource_name[var.resource_pool_name]
}

output "resource_pool_id" {
  value = module.resource_pool.id
}
