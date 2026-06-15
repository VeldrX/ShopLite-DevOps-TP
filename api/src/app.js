const express = require("express");
const cors = require("cors");
const logger = require("./middleware/logger");
const healthRoutes = require("./routes/health");
const productRoutes = require("./routes/products");

const app = express();

app.use(cors());
app.use(express.json());
app.use(logger);

app.get("/", (req, res) => {
  res.json({
    name: "ShopLite API",
    version: "0.1.0",
    endpoints: ["/health", "/products"],
  });
});

app.use("/health", healthRoutes);
app.use("/products", productRoutes);

app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});

app.use((err, req, res, _next) => {
  // Stocker le message d'erreur pour le logger
  res.locals.errorMessage = err.message;

  // Return 400 for JSON parsing errors, 500 otherwise
  const statusCode = err.type === "entity.parse.failed" ? 400 : 500;
  const errorMessage =
    statusCode === 400 ? "Invalid JSON" : "Internal server error";

  res.status(statusCode).json({ error: errorMessage });
});

module.exports = app;
