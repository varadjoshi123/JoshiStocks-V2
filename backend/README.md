# JoshiStocks API (V2)

JoshiStocks is an evolution of a collaborative USC CSCI 571 course project. This V2 backend is being re-engineered as a portfolio-quality paper-trading service while preserving attribution to the original coursework.

## What changed in V2

- API credentials and MongoDB connection data are environment variables.
- Each app installation gets an isolated demo account through `X-User-ID`.
- Buy/sell operations are server-authoritative MongoDB transactions.
- Average-cost accounting and realized/unrealized P/L are calculated correctly.
- Every trade is recorded in transaction history.
- Dashboard API returns cash, market value, cost basis, P/L, and net worth.
- Market-data calls have TTL caching and stale-on-provider-error behavior.
- MongoDB connections are pooled instead of opened/closed per request.
- Basic health endpoint and pure trading-logic tests are included.

## Local setup

1. Copy `.env.example` to `.env` and populate fresh credentials.
2. Export those variables in your shell (or use your hosting provider's environment-variable UI).
3. Run `npm install`.
4. Run `npm test`.
5. Run `npm start`.

The API listens on `PORT` (default `8080`).

### Key endpoints

- `GET /health`
- `GET /api/v2/market/quote/AAPL`
- `GET /api/v2/account/dashboard` (`X-User-ID` required)
- `POST /api/v2/account/trades` (`X-User-ID` required)
- `GET /api/v2/account/transactions` (`X-User-ID` required)
- `POST /api/v2/account/reset` (`X-User-ID` required)
- `GET/POST/DELETE /api/v2/watchlist` (`X-User-ID` required)

A trade body looks like:

```json
{
  "ticker": "AAPL",
  "company": "Apple Inc",
  "side": "BUY",
  "quantity": 5
}
```
