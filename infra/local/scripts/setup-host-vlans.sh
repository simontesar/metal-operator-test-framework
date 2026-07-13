#!/usr/bin/env bash
set -xeuo pipefail

PARENT_IF="${PARENT_IF:-en0}"
VLAN100_BRIDGE="${VLAN100_BRIDGE:-vlan0}"
VLAN200_BRIDGE="${VLAN200_BRIDGE:-vlan1}"
VLAN100_ID=100
VLAN200_ID=200

create_vlan() {
  local iface="$1"
  local vlan_id="$2"
  local parent="$3"

  if ifconfig "${iface}" >/dev/null 2>&1; then
    echo "Interface ${iface} already exists, skipping create"
    return 0
  fi

  ifconfig "${iface}" create
  ifconfig "${iface}" vlan "${vlan_id}" vlandev "${parent}"
  ifconfig "${iface}" up
  echo "Created ${iface} (VLAN ${vlan_id} on ${parent})"
}

create_vlans() {
  if ! ifconfig "${PARENT_IF}" >/dev/null 2>&1; then
    echo "Parent interface ${PARENT_IF} not found" >&2
    exit 1
  fi

  create_vlan "${VLAN100_BRIDGE}" "${VLAN100_ID}" "${PARENT_IF}"
  create_vlan "${VLAN200_BRIDGE}" "${VLAN200_ID}" "${PARENT_IF}"
}

cleanup_host_interfaces() {
  local destroyed=0
  local skipped=0

  for iface in "${VLAN100_BRIDGE}" "${VLAN200_BRIDGE}"; do
    if ifconfig "${iface}" >/dev/null 2>&1; then
      ifconfig "${iface}" destroy
      echo "Destroyed ${iface}"
      destroyed=$((destroyed + 1))
    else
      echo "Skipped ${iface} (not present)"
      skipped=$((skipped + 1))
    fi
  done

  echo "Cleanup complete: ${destroyed} destroyed, ${skipped} skipped"
}

case "${1:-create}" in
  create)
    create_vlans
    ;;
  cleanup)
    cleanup_host_interfaces
    ;;
  *)
    echo "Usage: $0 [create|cleanup]" >&2
    exit 1
    ;;
esac
