# tofu

OpenTofu configuration for the OVH VPS and DNS records on `fxhibon.fr`.

## Providers

| Provider        | Purpose                               |
|-----------------|---------------------------------------|
| `ovh/ovh`       | VPS provisioning, DNS zone management |
| `carlpett/sops` | Encrypted secrets decryption          |

## Resources

| Resource                                | Description                                 |
|-----------------------------------------|---------------------------------------------|
| `ovh_vps.main_vps`                      | OVH VPS-3 (8 vCores, 24 GB RAM, 200 GB SSD) |
| `ovh_domain_name.root_domain`           | `fxhibon.fr` domain                         |
| `ovh_domain_zone_record.vps_record`     | `vps.fxhibon.fr` → VPS IPv4                 |
| `ovh_domain_zone_record.home_subdomain` | `home.fxhibon.fr` → home public IP          |

## Secrets

Secrets are stored encrypted in `secrets.yaml`
via [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age).

```
brew install sops age
```

| Secret path            | Used for               |
|------------------------|------------------------|
| `variables.ovh.*`      | OVH API credentials    |
| `backend.s3_*`         | S3 backend credentials |
| `variables.home_ip_v4` | Home public IP for DNS |

## Usage

All infrastructure tasks are now integrated into the root `Taskfile.yml`. You no longer need to manually inject environment variables; the tasks will dynamically decrypt and export the required S3 backend credentials via SOPS.

Run these commands from the project root:

```shell
task tofu-init      # Initialize OpenTofu working directory
task tofu-plan      # Generate and show the execution plan
task tofu-apply     # Apply infrastructure changes
```

### Available Task Targets

| Task | Description |
|------|-------------|
| `task tofu-init` | Initialize OpenTofu working directory with S3 backend |
| `task tofu-plan` | Generate and show the OpenTofu execution plan |
| `task tofu-apply` | Build, change, or apply OpenTofu VPS infrastructure |
| `task tofu-fmt` | Run OpenTofu formatter recursively on all configuration files |
| `task tofu-secrets-edit` | Open OpenTofu secrets.yaml in your `$EDITOR` via SOPS |
| `task tofu-secrets-decrypt` | Decrypt OpenTofu secrets.yaml and print to standard output |
| `task tofu-secrets-encrypt FILE=<path>` | Encrypt a file in-place using SOPS + age |
