# Copy to terraform.tfvars. Supply credentials with TF_VAR_vsphere_user and TF_VAR_vsphere_password.
vsphere_server  = "vcenter.example.com"
project         = "example-project"
datacenter_name = "dc-01"
datastore_name  = "nfs-application-01"
host_names      = ["esxi-01.example.com", "esxi-02.example.com"]
remote_hosts    = ["nfs-a.example.com", "nfs-b.example.com"]
remote_path     = "/exports/vsphere/application"
