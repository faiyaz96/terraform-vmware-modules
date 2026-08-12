data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.this.id
}

locals {
  template_disks = [
    for disk in data.vsphere_virtual_machine.template.disks : {
      label             = disk.label
      size_gb           = coalesce(try(var.disk_overrides[disk.label].size_gb, null), disk.size)
      unit_number       = disk.unit_number
      thin_provisioned  = coalesce(try(var.disk_overrides[disk.label].thin_provisioned, null), disk.thin_provisioned)
      eagerly_scrub     = coalesce(try(var.disk_overrides[disk.label].eagerly_scrub, null), disk.eagerly_scrub)
      storage_policy_id = try(var.disk_overrides[disk.label].storage_policy_id, null) != null ? var.disk_overrides[disk.label].storage_policy_id : var.storage_policy_id
    }
  ]

  additional_disks = [
    for disk in var.additional_disks : {
      label             = disk.label
      size_gb           = disk.size_gb
      unit_number       = disk.unit_number
      thin_provisioned  = disk.thin_provisioned
      eagerly_scrub     = disk.eagerly_scrub
      storage_policy_id = disk.storage_policy_id != null ? disk.storage_policy_id : var.storage_policy_id
    }
  ]

  disks = concat(local.template_disks, local.additional_disks)
}

resource "vsphere_virtual_machine" "this" {
  name             = var.name
  folder           = var.folder
  annotation       = var.annotation
  resource_pool_id = var.resource_pool_id

  datastore_id         = var.datastore_id
  datastore_cluster_id = var.datastore_cluster_id
  storage_policy_id    = var.storage_policy_id

  num_cpus               = var.num_cpus
  num_cores_per_socket   = var.num_cores_per_socket
  memory                 = var.memory_mb
  cpu_hot_add_enabled    = var.cpu_hot_add_enabled
  memory_hot_add_enabled = var.memory_hot_add_enabled

  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  firmware  = coalesce(var.security_policy.firmware, data.vsphere_virtual_machine.template.firmware)

  efi_secure_boot_enabled = var.security_policy.efi_secure_boot_enabled
  vbs_enabled             = var.security_policy.vbs_enabled
  vvtd_enabled            = var.security_policy.vvtd_enabled
  nested_hv_enabled       = var.security_policy.nested_hv_enabled
  enable_logging          = var.security_policy.enable_logging

  tags              = sort(tolist(var.tags))
  custom_attributes = var.custom_attributes
  extra_config      = var.extra_config

  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      network_id = network_interface.value.network_id
      adapter_type = coalesce(
        network_interface.value.adapter_type,
        try(data.vsphere_virtual_machine.template.network_interface_types[network_interface.key], null),
        "vmxnet3"
      )
      use_static_mac = network_interface.value.use_static_mac
      mac_address    = network_interface.value.mac_address
    }
  }

  dynamic "disk" {
    for_each = local.disks
    content {
      label             = disk.value.label
      size              = disk.value.size_gb
      unit_number       = disk.value.unit_number
      thin_provisioned  = disk.value.thin_provisioned
      eagerly_scrub     = disk.value.eagerly_scrub
      storage_policy_id = disk.value.storage_policy_id
    }
  }

  dynamic "vtpm" {
    for_each = var.security_policy.vtpm_enabled ? [1] : []
    content {
      version = var.security_policy.vtpm_version
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    linked_clone  = var.linked_clone
    timeout       = var.clone_timeout_minutes

    dynamic "customize" {
      for_each = var.linux_customization != null || var.windows_customization != null ? [1] : []
      content {
        timeout = var.linux_customization != null ? (
          var.linux_customization.timeout
        ) : var.windows_customization.timeout
        dns_server_list = var.linux_customization != null ? (
          var.linux_customization.dns_server_list
        ) : var.windows_customization.dns_server_list
        dns_suffix_list = var.linux_customization != null ? (
          var.linux_customization.dns_suffix_list
        ) : var.windows_customization.dns_suffix_list
        ipv4_gateway = var.linux_customization != null ? (
          var.linux_customization.ipv4_gateway
        ) : var.windows_customization.ipv4_gateway
        ipv6_gateway = var.linux_customization != null ? (
          var.linux_customization.ipv6_gateway
        ) : var.windows_customization.ipv6_gateway

        dynamic "linux_options" {
          for_each = var.linux_customization == null ? [] : [var.linux_customization]
          content {
            host_name = linux_options.value.host_name
            domain    = linux_options.value.domain
          }
        }

        dynamic "windows_options" {
          for_each = var.windows_customization == null ? [] : [var.windows_customization]
          content {
            computer_name         = windows_options.value.computer_name
            workgroup             = windows_options.value.workgroup
            join_domain           = windows_options.value.join_domain
            domain_ou             = windows_options.value.domain_ou
            domain_admin_user     = windows_options.value.domain_admin_user
            domain_admin_password = var.windows_domain_admin_password
            admin_password        = var.windows_admin_password
            full_name             = windows_options.value.full_name
            organization_name     = windows_options.value.organization_name
            product_key           = var.windows_product_key
            run_once_command_list = windows_options.value.run_once_command_list
            auto_logon            = windows_options.value.auto_logon
            auto_logon_count      = windows_options.value.auto_logon_count
            time_zone             = windows_options.value.time_zone
          }
        }

        dynamic "network_interface" {
          for_each = var.network_interfaces
          content {
            ipv4_address    = network_interface.value.ipv4_address
            ipv4_netmask    = network_interface.value.ipv4_netmask
            ipv6_address    = network_interface.value.ipv6_address
            ipv6_netmask    = network_interface.value.ipv6_netmask
            dns_server_list = network_interface.value.dns_server_list
            dns_domain      = network_interface.value.dns_domain
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = (var.datastore_id != null) != (var.datastore_cluster_id != null)
      error_message = "Set exactly one of datastore_id or datastore_cluster_id."
    }
    precondition {
      condition     = var.num_cpus % var.num_cores_per_socket == 0
      error_message = "num_cores_per_socket must divide num_cpus evenly."
    }
    precondition {
      condition = alltrue([
        for disk in data.vsphere_virtual_machine.template.disks :
        coalesce(try(var.disk_overrides[disk.label].size_gb, null), disk.size) >= disk.size
      ])
      error_message = "A cloned template disk cannot be made smaller than its source disk."
    }
    precondition {
      condition     = !var.security_policy.efi_secure_boot_enabled || coalesce(var.security_policy.firmware, data.vsphere_virtual_machine.template.firmware) == "efi"
      error_message = "EFI Secure Boot requires firmware to be efi."
    }
    precondition {
      condition     = var.linux_customization == null || var.windows_customization == null
      error_message = "Set only one of linux_customization or windows_customization."
    }
    precondition {
      condition = var.windows_customization == null || var.windows_customization.join_domain == null || (
        var.windows_customization.domain_admin_user != null && var.windows_domain_admin_password != null
      )
      error_message = "Windows domain join requires domain_admin_user and windows_domain_admin_password."
    }
    precondition {
      condition = var.windows_customization == null || !var.windows_customization.auto_logon || (
        var.windows_admin_password != null && var.windows_customization.auto_logon_count > 0
      )
      error_message = "Windows auto-logon requires windows_admin_password and auto_logon_count greater than zero."
    }
  }
}
