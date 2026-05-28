# vps-iac

Infrastructure as Code (IaC) for a personal local homelab and public OVH VPS — managed with OpenTofu, Ansible, and Docker Compose.

## Repository Structure

```
.
├── infra/                 # Infrastructure Provisioning & Bootstrapping (The "How")
│   ├── tofu/              # OpenTofu — OVH VPS provisioning & DNS records
│   └── ansible/           # Ansible — host configuration & hardening
│
└── deployments/           # Application stacks grouped by target host (The "What")
    ├── vps/               # Running on public OVH VPS (Traefik, Monitoring, Fresh-Fridge)
    └── rp5/               # Running on Raspberry Pi 5 (Homepage, Monitoring, Transmission)
```

## Components

| Component | Technology | Description |
|-----------|------------|-------------|
| **[infra/tofu/](infra/tofu/)** | OpenTofu | Provisions the OVH VPS instance and configures DNS (A records, wildcards). |
| **[infra/ansible/](infra/ansible/)** | Ansible | Hardens SSH, installs UFW/Fail2Ban, configures Docker, and orchestrates container stack deployments. |
| **[deployments/vps/traefik/](deployments/vps/traefik/)** | Docker Compose / Traefik v3.7 | Exposes VPS containers publicly with auto Let's Encrypt SSL and defense-in-depth security. |
| **[deployments/vps/monitoring/](deployments/vps/monitoring/)** | Docker Compose / Prometheus / Grafana / Loki / Alloy / docker-stats-exporter | Scrapes VPS metrics (via docker-stats-exporter), aggregates logs dynamically (via Alloy + Loki), and hosts the unified dashboards. |
| **[deployments/vps/fresh-fridge/](deployments/vps/fresh-fridge/)** | Docker Compose / Node.js | Private web application deployed securely on the VPS. |
| **[deployments/rp5/](deployments/rp5/)** | Docker Compose | Deploys local home-monitoring (Grafana, Prometheus) and media services (Plex, Transmission). |

---

## Deployment & Management Workflows

The repository uses **Taskfile** (https://taskfile.dev/) as a local developer runner to orchestrate OpenTofu, Ansible, and Docker commands from the project root.

### 1. Compute & DNS Provisioning (OpenTofu)
Build the VPS and domain records. Subdomains are routed exclusively via IPv4 to preserve real client IPs for whitelists:
```bash
# Generate the execution plan
task tofu-plan

# Build or apply changes to OVH VPS infrastructure
task tofu-apply
```

### 2. Post-Provision Hardening & System Setup (Ansible)
Prepare the host with SSH hardening, firewall (UFW), Fail2Ban, and Docker engine installation:
```bash
cd infra/ansible/
# Install required galaxy collections
ansible-galaxy collection install community.general community.docker

# Run base configuration
ansible-playbook -i inventory.ini playbook.yml
```

### 3. Orchestrate Applications & Deployments (Taskfile / Ansible)
Deploy specific application stacks, upgrade system packages, or manage secrets securely using Taskfile commands:
```bash
# Deploy/update the entire VPS + Raspberry Pi stack
task deploy-all

# Deploy all applications on the VPS (Traefik, Monitoring, Fresh-Fridge)
task deploy-vps

# Deploy/update Traefik reverse proxy only
task deploy-traefik

# Deploy/update the VPS Monitoring stack (Loki, Alloy, Prometheus, Grafana, docker-stats-exporter)
task deploy-monitoring

# Deploy/update Fresh-Fridge application (with automatic secure SOPS secrets lookup)
task deploy-fresh-fridge

# Deploy/update the entire Raspberry Pi (rp5) home lab stack
task deploy-rp5
```

### 4. System Upgrades & Diagnostics
```bash
# Upgrade all packages on the VPS and Raspberry Pi in parallel
task upgrade-all

# Check live container statuses on the VPS
task vps-status

# Follow live container logs over SSH
task vps-logs container=alloy
```

---

## General Diagnostics & Security Commands

```shell
# Check security statuses
systemctl status fail2ban
systemctl status ufw

# List Fail2Ban jails & status
fail2ban-client status
fail2ban-client status sshd

# List geolocation of banned SSH IPs
fail2ban-client banned | \
tr "'" '"' | \
jq -r '.[0].sshd.[]' | \
while read line
do
  geoiplookup $line | sed -r 's/GeoIP Country Edition: //g'
done | \
sort | uniq -c | sort --numeric --reverse

# Check firewall rules
ufw status verbose

# Test local Alertmanager manual triggers
curl -v -H "Content-Type: application/json" -d '[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "critical",
      "instance": "localhost"
    },
    "annotations": {
      "summary": "Manual test alert",
      "description": "If you are seeing this, Alertmanager notifications are working!"
    }
  }
]' http://localhost:9093/api/v2/alerts
```
