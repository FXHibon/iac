# Architecture Design Plan: GitOps Migration for Multi-Node Docker Compose Infrastructure

## Context & Objectives

Currently, application stacks and system configurations are deployed using Ansible and Docker Compose across two nodes:
1. **OVH VPS (`vps.fxhibon.fr`)**: Public-facing workloads (Traefik, monitoring, public web applications, Satisfactory server).
2. **Raspberry Pi 5 (`home.fxhibon.fr`)**: Local homelab workloads (Homepage dashboard, transmission, local monitoring).

### The Current Deployment Pain Points
* **Workstation Dependency**: Deployments are executed manually from a local developer machine via `task deploy-*` or `scripts/deploy-changed.sh`.
* **Fragile State Tracking**: Change detection relies on a local Git tag (`deployed`) that is force-pushed to origin, which is prone to drift, concurrency issues, and race conditions.
* **Lack of Centralized Audit & Traceability**: No single pane of glass to view historical deployments, run logs, or which commit is currently active on each host.

### Why Not Kubernetes (k8s) + ArgoCD?
* **Resource Overhead**: ArgoCD and K8s control plane components require 1–2 GB+ RAM, which is prohibitive on cost-effective VPS nodes and constrained Raspberry Pi devices running heavy workloads.
* **Operational Complexity**: Migrating working Docker Compose setups to Helm charts or K8s manifests adds unnecessary maintenance friction without architectural benefits for a small multi-node setup.
* **Network Partition Vulnerability**: Joining hybrid nodes (OVH VPS + home RP5 behind NAT) into a single K8s cluster makes the control plane fragile to home ISP drops.

### Target Objectives
* **True GitOps (Push-based)**: Git is the sole source of truth; deployments trigger automatically upon pushing or merging to `master`.
* **Zero Resource Overhead**: No persistent agent or heavy daemon on the managed nodes; deployment execution runs on GitHub-hosted runners.
* **Preserve Ansible & SOPS Assets**: Capitalize on existing idempotent playbooks and in-memory SOPS decryption (`SOPS_AGE_KEY`).
* **Precise Change Detection**: Replace `scripts/deploy-changed.sh` with native GitHub Actions path filtering.
* **Centralized Observability**: Full execution logs, GitHub deployment environments, commit statuses, and optional chat notifications.

---

## Target Architecture Diagram

```mermaid
flowchart TD
    subgraph Git ["GitHub Repository (fxhibon/iac)"]
        Developer["Developer"] -->|git push / PR merge| MasterBranch["master branch"]
        MasterBranch --> Trigger["Workflow: CD Deploy"]
        Trigger --> Filter["dorny/paths-filter<br/>(Analyze modified paths)"]
    end

    subgraph SecretsStore ["GitHub Encrypted Secrets"]
        SopsKey["SOPS_AGE_KEY"]
        SSHVPS["SSH_PRIVATE_KEY_VPS"]
        SSHRP5["SSH_PRIVATE_KEY_RP5"]
    end

    SecretsStore -.-> Runner

    subgraph Runner ["GitHub Actions Runner (ubuntu-latest)"]
        Filter --> Decision{"Changes detected?"}
        Decision -->|Core infra changes| FullDeploy["Ansible: deploy-all<br/>(full playbook)"]
        Decision -->|Application changes| MatrixDeploy["Ansible Matrix Job<br/>(--tags app1, app2...)"]
        Decision -->|No deployable changes| Skip["Skip deployment"]
        
        FullDeploy --> RunnerSSH["ssh-agent + in-memory SOPS decrypt"]
        MatrixDeploy --> RunnerSSH
    end

    subgraph Infrastructure ["Target Infrastructure"]
        RunnerSSH -->|SSH (port 22) + SOPS secrets| VPS["OVH VPS (vps.fxhibon.fr)"]
        RunnerSSH -->|SSH / VPN + SOPS secrets| RP5["Raspberry Pi 5 (home.fxhibon.fr)"]
    end

    subgraph Feedback ["Feedback & Audit"]
        RunnerSSH --> GHDeploy["GitHub Deployments API & Status Badges"]
    end
```

---

## Detailed Specifications

### 1. Change Detection & Path Filtering

Replace the custom Bash logic in `scripts/deploy-changed.sh` with `dorny/paths-filter` in GitHub Actions.

