#!/bin/sh
set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/backups"
BACKUP_FILE="${BACKUP_DIR}/krm_backup_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting automated PostgreSQL backup for database: ${PGDATABASE}..."

mkdir -p ${BACKUP_DIR}

# Execute pg_dump with gzip compression
pg_dump -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" "${PGDATABASE}" | gzip -9 > "${BACKUP_FILE}"

echo "[$(date)] Backup completed successfully: ${BACKUP_FILE} ($(du -sh ${BACKUP_FILE} | cut -f1))"

# Push to Cloudflare R2 if credentials exist
if [ -n "$R2_ACCESS_KEY_ID" ] && [ -n "$R2_SECRET_ACCESS_KEY" ]; then
    echo "[$(date)] Uploading ${BACKUP_FILE} to Cloudflare R2 bucket: ${R2_BUCKET_NAME}..."
    if command -v aws >/dev/null 2>&1; then
        export AWS_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY}"
        export AWS_DEFAULT_REGION="auto"
        aws s3 cp "${BACKUP_FILE}" "s3://${R2_BUCKET_NAME}/database-backups/$(basename ${BACKUP_FILE})" --endpoint-url="${R2_ENDPOINT_URL}"
        echo "[$(date)] Successfully uploaded backup to Cloudflare R2."
    fi
fi

# Keep last 7 days of local backups
find ${BACKUP_DIR} -name "*.sql.gz" -mtime +7 -delete

echo "[$(date)] Cleaned up old local backup snapshots."
