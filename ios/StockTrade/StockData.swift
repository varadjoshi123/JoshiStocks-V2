//
//  StockData.swift
//  StockTrade
//
//  Created by Gaurav Baisware on 4/14/24.
//

import Foundation
import Alamofire
import SwiftyJSON

struct StockInfo: Identifiable, Decodable {
    var id: String?
    var stock_ticker: String
    var quantity: Int64
    var stock_company: String
    var total_cost: Double
    var current_price: Double?
    var market_value: Double?
    var change_in_price: Double?
    var change_in_price_percentage: Double?
}

struct StockSymbolOption: Identifiable, Decodable {
    var id: UUID?
    var description: String
    var displaySymbol: String
    var symbol: String
    var type: String

    private enum CodingKeys: String, CodingKey {
        case id, description, displaySymbol, symbol, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        description = try container.decode(String.self, forKey: .description)
        displaySymbol = try container.decode(String.self, forKey: .displaySymbol)
        symbol = try container.decode(String.self, forKey: .symbol)
        type = try container.decode(String.self, forKey: .type)
    }
}

struct StockInfoData: Decodable {
    var country: String?
    var currency: String?
    var estimateCurrency: String?
    var exchange: String?
    var finnhubIndustry: String?
    var ipo: String?
    var logo: String
    var marketCapitalization: Double?
    var name: String
    var phone: String?
    var shareOutstanding: Double?
    var ticker: String
    var weburl: String
    
    private enum CodingKeys: String, CodingKey {
        case country, currency, estimateCurrency, exchange, finnhubIndustry, ipo, logo, marketCapitalization, name, phone, shareOutstanding, ticker, weburl
    }
}

struct StockLatestPriceData: Decodable {
    var c: Double
    var d: Double
    var dp: Double
    var h: Double
    var l: Double
    var o: Double
    var pc: Double
    var t: Int64
}

struct StockInsiderSentiment: Decodable {
    var data: [StockInsiderSentimentElement]
}

struct StockInsiderSentimentElement: Decodable {
    var symbol: String
    var year: Int64
    var month: Int64
    var change: Double
    var mspr: Double
}

struct TopNewsElement: Identifiable, Decodable, Equatable {
    var category: String
    var datetime: Int64
    var headline: String
    var id: Int64
    var image: String
    var related: String?
    var source: String
    var summary: String
    var url: String
}

struct DeleteElement: Decodable {
    var acknowledged: Bool
    var deletedCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case acknowledged
        case deletedCount
    }
}

struct PriceData: Decodable {
    var ticker: String?
    var queryCount: Int64?
    var resultsCount: Int64?
    var adjusted: Bool?
    var results: [PointDetails]
    var status: String
    var request_id: String?
    var count: Int64
    
    private enum CodingKeys: String, CodingKey {
        case ticker, queryCount, resultsCount, adjusted, results, status, request_id, count
    }
}

struct PointDetails: Decodable {
    var v: Double
    var vw: Double
    var o: Double
    var c: Double
    var h: Double
    var l: Double
    var t: Int64
    var n: Int64
    
    private enum CodingKeys: String, CodingKey {
        case v, vw, o, c, h, l, t, n
    }
}

struct StockRecommendationElement: Decodable {
    var buy: Int64
    var hold: Int64
    var period: String
    var sell: Int64
    var strongBuy: Int64
    var strongSell: Int64
    var symbol: String
    
    private enum CodingKeys: String, CodingKey {
        case buy, hold, period, sell, strongBuy, strongSell, symbol
    }
}

struct StockEarningsElement: Decodable {
    var actual: Double
    var estimate: Double
    var period: String
    var quarter: Int64
    var surprise: Double
    var surprisePercent: Double
    var symbol: String
    var year: Int64
    
    private enum CodingKeys: String, CodingKey {
        case actual, estimate, period, quarter, surprise, surprisePercent, symbol, year
    }
}

