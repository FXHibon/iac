# AGENTS.md - VPS Infrastructure as Code Guide

## Project Overview

This is a multi-layer Infrastructure as Code (IaC) project managing a Raspberry Pi 5 (rp5) local cluster and an OVH VPS, with:
- **Compute provisioning**: OpenTofu (formerly Terraform) managing OVH VPS and DNS
- **System configuration**: Ansible playbooks for package installation, security, Docker setup, and Traefik provisioning
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
  - DNS records map subdomains to home IP (REDACTED_HOME_IP) and VPS IP
  - Ansible provisions hostname, Docker, Fail2Ban, UFW firewall, SSH hardening, and Traefik directories/networks

### Service Networking
- **Traefik proxy network**: All VPS services connect to the external `proxy` network created by Ansible/sync script.
- **Docker Compose structure**: Each service group has a separate compose file (`traefik/`, `rp5/`).
- **Port mapping**: Services expose container ports internally; Traefik routes via Docker labels (e.g., `traefik.enable=true`).
  - Homepage: 3001, Prometheus: 9090, Grafana: 3000, Transmission: 9091, Node Exporter: 9100.
  - Traefik: exposes public `80` (HTTP) and `443` (HTTPS) ports. The admin panel (`api@internal`) is secured and never exposed on a host port.

### Configuration Management
- **Terraform state**: Committed to repo (`terraform.tfstate`, `.tfstate.backup`)
- **OVH API credentials**: Via variables (ovh_application_key, ovh_application_secret, ovh_consumer_key)
- **Locals**: Home IP hardcoded in `tofu/variables.tf` (REDACTED_HOME_IP)
- **Sensitive data**: credentials stored externally (env file or tfvars, referenced in .gitignore)

## Critical Workflows

### Deploy to Raspberry Pi
```bash
cd rp5/
./sync.sh  # Syncs config to rp5-internal SSH host, runs docker compose up -d
```
- Pushes entire `rp5/` directory to remote
- Executes docker-compose with `--force-recreate` and `--pull always`
- Uses zsh with `set -eax` (exit on error, print commands)

### Deploy Traefik reverse proxy to VPS
```bash
cd traefik/
./sync.sh  # Syncs Traefik configuration, sets permissions, and starts container on VPS
```
- Recreates Traefik folders on remote VPS (`/home/debian/apps/traefik/data`).
- Syncs `docker-compose.yml` and `data/traefik.yml`.
- Automatically initializes `acme.json` with secure `0600` permissions.
- Ensures the external Docker `proxy` network exists and pulls the latest Traefik image.

### Provision OVH Infrastructure
```bash
cd tofu/vps/ovh/
tofu apply
```
- Creates VPS instance and DNS records (including wildcard `*.vps.fxhibon.fr` and `traefik.vps.fxhibon.fr`).
- Restricts external subdomains strictly to **IPv4 (A records)** to prevent source-IP preservation loss over Docker proxy.

### Configure VPS with Ansible
```bash
cd ansible/
ansible-playbook -i inventory.ini playbook.yml
```
- Targets `vps` host group (`inventory.ini`: `vps.fxhibon.fr`, `ansible_user=debian`, SSH key `~/.ssh/id_ovh_vps`)
- Sets hostname to `vps.fxhibon.fr`
- Hardens SSH: no root login, key-only auth, `MaxAuthTries 3`, no X11/TCP forwarding
- Configures Fail2Ban SSH jail (5 retries, 1 h ban, systemd backend)
- Enables UFW firewall (default deny, allow 22/80/443)
- Installs Docker Engine + Compose plugin; adds `debian` to `docker` group
- **Traefik Tag**: Add `--tags traefik` to provision ONLY Traefik configuration and start the proxy container.

## Project-Specific Conventions

### Directory Structure
- `tofu/`: OpenTofu/Terraform IaC (provider: OVH)
  - `env/main.tfvars`: Variable overrides (git-ignored)
  - `provider.tf`: OVH provider config + required version (2.12.0)
