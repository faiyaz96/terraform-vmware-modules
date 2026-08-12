#!/usr/bin/env bash
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
airgap_directory="$(cd "${script_directory}/.." && pwd)"
repository_directory="$(cd "${airgap_directory}/.." && pwd)"

# shellcheck disable=SC1091
source "${airgap_directory}/versions.env"

bundle_directory="${airgap_directory}/bundle"
download_directory="${bundle_directory}/downloads"
binary_directory="${bundle_directory}/bin"
mirror_directory="${bundle_directory}/provider-mirror"
module_directory="${bundle_directory}/modules"
configuration_directory="${bundle_directory}/config"
documentation_directory="${bundle_directory}/docs"
script_output_directory="${bundle_directory}/scripts"

for command_name in curl tar unzip; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command is unavailable: ${command_name}" >&2
    exit 1
  fi
done

if command -v sha256sum >/dev/null 2>&1; then
  checksum_command=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  checksum_command=(shasum -a 256)
else
  echo "Either sha256sum or shasum is required." >&2
  exit 1
fi

download_artifact() {
  local artifact_url="$1"
  local artifact_path="$2"

  if [[ -s "${artifact_path}" ]]; then
    echo "Reusing existing download: ${artifact_path##*/}"
    return
  fi

  curl --fail --location --retry 3 \
    --output "${artifact_path}" \
    "${artifact_url}"
}

mkdir -p \
  "${download_directory}" \
  "${binary_directory}" \
  "${mirror_directory}" \
  "${module_directory}" \
  "${configuration_directory}" \
  "${documentation_directory}" \
  "${script_output_directory}"

terraform_checksums="terraform_${TERRAFORM_VERSION}_SHA256SUMS"
terraform_signature="${terraform_checksums}.sig"
terraform_release_url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}"

download_artifact \
  "${terraform_release_url}/${terraform_checksums}" \
  "${download_directory}/${terraform_checksums}"
download_artifact \
  "${terraform_release_url}/${terraform_signature}" \
  "${download_directory}/${terraform_signature}"

for target_platform in ${TARGET_PLATFORMS}; do
  target_os="${target_platform%%_*}"
  target_arch="${target_platform#*_}"
  terraform_archive="terraform_${TERRAFORM_VERSION}_${target_os}_${target_arch}.zip"

  download_artifact \
    "${terraform_release_url}/${terraform_archive}" \
    "${download_directory}/${terraform_archive}"

  expected_checksum="$(awk -v archive="${terraform_archive}" '$2 == archive { print $1 }' "${download_directory}/${terraform_checksums}")"
  actual_checksum="$("${checksum_command[@]}" "${download_directory}/${terraform_archive}" | awk '{ print $1 }')"

  if [[ -z "${expected_checksum}" || "${expected_checksum}" != "${actual_checksum}" ]]; then
    echo "Checksum verification failed for ${terraform_archive}." >&2
    exit 1
  fi

  mkdir -p "${binary_directory}/${target_platform}"
  unzip -o -q "${download_directory}/${terraform_archive}" -d "${binary_directory}/${target_platform}"
done

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) host_platform="linux_amd64" ;;
  Linux-aarch64 | Linux-arm64) host_platform="linux_arm64" ;;
  Darwin-x86_64) host_platform="darwin_amd64" ;;
  Darwin-arm64) host_platform="darwin_arm64" ;;
  *)
    echo "Unsupported build host: $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

terraform_binary="${binary_directory}/${host_platform}/terraform"
chmod +x "${terraform_binary}"

mirror_arguments=()
lock_arguments=()
for target_platform in ${TARGET_PLATFORMS}; do
  mirror_arguments+=("-platform=${target_platform}")
  lock_arguments+=("-platform=${target_platform}")
done

"${terraform_binary}" -chdir="${airgap_directory}/provider-config" providers lock \
  "${lock_arguments[@]}" \
  registry.terraform.io/vmware/vsphere

"${terraform_binary}" -chdir="${airgap_directory}/provider-config" providers mirror \
  "${mirror_arguments[@]}" \
  "${mirror_directory}"

tar -C "${repository_directory}" \
  --exclude='.terraform' \
  --exclude='*.tfstate' \
  --exclude='*.tfstate.*' \
  -czf "${module_directory}/terraform-vmware-modules-${MODULE_RELEASE}.tar.gz" \
  modules examples README.md LICENSE CHANGELOG.md

cp "${airgap_directory}/config/terraform-airgap.tfrc.example" "${configuration_directory}/terraform-airgap.tfrc.example"
cp "${airgap_directory}/config/terraform-airgap-windows.tfrc.example" "${configuration_directory}/terraform-airgap-windows.tfrc.example"
cp "${airgap_directory}/config/backend-consul.tf.example" "${configuration_directory}/backend-consul.tf.example"
cp "${airgap_directory}/config/backend-consul.hcl.example" "${configuration_directory}/backend-consul.hcl.example"
cp "${airgap_directory}/config/backend-local.tf.example" "${configuration_directory}/backend-local.tf.example"
cp "${airgap_directory}/README.md" "${documentation_directory}/AIRGAP.md"
cp "${airgap_directory}/versions.env" "${bundle_directory}/versions.env"
mkdir -p "${configuration_directory}/provider-test"
cp "${airgap_directory}/provider-config/main.tf" "${configuration_directory}/provider-test/main.tf"
cp "${airgap_directory}/provider-config/.terraform.lock.hcl" "${configuration_directory}/provider-test/.terraform.lock.hcl"
cp "${airgap_directory}/scripts/verify-bundle.sh" "${script_output_directory}/verify-bundle.sh"
cp "${airgap_directory}/scripts/verify-bundle.ps1" "${script_output_directory}/verify-bundle.ps1"
cp "${airgap_directory}/scripts/test-offline-init.sh" "${script_output_directory}/test-offline-init.sh"
cp "${airgap_directory}/scripts/test-offline-init.ps1" "${script_output_directory}/test-offline-init.ps1"
chmod +x "${script_output_directory}/verify-bundle.sh" "${script_output_directory}/test-offline-init.sh"

manifest_file="${bundle_directory}/SHA256SUMS"
temporary_manifest="${bundle_directory}/SHA256SUMS.tmp"

find "${bundle_directory}" -type f \
  ! -name 'SHA256SUMS' \
  ! -name 'SHA256SUMS.tmp' \
  ! -name '.gitkeep' \
  | LC_ALL=C sort | while IFS= read -r artifact; do
    artifact_checksum="$("${checksum_command[@]}" "${artifact}" | awk '{ print $1 }')"
    artifact_path="${artifact#"${bundle_directory}"/}"
    printf '%s  %s\n' "${artifact_checksum}" "${artifact_path}"
  done > "${temporary_manifest}"

mv "${temporary_manifest}" "${manifest_file}"

echo "Air-gap bundle created at ${bundle_directory}"
echo "Run ${airgap_directory}/scripts/verify-bundle.sh before transfer."
