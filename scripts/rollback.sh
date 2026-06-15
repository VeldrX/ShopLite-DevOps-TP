#!/bin/sh
set -eu

# Usage: sh scripts/rollback.sh <env> <tag>
# Example: sh scripts/rollback.sh staging v1.0.0

ENV="${1:-staging}"
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
    ;;
  staging)
    PROJECT="shoplite-staging"
    COMPOSE="-f docker-compose.yml -f docker-compose.staging.yml"
    ENV_FILE=".env.staging"
    PORT=8081
    ;;
  prod)
    PROJECT="shoplite-prod"
    COMPOSE="-f docker-compose.yml -f docker-compose.prod.yml"
    ENV_FILE=".env.prod"
    PORT=8082
    ;;
  *)
    echo "Unknown environment: $ENV. Use dev, staging or prod."
    exit 1
    ;;
esac

echo "Rolling back $ENV to $TAG..."

# Step 1: checkout the target tag
git checkout "$TAG"

# Step 2: stop current stack
docker compose --project-name "$PROJECT" --env-file "$ENV_FILE" $COMPOSE down

# Step 3: rebuild and restart from the checked-out tag
docker compose --project-name "$PROJECT" --env-file "$ENV_FILE" $COMPOSE up -d --build

# Step 4: smoke test
sleep 15
BASE_URL="http://localhost:$PORT" sh scripts/smoke-test.sh

echo "Rollback to $TAG on $ENV complete."
