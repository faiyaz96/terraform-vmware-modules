terraform {
  required_version = ">= 1.6, < 2.0"

  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = ">= 2.16, < 3.0"
    }
  }
}
