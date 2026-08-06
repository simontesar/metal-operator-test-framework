#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ENV_DIR="$(pwd)"

SSH_CONFIG=$(vagrant ssh-config master)
MASTER_IP=$(awk '/HostName/ { print $2 }' <<<"${SSH_CONFIG}")
MASTER_KEY=$(awk '/IdentityFile/ { print $2 }' <<<"${SSH_CONFIG}")

if [[ -z "${MASTER_IP}" || -z "${MASTER_KEY}" ]]; then
  echo "Could not determine master IP/private key from vagrant ssh-config" >&2
  exit 1
fi

cat > inventory <<EOF
[master]
master ansible_host=${MASTER_IP} ansible_user=vagrant ansible_private_key_file=${MASTER_KEY}

[master:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF

ansible-playbook "${ENV_DIR}/../playbooks/master.yaml" \
  -i inventory \
  -e "kubeconfig_dest=${ENV_DIR}/kubeconfig"
