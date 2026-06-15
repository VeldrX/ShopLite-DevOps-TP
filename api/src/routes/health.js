const express = require("express");
const db = require("../db");

const router = express.Router();

router.get("/", async (req, res) => {
  const checks = {
    api: "ok",
    database: "unknown",
  };

  let status = 200;

  try {
    await db.query("SELECT 1");
    checks.database = "ok";
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        message: error.message,
        timestamp: new Date().toISOString(),
      }),
    );
    checks.database = "error";
    status = 503;
  }

  res.status(status).json({
    status: status === 200 ? "ok" : "error",
    service: "shoplite-api",
    checks,
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
