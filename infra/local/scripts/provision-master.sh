#!/usr/bin/env bash
set -euo pipefail

mapfile -t IFACES < <(
  ip -o link show |
    awk -F': ' '$2 !~ /lo/ {gsub(/@.*/, "", $2); print $2}'
)

if [[ ${#IFACES[@]} -lt 4 ]]; then
  echo "Expected at least 4 interfaces, found ${#IFACES[@]}" >&2
  exit 1
fi

UPSTREAM_IB="${IFACES[1]}"
UPSTREAM_OOB="${IFACES[2]}"
TRUNK_IF="${IFACES[3]}"

cat > /etc/netplan/60-master-network.yaml <<EOF
network:
  version: 2
  ethernets:
    ${UPSTREAM_IB}:
      dhcp4: false
      optional: true
    ${UPSTREAM_OOB}:
      dhcp4: false
      optional: true
    ${TRUNK_IF}:
      dhcp4: false
      optional: true
  vlans:
    ${TRUNK_IF}.100:
      id: 100
      link: ${TRUNK_IF}
      addresses: [172.16.100.1/24]
    ${TRUNK_IF}.200:
      id: 200
      link: ${TRUNK_IF}
      addresses: [10.250.200.1/24]
EOF

netplan apply

echo "Configured master network: trunk=${TRUNK_IF}"
