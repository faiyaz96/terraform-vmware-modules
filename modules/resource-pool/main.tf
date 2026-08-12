resource "vsphere_resource_pool" "this" {
  name                    = var.name
  parent_resource_pool_id = var.parent_resource_pool_id

  cpu_share_level = var.cpu.share_level
  cpu_shares      = var.cpu.shares
  cpu_reservation = var.cpu.reservation
  cpu_expandable  = var.cpu.expandable
  cpu_limit       = var.cpu.limit

  memory_share_level = var.memory.share_level
  memory_shares      = var.memory.shares
  memory_reservation = var.memory.reservation
  memory_expandable  = var.memory.expandable
  memory_limit       = var.memory.limit

  tags = sort(tolist(var.tags))

  lifecycle {
    precondition {
      condition     = var.cpu.share_level == "custom" || var.cpu.shares == null
      error_message = "cpu.shares can only be set when cpu.share_level is custom."
    }
    precondition {
      condition     = var.memory.share_level == "custom" || var.memory.shares == null
      error_message = "memory.shares can only be set when memory.share_level is custom."
    }
  }
}
