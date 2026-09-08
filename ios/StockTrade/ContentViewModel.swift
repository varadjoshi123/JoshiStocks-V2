//
//  ContentViewModel.swift
//  StockTrade / JoshiStocks
//

import Foundation

class ContentViewModel: ObservableObject {
    @Published var stock_ticker = ""
    @Published var stocksDataForPortfolio: [StockInfo] = []
    @Published var favourites: [WatchListElement] = []
    @Published var recentTransactions: [TransactionHistoryElement] = []

    @Published var cashBalance: Double = 0.0
    @Published var netWorth: Double = 0.0
    @Published var holdingsMarketValue: Double = 0.0
    @Published var costBasis: Double = 0.0
    @Published var unrealizedPnl: Double = 0.0
    @Published var unrealizedPnlPercent: Double = 0.0
    @Published var realizedPnl: Double = 0.0
    @Published var totalPnl: Double = 0.0

    @Published var isEditable = false
    @Published var timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()
    @Published var isLoading = true
    @Published var errorMessage: String?

    func fetchData() {
        isLoading = true
        errorMessage = nil

        let group = DispatchGroup()
        var errors: [String] = []

        group.enter()
        fetchDashboard { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dashboard):
                    self.apply(dashboard)
                case .failure(let error):
                    errors.append("Portfolio: \(error.localizedDescription)")
                }
                group.leave()
            }
        }

        group.enter()
        fetchFavourites { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let watchlist):
                    self.favourites = watchlist
                    self.updateFavourites()
                case .failure(let error):
                    errors.append("Watchlist: \(error.localizedDescription)")
                }
                group.leave()
            }
        }

        group.enter()
        fetchRecentTransactions(limit: 8) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transactions):
                    self.recentTransactions = transactions
                case .failure(let error):
                    errors.append("Activity: \(error.localizedDescription)")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.isLoading = false
            self.errorMessage = errors.isEmpty ? nil : errors.joined(separator: " • ")
        }
    }

    private func apply(_ dashboard: PortfolioDashboard) {
        cashBalance = dashboard.summary.cash_balance
        netWorth = dashboard.summary.net_worth
        holdingsMarketValue = dashboard.summary.holdings_market_value
        costBasis = dashboard.summary.cost_basis
        unrealizedPnl = dashboard.summary.unrealized_pnl
        unrealizedPnlPercent = dashboard.summary.unrealized_pnl_percent
        realizedPnl = dashboard.summary.realized_pnl
        totalPnl = dashboard.summary.total_pnl
        stocksDataForPortfolio = dashboard.positions
    }

    func refreshDashboard() {
        fetchDashboard { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dashboard):
                    self.apply(dashboard)
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = "Portfolio refresh failed: \(error.localizedDescription)"
                }
            }
        }
        fetchRecentTransactions(limit: 8) { result in
            if case .success(let transactions) = result {
                DispatchQueue.main.async { self.recentTransactions = transactions }
            }
        }
    }

    func updateFavourites() {
        guard !favourites.isEmpty else { return }
        let group = DispatchGroup()
        let source = favourites
        var updated: [WatchListElement] = []
        let lock = NSLock()

        for element in source {
            group.enter()
            fetchLatestPrice(stock_ticker: element.stock_ticker) { result in
                defer { group.leave() }
                switch result {
                case .success(let price):
                    let row = WatchListElement(
                        id: element.id,
                        stock_ticker: element.stock_ticker,
                        stock_company: element.stock_company,
                        current_price: price.c,
                        change_in_price: price.d,
                        change_in_price_percentage: price.dp / 100
                    )
                    lock.lock(); updated.append(row); lock.unlock()
                case .failure:
                    lock.lock(); updated.append(element); lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            let originalOrder = Dictionary(uniqueKeysWithValues: source.enumerated().map { ($0.element.stock_ticker, $0.offset) })
            self.favourites = updated.sorted {
                (originalOrder[$0.stock_ticker] ?? 0) < (originalOrder[$1.stock_ticker] ?? 0)
            }
        }
    }

    func updateStockDataList() {
        refreshDashboard()
    }
}
