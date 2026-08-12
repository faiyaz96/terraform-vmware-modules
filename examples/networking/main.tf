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
variable "switch_name" { type = string }
variable "port_group_name" { type = string }
variable "vlan_id" { type = number }
variable "host_uplinks" {
  type    = map(list(string))
  default = {}
}

module "tagging" {
  source = "../../modules/tagging"

  project        = var.project
  resource_names = [var.switch_name, var.port_group_name]
}

module "security" {
  source = "../../modules/security"
}

module "networking" {
  source = "../../modules/networking"

  datacenter_name = var.datacenter_name
  name            = var.switch_name
  host_uplinks    = var.host_uplinks
  network_policy  = module.security.network_policy
  tags            = module.tagging.tags_by_resource_name[var.switch_name]

  port_groups = {
    application = {
      name    = var.port_group_name
      vlan_id = var.vlan_id
      tags    = module.tagging.tags_by_resource_name[var.port_group_name]
    }
  }
}

output "distributed_switch_id" {
  value = module.networking.distributed_switch_id
}

output "port_group_ids" {
  value = module.networking.port_group_ids
}
