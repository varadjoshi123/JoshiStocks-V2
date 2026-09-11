const { MongoClient } = require("mongodb");
const { getConfig } = require("./config");
const { MarketDataService } = require("./services/marketData");
const { AccountService } = require("./services/accountService");
const { createApp } = require("./app");

async function main() {
  const config = getConfig();
  const client = new MongoClient(config.mongoUri, { serverSelectionTimeoutMS: 10000 });
  console.log("Connecting to MongoDB...");
  await client.connect();
  console.log("MongoDB connected");
  const db = client.db(config.mongoDb);
  await Promise.all([
    db.collection("wallets").createIndex({ user_id: 1 }, { unique: true }),
    db.collection("positions").createIndex({ user_id: 1, stock_ticker: 1 }, { unique: true }),
    db.collection("watchlist").createIndex({ user_id: 1, stock_ticker: 1 }, { unique: true }),
    db.collection("transactions").createIndex({ user_id: 1, created_at: -1 }),
  ]);

  const marketData = new MarketDataService(config);
  const accountService = new AccountService({
    db,
    mongoClient: client,
    marketData,
    startingCash: config.demoStartingCash,
  });
  const app = createApp({ db, marketData, accountService, corsOrigin: config.corsOrigin });

  const server = app.listen(config.port, () => {
    console.log(`JoshiStocks API listening on port ${config.port}`);
  });

  async function shutdown(signal) {
    console.log(`${signal} received; shutting down`);
    server.close(async () => {
      await client.close();
      process.exit(0);
    });
  }
  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
}

main().catch((error) => {
  console.error("Failed to start JoshiStocks API:", error);
  process.exit(1);
});
