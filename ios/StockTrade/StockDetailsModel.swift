//
//  StockDetailsModel.swift
//  StockTrade
//
//  Created by Gaurav Baisware on 4/21/24.
//

import Foundation

class StockDetailsModel: ObservableObject {
    @Published var stock_ticker = ""

    @Published var stock_info: StockInfoData = getDefaultStockInfoData()
    @Published var stockPortfolioData: PortFolioElement?
    @Published var peers_list: [String] = []
    @Published var top_news: [TopNewsElement] = []
    @Published var hourly_chart_data: [PointDetails] = []
    @Published var hourly_chart_data_count: Int64 = 0
    @Published var historical_chart_data: [PointDetails] = []
    @Published var recommendation_trends_chart_data: [StockRecommendationElement] = []
    @Published var eps_chart_data: [StockEarningsElement] = []

    @Published var current_price: Double = 0.0
    @Published var change_in_price: Double = 0.0
    @Published var change_in_price_percentage: Double = 0.0
    @Published var high_price: Double = 0.0
    @Published var low_price: Double = 0.0
    @Published var open_price: Double = 0.0
    @Published var prev_close_price: Double = 0.0
    @Published var avg_cost_per_share: Double = 0.0
    @Published var market_value: Double = 0.0
    @Published var change_from_total_cost: Double = 0.0
    @Published var cashBalance: Double = 0.0
    @Published var total_mspr: Double = 0.0
    @Published var positive_mspr: Double = 0.0
    @Published var negative_mspr: Double = 0.0
    @Published var total_change: Double = 0.0
    @Published var positive_change: Double = 0.0
    @Published var negative_change: Double = 0.0
    @Published var isInFavourite = false
    @Published var timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    @Published var favouriteToastMessage: String = ""
    @Published var successfulToastMessage: String = ""

    @Published var stockPortfolioUpdated = false
    @Published var shouldShowFavouriteToast = false
    @Published var stockInfoUpdated = false
    @Published var latestPriceUpdated = false
    @Published var stockFavouriteUpdated = false
    @Published var peersListUpdated = false
    @Published var insiderSentimentUpdated = false
    @Published var topNewsUpdated = false
    @Published var hourlyChartDataUpdated = false
    @Published var historicalChartDataUpdated = false
    @Published var recommendationTrendsChartDataUpdated = false
    @Published var epsChartDataUpdated = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    func fetchStockData() {
        let ticker = stock_ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !ticker.isEmpty else { return }
        stock_ticker = ticker
        resetLoadingState()

        updatePortfolioAndWallet()
        updateStockInfo()
        updateLatestPrice()
        updateCompanyPeers()
        updateInsiderSentimentDetails()
        updateTopNews()
        updateChartsData()
        updateFavouriteStatus()
    }

    private func resetLoadingState() {
        isLoading = true
        errorMessage = nil
        stockPortfolioUpdated = false
        stockInfoUpdated = false
        latestPriceUpdated = false
        stockFavouriteUpdated = false
        peersListUpdated = false
        insiderSentimentUpdated = false
        topNewsUpdated = false
        hourlyChartDataUpdated = false
        historicalChartDataUpdated = false
        recommendationTrendsChartDataUpdated = false
        epsChartDataUpdated = false
    }

    private func recordCoreError(_ message: String) {
        if errorMessage == nil {
            errorMessage = message
        }
    }

    func updatePortfolioAndWallet() {
        fetchStockPortfolioAndWallet(stock_ticker: stock_ticker) { result in
            switch result {
            case .success(let portfolio):
                self.cashBalance = portfolio.wallet_account.amount
                if let position = portfolio.portfolio_data {
                    self.stockPortfolioData = position
                } else if self.stockInfoUpdated {
                    self.stockPortfolioData = getDefaultPortfolioElement(
                        ticker: self.stock_info.ticker,
                        name: self.stock_info.name
                    )
                }
                self.stockPortfolioUpdated = true
                self.recalculatePortfolioMetrics()
                self.refreshLoadingState()
            case .failure(let error):
                self.recordCoreError("Portfolio unavailable: \(error.localizedDescription)")
                self.stockPortfolioUpdated = true
                self.refreshLoadingState()
            }
        }
    }

    func updateStockInfo() {
        fetchCompanyInfo(stock_ticker: stock_ticker) { stockInfoData in
            switch stockInfoData {
            case .success(let stockInfo):
                self.stock_info = stockInfo
                if self.stockPortfolioData == nil {
                    self.stockPortfolioData = getDefaultPortfolioElement(
                        ticker: stockInfo.ticker,
                        name: stockInfo.name
                    )
                }
                self.stockInfoUpdated = true
                self.recalculatePortfolioMetrics()
                self.refreshLoadingState()
            case .failure(let error):
                self.recordCoreError("Company details unavailable: \(error.localizedDescription)")
                self.stockInfoUpdated = true
                self.refreshLoadingState()
            }
        }
    }

    func updateLatestPrice() {
        fetchLatestPrice(stock_ticker: stock_ticker) { latestPriceInfo in
            switch latestPriceInfo {
            case .success(let priceInfo):
                self.current_price = priceInfo.c
                self.change_in_price = priceInfo.d
                self.change_in_price_percentage = priceInfo.dp / 100
                self.high_price = priceInfo.h
                self.low_price = priceInfo.l
                self.open_price = priceInfo.o
                self.prev_close_price = priceInfo.pc
                self.latestPriceUpdated = true
                self.recalculatePortfolioMetrics()
                self.refreshLoadingState()
            case .failure(let error):
                self.recordCoreError("Latest quote unavailable: \(error.localizedDescription)")
                self.latestPriceUpdated = true
                self.refreshLoadingState()
            }
        }
    }