- `ansible/`: Playbook for VPS bootstrapping
  - `inventory.ini`: Host definitions (`vps.fxhibon.fr`, user `debian`)
  - `playbook.yml`: Hostname, SSH hardening, Fail2Ban, UFW, Docker, and Traefik tasks
- `rp5/`: Docker Compose stack for Raspberry Pi
  - `sync.sh`: Deployment script (SSH+SCP to rp5-internal)
  - `homepage/config/`: Homepage YAML configs (services.yaml, settings.yaml, widgets.yaml)
  - `prometheus/`, `grafana/`, `transmission/config/`: Service-specific configs
- `traefik/`: Traefik reverse proxy (separate from rp5 for modularity)
  - `data/traefik.yml`: Static configuration enabling entrypoints, ACME, and logs
  - `data/acme.json`: ACME certificate storage (0600 permissions required, git-ignored)
  - `sync.sh`: Automated developer synchronization and deployment script
  - `whoami-test.yml`: Testing utility for dynamic auto-discovery validation

### Key Integration Points
1. **Traefik → Docker**: Listens to Docker socket, auto-discovers containers on the `proxy` network.
2. **Defense-in-Depth Dashboard**: Exposes the admin panel at `https://traefik.vps.fxhibon.fr` secured with an **IP AllowList** (limiting access to your home IPv4 and localhost) AND an **HTTP Basic Auth** layer.
3. **Prometheus → Node Exporter**: Scrapes `node-exporter:9100` (DNS resolved via Docker Compose network)
4. **Homepage → Docker**: Mounts `/var/run/docker.sock` for widget discovery
5. **RP5 Sync**: `rp5-internal` SSH host must be configured in local SSH config

### Secrets & Credentials
- OVH API keys: Variables in tfvars (not in repo)
- Transmission VPN: Hardcoded in compose (ProtonVPN credentials in environment block) ⚠️
- Grafana admin: Password in compose env (hashed string, not plaintext)
- SSH: Private key path: `~/.ssh/id_ovh_vps` (per inventory.ini)
- Traefik email: `fxhibon+traefik@proton.me` (hardcoded in traefik.yml)
- Traefik Basic Auth: Pre-hashed APR1 credential in compose labels (double-escaped as `$$apr1$$...`)

### Language & Tool Versions
- **Terraform/OpenTofu**: 2.12.0 OVH provider
- **Ansible**: Standard playbook format
- **Docker Compose**: v2 plugin (installed via apt)
- **Traefik**: v3.7
- **Monitoring**: Prometheus + Grafana (latest tags)

## Common Pitfalls & Debugging

- **Docker IPv6 Source IP Loss (403 Forbidden)**: If external services have `AAAA` (IPv6) records, browsers connect via IPv6. Because the Docker bridge network does not support IPv6 by default, `docker-proxy` translates the traffic to IPv4 and rewrites the source IP to the bridge gateway (`172.18.0.1`), causing IP Whitelists to return 403. **Solution**: Only use `A` (IPv4) records in `dns.tf` for whitelisted domains to preserve the real client IP.
- **sync.sh permissions**: Ensure zsh is available and SSH key configured for `vps.fxhibon.fr` and `rp5-internal`.
- **Traefik ACME**: `acme.json` must have strictly `0600` permissions; Ansible and the Traefik `sync.sh` script enforce this.
- **Docker network**: `proxy` network must be created before Traefik or service startup (both Ansible and `sync.sh` handle this).
- **OVH API**: Consumer key expires; regenerate via OVH Control Panel if auth fails.
- **Basic Auth escaping**: Hashed passwords in docker-compose.yml must use double dollar signs (`$$apr1$$...`) or Docker Compose will interpret them as empty environment variables.

## Files to Prioritize
- `tofu/vps/ovh/dns.tf`: VPS DNS resource definitions (A records only)
- `ansible/playbook.yml`: System setup + Traefik task blocks
- `traefik/docker-compose.yml`: Traefik v3.7 service and dashboard labels
- `traefik/sync.sh`: Traefik deployment script
- `traefik/data/traefik.yml`: Traefik static settings (logging, providers, entrypoints)
