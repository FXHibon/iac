# Fresh-Fridge Application

Private web application deployed securely on the VPS.

## Database Backup & Restore

The PostgreSQL database for the `fresh-fridge` service (`postgres:18-alpine`) is automatically backed up daily to an OVH S3-compatible object storage bucket (`backups-fxhibon`) using the `ghcr.io/solectrus/postgres-s3-backup:18` sidecar container.

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
cd /home/debian/apps/fresh-fridge
```

#### Step 3: Stop the Application Container
To prevent any reads or writes during the restore process and avoid application state issues, stop the `fresh-fridge` app container. The database and backup containers must remain running:
```bash
docker stop fresh-fridge
```

#### Step 4: Choose a Backup and Restore

##### Option A: Restore the Latest Backup
To restore the most recent backup found in the S3 bucket:
```bash
docker exec -it fresh-fridge-backup sh restore.sh
```

##### Option B: Restore a Specific Backup
1. **List available backups** inside the S3 bucket to find the desired timestamp:
   ```bash
   docker exec -it fresh-fridge-backup sh -c 'aws --endpoint-url $S3_ENDPOINT s3 ls s3://$S3_BUCKET/$S3_PREFIX/'
   ```
   *The backup files are named in the format: `<database_name>_<timestamp>.dump` (e.g., `fresh_fridge_db_2026-06-06T12:00:00.dump`).*

2. **Run the restore command** with the target timestamp as the parameter:
   ```bash
   docker exec -it fresh-fridge-backup sh restore.sh <timestamp>
   ```
   *For example:*
   ```bash
   docker exec -it fresh-fridge-backup sh restore.sh 2026-06-06T12:00:00
   ```

#### Step 5: Restart the Application Container
Once the restore completes successfully, start the application container again:
```bash
docker start fresh-fridge
```

### Manual/Ad-Hoc Backup Trigger
If you want to trigger a manual backup immediately (e.g., before performing system upgrades or code changes):
```bash
docker exec -it fresh-fridge-backup sh backup.sh
```
