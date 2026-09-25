# Infrastructure Specification: Ingress & TLS (Traefik)

## Purpose
Defines specifications for traffic ingestion, SSL/TLS certificate management, dynamic Docker label routing, and access control.

## Requirements

### Requirement: Automated Let's Encrypt TLS Certificates
Traefik MUST automatically issue and renew TLS certificates for configured subdomains.

#### Scenario: ACME TLS Certificate Resolution
- **GIVEN** Traefik running on ports 80/443 with `letsencrypt` cert resolver configured in `traefik.yml`
- **WHEN** a container joins the `proxy` network with `traefik.http.routers.<app>.tls.certresolver=letsencrypt`
- **THEN** Traefik MUST generate/retrieve a valid Let's Encrypt TLS certificate
- **AND** store it securely in `/etc/traefik/acme.json` with strict `0600` file permissions.

### Requirement: Admin Dashboard Defense-in-Depth
Access to the Traefik dashboard (`traefik.fxhibon.fr`) MUST be restricted to authorized users.

#### Scenario: IP AllowList & Basic Authentication Layer
- **GIVEN** request to `https://traefik.fxhibon.fr`
- **WHEN** the client IP is NOT in the allowed IP list (Home IPv4 / Localhost)
- **THEN** Traefik MUST return HTTP `403 Forbidden`
- **AND** when the client IP IS allowed, Traefik MUST prompt for HTTP Basic Auth before granting dashboard access.
