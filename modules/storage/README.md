# Storage module

Optionally creates a datastore cluster and creates tag-based VM storage policies. Pass the datastore cluster's standard tag set from the tagging module through `datastore_cluster.tags`. This module does not create or attach physical LUNs, VMFS volumes, NFS exports, or vSAN capacity because those choices require environment-specific storage design.

Storage DRS requires the appropriate vSphere license. Existing datastores must be placed in the datastore cluster separately or imported into a datastore resource workflow.

The datastore-cluster configuration exposes automation levels, latency and load-imbalance thresholds, reservable IOPS/percentage thresholds, free-space modes, balancing intervals, intra-VM affinity, and reviewed advanced options. Use `sdrs_io_reservable_threshold_mode = "manual"` only with an explicit `sdrs_io_reservable_iops_threshold`.

VMFS creation remains intentionally out of scope until ownership of LUN discovery, formatting, expansion, and destruction is confirmed. Existing VMFS datastores can still be referenced by callers through the `vsphere_datastore` data source.
