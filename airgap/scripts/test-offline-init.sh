#!/usr/bin/env bash
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
airgap_directory="$(cd "${script_directory}/.." && pwd)"
if [[ -d "${airgap_directory}/provider-mirror" ]]; then
  bundle_directory="${airgap_directory}"
  provider_configuration_directory="${bundle_directory}/config/provider-test"
else
  bundle_directory="${airgap_directory}/bundle"
  provider_configuration_directory="${airgap_directory}/provider-config"
fi

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) host_platform="linux_amd64" ;;
  Linux-aarch64 | Linux-arm64) host_platform="linux_arm64" ;;
  Darwin-x86_64) host_platform="darwin_amd64" ;;
  Darwin-arm64) host_platform="darwin_arm64" ;;
  *)
    echo "Unsupported test host: $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

terraform_binary="${bundle_directory}/bin/${host_platform}/terraform"
mirror_directory="${bundle_directory}/provider-mirror"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT

cp "${provider_configuration_directory}/main.tf" "${temporary_directory}/main.tf"
cp "${provider_configuration_directory}/.terraform.lock.hcl" "${temporary_directory}/.terraform.lock.hcl"

cli_configuration="${temporary_directory}/terraform.tfrc"
sed "s|/opt/terraform/provider-mirror|${mirror_directory}|" \
  "${airgap_directory}/config/terraform-airgap.tfrc.example" > "${cli_configuration}"

TF_CLI_CONFIG_FILE="${cli_configuration}" CHECKPOINT_DISABLE=1 \
  "${terraform_binary}" -chdir="${temporary_directory}" init -backend=false -input=false

TF_CLI_CONFIG_FILE="${cli_configuration}" CHECKPOINT_DISABLE=1 \
  "${terraform_binary}" -chdir="${temporary_directory}" providers

echo "Offline provider initialization succeeded for ${host_platform}."
