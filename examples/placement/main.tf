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
variable "cluster_name" { type = string }
variable "vm_names" { type = set(string) }

data "vsphere_datacenter" "this" { name = var.datacenter_name }
data "vsphere_compute_cluster" "this" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.this.id
}
data "vsphere_virtual_machine" "this" {
  for_each      = var.vm_names
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

module "placement" {
  source             = "../../modules/placement"
  compute_cluster_id = data.vsphere_compute_cluster.this.id

  vm_anti_affinity_rules = {
    application = {
      name                = "application-spread"
      virtual_machine_ids = [for vm in data.vsphere_virtual_machine.this : vm.id]
    }
  }
}
