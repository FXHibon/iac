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

```shell
# Inject S3 backend credentials into your shell
eval $(make env-print)

tofu init
tofu plan
tofu apply
```

### Makefile targets

| Target                | Description                                            |
|-----------------------|--------------------------------------------------------|
| `make env-print`      | Print `export` commands for S3 backend credentials     |
| `make secrets-edit`   | Edit `secrets.yaml` via SOPS in `$EDITOR`              |
| `make secrets-decode` | Decode secrets to `.secrets.decoded.yaml` (gitignored) |
