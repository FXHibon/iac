# AGENTS.md - VPS Infrastructure as Code Guide

## Project Overview

This is a multi-layer Infrastructure as Code (IaC) project managing a Raspberry Pi 5 (rp5) local cluster and an OVH VPS, with:
- **Compute provisioning**: OpenTofu (formerly Terraform) managing OVH VPS and DNS
- **System configuration**: Ansible playbooks for package installation, security, Docker setup
- **Application deployment**: Docker Compose services across RP5 and VPS
- **Traffic ingestion**: Traefik reverse proxy with auto SSL/TLS (ACME)
- **Monitoring stack**: Prometheus + Grafana + Node Exporter
- **Dashboard**: Homepage service + supporting apps (Transmission with VPN, Plex)

## Architecture Patterns

### Multi-Environment Topology
- **RP5 (Raspberry Pi 5)**: Local network services (192.168.1.59), synced via `rp5/sync.sh`
  - Runs main application stack: homepage, transmission, prometheus, grafana, node-exporter
  - Deployed via SSH + Docker Compose from local machine
  - DNS and VPS serve as external endpoints
  
- **OVH VPS**: Public-facing infrastructure
  - Managed by OpenTofu (`tofu/` dir)
  - Runs Traefik reverse proxy on public IP
  - DNS records map subdomains to home IP (REDACTED_HOME_IP_OLD) and VPS IP
  - Ansible provisions hostname, Docker, Fail2Ban, UFW firewall, SSH hardening

### Service Networking
- **Traefik proxy network**: All services connect to external `proxy` network created by Ansible
- **Docker Compose structure**: Each service group has separate compose file (traefik/, rp5/)
- **Port mapping**: Services expose container ports on host; Traefik routes via Docker labels (if configured)
  - Homepage: 3001, Prometheus: 9090, Grafana: 3000, Transmission: 9091, Node Exporter: 9100

### Configuration Management
- **Terraform state**: Committed to repo (`terraform.tfstate`, `.tfstate.backup`)
- **OVH API credentials**: Via variables (ovh_application_key, ovh_application_secret, ovh_consumer_key)
- **Locals**: Home IP hardcoded in `tofu/variables.tf` (REDACTED_HOME_IP_OLD)
- **Sensitive data**: credentials stored externally (env file or tfvars, referenced in .gitignore)

## Critical Workflows

### Deploy to Raspberry Pi
```bash
cd rp5/
./sync.sh  # Syncs config to rp5-internal SSH host, runs docker compose up -d
```
- Pushes entire rp5/ directory to remote
- Executes docker-compose with --force-recreate and --pull always
- Uses zsh with `set -eax` (exit on error, print commands)

### Provision OVH Infrastructure
```bash
cd tofu/
tofu apply -var-file=env/main.tfvars
```
- Creates VPS instance and DNS records
- Requires OVH credentials in tfvars file
- Outputs VPS ID, name for reference

### Configure VPS with Ansible
```bash
cd ansible/
ansible-playbook -i inventory.ini playbook.yml
```
- Targets `vps` host group (`inventory.ini`: `vps.fxhibon.fr`, `ansible_user=debian`, SSH key `~/.ssh/id_ovh_vps`)
- Sets hostname to `vps.fxhibon.fr`
- Hardens SSH: no root login, key-only auth, `MaxAuthTries 3`, no X11/TCP forwarding (drop-in `sshd_config.d/99-hardening.conf`)
- Configures Fail2Ban SSH jail (5 retries, 1 h ban, systemd backend)
- Enables UFW firewall (default deny, allow 22/80/443)
- Installs Docker Engine + Compose plugin; adds `debian` to `docker` group

## Project-Specific Conventions

### Directory Structure
- `tofu/`: OpenTofu/Terraform IaC (provider: OVH)
  - `env/main.tfvars`: Variable overrides (git-ignored)
  - `provider.tf`: OVH provider config + required version (2.12.0)
- `ansible/`: Playbook for VPS bootstrapping
  - `inventory.ini`: Host definitions (`vps.fxhibon.fr`, user `debian`)
  - `playbook.yml`: Hostname, SSH hardening, Fail2Ban, UFW, Docker
- `rp5/`: Docker Compose stack for Raspberry Pi
  - `sync.sh`: Deployment script (SSH+SCP to rp5-internal)
  - `homepage/config/`: Homepage YAML configs (services.yaml, settings.yaml, widgets.yaml)
  - `prometheus/`, `grafana/`, `transmission/config/`: Service-specific configs
- `traefik/`: Traefik reverse proxy (separate from rp5 for modularity)
  - `data/traefik.yml`: Static config (deployed manually or via separate step)
  - `data/acme.json`: ACME certificate storage (600 perms required)

### Key Integration Points
1. **Traefik → Docker**: Listens to Docker socket, auto-discovers containers on `proxy` network
3. **Prometheus → Node Exporter**: Scrapes `node-exporter:9100` (DNS resolved via Docker Compose network)
4. **Homepage → Docker**: Mounts `/var/run/docker.sock` for widget discovery
5. **RP5 Sync**: `rp5-internal` SSH host must be configured in local SSH config

### Secrets & Credentials
- OVH API keys: Variables in tfvars (not in repo)
- Transmission VPN: Hardcoded in compose (ProtonVPN credentials in environment block) ⚠️
- Grafana admin: Password in compose env (hashed string, not plaintext)
- SSH: Private key path: `~/.ssh/id_ovh_vps` (per inventory.ini)
- Traefik email: `fxhibon+traefik@proton.me` (hardcoded in traefik.yml)

### Language & Tool Versions
- **Terraform/OpenTofu**: 2.12.0 OVH provider
- **Ansible**: Standard playbook format
- **Docker Compose**: v2 plugin (installed via apt)
- **Traefik**: v3.6
- **Monitoring**: Prometheus + Grafana (latest tags)

## Common Pitfalls & Debugging

- **sync.sh permissions**: Ensure zsh is available and SSH key configured for `rp5-internal`
- **Traefik ACME**: acme.json must have 0600 permissions; Ansible enforces this
- **Docker network**: `proxy` network must be created before traefik/service startup (Ansible does this)
- **OVH API**: Consumer key expires; regenerate via OVH Control Panel if auth fails
- **Prometheus scrape**: Node Exporter DNS `node-exporter:9100` only works within Docker Compose network
- **Transmission credentials**: In git (security risk); should use secrets management

## Files to Prioritize
- `tofu/main.tf`: VPS resource definitions
- `ansible/playbook.yml`: System setup (Docker, security, network)
- `rp5/docker-compose.yml`: Application stack definition
- `rp5/sync.sh`: Deployment mechanism
- `traefik/traefik.yml`: Reverse proxy entry points and SSL

