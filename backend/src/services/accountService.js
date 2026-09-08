const { calculateBuy, calculateSell, positionMetrics, roundMoney } = require("./tradingMath");

class AccountService {
  constructor({ db, mongoClient, marketData, startingCash }) {
    this.db = db;
    this.mongoClient = mongoClient;
    this.marketData = marketData;
    this.startingCash = startingCash;
  }

  get wallets() { return this.db.collection("wallets"); }
  get positions() { return this.db.collection("positions"); }
  get transactions() { return this.db.collection("transactions"); }
  get watchlist() { return this.db.collection("watchlist"); }

  async ensureUser(userId, { session } = {}) {
    await this.wallets.updateOne(
      { user_id: userId },
      {
        $setOnInsert: {
          user_id: userId,
          amount: this.startingCash,
          created_at: new Date(),
          updated_at: new Date(),
        },
      },
      { upsert: true, session }
    );
    return this.wallets.findOne({ user_id: userId }, { session });
  }

  async dashboard(userId) {
    const wallet = await this.ensureUser(userId);
    const positions = await this.positions.find({ user_id: userId }).sort({ stock_ticker: 1 }).toArray();

    const enriched = await Promise.all(
      positions.map(async (position) => {
        let currentPrice = Number(position.last_price || 0);
        let quoteTimestamp = position.last_price_at || null;
        try {
          const quote = await this.marketData.quote(position.stock_ticker);
          if (Number(quote.c) > 0) {
            currentPrice = Number(quote.c);
            quoteTimestamp = quote.t ? new Date(Number(quote.t) * 1000) : new Date();
            await this.positions.updateOne(
              { _id: position._id },
              { $set: { last_price: currentPrice, last_price_at: quoteTimestamp } }
            );
          }
        } catch (error) {
          if (currentPrice <= 0) throw error;
        }

        const metrics = positionMetrics({
          quantity: position.quantity,
          totalCost: position.total_cost,
          currentPrice,
        });

        return {
          id: String(position._id),
          stock_ticker: position.stock_ticker,
          stock_company: position.stock_company,
          quantity: position.quantity,
          total_cost: position.total_cost,
          average_cost: metrics.averageCost,
          current_price: currentPrice,
          market_value: metrics.marketValue,
          unrealized_pnl: metrics.unrealizedPnl,
          unrealized_pnl_percent: metrics.unrealizedPnlPercent,
          change_in_price: metrics.unrealizedPnl,
          change_in_price_percentage: metrics.unrealizedPnlPercent,
          quote_timestamp: quoteTimestamp,
        };
      })
    );

    const holdingsMarketValue = roundMoney(enriched.reduce((sum, p) => sum + p.market_value, 0));
    const costBasis = roundMoney(enriched.reduce((sum, p) => sum + p.total_cost, 0));
    const unrealizedPnl = roundMoney(holdingsMarketValue - costBasis);
    const realizedRows = await this.transactions
      .aggregate([
        { $match: { user_id: userId, side: "SELL" } },
        { $group: { _id: null, total: { $sum: "$realized_pnl" } } },
      ])
      .toArray();
    const realizedPnl = roundMoney(realizedRows[0]?.total || 0);
    const netWorth = roundMoney(wallet.amount + holdingsMarketValue);

    return {
      wallet: { amount: roundMoney(wallet.amount) },
      summary: {
        cash_balance: roundMoney(wallet.amount),
        holdings_market_value: holdingsMarketValue,
        cost_basis: costBasis,
        unrealized_pnl: unrealizedPnl,
        unrealized_pnl_percent: costBasis > 0 ? unrealizedPnl / costBasis : 0,
        realized_pnl: realizedPnl,
        total_pnl: roundMoney(unrealizedPnl + realizedPnl),
        net_worth: netWorth,
      },
      positions: enriched,
    };
  }

  async stockPosition(userId, ticker) {
    const wallet = await this.ensureUser(userId);
    const position = await this.positions.findOne({ user_id: userId, stock_ticker: ticker });
    return {
      wallet_account: { amount: roundMoney(wallet.amount) },
      portfolio_data: position
        ? {
            id: String(position._id),
            stock_ticker: position.stock_ticker,
            stock_company: position.stock_company,
            quantity: position.quantity,
            total_cost: position.total_cost,
          }
        : null,
    };
  }

