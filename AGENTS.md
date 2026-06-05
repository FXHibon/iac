# AGENTS.md - VPS Infrastructure as Code Guide

## Project Overview

This is a multi-layer Infrastructure as Code (IaC) project managing a Raspberry Pi 5 (rp5) local cluster and an OVH VPS, with:
- **Compute provisioning**: OpenTofu (formerly Terraform) managing OVH VPS and DNS
- **System configuration**: Ansible playbooks for package installation, security, Docker setup, and Traefik provisioning
- **Application deployment**: Docker Compose services across RP5 and VPS
- **Traffic ingestion**: Traefik reverse proxy with auto Let's Encrypt SSL/TLS
- **Monitoring & Metrics**: Prometheus + Grafana + Node Exporter + socket-based `docker-stats-exporter`
- **Log Aggregation**: Grafana Loki (30d retention) + dynamic Grafana Alloy log shipper
- **Dashboard**: Homepage service + supporting apps (Transmission with VPN, Plex)

## Architecture Patterns

### Multi-Environment Topology
- **RP5 (Raspberry Pi 5)**: Local network services (192.168.1.59), managed via Ansible (`--tags rp5`)
  - Runs main application stack: homepage, transmission, prometheus, grafana, node-exporter
  - Deployed via SSH + Docker Compose from local machine
  - DNS and VPS serve as external endpoints
  
- **OVH VPS**: Public-facing infrastructure
  - Managed by OpenTofu (`infra/tofu/` dir)
  - Runs Traefik reverse proxy on public IP
  - DNS records map subdomains to home IP (<HOME_IP>) and VPS IP
  - Ansible provisions hostname, Docker, Fail2Ban, UFW firewall, SSH hardening, and Traefik directories/networks

### Service Networking
- **Traefik proxy network**: All VPS services connect to the external `proxy` network created by Ansible/sync script.
- **Docker Compose structure**: Each service group has a separate compose file under `deployments/` (`vps/traefik/`, `rp5/`).
- **Port mapping**: Services expose container ports internally; Traefik routes via Docker labels (e.g., `traefik.enable=true`).
  - Homepage: 3001, Prometheus: 9090, Grafana: 3000, Transmission: 9091, Node Exporter: 9100, Running Pace Calculator: 80, fxhibon.fr: 80. External/direct exposure: Satisfactory Dedicated Server: 7777 (UDP/TCP).
  - Internal Services (No Traefik Routing): `docker-stats-exporter` listens internally on `9487`, `loki` listens internally on `3100`, and `alloy` runs internally.
  - Traefik: exposes public `80` (HTTP) and `443` (HTTPS) ports. The admin panel (`api@internal`) is secured and never exposed on a host port.

### Configuration Management
- **Terraform state**: Committed to repo (`terraform.tfstate`, `.tfstate.backup`)
- **OVH API credentials**: Via variables (ovh_application_key, ovh_application_secret, ovh_consumer_key)
- **Sensitive data**: credentials stored externally (env file or tfvars, referenced in .gitignore)

## Critical Workflows

### Deploy Stacks and Applications (Taskfile / Ansible Workflow)
All container stacks are deployed, updated, and orchestrated using task runner commands from the project root:
```bash
# Deploy/update the entire infrastructure stack (VPS + Raspberry Pi)
task deploy-all

# Deploy/update Traefik reverse proxy only
task deploy-traefik

# Deploy/update the VPS Monitoring stack (Loki, Alloy, Prometheus, Grafana, docker-stats-exporter)
task deploy-monitoring

# Deploy/update the Fresh-Fridge application (with secure in-memory SOPS secrets)
task deploy-fresh-fridge

# Deploy/update the Running Pace Calculator application
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
- **Performance Optimizations**: Playbook executions are extremely fast thanks to enabled **SSH pipelining**, **ControlPersist SSH multiplexing**, and local **fact caching** inside `ansible.cfg`.
- **Idempotent Deployments**: Ansible ensures host folders exist, copies configurations only when changed, enforces secure permissions (e.g. `acme.json` `0600`), and restarts containers only upon configuration shifts.
- **Secure Secrets Handling**: Decrypts secrets in-memory using SOPS during playbook execution, avoiding writing temporary unencrypted files to local disk.

### Provision OVH Infrastructure
```bash
task tofu-apply
```
- Creates VPS instance and DNS records (including wildcard `*.fxhibon.fr` and `traefik.fxhibon.fr`).
- Restricts external subdomains strictly to **IPv4 (A records)** to prevent source-IP preservation loss over Docker proxy.

### Configure VPS with Ansible
```bash
cd infra/ansible/
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
- `infra/tofu/`: OpenTofu/Terraform IaC (provider: OVH)
  - `env/main.tfvars`: Variable overrides (git-ignored)
  - `provider.tf`: OVH provider config + required version (2.12.0)
