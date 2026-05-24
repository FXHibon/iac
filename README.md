# vps-iac

Infrastructure as Code (IaC) for a personal local homelab and public OVH VPS — managed with OpenTofu, Ansible, and Docker Compose.

## Repository Structure

```
.
├── tofu/       # OpenTofu — OVH VPS provisioning & DNS records (vps.fxhibon.fr)
├── ansible/    # Ansible — server bootstrapping & security hardening
├── rp5/        # Raspberry Pi 5 — local private homelab services (Plex, Transmission, Grafana...)
└── traefik/    # Traefik v3.7 — frontal HTTP/HTTPS reverse proxy configuration on VPS
```

## Components

| Component | Technology | Description |
|-----------|------------|-------------|
| **[tofu/](tofu/)** | OpenTofu | Provisions the OVH VPS instance and configures DNS (A records, wildcards). |
| **[ansible/](ansible/)** | Ansible | Hardens SSH, installs UFW/Fail2Ban, configures Docker, and sets up Traefik directories. |
| **[traefik/](traefik/)** | Docker Compose / Traefik v3.7 | Exposes VPS containers publicly with auto Let's Encrypt SSL and defense-in-depth security. |
| **[rp5/](rp5/)** | Docker Compose | Deploys local home-monitoring (Grafana, Prometheus) and torrent/media services. |

---

## Deployment Workflows

### 1. Compute & DNS Provisioning (OpenTofu)
Build the VPS and domain records. Subdomains are routed exclusively via IPv4 to preserve real client IPs for whitelists:
```bash
cd tofu/vps/ovh/
tofu init
tofu apply
```

### 2. Post-Provision Hardening & Setup (Ansible)
Prepare the host with SSH hardening, firewall (UFW), Docker, and directory infrastructure:
```bash
cd ansible/
# Install collections
ansible-galaxy collection install community.general community.docker

# Run full configuration
ansible-playbook -i inventory.ini playbook.yml
```

### 3. Deploy Traefik Reverse Proxy (VPS)
Deploy the front-end reverse proxy. The Traefik Admin Dashboard (`https://traefik.vps.fxhibon.fr`) is secured with both an **IP AllowList** (limiting access to your home IPv4) and **HTTP Basic Auth**:
```bash
cd traefik/
./sync.sh
```

### 4. Deploy Raspberry Pi Services (Local Homelab)
Sync configuration files and launch your home container stack:
```bash
cd rp5/
./sync.sh
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
