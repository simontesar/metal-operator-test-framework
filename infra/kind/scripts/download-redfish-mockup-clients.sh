#!/usr/bin/env bash
# Downloads and extracts Dell's iDRAC Redfish mockup client data
set -euo pipefail

TARGET_DIR="${1:-../../redfish-mockup-clients}"

REPO_RAW_BASE="https://raw.githubusercontent.com/dell/iDRAC-Redfish-Scripting/master/iDRAC%20Redfish%20Mockup%20Clients"

CLIENTS=(
  R660xs_iDRAC9_7_20_10_05_mockup_client
  R770_iDRAC10_1_10_17_00_mockup_client
  R7725_iDRAC10_1_20_70_50_mockup_client
  XE9712_iDRAC10_1_30_07_10_mockup_client
  iDRAC_mockup_client_GPU_DPU_config
  iDRAC_mockup_client_basic_config
)

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v unzip >/dev/null || { echo "unzip is required" >&2; exit 1; }

mkdir -p "${TARGET_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

for client in "${CLIENTS[@]}"; do
  if [[ -d "${TARGET_DIR}/${client}" ]]; then
    echo "Skipping ${client} (already present in ${TARGET_DIR})"
    continue
  fi

  echo "Downloading ${client}.zip"
  curl -fsSL -o "${TMP_DIR}/${client}.zip" "${REPO_RAW_BASE}/${client}.zip"

  echo "Extracting ${client}.zip into ${TARGET_DIR}"
  unzip -q "${TMP_DIR}/${client}.zip" -d "${TARGET_DIR}"
  rm -f "${TMP_DIR}/${client}.zip"
done

echo "Redfish mockup clients ready in ${TARGET_DIR}"
