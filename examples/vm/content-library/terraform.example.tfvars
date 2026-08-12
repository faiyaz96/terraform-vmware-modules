# Copy to terraform.tfvars. Supply credentials with TF_VAR_vsphere_user and TF_VAR_vsphere_password.
vsphere_server            = "vcenter.example.com"
project                   = "example-project"
datacenter_name           = "dc-01"
cluster_name              = "cluster-01"
datastore_name            = "datastore-01"
network_name              = "dvpg-application"
content_library_name      = "production-templates"
content_library_item_name = "ubuntu-24.04"
customization_spec_name   = "linux-production"
guest_id                  = "ubuntu64Guest"
vm_name                   = "app-01"
root_disk_size_gb         = 40
