# vps-iac

Infrastructure as Code for a personal homelab and OVH VPS — managed with OpenTofu, Ansible, and Docker Compose.

## Structure

```
.
├── tofu/       # OpenTofu — OVH VPS provisioning & DNS records
├── ansible/    # Ansible — server configuration
├── rp5/        # Raspberry Pi 5 — local services (Grafana, Prometheus, Plex…)
└── traefik/    # Traefik reverse proxy config
```

## Modules

| Module | Description |
|--------|-------------|
| [`tofu/`](tofu/) | Provisions an OVH VPS and manages DNS records for `fxhibon.fr` |
| [`ansible/`](ansible/) | Configures the VPS post-provision |
| [`rp5/`](rp5/) | Docker Compose stack running on a local Raspberry Pi 5 |
| [`traefik/`](traefik/) | Reverse proxy routing for exposed services |
