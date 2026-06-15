const express = require("express");
const db = require("../db");

const router = express.Router();

// Healthcheck détaillé - indique si l'API et la DB sont opérationnelles
router.get("/", async (req, res) => {
  const checks = {
    api: { status: "ok" },
    database: { status: "unknown" },
  };

  let overallStatus = 200;

  // Vérification de la base de données
  try {
    const result = await db.query("SELECT 1");
    checks.database = {
      status: "ok",
      response_time_ms: result?.rowCount ? 1 : 0, // simplifié
    };
  } catch (error) {
    checks.database = {
      status: "error",
      error: "Database connection failed",
    };
    overallStatus = 503;
  }

  res.status(overallStatus).json({
    status: overallStatus === 200 ? "ok" : "error",
    service: "shoplite-api",
    version: process.env.APP_VERSION || "unknown",
    timestamp: new Date().toISOString(),
    checks,
  });
});

// Readiness probe - PostgreSQL est-il prêt ?
router.get("/ready", async (req, res) => {
  try {
    await db.query("SELECT 1");
    res.status(200).json({
      status: "ok",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: "error",
      message: "Database not ready",
      timestamp: new Date().toISOString(),
    });
  }
});

module.exports = router;
