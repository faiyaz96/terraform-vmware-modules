# Copy to terraform.tfvars. Supply credentials with TF_VAR_vsphere_user and TF_VAR_vsphere_password.
vsphere_server  = "vcenter.example.com"
datacenter_name = "dc-01"
host_name       = "esxi-01.example.com"
switch_name     = "vSwitch-application"
port_group_name = "pg-application"
vlan_id         = 120
