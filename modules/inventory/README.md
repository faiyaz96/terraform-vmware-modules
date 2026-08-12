# Inventory module

Creates vSphere inventory folders in an existing datacenter. Use stable map keys so display-name changes do not change Terraform resource addresses.

Folder paths are relative to the corresponding datacenter inventory root. Pass standard tag IDs from the tagging module through each folder's `tags` property.
