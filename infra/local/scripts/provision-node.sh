#!/usr/bin/env bash
set -euo pipefail

mapfile -t IFACES < <(
  ip -o link show |
    awk -F': ' '$2 !~ /lo/ {gsub(/@.*/, "", $2); print $2}'
)

if [[ ${#IFACES[@]} -lt 3 ]]; then
  echo "Expected at least 3 interfaces, found ${#IFACES[@]}" >&2
  exit 1
fi

IDRAC_IF="${IFACES[1]}"
NIC1_IF="${IFACES[2]}"

cat > /etc/netplan/60-node-network.yaml <<EOF
network:
  version: 2
  ethernets:
    ${IDRAC_IF}:
      dhcp4: true
      optional: true
    ${NIC1_IF}:
      dhcp4: true
      optional: true
EOF

netplan apply
echo "Configured DHCP client on ${IDRAC_IF} (iDRAC) and ${NIC1_IF} (NIC1)"
