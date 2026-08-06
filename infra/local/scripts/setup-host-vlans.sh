#!/usr/bin/env bash
set -xeuo pipefail

PARENT_IF="${PARENT_IF:-dummy0}"
VLAN100_BRIDGE="${VLAN100_BRIDGE:-vlan0}"
VLAN200_BRIDGE="${VLAN200_BRIDGE:-vlan1}"
VLAN100_ID=100
VLAN200_ID=200

ensure_parent() {
  if ip link show "${PARENT_IF}" >/dev/null 2>&1; then
    echo "Parent interface ${PARENT_IF} already exists, skipping create"
    return 0
  fi

  if [[ "${PARENT_IF}" != dummy* ]]; then
    echo "Parent interface ${PARENT_IF} not found and is not a dummy device (refusing to auto-create a real NIC)" >&2
    exit 1
  fi

  sudo ip link add "${PARENT_IF}" type dummy
  sudo ip link set "${PARENT_IF}" up
  echo "Created dummy parent ${PARENT_IF}"
}

create_vlan() {
  local iface="$1"
  local vlan_id="$2"
  local parent="$3"

  if ip link show "${iface}" >/dev/null 2>&1; then
    echo "Interface ${iface} already exists, skipping create"
    return 0
  fi

  sudo ip link add link "${parent}" name "${iface}" type vlan id "${vlan_id}"
  sudo ip link set "${iface}" up
  echo "Created ${iface} (VLAN ${vlan_id} on ${parent})"
}

create_vlans() {
  ensure_parent
  create_vlan "${VLAN100_BRIDGE}" "${VLAN100_ID}" "${PARENT_IF}"
  create_vlan "${VLAN200_BRIDGE}" "${VLAN200_ID}" "${PARENT_IF}"
}

cleanup_host_interfaces() {
  local destroyed=0
  local skipped=0

  for iface in "${VLAN100_BRIDGE}" "${VLAN200_BRIDGE}"; do
    if ip link show "${iface}" >/dev/null 2>&1; then
      sudo ip link delete "${iface}"
      echo "Destroyed ${iface}"
      destroyed=$((destroyed + 1))
    else
      echo "Skipped ${iface} (not present)"
      skipped=$((skipped + 1))
    fi
  done

  if [[ "${PARENT_IF}" == dummy* ]] && ip link show "${PARENT_IF}" >/dev/null 2>&1; then
    sudo ip link delete "${PARENT_IF}"
    echo "Destroyed dummy parent ${PARENT_IF}"
    destroyed=$((destroyed + 1))
  fi

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
