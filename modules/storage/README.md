# Storage module

Optionally creates a datastore cluster and creates tag-based VM storage policies. Pass the datastore cluster's standard tag set from the tagging module through `datastore_cluster.tags`. This module does not create or attach physical LUNs, VMFS volumes, NFS exports, or vSAN capacity because those choices require environment-specific storage design.

Storage DRS requires the appropriate vSphere license. Existing datastores must be placed in the datastore cluster separately or imported into a datastore resource workflow.
