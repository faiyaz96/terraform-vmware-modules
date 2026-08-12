# Networking module

Creates one vSphere Distributed Switch and any number of distributed port groups. Port groups default to rejecting promiscuous mode, forged transmits, and guest MAC changes. Pass standard tag IDs from the tagging module to the switch and each port group.

Physical NIC migration is an operationally sensitive change. When `host_uplinks` is non-empty, verify physical switch trunks, management connectivity, uplink order, VLANs, and rollback access before applying. Use an empty map if the switch will be attached to hosts through a separately controlled migration.

This module creates VLAN-backed vSphere networks; it does not create IP subnets, DHCP, routing, or NSX firewall rules.

## Network I/O Control

Network I/O Control is disabled by default. When enabled, `traffic_classes` accepts the provider-supported `management`, `faulttolerance`, `vmotion`, `virtualmachine`, `iscsi`, `nfs`, `hbr`, `vsan`, `vdp`, and `backupnfc` keys. Each class can set a share level, custom share count, maximum bandwidth, and guaranteed bandwidth in Mbit/s.

```hcl
network_io_control = {
  enabled = true
  version = "version3"
  traffic_classes = {
    virtualmachine = {
      share_level      = "custom"
      share_count      = 150
      maximum_mbit     = 2000
      reservation_mbit = 500
    }
    vmotion = {
      share_level      = "high"
      maximum_mbit     = 1000
      reservation_mbit = 200
    }
  }
}
```

Confirm that the vSphere edition and VDS version support the selected classes. Ensure total reservations fit the physical uplink capacity.
