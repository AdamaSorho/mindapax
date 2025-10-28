#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$PROJECT_ROOT/infra/ansible"

echo "==> Installing Ansible collections"
pushd "$ANSIBLE_DIR" >/dev/null
ansible-galaxy collection install -r requirements.yml >/dev/null

if [[ ! -f inventory.ini ]]; then
  echo "⚠️  Missing inventory.ini in $ANSIBLE_DIR. Copy inventory.example.ini and fill the server details." >&2
  exit 1
fi

echo "==> Deploying backend stack (Docker containers)"
ansible-playbook -i inventory.ini deploy-backend-docker.yml "$@"
popd >/dev/null