func fetchCompanyInfo(stock_ticker: String, completion: @escaping (Result<StockInfoData, Error>) -> Void) {
    APIClient.request("/api/v2/market/profile/\(stock_ticker)").responseDecodable(of: StockInfoData.self) { response in
        switch response.result {
        case .success(let stock_info):
            completion(.success(stock_info))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchLatestPrice(stock_ticker: String, completion: @escaping (Result<StockLatestPriceData, Error>) -> Void) {
    APIClient.request("/api/v2/market/quote/\(stock_ticker)").responseDecodable(of: StockLatestPriceData.self) { response in
        switch response.result {
        case .success(let latest_price):
            completion(.success(latest_price))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchCompanyPeers(stock_ticker: String, completion: @escaping (Result<[String], Error>) -> Void) {
    APIClient.request("/api/v2/market/peers/\(stock_ticker)").responseDecodable(of: [String].self) { response in
        switch response.result {
        case .success(let peers):
            completion(.success(peers.filter({ peer in !peer.contains(".")})))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchStockInsiderSentiment(stock_ticker: String, completion: @escaping (Result<StockInsiderSentiment, Error>) -> Void) {
    APIClient.request("/api/v2/market/sentiment/\(stock_ticker)").responseDecodable(of: StockInsiderSentiment.self) { response in
        switch response.result {
        case .success(let stock_insider_sentiment):
            completion(.success(stock_insider_sentiment))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchTopNews(stock_ticker: String, completion: @escaping (Result<[TopNewsElement], Error>) -> Void) {
    APIClient.request("/api/v2/market/news/\(stock_ticker)").responseDecodable(of: [TopNewsElement].self) { response in
        switch response.result {
        case .success(let top_news):
            completion(.success(top_news))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchHourlyPriceData(stock_ticker: String, completion: @escaping (Result<PriceData, Error>) -> Void) {
    APIClient.request("/api/v2/market/hourly/\(stock_ticker)").responseDecodable(of: PriceData.self) { response in
        switch response.result {
        case .success(let hourly_price_data):
            completion(.success(hourly_price_data))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchHistoricalPriceData(stock_ticker: String, completion: @escaping (Result<PriceData, Error>) -> Void) {
    APIClient.request("/api/v2/market/historical/\(stock_ticker)").responseDecodable(of: PriceData.self) { response in
        switch response.result {
        case .success(let historical_price_data):
            completion(.success(historical_price_data))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchStockRecommendation(stock_ticker: String, completion: @escaping (Result<[StockRecommendationElement], Error>) -> Void) {
    APIClient.request("/api/v2/market/recommendations/\(stock_ticker)").responseDecodable(of: [StockRecommendationElement].self) { response in
        switch response.result {
        case .success(let stock_recommendation):
            completion(.success(stock_recommendation))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func fetchStockEarnings(stock_ticker: String, completion: @escaping (Result<[StockEarningsElement], Error>) -> Void) {
    APIClient.request("/api/v2/market/earnings/\(stock_ticker)").responseDecodable(of: [StockEarningsElement].self) { response in
        switch response.result {
        case .success(let stock_earnings):
            completion(.success(stock_earnings))
        case .failure(let error):
            print("Error \(error)")
            completion(.failure(error))
        }
    }
}

func getMarketValue(stock_info: StockInfo) -> Double {
    let market_value = (stock_info.current_price ?? 0.0) * Double(stock_info.quantity)
    return market_value
}

func getChangeInPrice(stock_info : StockInfo) -> Double {
    getMarketValue(stock_info: stock_info) - stock_info.total_cost
}

func getChangeInPricePercent(stock_info : StockInfo) -> Double {
    guard stock_info.total_cost > 0 else { return 0 }
    return getChangeInPrice(stock_info: stock_info) / stock_info.total_cost
}

func getCurrencyFormat(value: Double) -> String {
    let checkedValue = String(format: "%.2f", abs(value)) == "0.00" ? 0.00 : value
    let modifiedValue = Decimal(checkedValue)
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "en_US")
    formatter.currencyCode = "USD"
    return formatter.string(from: modifiedValue as NSNumber) ?? ""
}

func getPercentageFormat(value: Double) -> String {
    let checkedValue = String(format: "%.2f", abs(value)) == "0.00" ? 0.00 : value
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: checkedValue)) ?? ""
}


func getRelativeDateTime(from date: Int64) -> String {
    let currentDate = Date()
    let epochDate = Date(timeIntervalSince1970: TimeInterval(date))
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day, .hour, .minute], from: epochDate, to: currentDate)
    
    var result = ""
    if let days = components.day, days > 0 {
        result += "\(days) day\(days == 1 ? "" : "s"), "
    }
    if let hours = components.hour, let minutes = components.minute, hours > 0 {
        result += "\(hours) hr\((hours == 1) || (minutes > 1) ? "" : "s"), "
    }
    if let minutes = components.minute {
        result += "\(minutes) min\(minutes == 1 ? "" : "s")"
    }
    
    return result.isEmpty ? "Just now" : result + ""
}

func buyStocks(portfolio_element: PortFolioElement, quantity_bought: Int64, cash_balance: Double, completion: @escaping (Result<String, Error>) -> Void) {
    guard quantity_bought > 0 else {
        completion(.success(quantity_bought == 0 ? "Please enter a valid amount" : "Cannot buy non-positive shares"))
        return
    }

    executeTrade(
        stock_ticker: portfolio_element.stock_ticker,
        stock_company: portfolio_element.stock_company,
        side: "BUY",
        quantity: quantity_bought
    ) { result in
        switch result {
        case .success(let response): completion(.success(response.message))
        case .failure(let error): completion(.failure(error))
        }
    }
}

func sellStocks(portfolio_element: PortFolioElement, quantity_sold: Int64, cash_balance: Double, completion: @escaping (Result<String, Error>) -> Void) {
    guard quantity_sold > 0 else {
        completion(.success(quantity_sold == 0 ? "Please enter a valid amount" : "Cannot sell non-positive shares"))
        return
    }

    executeTrade(
        stock_ticker: portfolio_element.stock_ticker,
        stock_company: portfolio_element.stock_company,
        side: "SELL",
        quantity: quantity_sold
    ) { result in
        switch result {
        case .success(let response): completion(.success(response.message))
        case .failure(let error): completion(.failure(error))
        }
    }
}

func getDefaultStockInfoData() -> StockInfoData {
    let defItem = StockInfoData ( country: "US"
                                , currency: "USD"
                                , estimateCurrency: "USD"
                                , exchange: "NASDAQ NMS - GLOBAL MARKET"
                                , finnhubIndustry: "Technology"
                                , ipo: "1980-12-12"
                                , logo: "https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.png"
                                , marketCapitalization: 100000.00
                                , name: "Apple Inc"
                                , phone: "14089961010"
                                , shareOutstanding: 100.00
                                , ticker: "AAPL"
                                , weburl: "https://www.apple.com/"
                                )
    return defItem
}
