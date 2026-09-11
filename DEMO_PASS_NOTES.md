# Demo-ready engineering pass

This pass focuses on making the existing app reliable enough to demonstrate before adding larger features.

## Changes in this pass

- Replaced the brittle WKWebView/Highcharts stock charts with native Swift Charts.
- Added historical range selection (1M, 3M, 6M, 1Y, 2Y).
- Removed duplicate chart requests and duplicate stock-detail fetches.
- Parallelized core stock-detail requests so the page is not blocked by news/insights/charts.
- Fixed Polygon/Massive fractional-volume decoding (`v` is `Double`).
- Added visible loading/empty states for search and charts.
- Reduced search debounce latency and ignore stale search responses.
- Improved trade entry, validation, submission state, and backend error messages.
- Improved favourites UX and fixed multi-delete failure bookkeeping.
- Added portfolio allocation percentages.
- Added production API-base configuration while preserving the local Debug demo account.
- Added Docker + Render deployment configuration.

## Still requires macOS/Xcode validation

This repository was edited in a non-macOS build environment, so the final SwiftUI/Xcode compile and simulator/device flow must be verified in Xcode before distribution.

The highest-priority validation is:

1. Clean Build Folder, then Build.
2. Open AAPL and verify both chart tabs.
3. Test add/remove favourite.
4. Test BUY and SELL from the iOS sheet.
5. Verify home portfolio and recent activity refresh after each trade.

If Xcode surfaces a compiler-specific issue, fix that before deploying the backend.
