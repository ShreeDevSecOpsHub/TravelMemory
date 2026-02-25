#!/bin/bash
# This script helps run Ansible from Windows via WSL
# Save the inventory and playbook content to mounted Windows directory
# Then run playbooks from within WSL

# Script name: run-ansible.sh
# Usage: chmod +x run-ansible.sh
#        ./run-ansible.sh playbooks/db-server.yml

ANSIBLE_PLAYBOOK="${1:-playbooks/main.yml}"
ADMIN_PASS="${2:-admin123}"
APP_PASS="${3:-appuser123}"

echo "Running Ansible Playbook: $ANSIBLE_PLAYBOOK"
echo "From directory: $(pwd)"
echo ""

# Run the playbook
ansible-playbook "$ANSIBLE_PLAYBOOK" \
    -i inventory.ini \
    -e mongodb_admin_password="$ADMIN_PASS" \
    -e mongodb_password="$APP_PASS" \
    -vv

exit $?
