# Ansible — VPS Bootstrap

Provisions and hardens the OVH VPS (`vps.fxhibon.fr`).

## What it does

| Area               | Details                                                                                                                   |
|--------------------|---------------------------------------------------------------------------------------------------------------------------|
| **Hostname**       | Sets hostname to `vps.fxhibon.fr`                                                                                         |
| **SSH hardening**  | Drop-in `/etc/ssh/sshd_config.d/99-hardening.conf`: no root login, key-only auth, `MaxAuthTries 3`, no X11/TCP forwarding |
| **Fail2Ban**       | SSH jail: 5 retries, 1 h ban, 10 min window, systemd backend                                                              |
| **Firewall (UFW)** | Default deny — allows 22/tcp, 80/tcp, 443/tcp                                                                             |
| **Docker**         | Engine + Compose plugin from the official Docker apt repo; `debian` user added to `docker` group                          |

## Prerequisites

- Ansible ≥ 2.14
- `community.general` and `community.docker` collections
- SSH key at `~/.ssh/id_ovh_vps` with access to `vps.fxhibon.fr` as `debian`

```bash
ansible-galaxy collection install community.general community.docker
```

## Usage

```bash
cd ansible/

# Dry-run (check mode, no changes applied)
ansible-playbook playbook.yml --check

# Apply
ansible-playbook playbook.yml
```

Run a specific section using tags:

```bash
ansible-playbook playbook.yml --tags ssh
ansible-playbook playbook.yml --tags fail2ban
ansible-playbook playbook.yml --tags docker
```

> **Note:** tags are not yet defined in the playbook — add `tags:` to task blocks if you need to run sections
> independently.

## File structure

```
ansible/
├── ansible.cfg       # Default settings (inventory, user, SSH key)
├── inventory.ini     # [vps] host group → vps.fxhibon.fr
├── playbook.yml      # Single playbook, idempotent
└── README.md
```

## Inventory

`inventory.ini` targets a single host in the `[vps]` group:

```ini
[vps]
vps.fxhibon.fr ansible_user=debian ansible_ssh_private_key_file=~/.ssh/id_ovh_vps
```

To target a different host or user without editing the file:

```bash
ansible-playbook playbook.yml -i "1.2.3.4," -u root --private-key ~/.ssh/other_key
```

## Verify after provisioning

```bash
# SSH hardening applied
ssh -o PasswordAuthentication=yes debian@vps.fxhibon.fr   # should be refused

# Fail2Ban active
ssh debian@vps.fxhibon.fr "sudo fail2ban-client status sshd"

# Docker running
ssh debian@vps.fxhibon.fr "docker info"
ssh debian@vps.fxhibon.fr "docker compose version"
```
