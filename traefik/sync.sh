#!/bin/zsh

# exit on error, print commands
set -eax

# Target VPS host details
VPS_HOST="vps.fxhibon.fr"
VPS_USER="debian"
SSH_KEY="$HOME/.ssh/id_ovh_vps"

# Remote path
REMOTE_DIR="/home/debian/apps/traefik"

echo "=== Deploying Traefik to VPS ($VPS_HOST) ==="

# Create directories on VPS if they do not exist
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $REMOTE_DIR/data"

# Copy local config files to VPS
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" docker-compose.yml "$VPS_USER@$VPS_HOST:$REMOTE_DIR/"
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" data/traefik.yml "$VPS_USER@$VPS_HOST:$REMOTE_DIR/data/"

# Ensure acme.json exists with correct permissions (0600) on the VPS
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "touch $REMOTE_DIR/data/acme.json && chmod 600 $REMOTE_DIR/data/acme.json"

# Ensure external docker network 'proxy' exists and deploy Traefik
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" << 'EOF'
    docker network create proxy || true
    cd /home/debian/apps/traefik
    docker compose up -d --remove-orphans --force-recreate --pull always
EOF

echo "=== Traefik Deployment Completed Successfully ==="
