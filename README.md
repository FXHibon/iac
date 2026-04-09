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

## General

```shell

# security tools
systemctl status fail2ban
systemctl status ufw

# list jails
fail2ban-client status

# details on a specific jail
fail2ban-client status sshd

# list banned IPs, grouped by jails
fail2ban-client banned | tr "'" '"' | jq

# list geolocation of banned IPs
fail2ban-client banned | \
tr "'" '"' | \
jq -r '.[0].sshd.[]' | \
while read line
do
  geoiplookup $line | sed -r 's/GeoIP Country Edition: //g'
done | \
sort | uniq -c | sort --numeric --reverse

# firewall status
ufw status verbose

# test alertmanager
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
