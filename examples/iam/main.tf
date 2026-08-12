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
variable "entity_id" { type = string }
variable "entity_type" { type = string }
variable "principal_group" { type = string }

module "iam" {
  source = "../../modules/iam"

  roles = {
    vm_operator = {
      name = "Terraform VM Operator"
      privileges = [
        "VirtualMachine.Interact.ConsoleInteract",
        "VirtualMachine.Interact.PowerOff",
        "VirtualMachine.Interact.PowerOn",
        "VirtualMachine.Interact.Reset",
      ]
    }
  }

  entity_permissions = {
    target = {
      entity_id   = var.entity_id
      entity_type = var.entity_type
      permissions = [{
        user_or_group = var.principal_group
        is_group      = true
        propagate     = true
        role_key      = "vm_operator"
      }]
    }
  }
}

output "role_ids" {
  value = module.iam.role_ids
}
