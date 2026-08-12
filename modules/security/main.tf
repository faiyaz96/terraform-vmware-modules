locals {
  vm_requires_efi = var.enable_secure_boot || var.enable_vtpm || var.enable_vbs
}
