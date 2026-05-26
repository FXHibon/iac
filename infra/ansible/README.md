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
cd infra/ansible/

# Dry-run (check mode, no changes applied)
ansible-playbook playbook.yml --check

# Apply
ansible-playbook playbook.yml

# Apply only specific sections using tags:
ansible-playbook playbook.yml --tags "fail2ban"
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
infra/ansible/
├── ansible.cfg       # Default settings (inventory, user, SSH key)
├── inventory.ini     # [vps] host group → vps.fxhibon.fr
├── playbook.yml      # Single playbook, idempotent
└── README.md
```

## Inventory

To target a different host or user without editing the file:

```bash
ansible-playbook playbook.yml -i "1.2.3.4," -u root --private-key ~/.ssh/other_key
```



## Maintenance & Ad-Hoc Commands

For simple, one-off maintenance tasks across all managed machines, you can use Ansible ad-hoc commands:

### Update and Upgrade OS Packages
To run `apt update && apt upgrade` in parallel on both the VPS and Raspberry Pi:
```bash
ansible all -i inventory.ini -m ansible.builtin.apt -a "update_cache=yes upgrade=dist" --become
```

## Verify after provisioning

```bash
# Fail2Ban active
ssh debian@vps.fxhibon.fr "sudo fail2ban-client status sshd"
```
