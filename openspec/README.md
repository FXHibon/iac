# OpenSpec Framework for Infrastructure as Code (IaC)

This directory contains the **OpenSpec** framework configuration, living specifications, and change management workflows for this IaC codebase.

## Why OpenSpec for IaC?

Unlike standard software development repositories where specifications target UI components, domain models, or API endpoints, **IaC specifications** define:
- **Desired Cloud & Host State**: Compute resources (OpenTofu), security hardening, firewall rules, and package dependencies (Ansible).
- **Ingress & Networking Contracts**: Routing rules, TLS certificate renewal, entrypoints, and IP Whitelisting (Traefik).
- **Telemetry & Health SLOs**: Log aggregation (Loki/Alloy) and socket-based metrics collection (`docker-stats-exporter`).
- **Operational & Secret Safety Invariants**: In-memory SOPS decryption, non-disruptive deployments, and source-IP preservation (IPv4 enforcement).

## Directory Structure

```text
openspec/
├── AGENTS.md          # OpenSpec guidelines for AI coding agents
├── project.md         # IaC architecture, tech stack & operational invariants
├── README.md          # Usage guide (this file)
├── specs/             # Source of Truth specifications
│   ├── provisioning/  # OpenTofu OVH VPS compute & DNS specifications
│   ├── configuration/ # Ansible host setup, SSH hardening, Fail2Ban, UFW, Docker
│   ├── ingress/       # Traefik reverse proxy, Let's Encrypt TLS, IP Whitelisting
│   ├── monitoring/    # Prometheus, Grafana, Loki (30d), Alloy, socket scrapers
│   └── deployments/   # Taskfile workflows, changed app auto-detection, SOPS secrets
└── changes/           # Active change proposals & delta specs
    ├── README.md      # Structure and lifecycle of a change
    └── archive/       # Completed & merged historical changesets
```

## How to Use OpenSpec in this Repository

### 1. Planning a New Feature or Infrastructure Change
When introducing a new service (e.g. adding a new container stack under `deployments/vps/`), modifying security policies, or updating OpenTofu provisioning:

1. Create a change folder in `openspec/changes/<change-id>/` (e.g. `openspec/changes/add-nextcloud-service/`).
2. Add the following files:
   - `proposal.md`: Goal, rationale, scope, and non-goals.
   - `design.md`: Technical approach (OpenTofu resource definitions, Ansible tasks, Docker Compose structure, Traefik labels).
   - `tasks.md`: Step-by-step checklist of tasks.
   - `specs/<domain>/spec.md`: Delta specifications (added/modified Gherkin scenarios).

### 2. Implementing & Verifying Changes
1. Follow the checklist in `tasks.md`.
2. Execute target Taskfile commands to verify deployment (e.g. `task deploy-<app>`, `task deploy-changed`, `task tofu-plan`).
3. Confirm operational invariants (e.g. Traefik auto-discovered service, SSL cert generated, metrics scraped).

### 3. Archiving and Updating Source of Truth
Once verified:
1. Merge the delta scenarios from `openspec/changes/<change-id>/specs/` into the main `openspec/specs/` source of truth.
2. Move `openspec/changes/<change-id>/` into `openspec/changes/archive/<change-id>/`.
