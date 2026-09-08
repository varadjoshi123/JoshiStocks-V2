function required(name) {
  const value = process.env[name];
  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function numberFromEnv(name, fallback) {
  const raw = process.env[name];
  if (raw === undefined || raw === "") return fallback;
  const value = Number(raw);
  if (!Number.isFinite(value)) throw new Error(`${name} must be a number`);
  return value;
}

function getConfig() {
  return {
    port: numberFromEnv("PORT", 8080),
    mongoUri: required("MONGODB_URI"),
    mongoDb: process.env.MONGODB_DB?.trim() || "JoshiStocks",
    finnhubApiKey: required("FINNHUB_API_KEY"),
    polygonApiKey: required("POLYGON_API_KEY"),
    demoStartingCash: numberFromEnv("DEMO_STARTING_CASH", 25000),
    corsOrigin: process.env.CORS_ORIGIN?.trim() || "*",
  };
}

module.exports = { getConfig };
