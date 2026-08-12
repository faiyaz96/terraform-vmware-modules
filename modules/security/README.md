# Security baseline module

Produces a centrally defined set of secure defaults for the VM and networking modules. The module does not create resources on its own; enforcement occurs when its outputs are passed to those modules.

Secure boot requires an EFI-compatible template. vTPM requires a supported vCenter/ESXi configuration and an appropriate key provider. VBS is primarily for supported Windows guests and also enables the provider-required virtualization settings.

This module does not create firewall rules. Use VMware NSX for distributed firewalling and micro-segmentation.
