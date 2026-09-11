# JoshiStocks V2

JoshiStocks V2 is an independent continuation of a collaborative USC CSCI 571 stock-market / paper-trading course project. The original assignment code is retained as a recovery baseline and attribution is preserved in source headers; the V2 Git history separates the new engineering work.

## What the app does

JoshiStocks is an iOS paper-trading application backed by Node.js, Express, MongoDB Atlas, Finnhub, and Polygon/Massive market data.

Current V2 functionality includes:

- stock search with debounced autocomplete
- company profile, quote, peers, news, sentiment, recommendations, and earnings
- native Swift Charts for intraday and historical price visualization
- selectable historical ranges (1M / 3M / 6M / 1Y / 2Y)
- per-install demo accounts for release builds and a stable development demo account
- server-authoritative BUY / SELL paper trades
- MongoDB transaction-based wallet and position updates
- average-cost accounting
- realized and unrealized P/L
- portfolio net worth, cash, market value, and allocation percentages
- recent transaction history
- per-user favourites / watchlist
- trade validation for insufficient cash and shares
- backend market-data caching with stale fallback
- environment-based secrets
- pooled MongoDB connection
- health check and trading-logic tests
- Docker / Render deployment configuration

## Architecture

```text
iOS (SwiftUI)
    |
    | HTTPS / REST + X-User-ID
    v
Node.js / Express API
    |                 |
    |                 +--> Finnhub (quotes, profiles, news, fundamentals)
    |                 +--> Polygon/Massive (intraday + historical aggregates)
    v
MongoDB Atlas
(wallets, positions, transactions, watchlist)
```

## Local backend setup

```bash
cd backend
cp .env.example .env
# Fill in your own credentials in .env
npm install
npm test
node --env-file=.env src/server.js
```

The API defaults to `http://127.0.0.1:8080`.

## iOS setup

Open:

```text
ios/StockTrade.xcodeproj
```

The Debug build defaults to `http://127.0.0.1:8080`, which works with the iOS Simulator when the backend is running on the same Mac.

For a deployed build, set the app target's generated Info.plist key:

```text
JOSHISTOCKS_API_BASE_URL = https://your-api-host.example.com
```

`APIClient.swift` also accepts a `UserDefaults` override named `JoshiStocks.APIBaseURL`, which is useful for development/testing.

## Backend deployment

The repository includes:

- `backend/Dockerfile`
- `backend/.dockerignore`
- `render.yaml`

For Render, create/deploy the Blueprint and supply these secrets in the Render environment:

- `MONGODB_URI`
- `FINNHUB_API_KEY`
- `POLYGON_API_KEY`

Do not commit or upload a real `.env` file.

## Demo verification checklist

Before sending a build to someone else, verify on a Mac with Xcode:

1. Backend health returns `status: ok`.
2. Home screen loads cash, net worth, holdings, P/L, activity, and favourites.
3. Search `AAPL` and open Apple.
4. Intraday chart renders.
5. Historical chart renders and all range selectors work.
6. Add/remove AAPL from favourites.
7. BUY 1 share and confirm portfolio/activity refresh.
8. SELL 1 share and confirm realized P/L / cash refresh.
9. Attempt an invalid trade and confirm a human-readable error appears.
10. Clean build and run once more before archiving or TestFlight distribution.

## Security

Secrets live only in backend environment variables. The iOS client never contains Finnhub, Polygon/Massive, or MongoDB credentials.

The shareable repository should exclude:

```text
backend/.env
backend/node_modules
DerivedData
.DS_Store
```

## Attribution

The original course-project file attribution is intentionally preserved. V2 additions and commits document the independent continuation and modernization work.
