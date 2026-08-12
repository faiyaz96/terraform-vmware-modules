# Copy this file to terraform.tfvars and replace the example values.
vsphere_server  = "vcenter.example.com"
entity_id       = "group-v123"
entity_type     = "Folder"
principal_group = "EXAMPLE\\VMware-Operators"

# Set TF_VAR_vsphere_user and TF_VAR_vsphere_password securely.
