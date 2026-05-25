#!/bin/zsh

# exit on error, print commands
set -eax

# Target VPS host details
VPS_HOST="vps.fxhibon.fr"
VPS_USER="debian"
SSH_KEY="$HOME/.ssh/id_ovh_vps"

# Remote path
REMOTE_DIR="/home/debian/apps/monitoring"

echo "=== Deploying Monitoring Stack to VPS ($VPS_HOST) ==="

# Create directories on VPS if they do not exist
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "mkdir -p $REMOTE_DIR/config/grafana/provisioning/datasources $REMOTE_DIR/config/grafana/provisioning/dashboards $REMOTE_DIR/dashboards $REMOTE_DIR/prometheus-data $REMOTE_DIR/grafana-data"

# Copy local config files to VPS
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" docker-compose.yml "$VPS_USER@$VPS_HOST:$REMOTE_DIR/"
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" config/prometheus.yml "$VPS_USER@$VPS_HOST:$REMOTE_DIR/config/"
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" config/grafana/provisioning/datasources/datasource.yml "$VPS_USER@$VPS_HOST:$REMOTE_DIR/config/grafana/provisioning/datasources/"
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" config/grafana/provisioning/dashboards/dashboard.yml "$VPS_USER@$VPS_HOST:$REMOTE_DIR/config/grafana/provisioning/dashboards/"
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" dashboards/traefik.json "$VPS_USER@$VPS_HOST:$REMOTE_DIR/dashboards/"

# Ensure correct permissions on data directories for persistent volumes
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" "chmod 755 $REMOTE_DIR/prometheus-data $REMOTE_DIR/grafana-data"

# Ensure external docker network 'proxy' exists and deploy monitoring stack
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VPS_USER@$VPS_HOST" << 'EOF'
    docker network create proxy || true
    cd /home/debian/apps/monitoring
    docker compose up -d --remove-orphans --force-recreate --pull always
EOF

echo "=== Monitoring Stack Deployment Completed Successfully ==="
