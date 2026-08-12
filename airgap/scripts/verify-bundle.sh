#!/usr/bin/env bash
set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
airgap_directory="$(cd "${script_directory}/.." && pwd)"
if [[ -f "${airgap_directory}/SHA256SUMS" ]]; then
  bundle_directory="${airgap_directory}"
else
  bundle_directory="${airgap_directory}/bundle"
fi
manifest_file="${bundle_directory}/SHA256SUMS"

if [[ ! -f "${manifest_file}" ]]; then
  echo "Bundle manifest not found: ${manifest_file}" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  (cd "${bundle_directory}" && sha256sum --check SHA256SUMS)
elif command -v shasum >/dev/null 2>&1; then
  (cd "${bundle_directory}" && shasum -a 256 --check SHA256SUMS)
else
  echo "Either sha256sum or shasum is required." >&2
  exit 1
fi

echo "All air-gap bundle checksums are valid."
