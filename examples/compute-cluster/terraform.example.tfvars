# Copy to terraform.tfvars. Supply credentials with TF_VAR_vsphere_user and TF_VAR_vsphere_password.
vsphere_server  = "vcenter.example.com"
project         = "example-project"
datacenter_name = "dc-01"
cluster_name    = "cluster-application"
host_names      = ["esxi-01.example.com", "esxi-02.example.com"]
