# JoshiStocks V2

JoshiStocks V2 is a full-stack iOS paper-trading application built with SwiftUI, Node.js, Express, and MongoDB Atlas.

It is an independent continuation and modernization of a collaborative USC CSCI 571 course project. The V2 work expands the original project with a redesigned backend, server-authoritative trading, portfolio accounting, native charts, improved search and watchlist workflows, automated tests, and cloud deployment.

## Features

- Live stock search with debounced autocomplete
- Recent Searches stored locally on-device
- Quick Picks for commonly viewed stocks
- Live stock quotes and company profiles
- Native Swift Charts for intraday price movement
- Historical charts with 1M, 3M, 6M, 1Y, and 2Y ranges
- Company statistics, industry information, and clickable peer stocks
- Insider sentiment
- Analyst recommendation trends
- Historical EPS surprises
- Financial news
- Persistent favourites / watchlist
- BUY and SELL paper trading
- Insufficient-cash and overselling validation
- Average-cost position accounting
- Realized and unrealized profit/loss
- Portfolio net worth, cash, holdings, and cost basis
- Position allocation percentages
- Recent transaction activity
- Independent anonymous demo accounts for Release installations
- $25,000 starting paper balance for new demo accounts
- Backend market-data caching with stale-data fallback
- MongoDB transaction-based portfolio updates
- Automated backend accounting tests
- Production backend deployed over HTTPS

## Architecture

```text
iOS App
Swift / SwiftUI / Swift Charts
        |
        | HTTPS REST API
        | X-User-ID
        v
Node.js + Express API
        |
        |---- Finnhub
        |     quotes, profiles, news,
        |     fundamentals and insights
        |
        |---- Polygon / Massive
        |     intraday and historical data
        |
        v
MongoDB Atlas
wallets | positions | transactions | watchlist
```

## Tech Stack

### iOS

- Swift
- SwiftUI
- Swift Charts
- Alamofire
- Kingfisher

### Backend

- Node.js
- Express
- MongoDB Node.js Driver
- REST APIs

### Data & Infrastructure

- Finnhub
- Polygon / Massive
- MongoDB Atlas
- Docker
- Render
- GitHub

## Paper Trading

Trades are processed by the backend rather than calculated only on the device.

The backend validates available cash and owned shares, updates wallet and position state, records transactions, and maintains average-cost accounting.

Portfolio metrics include cash balance, holdings market value, cost basis, net worth, unrealized P/L, realized P/L, total P/L, and position allocation.

## Backend Tests

Run:

```bash
cd backend
npm test
npm run check
```

The automated test suite verifies:

- BUY cash calculations
- rejection of purchases above available cash
- average-cost handling during partial sales
- cost-basis reset after selling a full position
- rejection of overselling
- portfolio market-value and return calculations

## Local Development

Create the backend environment file:

```bash
cd backend
cp .env.example .env
npm install
```

Provide your own credentials in `.env`:

```text
MONGODB_URI=
MONGODB_DB=joshistocks
FINNHUB_API_KEY=
POLYGON_API_KEY=
DEMO_STARTING_CASH=25000
```

Start the backend:

```bash
node --env-file=.env src/server.js
```

The Debug iOS build connects to:

```text
http://127.0.0.1:8080
```

Open the iOS project:

```text
ios/StockTrade.xcodeproj
```

## Production Deployment

The backend is deployed on Render using the repository's `render.yaml` and Docker configuration.

Production API:

```text
https://joshistocks-api.onrender.com
```

Health endpoint:

```text
https://joshistocks-api.onrender.com/health
```

A successful health response looks like:

```json
{"status":"ok","service":"joshistocks-api","version":"2.0.0"}
```

Release builds automatically use the deployed HTTPS backend.

Because the current Render deployment uses the free service tier, the first request after a period of inactivity may take longer while the service wakes up.

## Demo Accounts

Debug builds use a stable development account so local test data persists between runs.

Release builds generate and persist a unique anonymous identifier for each installation. This prevents separate testers from sharing the same paper-trading portfolio.

The current identity mechanism is intended for demonstration and paper trading, not production-grade authentication.

## Security

Finnhub, Polygon / Massive, and MongoDB credentials remain server-side.

Sensitive and generated files are excluded from the repository, including:

```text
backend/.env
backend/node_modules
DerivedData
.DS_Store
```

MongoDB Atlas network access is restricted to approved development access and the outbound ranges used by the deployed backend.

## Project Status

The application has been verified locally and against the deployed production backend.

Verified workflows include stock search, stock-detail pages, intraday and historical charts, favourites, Recent Searches, Quick Picks, BUY and SELL trades, invalid-trade protection, portfolio accounting, and production iOS-to-Render-to-MongoDB connectivity.

## Attribution

JoshiStocks V2 is an independent continuation of a collaborative USC CSCI 571 course project.

The V2 Git history documents the subsequent modernization and engineering work across the iOS application, backend architecture, trading/accounting system, market-data integration, automated testing, and deployment.
