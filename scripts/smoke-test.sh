#!/bin/sh
set -eu

# Usage: sh scripts/smoke-test.sh [port]
# Runs smoke tests: health, ready, products endpoints and data verification.
# port: 8080 (default), 8081 (staging), 8082 (prod)
# Also supports BASE_URL env var (backward compat with CD workflows).

if [ -n "${1:-}" ]; then
  BASE_URL="http://localhost:$1"
else
  BASE_URL="${BASE_URL:-http://localhost:8080}"
fi

echo "Smoke testing $BASE_URL..."
echo ""

# Test 1: Health endpoint
echo "--- Health check ---"
HEALTH=$(curl -fsS "$BASE_URL/api/health" 2>&1) || {
  echo "FAIL: /api/health returned non-200"
  exit 1
}
echo "$HEALTH" | head -c 200
echo ""

# Test 2: Ready endpoint
echo "--- Readiness check ---"
READY=$(curl -fsS "$BASE_URL/api/ready" 2>&1) || {
  echo "FAIL: /api/ready returned non-200"
  exit 1
}
echo "$READY"
echo ""

# Test 3: Products endpoint
echo "--- Products check ---"
PRODUCTS=$(curl -fsS "$BASE_URL/api/products" 2>&1) || {
  echo "FAIL: /api/products returned non-200"
  exit 1
}
PRODUCT_COUNT=$(echo "$PRODUCTS" | grep -o '"id"' | wc -l)
echo "Products returned: $PRODUCT_COUNT"
echo ""

# Test 4: Data integrity - at least 3 products seeded
echo "--- Data integrity ---"
if [ "$PRODUCT_COUNT" -ge 3 ]; then
  echo "PASS: $PRODUCT_COUNT products found (>= 3)"
else
  echo "FAIL: Only $PRODUCT_COUNT products found (expected >= 3)"
  exit 1
fi

echo ""
echo "=============================="
echo " SMOKE TEST: ALL CHECKS PASSED"
echo "=============================="
