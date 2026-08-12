# Networking module

Creates one vSphere Distributed Switch and any number of distributed port groups. Port groups default to rejecting promiscuous mode, forged transmits, and guest MAC changes. Pass standard tag IDs from the tagging module to the switch and each port group.

Physical NIC migration is an operationally sensitive change. When `host_uplinks` is non-empty, verify physical switch trunks, management connectivity, uplink order, VLANs, and rollback access before applying. Use an empty map if the switch will be attached to hosts through a separately controlled migration.

This module creates VLAN-backed vSphere networks; it does not create IP subnets, DHCP, routing, or NSX firewall rules.
