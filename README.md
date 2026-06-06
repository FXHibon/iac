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

---

## Database Backup & Restore

The PostgreSQL database for the `fresh-fridge` service (`postgres:18-alpine`) is automatically backed up daily to an OVH S3-compatible object storage bucket (`backups-fxhibon`) using the `ghcr.io/solectrus/postgres-s3-backup:18` sidecar container.

### ⚠️ Warning: Data Loss
Restoring a database backup is **destructive**. All existing tables, data, and database objects in the target database will be dropped and re-created using the backup.

### Restoration Procedure

All commands should be executed on the VPS host.

#### Step 1: SSH into the VPS
```bash
ssh vps
```

#### Step 2: Navigate to the Application Directory
```bash
cd /home/debian/apps/fresh-fridge
```

#### Step 3: Stop the Application Container
To prevent any reads or writes during the restore process and avoid application state issues, stop the `fresh-fridge` app container. The database and backup containers must remain running:
```bash
docker stop fresh-fridge
```

#### Step 4: Choose a Backup and Restore

##### Option A: Restore the Latest Backup
To restore the most recent backup found in the S3 bucket:
```bash
docker exec -it fresh-fridge-backup sh restore.sh
```

##### Option B: Restore a Specific Backup
1. **List available backups** inside the S3 bucket to find the desired timestamp:
   ```bash
   docker exec -it fresh-fridge-backup sh -c 'aws --endpoint-url $S3_ENDPOINT s3 ls s3://$S3_BUCKET/$S3_PREFIX/'
   ```
   *The backup files are named in the format: `<database_name>_<timestamp>.dump` (e.g., `fresh_fridge_db_2026-06-06T12:00:00.dump`).*

2. **Run the restore command** with the target timestamp as the parameter:
   ```bash
   docker exec -it fresh-fridge-backup sh restore.sh <timestamp>
   ```
   *For example:*
   ```bash
   docker exec -it fresh-fridge-backup sh restore.sh 2026-06-06T12:00:00
   ```

#### Step 5: Restart the Application Container
Once the restore completes successfully, start the application container again:
```bash
docker start fresh-fridge
```

### Manual/Ad-Hoc Backup Trigger
If you want to trigger a manual backup immediately (e.g., before performing system upgrades or code changes):
```bash
docker exec -it fresh-fridge-backup sh backup.sh
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

## Reusable GitHub Action (Docker Build & Push)

This repository implements a reusable GitHub Actions workflow to build and push multi-platform (`amd64`/`arm64`) Docker images for your other projects.

### How to Use

Create a workflow file in your other repository (e.g., `.github/workflows/ci.yml`):

```yaml
name: Build and Push Service

on:
  push:
    branches:
      - master
    tags:
      - 'v*' # Trigger on SemVer version tags

jobs:
  docker-build-push:
    uses: fxhibon/iac/.github/workflows/docker-build-push.yml@master
    secrets:
      dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
```

### Secrets Setup
Make sure you store the following secrets under **Settings** -> **Secrets and variables** -> **Actions** in the calling repository:
- `DOCKERHUB_USERNAME`: Set to `fxhibon`.
- `DOCKERHUB_TOKEN`: Your Docker Hub Personal Access Token.

The workflow automatically names the image based on the caller repository's name and handles SemVer, branch, and commit-level tagging automatically. For detailed configuration, refer to [.github/workflows/docker-build-push.yml](.github/workflows/docker-build-push.yml).


