# Copy this file to terraform.tfvars and replace the example values.
vsphere_server  = "vcenter.example.com"
project         = "example-project"
datacenter_name = "dc-01"
switch_name     = "vds-workloads"
port_group_name = "dvpg-application"
vlan_id         = 110

# Populate only after validating physical switch trunks and rollback access.
host_uplinks = {
  "esxi-01.example.com" = ["vmnic2", "vmnic3"]
  "esxi-02.example.com" = ["vmnic2", "vmnic3"]
}

# Set TF_VAR_vsphere_user and TF_VAR_vsphere_password securely.
