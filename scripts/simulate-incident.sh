#!/bin/sh
set -eu

# =============================================================================
# simulate-incident.sh - Introduce a controlled incident in /api/products
#
# Usage: sh scripts/simulate-incident.sh
#
# This script modifies the products route to return a 500 error,
# simulating a broken deployment for rollback testing.
# =============================================================================

echo "========================================"
echo " Simulating controlled incident"
echo "========================================"
echo ""

PRODUCTS_FILE="api/src/routes/products.js"
BACKUP_FILE="api/src/routes/products.js.incident_backup"

# Backup original file if not already backed up
if [ ! -f "$BACKUP_FILE" ]; then
  cp "$PRODUCTS_FILE" "$BACKUP_FILE"
  echo "Backup saved: $BACKUP_FILE"
fi

# Introduce intentional error
cat > "$PRODUCTS_FILE" << 'EOF'
const express = require("express");
const db = require("../db");

const router = express.Router();

router.get("/", async (req, res, next) => {
  try {
    // Intentional bug: wrong table name to simulate incident
    const result = await db.query(
      "SELECT id, name, description, price_cents FROM broken_products ORDER BY id",
    );

    res.json({
      source: "database",
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
EOF

echo "Incident introduced: /api/products now queries 'broken_products' table"
echo "Rebuild and restart the API to activate the incident."
echo ""
echo "To rebuild: docker compose up -d --build api"
echo "To restore: cp $BACKUP_FILE $PRODUCTS_FILE"
