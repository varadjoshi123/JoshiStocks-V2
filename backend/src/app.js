const express = require("express");
const cors = require("cors");
const { marketRoutes } = require("./routes/market");
const { accountRoutes } = require("./routes/account");
const { watchlistRoutes } = require("./routes/watchlist");

function createApp({ db, marketData, accountService, corsOrigin = "*" }) {
  const app = express();
  app.disable("x-powered-by");
  app.use(cors({ origin: corsOrigin === "*" ? true : corsOrigin }));
  app.use(express.json({ limit: "64kb" }));

  app.get("/health", (req, res) => {
    res.json({ status: "ok", service: "joshistocks-api", version: "2.0.0" });
  });

  app.use("/api/v2/market", marketRoutes(marketData));
  app.use("/api/v2/account", accountRoutes(accountService));
  app.use("/api/v2/watchlist", watchlistRoutes(db, marketData));

  // Compatibility aliases for the original CSCI 571 Swift screens.
  app.get("/getStockSymbols/:query", async (req, res, next) => {
    try { res.json(await marketData.search(req.params.query)); } catch (e) { next(e); }
  });
  app.get("/getStockDetails/:ticker", async (req, res, next) => {
    try { res.json(await marketData.profile(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getStockLatestPrice/:ticker", async (req, res, next) => {
    try { res.json(await marketData.quote(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getCompanyNews/:ticker", async (req, res, next) => {
    try { res.json(await marketData.news(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getStockHistoricalData/:ticker", async (req, res, next) => {
    try { res.json(await marketData.historical(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getStockPriceOnHourlyBasis/:ticker", async (req, res, next) => {
    try { res.json(await marketData.hourly(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getStockRecommendation/:ticker", async (req, res, next) => {
    try { res.json(await marketData.recommendation(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getStockInsiderSentiment/:ticker", async (req, res, next) => {
    try { res.json(await marketData.insiderSentiment(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getCompanyPeers/:ticker", async (req, res, next) => {
    try { res.json(await marketData.peers(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });
  app.get("/getStockEarnings/:ticker", async (req, res, next) => {
    try { res.json(await marketData.earnings(req.params.ticker.toUpperCase())); } catch (e) { next(e); }
  });

  app.use((req, res) => {
    res.status(404).json({ error: "NOT_FOUND", message: "Route not found" });
  });

  app.use((error, req, res, next) => {
    console.error(error);
    const status = error.status || (
      ["INVALID_QUANTITY", "INVALID_PRICE", "INVALID_SIDE", "INSUFFICIENT_FUNDS", "INSUFFICIENT_SHARES", "PRICE_UNAVAILABLE"].includes(error.code)
        ? 400
        : 500
    );
    res.status(status).json({
      error: error.code || error.name || "INTERNAL_ERROR",
      message: error.message || "Unexpected server error",
    });
  });

  return app;
}

module.exports = { createApp };
