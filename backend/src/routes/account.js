const express = require("express");
const { userContext } = require("../middleware/userContext");

function accountRoutes(accountService) {
  const router = express.Router();
  router.use(userContext);

  router.get("/dashboard", async (req, res, next) => {
    try { res.json(await accountService.dashboard(req.userId)); } catch (e) { next(e); }
  });

  router.get("/position/:ticker", async (req, res, next) => {
    try {
      res.json(await accountService.stockPosition(req.userId, req.params.ticker.toUpperCase()));
    } catch (e) { next(e); }
  });

  router.post("/trades", async (req, res, next) => {
    try {
      const quantity = Number(req.body.quantity);
      const ticker = String(req.body.ticker || "").trim().toUpperCase();
      const company = String(req.body.company || "").trim();
      if (!/^[A-Z0-9.-]{1,15}$/.test(ticker)) {
        return res.status(400).json({ error: "INVALID_TICKER", message: "A valid stock ticker is required" });
      }
      if (!Number.isInteger(quantity) || quantity <= 0) {
        return res.status(400).json({ error: "INVALID_QUANTITY", message: "Quantity must be a positive whole number" });
      }
      const result = await accountService.trade({
        userId: req.userId,
        ticker,
        company: company || ticker,
        side: req.body.side,
        quantity,
      });
      res.status(201).json(result);
    } catch (e) { next(e); }
  });

  router.get("/transactions", async (req, res, next) => {
    try { res.json(await accountService.recentTransactions(req.userId, req.query.limit)); } catch (e) { next(e); }
  });

  router.post("/reset", async (req, res, next) => {
    try { res.json(await accountService.resetDemo(req.userId)); } catch (e) { next(e); }
  });

  return router;
}

module.exports = { accountRoutes };
