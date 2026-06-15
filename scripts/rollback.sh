#!/bin/sh
set -eu

# =============================================================================
# rollback.sh - Rollback to a stable Docker image tag while preserving volumes
#
# Usage:   sh scripts/rollback.sh <env> <tag>
# Example: sh scripts/rollback.sh staging v1.0.0
#
# Steps:
#   1. Export current API logs
#   2. Identify current deployed version
#   3. Verify the target image tag exists
#   4. Backup PostgreSQL
#   5. Stop current stack (volumes preserved)
#   6. Restart using the tagged stable image
#   7. Run smoke tests + data verification
#   8. Print incident summary
# =============================================================================

ENV="${1:-}"
TAG="${2:-}"

if [ -z "$TAG" ]; then
  echo "Usage: sh scripts/rollback.sh <env> <tag>"
  echo "Example: sh scripts/rollback.sh staging v1.0.0"
  exit 1
fi

case "$ENV" in
  dev)
    PROJECT="shoplite-dev"
    COMPOSE="-f docker-compose.yml"
    ENV_FILE=".env"
    PORT=8080
    API_CONTAINER="shoplite_api"
    DB_CONTAINER="shoplite_db"
    DB_NAME="shoplite"
    DB_USER="shoplite"
    API_IMAGE="shoplite-api"
    FRONTEND_IMAGE="shoplite-frontend"
    ;;
  staging)
    PROJECT="shoplite-staging"
    COMPOSE="-f docker-compose.yml -f docker-compose.staging.yml"
    ENV_FILE=".env.staging"
    PORT=8081
    API_CONTAINER="shoplite_api_staging"
    DB_CONTAINER="shoplite_db_staging"
    DB_NAME="shoplite_staging"
    DB_USER="shoplite_staging"
    API_IMAGE="shoplite-api"
    FRONTEND_IMAGE="shoplite-frontend"
    ;;
  prod)
    PROJECT="shoplite-prod"
    COMPOSE="-f docker-compose.yml -f docker-compose.prod.yml"
    ENV_FILE=".env.prod"
    PORT=8082
    API_CONTAINER="shoplite_api_prod"
    DB_CONTAINER="shoplite_db_prod"
    DB_NAME="shoplite_prod"
    DB_USER="shoplite_prod"
    API_IMAGE="shoplite-api"
    FRONTEND_IMAGE="shoplite-frontend"
    ;;
  *)
    echo "Unknown environment: $ENV. Use dev, staging or prod."
    exit 1
    ;;
esac

echo ""
echo "========================================================================"
echo " ROLLBACK: $ENV -> $TAG"
echo "========================================================================"
echo ""

# -------------------------------------------------------------------------
# Step 1: Export current API logs before rolling back
# -------------------------------------------------------------------------
echo "[1/8] Exporting current API logs..."
LOGS_DIR="./logs"
mkdir -p "$LOGS_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGS_FILE="$LOGS_DIR/${ENV}_pre_rollback_logs_${TIMESTAMP}.json"
docker logs "$API_CONTAINER" 2>&1 > "$LOGS_FILE" || echo "  Warning: could not export logs (container may not be running)"
echo "  Logs saved to: $LOGS_FILE"

