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
variable "datastore_name" { type = string }
variable "network_name" { type = string }
variable "template_name" { type = string }
variable "vm_name" { type = string }
variable "dns_domain" { type = string }

data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "this" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_datastore" "this" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_network" "this" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.this.id
}

module "tagging" {
  source = "../../../modules/tagging"

  project        = var.project
  resource_names = [var.vm_name]
}

module "security" {
  source = "../../../modules/security"

  enable_secure_boot = true
  enable_vtpm        = false
}

module "vm" {
  source = "../../../modules/vm"

  name             = var.vm_name
  datacenter_name  = var.datacenter_name
  template_name    = var.template_name
  resource_pool_id = data.vsphere_compute_cluster.this.resource_pool_id
  datastore_id     = data.vsphere_datastore.this.id
  security_policy  = module.security.vm_policy
  tags             = module.tagging.tags_by_resource_name[var.vm_name]

  network_interfaces = [{
    network_id = data.vsphere_network.this.id
  }]

  linux_customization = {
    host_name = var.vm_name
    domain    = var.dns_domain
  }
}

output "vm_id" {
  value = module.vm.id
}

output "default_ip_address" {
  value = module.vm.default_ip_address
}