- `infra/ansible/`: Playbook for host bootstrapping and stack deployments
  - `inventory.ini`: Host definitions (`vps.fxhibon.fr`, user `debian`, `home.fxhibon.fr`, user `fxhibon`)
  - `playbook.yml`: SSH hardening, Fail2Ban, UFW, Docker, and service deployment tasks
- `deployments/rp5/`: Docker Compose stack for Raspberry Pi
  - `homepage/config/`: Homepage YAML configs (services.yaml, settings.yaml, widgets.yaml)
  - `prometheus/`, `grafana/`, `transmission/config/`: Service-specific configs
- `deployments/vps/traefik/`: Traefik reverse proxy
  - `data/traefik.yml`: Static configuration enabling entrypoints, ACME, and logs
  - `data/acme.json`: ACME certificate storage (0600 permissions required, git-ignored)
  - `whoami-test.yml`: Testing utility for dynamic auto-discovery validation

### Key Integration Points
1. **Traefik → Docker**: Listens to Docker socket, auto-discovers containers on the `proxy` network.
2. **Defense-in-Depth Dashboard**: Exposes the admin panel at `https://traefik.fxhibon.fr` secured with an **IP AllowList** (limiting access to your home IPv4 and localhost) AND an **HTTP Basic Auth** layer.
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

- **Docker containerd-snapshotter (cAdvisor / Promtail File Scrape Failures)**: Modern Docker engines configured with containerd snapshotters (`io.containerd.snapshotter.v1.overlayfs`) relocate container layer metadata and logs. This breaks low-level filesystem inspection tools like `cAdvisor` (giving read-write layer open errors) and Promtail direct-file scraping.
  * **Solution for Metrics**: Use Docker API socket-based stats scrapers such as `wywywywy/docker_stats_exporter` which communicate via `/var/run/docker.sock` and are completely immune to underlying storage drivers.
  * **Solution for Logs**: Use modern `Grafana Alloy` with the `discovery.docker` and `loki.source.docker` components. These tail logs cleanly over the Docker API socket, avoiding host log file mounts and storage driver dependency issues.
- **Docker IPv6 Source IP Loss (403 Forbidden)**: If external services have `AAAA` (IPv6) records, browsers connect via IPv6. Because the Docker bridge network does not support IPv6 by default, `docker-proxy` translates the traffic to IPv4 and rewrites the source IP to the bridge gateway (`172.18.0.1`), causing IP Whitelists to return 403. **Solution**: Only use `A` (IPv4) records in `dns.tf` for whitelisted domains to preserve the real client IP.
- **Traefik ACME**: `acme.json` must have strictly `0600` permissions; Ansible enforces this.
- **Docker network**: `proxy` network must be created before Traefik or service startup (Ansible handles this).
- **OVH API**: Consumer key expires; regenerate via OVH Control Panel if auth fails.
- **Basic Auth escaping**: Hashed passwords in docker-compose.yml must use double dollar signs (`$$apr1$$...`) or Docker Compose will interpret them as empty environment variables.

## Files to Prioritize
- `infra/tofu/vps/ovh/dns.tf`: VPS DNS resource definitions (A records only)
- `infra/ansible/playbook.yml`: System setup + service deployment task blocks
- `deployments/vps/traefik/docker-compose.yml`: Traefik v3.7 service and dashboard labels
- `deployments/vps/traefik/data/traefik.yml`: Traefik static settings (logging, providers, entrypoints)
