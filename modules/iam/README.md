# IAM module

Creates custom vCenter roles and assigns roles to existing SSO or external identity-provider users and groups on vSphere inventory entities.

Prefer group-based permissions and propagation from the narrowest suitable inventory folder. Do not manage human-user passwords in Terraform. Privilege identifiers differ by vSphere version and enabled products, so validate a least-privilege role in a non-production vCenter first.
