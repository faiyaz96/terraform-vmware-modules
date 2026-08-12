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
variable "datacenter_name" { type = string }
variable "host_name" { type = string }
variable "switch_name" { type = string }
variable "port_group_name" { type = string }
variable "vlan_id" { type = number }

data "vsphere_datacenter" "this" { name = var.datacenter_name }
data "vsphere_host" "this" {
  name          = var.host_name
  datacenter_id = data.vsphere_datacenter.this.id
}

module "standard_networking" {
  source = "../../modules/standard-networking"

  name             = var.switch_name
  host_system_id   = data.vsphere_host.this.id
  network_adapters = ["vmnic2", "vmnic3"]
  active_nics      = ["vmnic2"]
  standby_nics     = ["vmnic3"]

  port_groups = {
    application = {
      name    = var.port_group_name
      vlan_id = var.vlan_id
    }
  }
}

output "port_group_ids" { value = module.standard_networking.port_group_ids }
