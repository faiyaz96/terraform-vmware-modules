# Copy this file to terraform.tfvars and replace the example values.
vsphere_server = "vcenter.example.com"
project        = "example-project"

datacenter_name = "dc-01"
cluster_name    = "cluster-01"
datastore_name  = "datastore-01"
network_name    = "dvpg-application"
template_name   = "templates/ubuntu-24.04"
vm_name         = "app-01"
dns_domain      = "example.com"

# Set TF_VAR_vsphere_user and TF_VAR_vsphere_password securely.
