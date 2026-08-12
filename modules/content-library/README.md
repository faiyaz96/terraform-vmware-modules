# Content library module

Creates a local, published, or subscribed vSphere content library and optional OVF, ISO, or VM-template items. The vCenter environment—not the Terraform workstation—must be able to reach every `file_url`.

Passwords are sensitive inputs but, like all Terraform-managed secrets, are still stored in state. Protect the state backend and supply passwords from environment variables or a secrets workflow.
