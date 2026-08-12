# Tagging module

Creates three standard vSphere tag categories and returns a tag set for each supplied resource name:

- `Name=<resource name>`
- `project=<project>`
- `Terraform=True`

Instantiate this module once in a deployment and pass `tags_by_resource_name[<name>]` to every tag-capable resource module. A single shared instance avoids duplicate vCenter category conflicts.

The default associable types cover the resources in this repository that expose a `tags` argument. vSphere roles, entity permissions, storage policies, security-policy outputs, and content libraries do not expose tag assignment through their provider resources.
