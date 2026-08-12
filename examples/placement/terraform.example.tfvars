# Copy to terraform.tfvars. Supply credentials with TF_VAR_vsphere_user and TF_VAR_vsphere_password.
vsphere_server  = "vcenter.example.com"
datacenter_name = "dc-01"
cluster_name    = "cluster-application"
vm_names        = ["app-01", "app-02"]
