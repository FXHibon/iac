# Infrastructure Specification: System Configuration & Security (Ansible)

## Purpose
Defines specifications for host bootstrapping, security hardening, firewall configuration, and runtime environment setup managed via Ansible (`infra/ansible/`).

## Requirements

### Requirement: Host SSH Hardening & Authentication
The target VPS host (`vps.fxhibon.fr`) MUST be hardened against brute-force attacks and unauthorized access.

#### Scenario: Key-Only Root-Disabled SSH Access
- **GIVEN** an Ansible run targeting `vps.fxhibon.fr` using key `~/.ssh/id_ovh_vps`
- **WHEN** the security playbooks are executed
- **THEN** password authentication MUST be disabled in `/etc/ssh/sshd_config`
- **AND** root SSH login MUST be set to `no`
- **AND** `MaxAuthTries` MUST be capped at 3.

### Requirement: Fail2Ban & UFW Firewall Protection
The VPS host MUST enforce network perimeter defense.

#### Scenario: Firewall Port Restrictions & SSH Jail
- **GIVEN** a default deny incoming policy on UFW
- **WHEN** Ansible configures the network firewall and Fail2Ban
- **THEN** UFW MUST allow only explicitly declared ports (22/SSH, 80/HTTP, 443/HTTPS, and application-specific ports such as 7777 for Satisfactory)
- **AND** Fail2Ban MUST monitor SSH logs with a 1-hour ban trigger after 5 failed authentication attempts.

### Requirement: Docker Engine & Network Preparation
The host MUST run Docker Engine with Compose plugin and pre-created external networks.

#### Scenario: Pre-Provisioned Proxy Network
- **GIVEN** Docker Engine installed on the host with user `debian` added to the `docker` group
- **WHEN** Ansible executes system setup
- **THEN** the external Docker network `proxy` MUST exist before launching any container service.
