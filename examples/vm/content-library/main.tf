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
variable "content_library_name" { type = string }
variable "content_library_item_name" { type = string }
variable "customization_spec_name" { type = string }
variable "guest_id" { type = string }
variable "vm_name" { type = string }
variable "root_disk_size_gb" { type = number }

data "vsphere_datacenter" "this" { name = var.datacenter_name }
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
data "vsphere_content_library" "this" { name = var.content_library_name }
data "vsphere_content_library_item" "this" {
  name       = var.content_library_item_name
  type       = "ovf"
  library_id = data.vsphere_content_library.this.id
}
data "vsphere_guest_os_customization" "this" { name = var.customization_spec_name }

module "tagging" {
  source         = "../../../modules/tagging"
  project        = var.project
  resource_names = [var.vm_name]
}

module "security" { source = "../../../modules/security" }

module "vm" {
  source = "../../../modules/vm"

  name                    = var.vm_name
  datacenter_name         = var.datacenter_name
  content_library_item_id = data.vsphere_content_library_item.this.id
  guest_id                = var.guest_id
  resource_pool_id        = data.vsphere_compute_cluster.this.resource_pool_id
  datastore_id            = data.vsphere_datastore.this.id
  customization_spec_id   = data.vsphere_guest_os_customization.this.id
  security_policy         = module.security.vm_policy
  tags                    = module.tagging.tags_by_resource_name[var.vm_name]

  network_interfaces = [{ network_id = data.vsphere_network.this.id }]
  content_library_disks = [{
    label       = "disk0"
    size_gb     = var.root_disk_size_gb
    unit_number = 0
  }]
}

output "vm_id" { value = module.vm.id }
