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

## Database Backup & Restore

The MySQL database for the `stanne` service (`mysql:9.7.0`) is automatically backed up daily to the OVH S3-compatible object storage bucket (`backups-fxhibon`) under the `/stanne` folder using the `jkaninda/mysql-bkup:v1.3.2` sidecar container.

### ⚠️ Warning: Data Loss
Restoring a database backup is **destructive**. All existing tables, data, and database objects in the target database will be dropped and re-created using the backup.

### Restoration Procedure

All commands should be executed on the VPS host.

#### Step 1: SSH into the VPS
```bash
ssh vps
```

#### Step 2: Navigate to the Application Directory
```bash
cd /home/debian/apps/stanne
```

#### Step 3: Stop the Joomla Application Container
To prevent any reads or writes during the restore process and avoid application state issues, stop the `stanne` app container. The database and backup containers must remain running:
```bash
docker stop stanne
```

#### Step 4: Choose a Backup and Restore

1. **List available backups** inside the S3 bucket to find the desired filename:
   ```bash
   docker exec -it fresh-fridge-backup sh -c 'aws --endpoint-url $S3_ENDPOINT s3 ls s3://$S3_BUCKET/stanne/'
   ```
   *The backup files are named in the format: `stanne_YYYYMMDD_HHMMSS.sql.gz` or similar.*

2. **Run the restore command** with the target filename:
   ```bash
   docker exec -it stanne-backup mysql-bkup restore --storage s3 -f <backup-filename> --path /stanne
   ```
   *For example:*
   ```bash
   docker exec -it stanne-backup mysql-bkup restore --storage s3 -f stanne_20260607_120000.sql.gz --path /stanne
   ```

#### Step 5: Restart the Joomla Application Container
Once the restore completes successfully, start the application container again:
```bash
docker start stanne
```

### Manual/Ad-Hoc Backup Trigger
If you want to trigger a manual backup immediately (e.g., before performing system upgrades or code changes):
```bash
docker exec -it stanne-backup mysql-bkup backup --storage s3 --path /stanne
```

