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
variable "cluster_name" { type = string }
variable "host_names" { type = set(string) }

data "vsphere_datacenter" "this" { name = var.datacenter_name }
data "vsphere_host" "this" {
  for_each      = var.host_names
  name          = each.value
  datacenter_id = data.vsphere_datacenter.this.id
}

module "tagging" {
  source         = "../../modules/tagging"
  project        = var.project
  resource_names = [var.cluster_name]
}

module "compute_cluster" {
  source = "../../modules/compute-cluster"

  name            = var.cluster_name
  datacenter_name = var.datacenter_name
  host_system_ids = [for host in data.vsphere_host.this : host.id]
  tags            = module.tagging.tags_by_resource_name[var.cluster_name]

  drs = {
    enabled          = true
    automation_level = "fullyAutomated"
  }

  ha = {
    enabled                  = true
    admission_control_policy = "resourcePercentage"
    host_failure_tolerance   = 1
  }
}

output "cluster_id" { value = module.compute_cluster.id }
output "root_resource_pool_id" { value = module.compute_cluster.resource_pool_id }