#### Monitored Application Targets
* **`traefik`**: `deployments/vps/traefik/**`
* **`monitoring`**: `deployments/vps/monitoring/**`
* **`fresh-fridge`**: `deployments/vps/fresh-fridge/**`
* **`running-pace-calculator`**: `deployments/vps/running-pace-calculator/**`
* **`fxhibon-fr`**: `deployments/vps/fxhibon-fr/**`
* **`stanne`**: `deployments/vps/stanne/**`
* **`satisfactory`**: `deployments/vps/satisfactory/**`
* **`rp5`**: `deployments/rp5/**`
* **`core`** (Triggers full infrastructure deployment):
  * `infra/ansible/**`
  * `Taskfile.yml`

---

### 2. Secrets Management & Connectivity

1. **SOPS Age Key**:
   * The secret `SOPS_AGE_KEY` is already configured in GitHub Secrets for OpenTofu CI (`.github/workflows/ci.yml`).
   * It will be passed to Ansible to decrypt `infra/ansible/secrets.enc.yaml` dynamically in memory via process substitution (`-e @<(sops -d secrets.enc.yaml)`), preserving zero plaintext on disk.

2. **SSH Authentication**:
   * Configure dedicated, restricted SSH keys in GitHub Secrets:
     * `SSH_PRIVATE_KEY_VPS`: SSH access for `debian@vps.fxhibon.fr`.
     * `SSH_PRIVATE_KEY_RP5`: SSH access for `fxhibon@home.fxhibon.fr`.
   * Load keys dynamically into `ssh-agent` using `webfactory/ssh-agent@v0.9.0`.
   * Add public host keys to `known_hosts` to prevent interactive host key verification prompts.

3. **RP5 Ingress Security**:
   * For the RP5, connections can either route through `home.fxhibon.fr` with SSH key authentication and Fail2Ban, or via a mesh tunnel like **Tailscale** (`tailscale/github-action`) to reach internal IPs directly without public SSH exposure.

---

### 3. GitHub Actions Deployment Workflow (`.github/workflows/deploy.yml`)

#### Trigger Configuration
* **Automatic**: Push to `master` (after passing CI linting and validation).
* **Manual (`workflow_dispatch`)**:
  * Option to specify a target application or force a full deployment.
  * Option for `dry-run` mode to preview planned Ansible tasks without applying them.

#### Workflow Jobs
1. **`detect-changes`**: Evaluates modified paths and outputs a JSON list of tags to run, plus a boolean flag for core infrastructure changes.
2. **`deploy`**:
   * Runs sequentially or in parallel using GitHub Environments (`vps-production`, `rp5-homelab`).
   * Installs dependencies: `ansible`, `sops`, required Ansible collections (`community.docker`, etc.).
   * Runs the deployment command:
     ```bash
     ansible-playbook -i inventory.ini playbook.yml -e @<(sops -d secrets.enc.yaml) --tags "$TAGS"
     ```

---

### 4. Rollback & Auditability Strategy

* **Rollback mechanism**: Simply use `git revert <commit>` and push to `master`. The GitOps pipeline will automatically re-apply the previous Docker Compose definitions and restart containers.
* **Audit trail**: Every deploy run is linked to the exact Git commit, author, commit message, and full Ansible stdout in the GitHub Actions dashboard.
* **Concurrency control**: Concurrency groups (`concurrency: production-deploy`) ensure only one deployment runs at a time, preventing race conditions.

---

## Implementation Checklist

- [ ] **Step 1: Secrets & Key Configuration**
  - [ ] Add `SSH_PRIVATE_KEY_VPS` to GitHub Repository Secrets.
  - [ ] Add `SSH_PRIVATE_KEY_RP5` to GitHub Repository Secrets.
  - [ ] Ensure `SOPS_AGE_KEY` is accessible to the deployment workflow.
  - [ ] Verify SSH access from GitHub runner environment to `vps.fxhibon.fr` and `home.fxhibon.fr`.

- [ ] **Step 2: Create Workflow `.github/workflows/deploy.yml`**
  - [ ] Configure `dorny/paths-filter` with application tags and core paths.
  - [ ] Implement `workflow_dispatch` inputs (stack selector and dry-run toggle).
  - [ ] Setup Ansible, SOPS, and SSH agent step definitions.
  - [ ] Test dry-run execution on a feature branch.

- [ ] **Step 3: Environment Setup & Branch Protection**
  - [ ] Create GitHub Environments: `vps-production` and `rp5-homelab`.
  - [ ] Optional: Add deployment protection rules (approvals for core infrastructure).
  - [ ] Add deployment status badges to `README.md`.

- [ ] **Step 4: Deprecate Legacy Local Sync**
  - [ ] Update `Taskfile.yml` to clearly mark local `deploy-changed` as a fallback or development tool.
  - [ ] Update `AGENTS.md` and `README.md` to reflect the GitOps CI/CD workflow as the primary deployment path.
