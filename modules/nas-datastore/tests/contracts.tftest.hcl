mock_provider "vsphere" {}

variables {
  name            = "nfs-application"
  host_system_ids = ["host-1", "host-2"]
  type            = "NFS41"
  remote_hosts    = ["nfs-a.example.com", "nfs-b.example.com"]
  remote_path     = "/exports/application"
}

run "nfs41_contract" {
  command = plan

  assert {
    condition = (
      vsphere_nas_datastore.this.type == "NFS41" &&
      length(vsphere_nas_datastore.this.host_system_ids) == 2 &&
      vsphere_nas_datastore.this.security_type == "AUTH_SYS"
    )
    error_message = "NFS 4.1 endpoint, host, or security settings were not passed through."
  }
}

run "reject_multiple_nfs3_endpoints" {
  command = plan

  variables {
    type = "NFS"
  }

  expect_failures = [vsphere_nas_datastore.this]
}
