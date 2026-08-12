data "vsphere_datacenter" "this" {
  name = var.datacenter_name
}

data "vsphere_virtual_machine" "template" {
  count = var.template_name == null ? 0 : 1

  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.this.id
}

locals {
  template_disks = [
    for disk in try(data.vsphere_virtual_machine.template[0].disks, []) : {
      label             = disk.label
      size_gb           = coalesce(try(var.disk_overrides[disk.label].size_gb, null), disk.size)
      unit_number       = disk.unit_number
      thin_provisioned  = coalesce(try(var.disk_overrides[disk.label].thin_provisioned, null), disk.thin_provisioned)
      eagerly_scrub     = coalesce(try(var.disk_overrides[disk.label].eagerly_scrub, null), disk.eagerly_scrub)
      datastore_id      = try(var.disk_overrides[disk.label].datastore_id, null)
      storage_policy_id = try(var.disk_overrides[disk.label].storage_policy_id, null) != null ? var.disk_overrides[disk.label].storage_policy_id : var.storage_policy_id
      disk_mode         = try(var.disk_overrides[disk.label].disk_mode, null)
      disk_sharing      = try(var.disk_overrides[disk.label].disk_sharing, null)
      io_reservation    = try(var.disk_overrides[disk.label].io_reservation, null)
      io_share_level    = try(var.disk_overrides[disk.label].io_share_level, "normal")
      io_share_count    = try(var.disk_overrides[disk.label].io_share_count, null)
      attach            = false
      path              = null
      keep_on_remove    = false
    }
  ]

  content_library_disks = [
    for disk in var.content_library_disks : merge(disk, {
      storage_policy_id = disk.storage_policy_id != null ? disk.storage_policy_id : var.storage_policy_id
      attach            = false
      path              = null
      keep_on_remove    = false
    })
  ]

  additional_disks = [
    for disk in var.additional_disks : {
      label             = disk.label
      size_gb           = disk.size_gb
      unit_number       = disk.unit_number
      thin_provisioned  = disk.thin_provisioned
      eagerly_scrub     = disk.eagerly_scrub
      datastore_id      = disk.datastore_id
      storage_policy_id = disk.storage_policy_id != null ? disk.storage_policy_id : var.storage_policy_id
      disk_mode         = disk.disk_mode
      disk_sharing      = disk.disk_sharing
      io_reservation    = disk.io_reservation
      io_share_level    = disk.io_share_level
      io_share_count    = disk.io_share_count
      attach            = disk.attach
      path              = disk.path
      keep_on_remove    = disk.keep_on_remove
    }
  ]

  source_disks = var.content_library_item_id == null ? local.template_disks : local.content_library_disks
  disks        = concat(local.source_disks, local.additional_disks)
}