  async trade({ userId, ticker, company, side, quantity }) {
    const normalizedSide = String(side || "").toUpperCase();
    if (!["BUY", "SELL"].includes(normalizedSide)) {
      const error = new Error("Trade side must be BUY or SELL");
      error.code = "INVALID_SIDE";
      throw error;
    }

    const quote = await this.marketData.quote(ticker);
    const price = Number(quote.c);
    if (!Number.isFinite(price) || price <= 0) {
      const error = new Error("Current market price is unavailable");
      error.code = "PRICE_UNAVAILABLE";
      throw error;
    }

    const session = this.mongoClient.startSession();
    let response;
    try {
      await session.withTransaction(async () => {
        const wallet = await this.ensureUser(userId, { session });
        const position = await this.positions.findOne(
          { user_id: userId, stock_ticker: ticker },
          { session }
        );

        const calculation = normalizedSide === "BUY"
          ? calculateBuy({ position, quantity, price, cash: wallet.amount })
          : calculateSell({ position, quantity, price, cash: wallet.amount });

        await this.wallets.updateOne(
          { user_id: userId },
          { $set: { amount: calculation.newCash, updated_at: new Date() } },
          { session }
        );

        if (calculation.position.quantity === 0) {
          await this.positions.deleteOne({ user_id: userId, stock_ticker: ticker }, { session });
        } else {
          await this.positions.updateOne(
            { user_id: userId, stock_ticker: ticker },
            {
              $set: {
                user_id: userId,
                stock_ticker: ticker,
                stock_company: company,
                quantity: calculation.position.quantity,
                total_cost: calculation.position.total_cost,
                last_price: price,
                last_price_at: new Date(),
                updated_at: new Date(),
              },
              $setOnInsert: { created_at: new Date() },
            },
            { upsert: true, session }
          );
        }

        const transaction = {
          user_id: userId,
          stock_ticker: ticker,
          stock_company: company,
          side: normalizedSide,
          quantity,
          price,
          gross_amount: calculation.grossAmount,
          realized_pnl: calculation.realizedPnl || 0,
          created_at: new Date(),
        };
        const inserted = await this.transactions.insertOne(transaction, { session });

        response = {
          message: `You have successfully ${normalizedSide === "BUY" ? "bought" : "sold"} ${quantity} ${quantity === 1 ? "share" : "shares"} of ${ticker}`,
          trade: {
            id: String(inserted.insertedId),
            ...transaction,
          },
          wallet: { amount: calculation.newCash },
          position: calculation.position.quantity === 0
            ? null
            : {
                stock_ticker: ticker,
                stock_company: company,
                quantity: calculation.position.quantity,
                total_cost: calculation.position.total_cost,
                average_cost: calculation.position.average_cost,
              },
        };
      });
    } finally {
      await session.endSession();
    }
    return response;
  }

  async recentTransactions(userId, limit = 25) {
    const safeLimit = Math.min(Math.max(Number(limit) || 25, 1), 100);
    return this.transactions
      .find({ user_id: userId })
      .sort({ created_at: -1 })
      .limit(safeLimit)
      .map((row) => ({
        id: String(row._id),
        stock_ticker: row.stock_ticker,
        stock_company: row.stock_company,
        side: row.side,
        quantity: row.quantity,
        price: row.price,
        gross_amount: row.gross_amount,
        realized_pnl: row.realized_pnl || 0,
        created_at: row.created_at,
      }))
      .toArray();
  }

  async resetDemo(userId) {
    const session = this.mongoClient.startSession();
    try {
      await session.withTransaction(async () => {
        await Promise.all([
          this.positions.deleteMany({ user_id: userId }, { session }),
          this.transactions.deleteMany({ user_id: userId }, { session }),
          this.watchlist.deleteMany({ user_id: userId }, { session }),
        ]);
        await this.wallets.updateOne(
          { user_id: userId },
          {
            $set: { amount: this.startingCash, updated_at: new Date() },
            $setOnInsert: { user_id: userId, created_at: new Date() },
          },
          { upsert: true, session }
        );
      });
    } finally {
      await session.endSession();
    }
    return { ok: true, starting_cash: this.startingCash };
  }
}

module.exports = { AccountService };
