# JoshiStocks V2

JoshiStocks V2 is an independent continuation of a collaborative USC CSCI 571 stock-market/paper-trading course project. The original assignment code is being used as a recovery baseline because one collaborator's copy survived; V2 work is intentionally separated so new engineering contributions are traceable.

## V2 milestone 1

This working branch introduces the foundation for a recruiter-ready demo:

- centralized iOS API configuration
- per-install anonymous demo accounts
- server-authoritative paper trades
- MongoDB transaction-based wallet/position updates
- correct average-cost accounting
- realized and unrealized P/L
- transaction history
- portfolio dashboard summary
- per-user watchlists
- market-data caching with stale fallback
- environment-based secrets
- pooled MongoDB connection
- backend health check
- trading-logic unit tests
- improved iOS loading resilience
- JoshiStocks UI branding and recent-activity section

## Important before running

The V2 backend intentionally contains **no live credentials**. Create fresh Finnhub, Polygon/Massive, and MongoDB credentials and configure them from `backend/.env.example`.

The iOS client currently defaults to `http://127.0.0.1:8080` for Simulator development. After the backend is deployed, set a `UserDefaults` override for `JoshiStocks.APIBaseURL` during development or update `APIConfig.baseURL` for the release build.

## Original-course attribution

Do not erase the original source-file attribution simply to make the repository appear individually authored. New V2 files and Git history should make the independent continuation clear.
