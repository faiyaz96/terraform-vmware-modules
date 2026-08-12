terraform {
  required_version = ">= 1.6, < 2.0"
}

module "security" {
  source = "../../modules/security"

  enable_secure_boot = true
  enable_vtpm        = false
  enable_vbs         = false
}

output "vm_policy" {
  value = module.security.vm_policy
}

output "network_policy" {
  value = module.security.network_policy
}
