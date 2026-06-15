const fs = require("fs");
const path = require("path");
const db = require("../src/db");

async function initializeDatabase() {
  try {
    const sqlPath = path.resolve(__dirname, "../../database/init.sql");
    const sql = fs.readFileSync(sqlPath, "utf8");
    await db.query(sql);
  } catch (error) {
    console.error("Failed to initialize database:", error);
    throw error;
  }
}

module.exports = { initializeDatabase };
