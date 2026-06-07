# Stanne Joomla Application

A secure, Dockerized Joomla web application deployed on the VPS.

## Overview

- **Joomla Version**: 6.1.1-php8.4-apache
- **MySQL Version**: 9.7.0
- **Domain**: `stanne.fxhibon.fr`
- **Reverse Proxy**: Traefik (HTTPS, TLS via Let's Encrypt, global rate-limiting, and CrowdSec bouncer protection)

## Deployment

The application is deployed using the central Ansible orchestrator. The database credentials and MySQL root passwords are encrypted locally using SOPS + Age and injected dynamically as a secure `.env` file (`mode: 0600`) on the VPS during deployment.

To deploy or update Stanne:
```bash
task deploy-stanne
```
