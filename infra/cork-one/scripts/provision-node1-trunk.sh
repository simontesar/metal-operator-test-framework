#!/usr/bin/env bash
set -euo pipefail

# eth0 is the Parallels shared adapter; eth1-eth3 are the bridged role NICs.
# The trunk (NIC2) is the third bridged adapter.
TRUNK_IF=$(
  ip -o link show |
    awk -F': ' '$2 !~ /lo/ {gsub(/@.*/, "", $2); print $2}' |
    sed -n '4p'
)

if [[ -z "${TRUNK_IF}" ]]; then
  echo "Could not detect trunk interface" >&2
  exit 1
fi

cat > /etc/netplan/60-trunk-vlans.yaml <<EOF
network:
  version: 2
  ethernets:
    ${TRUNK_IF}:
      dhcp4: false
      optional: true
  vlans:
    ${TRUNK_IF}.100:
      id: 100
      link: ${TRUNK_IF}
    ${TRUNK_IF}.200:
      id: 200
      link: ${TRUNK_IF}
EOF

netplan apply
echo "Configured VLAN 100 and 200 on ${TRUNK_IF}"