    private func recalculatePortfolioMetrics() {
        let quantity = stockPortfolioData?.quantity ?? 0
        let totalCost = stockPortfolioData?.total_cost ?? 0
        avg_cost_per_share = quantity > 0 ? totalCost / Double(quantity) : 0
        market_value = Double(quantity) * current_price
        change_from_total_cost = market_value - totalCost
    }

    func updateCompanyPeers() {
        fetchCompanyPeers(stock_ticker: stock_ticker) { peersData in
            switch peersData {
            case .success(let peers):
                self.peers_list = peers
            case .failure(let error):
                print("Error fetching company peers data for stock \(self.stock_ticker): \(error.localizedDescription)")
            }
            self.peersListUpdated = true
        }
    }

    func updateInsiderSentimentDetails() {
        fetchStockInsiderSentiment(stock_ticker: stock_ticker) { insiderSentimentData in
            switch insiderSentimentData {
            case .success(let insiderSentiment):
                let msprList = insiderSentiment.data.map(\.mspr)
                self.total_mspr = msprList.reduce(0, +)
                self.positive_mspr = msprList.filter { $0 >= 0 }.reduce(0, +)
                self.negative_mspr = msprList.filter { $0 < 0 }.reduce(0, +)

                let changeList = insiderSentiment.data.map(\.change)
                self.total_change = changeList.reduce(0, +)
                self.positive_change = changeList.filter { $0 >= 0 }.reduce(0, +)
                self.negative_change = changeList.filter { $0 < 0 }.reduce(0, +)
            case .failure(let error):
                print("Error fetching insider sentiments for stock \(self.stock_ticker): \(error.localizedDescription)")
            }
            self.insiderSentimentUpdated = true
        }
    }

    func updateTopNews() {
        fetchTopNews(stock_ticker: stock_ticker) { topNewsData in
            switch topNewsData {
            case .success(let topNews):
                self.top_news = Array(topNews.prefix(20))
            case .failure(let error):
                print("Error fetching top news for stock \(self.stock_ticker): \(error.localizedDescription)")
            }
            self.topNewsUpdated = true
        }
    }

    func updateChartsData() {
        fetchHourlyPriceData(stock_ticker: stock_ticker) { hourlyChartData in
            switch hourlyChartData {
            case .success(let data):
                self.hourly_chart_data = data.results
                self.hourly_chart_data_count = data.count
            case .failure(let error):
                print("Error fetching hourly chart data for stock \(self.stock_ticker): \(error.localizedDescription)")
            }
            self.hourlyChartDataUpdated = true
        }

        fetchHistoricalPriceData(stock_ticker: stock_ticker) { historicalChartData in
            switch historicalChartData {
            case .success(let data):
                self.historical_chart_data = data.results
            case .failure(let error):
                print("Error fetching historical chart data for stock \(self.stock_ticker): \(error.localizedDescription)")
            }
            self.historicalChartDataUpdated = true
        }

        fetchStockRecommendation(stock_ticker: stock_ticker) { stockRecommendationData in
            switch stockRecommendationData {
            case .success(let data):
                self.recommendation_trends_chart_data = data
            case .failure(let error):
                print("Error fetching recommendations for stock \(self.stock_ticker): \(error.localizedDescription)")
            }
            self.recommendationTrendsChartDataUpdated = true
        }

        fetchStockEarnings(stock_ticker: stock_ticker) { stockEarningsData in
            switch stockEarningsData {
            case .success(let data):
                self.eps_chart_data = data
            case .failure(let error):
                print("Error fetching earnings for stock \(self.stock_ticker): \(error.localizedDescription)")
            }
            self.epsChartDataUpdated = true
        }
    }

    func updateFavouriteStatus() {
        fetchStockFavourite(stock_ticker: stock_ticker) { result in
            switch result {
            case .success(let favourite):
                self.isInFavourite = favourite != nil
            case .failure(let error):
                print("Error fetching watchlist data: \(error.localizedDescription)")
                self.isInFavourite = false
            }
            self.stockFavouriteUpdated = true
        }
    }

    private func refreshLoadingState() {
        isLoading = !(stockPortfolioUpdated && stockInfoUpdated && latestPriceUpdated)
    }

    func addOrRemoveFromFavourites(completion: (() -> Void)? = nil) {
        if isInFavourite {
            deleteFavourites(stock_ticker: stock_ticker) { response in
                switch response {
                case .success(let resp):
                    if resp.deletedCount == 1 {
                        self.isInFavourite = false
                        self.favouriteToastMessage = "Removed \(self.stock_ticker) from Favourites"
                        self.shouldShowFavouriteToast = true
                        completion?()
                    }
                case .failure(let error):
                    print("Error deleting \(self.stock_ticker) from Watchlist: \(error.localizedDescription)")
                }
            }
        } else {
            addToFavourite(stock_ticker: stock_ticker, stock_company: stock_info.name) { response in
                switch response {
                case .success(let resp):
                    if resp.acknowledged {
                        self.isInFavourite = true
                        self.favouriteToastMessage = "Added \(self.stock_ticker) to Favourites"
                        self.shouldShowFavouriteToast = true
                        completion?()
                    }
                case .failure(let error):
                    print("Error adding \(self.stock_ticker) to Watchlist: \(error.localizedDescription)")
                }
            }
        }
    }
}
