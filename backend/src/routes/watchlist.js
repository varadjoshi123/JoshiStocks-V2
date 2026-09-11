const express = require("express");
const { userContext } = require("../middleware/userContext");

function watchlistRoutes(db, marketData) {
  const router = express.Router();
  router.use(userContext);
  const collection = db.collection("watchlist");

  const baseRow = (row) => ({
    id: String(row._id),
    stock_ticker: row.stock_ticker,
    stock_company: row.stock_company,
  });

  router.get("/", async (req, res, next) => {
    try {
      const rows = await collection.find({ user_id: req.userId }).sort({ created_at: 1 }).toArray();
      const enriched = await Promise.all(rows.map(async (row) => {
        const item = baseRow(row);
        try {
          const quote = await marketData.quote(row.stock_ticker);
          return {
            ...item,
            current_price: Number(quote.c) || 0,
            change_in_price: Number(quote.d) || 0,
            change_in_price_percentage: (Number(quote.dp) || 0) / 100,
          };
        } catch {
          return item;
        }
      }));
      res.json(enriched);
    } catch (e) { next(e); }
  });

  router.get("/:ticker", async (req, res, next) => {
    try {
      const row = await collection.findOne({ user_id: req.userId, stock_ticker: req.params.ticker.toUpperCase() });
      res.json(row ? baseRow(row) : null);
    } catch (e) { next(e); }
  });

  router.post("/", async (req, res, next) => {
    try {
      const stockTicker = String(req.body.stock_ticker || "").trim().toUpperCase();
      const stockCompany = String(req.body.stock_company || "").trim();
      if (!/^[A-Z0-9.-]{1,15}$/.test(stockTicker) || !stockCompany) {
        return res.status(400).json({
          error: "INVALID_WATCHLIST_ITEM",
          message: "A valid ticker and company are required",
        });
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
