#!/bin/sh
set -eu

# Usage: sh scripts/backup.sh [env]
# env: dev (default), staging, prod

ENV="${1:-dev}"

case "$ENV" in
  dev)
    CONTAINER="shoplite_db"
    DB_NAME="shoplite"
    DB_USER="shoplite"
    ;;
  staging)
    CONTAINER="shoplite_db_staging"
    DB_NAME="shoplite_staging"
    DB_USER="shoplite_staging"
    ;;
  prod)
    CONTAINER="shoplite_db_prod"
    DB_NAME="shoplite_prod"
    DB_USER="shoplite_prod"
    ;;
  *)
    echo "Unknown environment: $ENV. Use dev, staging or prod."
    exit 1
    ;;
esac

BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${ENV}_${TIMESTAMP}.sql"

echo "Backing up $DB_NAME from $CONTAINER..."
docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE"

# Retention: keep last 7 dumps per environment
DUMPS=$(ls -t "$BACKUP_DIR"/${ENV}_*.sql 2>/dev/null || true)
DUMPS_COUNT=$(echo "$DUMPS" | grep -c '.sql' || true)
if [ "$DUMPS_COUNT" -gt 7 ]; then
  echo "$DUMPS" | tail -n +8 | xargs rm -f
  echo "Retention applied: kept last 7 dumps for $ENV"
fi
