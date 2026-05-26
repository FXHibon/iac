#!/bin/zsh
set -e

# Decrypt the secrets to a temporary file
echo "Decrypting Ansible secrets..."
sops -d secrets.enc.yaml > secrets.decrypted.yaml

# Ensure cleanup on exit
trap "rm -f secrets.decrypted.yaml" EXIT INT TERM

# Run the playbook passing the decrypted secrets
ansible-playbook -i inventory.ini playbook.yml -e @secrets.decrypted.yaml "$@"
