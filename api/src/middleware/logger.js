const crypto = require("crypto");

// Liste de clés sensibles à masquer dans les logs
const SENSITIVE_KEYS = [
  "password",
  "passwd",
  "pwd",
  "token",
  "secret",
  "key",
  "authorization",
  "auth",
  "credentials",
  "apikey",
  "api_key",
];

function sanitize(obj) {
  if (!obj || typeof obj !== "object") return obj;

  if (Array.isArray(obj)) {
    return obj.map((item) => sanitize(item));
  }

  const result = {};
  for (const key in obj) {
    if (SENSITIVE_KEYS.includes(key.toLowerCase())) {
      result[key] = "[REDACTED]";
    } else if (typeof obj[key] === "object" && obj[key] !== null) {
      result[key] = sanitize(obj[key]);
    } else {
      result[key] = obj[key];
    }
  }
  return result;
}

module.exports = function logger(req, res, next) {
  const requestId = crypto.randomUUID();
  req.requestId = requestId;
  const startedAt = Date.now();

  // Logger la requête terminée
  res.on("finish", () => {
    const duration = Date.now() - startedAt;
    let level = "info";

    // Déterminer le niveau en fonction du status HTTP
    if (res.statusCode >= 500) {
      level = "error";
    } else if (res.statusCode >= 400) {
      level = "warn";
    }

    const logEntry = {
      level,
      requestId,
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      duration_ms: duration,
      remote_addr: req.ip || req.connection?.remoteAddress || "unknown",
      timestamp: new Date().toISOString()
    };

    // Ajouter les query parameters (sans secrets)
    if (req.query && Object.keys(req.query).length > 0) {
      logEntry.query = sanitize(req.query);
    }

    // Pour les erreurs 5xx, logger le message d'erreur stocké dans res.locals
    if (level === "error" && res.locals && res.locals.errorMessage) {
      logEntry.error = {
        message: res.locals.errorMessage
      };
    }

    console.log(JSON.stringify(logEntry));
  });

  next();
};
