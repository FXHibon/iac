# vps-iac

Infrastructure as Code (IaC) for a personal local homelab and public OVH VPS — managed with OpenTofu, Ansible, and Docker Compose.

## Repository Structure

```
.
├── openspec/              # Spec-Driven Development (SDD) specifications & changesets
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
| **[openspec/](openspec/)** | OpenSpec / SDD | Source-of-truth specifications (`specs/`) and delta proposals (`changes/`) for IaC iterations. |
| **[infra/tofu/](infra/tofu/)** | OpenTofu | Provisions the OVH VPS instance and configures DNS (A records, wildcards). |
| **[infra/ansible/](infra/ansible/)** | Ansible | Hardens SSH, installs UFW/Fail2Ban, configures Docker, and orchestrates container stack deployments. |
| **[deployments/vps/traefik/](deployments/vps/traefik/)** | Docker Compose / Traefik v3.7 | Exposes VPS containers publicly with auto Let's Encrypt SSL and defense-in-depth security. |
| **[deployments/vps/monitoring/](deployments/vps/monitoring/)** | Docker Compose / Prometheus / Grafana / Loki / Alloy / docker-stats-exporter | Scrapes VPS metrics (via docker-stats-exporter), aggregates logs dynamically (via Alloy + Loki), and hosts the unified dashboards. |
| **[deployments/vps/fresh-fridge/](deployments/vps/fresh-fridge/)** | Docker Compose / Node.js | Private web application deployed securely on the VPS. |
| **[deployments/vps/running-pace-calculator/](deployments/vps/running-pace-calculator/)** | Docker Compose / React / Nginx | Public running pace calculator application deployed on the VPS. |
| **[deployments/vps/fxhibon-fr/](deployments/vps/fxhibon-fr/)** | Docker Compose / Nginx | Public main personal site deployed on the VPS. |
| **[deployments/vps/satisfactory/](deployments/vps/satisfactory/)** | Docker Compose / SteamCMD | Satisfactory Dedicated Server deployed directly on the VPS. |
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

# Deploy/update Running Pace Calculator application
task deploy-running-pace-calculator

# Deploy/update the fxhibon.fr application
task deploy-fxhibon-fr

# Deploy/update the Satisfactory Dedicated Server application
task deploy-satisfactory

# Stop the Satisfactory Dedicated Server application
task stop-satisfactory

# Deploy/update the entire Raspberry Pi (rp5) home lab stack
task deploy-rp5

# Automatically detect and deploy only updated applications/stacks
task deploy-changed

# Dry-run what applications would be redeployed by the change detection script
task deploy-changed-dry

# Initialize or reset the 'deployed' git tag at the current commit
task deploy-init-tag
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

## Dependency Management (Renovate)

This project uses [Renovate](https://docs.renovatebot.com/) to automatically check and update external components (Docker Compose image tags and OpenTofu provider versions). 

The configuration in [`renovate.json`](renovate.json) specifies the update policies:
- **Auto-Discovery:** Automatically scans all `docker-compose.yml` and `.tf` files recursively.
- **Grouping:** Groups all minor and patch updates together (into a single update) to minimize noise.
- **Major Upgrades:** Requires explicit approval for major upgrades because they may contain breaking changes.

### Running Renovate Locally

Using the configured `Taskfile.yml` tasks, you can run Renovate locally in dry-run mode to audit packages or run it in write mode to automatically update the files on your disk:

```bash
# 1. Audit your dependencies (Dry-run / Lookup mode - Read Only)
task renovate-check

# 2. Automatically apply available updates directly to your local files
task renovate-apply
```

### Git Platform Integration (Optional)
For complete hands-free automation, you can enable Renovate on your git hosting provider:
- **GitHub:** Install the [Renovate GitHub App](https://github.com/apps/renovate). It will read your `renovate.json` and automatically open daily/weekly Pull Requests for updates.
- **Self-Hosted / CI Pipelines:** You can run it inside a scheduled pipeline (e.g. GitHub Actions, GitLab CI) using the official Renovate runner images.

---

## Advanced Guides & Operations

For specialized procedures, diagnostics, and configurations, refer to the following sub-documents:

- 🗄️ **[Database Backup & Restore (Fresh-Fridge)](deployments/vps/fresh-fridge/README.md)**: Steps for managing PostgreSQL backups and performing recovery on the VPS.
- 🛡️ **[Diagnostics & System Security](infra/ansible/README.md#diagnostics--security-runbook)**: Verification commands for Fail2Ban, UFW firewall, SSH IP geolocation scripts, and testing Alertmanager alerts.
- 🤖 **[Reusable GitHub Actions](.github/workflows/README.md)**: Guidelines on utilizing the shared Docker Build & Push workflow within external repositories.


