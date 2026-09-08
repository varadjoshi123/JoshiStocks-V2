const express = require("express");
const { userContext } = require("../middleware/userContext");

function watchlistRoutes(db) {
  const router = express.Router();
  router.use(userContext);
  const collection = db.collection("watchlist");

  router.get("/", async (req, res, next) => {
    try {
      const rows = await collection.find({ user_id: req.userId }).sort({ created_at: 1 }).toArray();
      res.json(rows.map((row) => ({
        id: String(row._id),
        stock_ticker: row.stock_ticker,
        stock_company: row.stock_company,
      })));
    } catch (e) { next(e); }
  });

  router.get("/:ticker", async (req, res, next) => {
    try {
      const row = await collection.findOne({ user_id: req.userId, stock_ticker: req.params.ticker.toUpperCase() });
      res.json(row ? {
        id: String(row._id),
        stock_ticker: row.stock_ticker,
        stock_company: row.stock_company,
      } : null);
    } catch (e) { next(e); }
  });

  router.post("/", async (req, res, next) => {
    try {
      const stockTicker = String(req.body.stock_ticker || "").trim().toUpperCase();
      const stockCompany = String(req.body.stock_company || "").trim();
      if (!stockTicker || !stockCompany) {
        return res.status(400).json({ error: "INVALID_WATCHLIST_ITEM", message: "Ticker and company are required" });
      }
      const result = await collection.updateOne(
        { user_id: req.userId, stock_ticker: stockTicker },
        {
          $set: { stock_company: stockCompany, updated_at: new Date() },
          $setOnInsert: { user_id: req.userId, stock_ticker: stockTicker, created_at: new Date() },
        },
        { upsert: true }
      );
      const row = await collection.findOne({ user_id: req.userId, stock_ticker: stockTicker });
      res.status(result.upsertedCount ? 201 : 200).json({
        acknowledged: result.acknowledged,
        insertedId: String(row._id),
      });
    } catch (e) { next(e); }
  });

  router.delete("/:ticker", async (req, res, next) => {
    try {
      const result = await collection.deleteOne({
        user_id: req.userId,
        stock_ticker: req.params.ticker.toUpperCase(),
      });
      res.json({ acknowledged: result.acknowledged, deletedCount: result.deletedCount });
    } catch (e) { next(e); }
  });

  return router;
}

module.exports = { watchlistRoutes };
