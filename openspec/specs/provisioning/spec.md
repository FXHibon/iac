# Infrastructure Specification: Provisioning (OpenTofu & OVH)

## Purpose
Defines specifications for cloud compute resources and DNS management using OpenTofu (`infra/tofu/`).

## Requirements

### Requirement: Cloud Compute Provisioning
The infrastructure MUST provision and manage the OVH VPS instance using declarative OpenTofu state.

#### Scenario: VPS Instance State Maintenance
- **GIVEN** valid OVH API credentials (`ovh_application_key`, `ovh_application_secret`, `ovh_consumer_key`)
- **WHEN** `task tofu-apply` is executed
- **THEN** OpenTofu MUST maintain the VPS instance configuration aligned with `infra/tofu/vps/ovh/`
- **AND** state changes MUST be stored idempotently in `terraform.tfstate`.

### Requirement: Domain & DNS Record Integrity
All external subdomain DNS records managed by OVH MUST route traffic reliably to public endpoints.

#### Scenario: IPv4 A-Record Enforcement for Subdomains
- **GIVEN** subdomains configured in `infra/tofu/vps/ovh/dns.tf` (including `*.fxhibon.fr` and `traefik.fxhibon.fr`)
- **WHEN** DNS records are generated or updated
- **THEN** DNS records MUST strictly use IPv4 (`A`) records pointing to the VPS public IP or Home IP
- **AND** IPv6 (`AAAA`) records MUST NOT be created for whitelisted endpoints to prevent client source IP loss across Docker proxy.
