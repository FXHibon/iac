#!/bin/zsh
set -e

echo "Decrypting secrets into memory and running Ansible playbook..."
ansible-playbook -i inventory.ini playbook.yml -e @<(sops -d secrets.enc.yaml) "$@"

