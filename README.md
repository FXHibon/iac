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
| **[deployments/vps/monitoring/](deployments/vps/monitoring/)** | Docker Compose / Prometheus / Grafana | Scrapes metrics and displays dashboards for the VPS host and services. |
| **[deployments/vps/fresh-fridge/](deployments/vps/fresh-fridge/)** | Docker Compose / Node.js | Private web application deployed securely on the VPS. |
| **[deployments/rp5/](deployments/rp5/)** | Docker Compose | Deploys local home-monitoring (Grafana, Prometheus) and media services (Plex, Transmission). |

---

## Deployment Workflows

All host configuration and container stacks are orchestrated from the unified Ansible management folder.

### 1. Compute & DNS Provisioning (OpenTofu)
Build the VPS and domain records. Subdomains are routed exclusively via IPv4 to preserve real client IPs for whitelists:
```bash
cd infra/tofu/vps/ovh/
tofu init
tofu apply
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

### 3. Orchestrate Applications & Deployments (Ansible Tags)
Deploy specific application stacks or everything at once using tags inside the unified Ansible setup:
```bash
cd infra/ansible/

# Deploy/update Traefik reverse proxy only
./deploy.sh --tags traefik

# Deploy/update Monitoring stack only
./deploy.sh --tags monitoring

# Deploy/update Fresh-Fridge application (with secure in-memory SOPS secrets)
./deploy.sh --tags fresh-fridge

# Deploy/update the entire Raspberry Pi (rp5) home lab stack
./deploy.sh --tags rp5

# Run the complete configuration and deploy all stacks across both hosts
./deploy.sh
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
