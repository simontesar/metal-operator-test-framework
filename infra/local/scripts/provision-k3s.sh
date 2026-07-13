#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

MASTER_IP=$(
  vagrant ssh-config master | awk '/HostName/ { print $2 }'
)

if [[ -z "${MASTER_IP}" ]]; then
  echo "Could not determine master IP from vagrant ssh-config" >&2
  exit 1
fi

cat > inventory <<EOF
[master]
master ansible_host=${MASTER_IP} ansible_user=vagrant ansible_private_key_file=.vagrant/machines/master/parallels/private_key

[master:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF

ansible-playbook master.yaml -i inventory