resource "vsphere_virtual_machine" "this" {
  name             = var.name
  folder           = var.folder
  annotation       = var.annotation
  resource_pool_id = var.resource_pool_id
  host_system_id   = var.host_system_id

  datastore_id         = var.datastore_id
  datastore_cluster_id = var.datastore_cluster_id
  storage_policy_id    = var.storage_policy_id

  num_cpus               = var.num_cpus
  num_cores_per_socket   = var.num_cores_per_socket
  memory                 = var.memory_mb
  cpu_hot_add_enabled    = var.cpu_hot_add_enabled
  cpu_hot_remove_enabled = var.cpu_hot_remove_enabled
  memory_hot_add_enabled = var.memory_hot_add_enabled

  cpu_reservation = var.cpu_allocation.reservation
  cpu_limit       = var.cpu_allocation.limit
  cpu_share_level = var.cpu_allocation.share_level
  cpu_share_count = var.cpu_allocation.share_level == "custom" ? var.cpu_allocation.share_count : null

  memory_reservation               = var.memory_allocation.reservation
  memory_reservation_locked_to_max = var.memory_allocation.reservation_locked
  memory_limit                     = var.memory_allocation.limit
  memory_share_level               = var.memory_allocation.share_level
  memory_share_count               = var.memory_allocation.share_level == "custom" ? var.memory_allocation.share_count : null

  guest_id              = try(coalesce(var.guest_id, data.vsphere_virtual_machine.template[0].guest_id), null)
  scsi_type             = try(coalesce(var.scsi_type, data.vsphere_virtual_machine.template[0].scsi_type), null)
  scsi_controller_count = var.scsi_controller_count
  scsi_bus_sharing      = var.scsi_bus_sharing
  firmware              = try(coalesce(var.security_policy.firmware, data.vsphere_virtual_machine.template[0].firmware), null)
  hardware_version      = var.hardware_version

  efi_secure_boot_enabled          = var.security_policy.efi_secure_boot_enabled
  vbs_enabled                      = var.security_policy.vbs_enabled
  vvtd_enabled                     = var.security_policy.vvtd_enabled
  nested_hv_enabled                = var.security_policy.nested_hv_enabled
  enable_logging                   = var.security_policy.enable_logging
  enable_disk_uuid                 = var.enable_disk_uuid
  cpu_performance_counters_enabled = var.cpu_performance_counters_enabled
  latency_sensitivity              = var.latency_sensitivity
  swap_placement_policy            = var.swap_placement_policy

  tags              = sort(tolist(var.tags))
  custom_attributes = var.custom_attributes
  extra_config      = var.extra_config

  wait_for_guest_net_timeout  = var.wait_for_guest_net_timeout
  wait_for_guest_ip_timeout   = var.wait_for_guest_ip_timeout
  wait_for_guest_net_routable = var.wait_for_guest_net_routable
  ignored_guest_ips           = var.ignored_guest_ips
  shutdown_wait_timeout       = var.shutdown_wait_timeout
  force_power_off             = var.force_power_off

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      network_id = network_interface.value.network_id
      adapter_type = coalesce(
        network_interface.value.adapter_type,
        try(data.vsphere_virtual_machine.template[0].network_interface_types[network_interface.key], null),
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
      datastore_id      = disk.value.datastore_id
      storage_policy_id = disk.value.storage_policy_id
      disk_mode         = disk.value.disk_mode
      disk_sharing      = disk.value.disk_sharing
      io_reservation    = disk.value.io_reservation
      io_share_level    = disk.value.io_share_level
      io_share_count    = disk.value.io_share_level == "custom" ? disk.value.io_share_count : null
      attach            = disk.value.attach
      path              = disk.value.path
      keep_on_remove    = disk.value.keep_on_remove
    }
  }

  dynamic "vtpm" {
    for_each = var.security_policy.vtpm_enabled ? [1] : []
    content {
      version = var.security_policy.vtpm_version
    }
  }

  clone {
    template_uuid   = var.content_library_item_id != null ? var.content_library_item_id : data.vsphere_virtual_machine.template[0].id
    linked_clone    = var.linked_clone
    timeout         = var.clone_timeout_minutes
    ovf_network_map = var.ovf_network_map
    ovf_storage_map = var.ovf_storage_map

    dynamic "customization_spec" {
      for_each = var.customization_spec_id == null ? [] : [var.customization_spec_id]
      content {
        id      = customization_spec.value
        timeout = var.customization_spec_timeout
      }
    }

    dynamic "customize" {
      for_each = var.customization_spec_id == null && (var.linux_customization != null || var.windows_customization != null) ? [1] : []
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
      condition     = (var.template_name != null) != (var.content_library_item_id != null)
      error_message = "Set exactly one of template_name or content_library_item_id."
    }
    precondition {
      condition     = var.content_library_item_id == null || var.guest_id != null
      error_message = "guest_id is required when cloning a content-library item."
    }
    precondition {
      condition     = var.content_library_item_id == null || length(var.content_library_disks) > 0
      error_message = "content_library_disks must declare at least one disk for a content-library clone."
    }
    precondition {
      condition     = var.content_library_item_id == null || !var.linked_clone
      error_message = "linked_clone is supported only with an inventory VM template."
    }
    precondition {
      condition     = var.content_library_item_id != null || (length(var.ovf_network_map) == 0 && length(var.ovf_storage_map) == 0)
      error_message = "OVF network and storage maps are supported only for content-library sources."
    }
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
        for disk in try(data.vsphere_virtual_machine.template[0].disks, []) :
        coalesce(try(var.disk_overrides[disk.label].size_gb, null), disk.size) >= disk.size
      ])
      error_message = "A cloned template disk cannot be made smaller than its source disk."
    }
    precondition {
      condition     = !var.security_policy.efi_secure_boot_enabled || try(coalesce(var.security_policy.firmware, data.vsphere_virtual_machine.template[0].firmware), null) == "efi"
      error_message = "EFI Secure Boot requires firmware to be efi."
    }
    precondition {
      condition     = var.linux_customization == null || var.windows_customization == null
      error_message = "Set only one of linux_customization or windows_customization."
    }
    precondition {
      condition     = var.customization_spec_id == null || (var.linux_customization == null && var.windows_customization == null)
      error_message = "customization_spec_id conflicts with inline Linux or Windows customization."
    }
    precondition {
      condition     = length(local.disks) == length(distinct([for disk in local.disks : disk.label]))
      error_message = "Disk labels must be unique."
    }
    precondition {
      condition     = length(local.disks) == length(distinct([for disk in local.disks : disk.unit_number]))
      error_message = "Disk unit numbers must be unique."
    }
    precondition {
      condition = alltrue([
        for disk in local.disks : !(disk.thin_provisioned && disk.eagerly_scrub)
      ])
      error_message = "A disk cannot be both thin provisioned and eagerly scrubbed."
    }
    precondition {
      condition = var.datastore_cluster_id == null || alltrue([
        for disk in local.disks : disk.datastore_id == null && !disk.attach
      ])
      error_message = "Per-disk datastores and attached VMDKs cannot be combined with datastore_cluster_id."
    }
    precondition {
      condition = alltrue([
        for disk in local.disks : disk.io_share_level != "custom" || disk.io_share_count != null
      ])
      error_message = "A custom disk I/O share level requires io_share_count."
    }
    precondition {
      condition = var.windows_customization == null ? true : (
        var.windows_customization.join_domain == null ? true : (
          var.windows_customization.domain_admin_user != null && var.windows_domain_admin_password != null
        )
      )
      error_message = "Windows domain join requires domain_admin_user and windows_domain_admin_password."
    }
    precondition {
      condition = var.windows_customization == null ? true : (
        !var.windows_customization.auto_logon ? true : (
          var.windows_admin_password != null && var.windows_customization.auto_logon_count > 0
        )
      )
      error_message = "Windows auto-logon requires windows_admin_password and auto_logon_count greater than zero."
    }
  }
}
