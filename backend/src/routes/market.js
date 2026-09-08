const express = require("express");

function marketRoutes(marketData) {
  const router = express.Router();
  const ticker = (req) => String(req.params.ticker || "").trim().toUpperCase();

  router.get("/search/:query", async (req, res, next) => {
    try { res.json(await marketData.search(req.params.query)); } catch (e) { next(e); }
  });
  router.get("/profile/:ticker", async (req, res, next) => {
    try { res.json(await marketData.profile(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/quote/:ticker", async (req, res, next) => {
    try { res.json(await marketData.quote(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/news/:ticker", async (req, res, next) => {
    try { res.json(await marketData.news(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/historical/:ticker", async (req, res, next) => {
    try { res.json(await marketData.historical(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/hourly/:ticker", async (req, res, next) => {
    try { res.json(await marketData.hourly(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/recommendations/:ticker", async (req, res, next) => {
    try { res.json(await marketData.recommendation(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/sentiment/:ticker", async (req, res, next) => {
    try { res.json(await marketData.insiderSentiment(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/peers/:ticker", async (req, res, next) => {
    try { res.json(await marketData.peers(ticker(req))); } catch (e) { next(e); }
  });
  router.get("/earnings/:ticker", async (req, res, next) => {
    try { res.json(await marketData.earnings(ticker(req))); } catch (e) { next(e); }
  });

  return router;
}

module.exports = { marketRoutes };
