#!/bin/sh
set -eu

# Usage: sh scripts/restore-test.sh <backup_file> [env]
# Restores a dump into a temporary database to verify its integrity
# Example: sh scripts/restore-test.sh backups/dev_20260616_120000.sql dev

BACKUP_FILE="${1:-}"
ENV="${2:-dev}"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: sh scripts/restore-test.sh <backup_file> [env]"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

case "$ENV" in
  dev)
    CONTAINER="shoplite_db"
    DB_USER="shoplite"
    ;;
  staging)
    CONTAINER="shoplite_db_staging"
    DB_USER="shoplite_staging"
    ;;
  prod)
    CONTAINER="shoplite_db_prod"
    DB_USER="shoplite_prod"
    ;;
  *)
    echo "Unknown environment: $ENV. Use dev, staging or prod."
    exit 1
    ;;
esac

TEMP_DB="restore_test_$(date +%s)"

echo "Creating temporary database $TEMP_DB in $CONTAINER..."
docker exec "$CONTAINER" psql -U "$DB_USER" -c "CREATE DATABASE $TEMP_DB;"

echo "Restoring $BACKUP_FILE into $TEMP_DB..."
docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$TEMP_DB" < "$BACKUP_FILE"

echo "Verifying restoration..."
PRODUCT_COUNT=$(docker exec "$CONTAINER" psql -U "$DB_USER" -d "$TEMP_DB" -t -c "SELECT COUNT(*) FROM products;" | tr -d ' \n')
echo "Products found in restored database: $PRODUCT_COUNT"

echo "Cleaning up temporary database..."
docker exec "$CONTAINER" psql -U "$DB_USER" -c "DROP DATABASE $TEMP_DB;"

echo "Restore test complete. $PRODUCT_COUNT products verified."
