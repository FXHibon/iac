# Infrastructure Specification: Deployments & Orchestration

## Purpose
Defines specifications for Taskfile-driven orchestration, git tag change detection, and SOPS secret management.

## Requirements

### Requirement: Automated Task Orchestration & Delta Deployments
Application stacks MUST be deployable individually or dynamically based on modified code paths.

#### Scenario: Changed Applications Auto-Detection
- **GIVEN** git commits pushed since the last deployment tag (`deployed`)
- **WHEN** `task deploy-changed` is executed
- **THEN** the deployment runner MUST identify modified subdirectories under `deployments/`
- **AND** execute deployment playbooks ONLY for modified stacks, leaving untouched containers running.

### Requirement: Secure In-Memory Secret Decryption
Sensitive credentials MUST NOT be written unencrypted to disk during deployment.

#### Scenario: SOPS In-Memory Decryption
- **GIVEN** secrets encrypted with SOPS (`.sops.yaml`)
- **WHEN** Ansible executes deployment tasks (e.g. `task deploy-fresh-fridge`)
- **THEN** secrets MUST be decrypted directly into memory for playbook consumption
- **AND** raw secrets MUST NEVER be written to unencrypted temporary files on local or target filesystems.
