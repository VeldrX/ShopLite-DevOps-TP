#!/bin/sh
set -eu

# Usage: sh scripts/export-logs.sh [env]
# Exports Docker logs from API container to a file before any rollback.
# env: dev (default), staging, prod

ENV="${1:-dev}"

case "$ENV" in
  dev)
    CONTAINER="shoplite_api"
    ;;
  staging)
    CONTAINER="shoplite_api_staging"
    ;;
  prod)
    CONTAINER="shoplite_api_prod"
    ;;
  *)
    echo "Unknown environment: $ENV. Use dev, staging or prod."
    exit 1
    ;;
esac

LOGS_DIR="./logs"
mkdir -p "$LOGS_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGS_FILE="$LOGS_DIR/${ENV}_api_logs_${TIMESTAMP}.json"

echo "Exporting logs from $CONTAINER..."
docker logs "$CONTAINER" 2>&1 > "$LOGS_FILE"

echo "Logs exported: $LOGS_FILE"
echo "Size: $(wc -c < "$LOGS_FILE") bytes"