# -------------------------------------------------------------------------
# Step 2: Identify current deployed version
# -------------------------------------------------------------------------
echo "[2/8] Identifying current deployed version..."
CURRENT_VERSION=$(docker inspect "$API_CONTAINER" --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")
echo "  Current image: $CURRENT_VERSION"
CURRENT_TAG=$(echo "$CURRENT_VERSION" | awk -F: '{print $2}')
echo "  Current tag: $CURRENT_TAG"

# -------------------------------------------------------------------------
# Step 3: Verify the target stable image exists locally
# -------------------------------------------------------------------------
echo "[3/8] Verifying target image: ${API_IMAGE}:${TAG}..."
if docker image inspect "${API_IMAGE}:${TAG}" >/dev/null 2>&1; then
  echo "  Image ${API_IMAGE}:${TAG} found locally."
else
  echo "  Image ${API_IMAGE}:${TAG} not found locally. Attempting to pull..."
  docker pull "${API_IMAGE}:${TAG}" 2>/dev/null || {
    echo "  ERROR: Image ${API_IMAGE}:${TAG} is not available locally or remotely."
    echo "  Available images:"
    docker images "$API_IMAGE" --format "  - {{.Repository}}:{{.Tag}}"
    exit 1
  }
fi

echo "  Frontend image: ${FRONTEND_IMAGE}:${TAG}"
if docker image inspect "${FRONTEND_IMAGE}:${TAG}" >/dev/null 2>&1; then
  echo "  Image ${FRONTEND_IMAGE}:${TAG} found locally."
else
  echo "  Image ${FRONTEND_IMAGE}:${TAG} not found locally. Attempting to pull..."
  docker pull "${FRONTEND_IMAGE}:${TAG}" 2>/dev/null || {
    echo "  WARNING: ${FRONTEND_IMAGE}:${TAG} not available. Will build from source."
  }
fi

# -------------------------------------------------------------------------
# Step 4: Backup PostgreSQL before rollback
# -------------------------------------------------------------------------
echo "[4/8] Backing up PostgreSQL database..."
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/${ENV}_pre_rollback_${TIMESTAMP}.sql"
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null || {
  echo "  Warning: could not backup database (container may not be running)"
  BACKUP_FILE=""
}
if [ -n "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
  echo "  Backup created: $BACKUP_FILE ($(wc -c < "$BACKUP_FILE") bytes)"
else
  echo "  No backup created (container not running or no data)."
  BACKUP_FILE=""
fi

# -------------------------------------------------------------------------
# Step 5: Stop current stack (preserve volumes: no -v flag)
# -------------------------------------------------------------------------
echo "[5/8] Stopping current stack (volumes preserved)..."
docker compose --project-name "$PROJECT" --env-file "$ENV_FILE" $COMPOSE down
echo "  Stack stopped. Volumes retained."

# -------------------------------------------------------------------------
# Step 6: Restart using the tagged stable image
# -------------------------------------------------------------------------
echo "[6/8] Restarting with tagged image ${API_IMAGE}:${TAG}..."
export APP_VERSION="$TAG"
docker compose --project-name "$PROJECT" --env-file "$ENV_FILE" $COMPOSE up -d

echo "  Waiting for services to be healthy..."
sleep 15

# Verify the API is using the correct image
RUNNING_IMAGE=$(docker inspect "$API_CONTAINER" --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")
echo "  Running image: $RUNNING_IMAGE"

# -------------------------------------------------------------------------
# Step 7: Run smoke tests and data verification
# -------------------------------------------------------------------------
echo "[7/8] Running post-rollback verification..."
BASE_URL="http://localhost:$PORT"

# Smoke test (health + ready + products)
echo "  Smoke testing..."
sh scripts/smoke-test.sh "$PORT" && echo "  Smoke test: PASSED" || echo "  Smoke test: FAILED"

# Verify data integrity
echo "  Verifying data integrity..."
PRODUCTS_JSON=$(curl -fsS "$BASE_URL/api/products" 2>/dev/null || echo '{"data":[]}')
PRODUCT_COUNT=$(echo "$PRODUCTS_JSON" | grep -o '"id"' | wc -l)
echo "  Products found: $PRODUCT_COUNT"

if [ "$PRODUCT_COUNT" -ge 3 ]; then
  echo "  Data integrity: PASSED (≥3 products)"
else
  echo "  Data integrity: WARNING (< 3 products)"
fi

# -------------------------------------------------------------------------
# Step 8: Print incident summary
# -------------------------------------------------------------------------
echo "[8/8] Rollback complete."
echo ""
echo "========================================================================"
echo " INCIDENT SUMMARY"
echo "========================================================================"
echo " Environment: $ENV"
echo " Previous version: $CURRENT_TAG"
echo " Rolled back to: $TAG"
echo " Running image: $RUNNING_IMAGE"
echo " Products in DB: $PRODUCT_COUNT"
echo " Logs exported: $LOGS_FILE"
if [ -n "$BACKUP_FILE" ]; then
  echo " DB backup: $BACKUP_FILE"
fi
echo "========================================================================"
echo ""
echo "Rollback to $TAG on $ENV complete."
