# Copy this file to terraform.tfvars and replace the example values.
vsphere_server = "vcenter.example.com"
project        = "example-project"

datacenter_name   = "dc-01"
cluster_name      = "cluster-01"
datastore_name    = "datastore-01"
network_name      = "dvpg-application"
template_name     = "templates/windows-server-2025"
vm_name           = "win-app-01"
windows_workgroup = "WORKGROUP"
dns_domain        = "example.com"
dns_servers       = ["10.0.0.10", "10.0.0.11"]

# Set TF_VAR_vsphere_user, TF_VAR_vsphere_password and
# TF_VAR_windows_admin_password securely.
