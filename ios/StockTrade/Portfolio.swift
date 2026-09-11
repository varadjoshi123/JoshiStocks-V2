//
//  Portfolio.swift
//  StockTrade / JoshiStocks
//
//  Original course-project model retained and extended for JoshiStocks V2.
//

import Foundation
import Alamofire

struct PortFolioElement: Identifiable, Decodable {
    var id: String?
    var _id: String?
    var stock_ticker: String
    var quantity: Int64
    var stock_company: String
    var total_cost: Double

    private enum CodingKeys: String, CodingKey {
        case id, _id, stock_ticker, quantity, stock_company, total_cost
    }
}

struct WalletAccount: Decodable {
    var _id: String?
    var amount: Double
}

struct StockPortfolioElement: Decodable {
    var portfolio_data: PortFolioElement?
    var wallet_account: WalletAccount
}

struct PortfolioSummary: Decodable {
    var cash_balance: Double
    var holdings_market_value: Double
    var cost_basis: Double
    var unrealized_pnl: Double
    var unrealized_pnl_percent: Double
    var realized_pnl: Double
    var total_pnl: Double
    var net_worth: Double
}

struct PortfolioDashboard: Decodable {
    var wallet: WalletAccount
    var summary: PortfolioSummary
    var positions: [StockInfo]
}

struct TradeResponse: Decodable {
    var message: String
    var wallet: WalletAccount
    var position: TradePosition?
}

struct TradePosition: Decodable {
    var stock_ticker: String
    var stock_company: String
    var quantity: Int64
    var total_cost: Double
    var average_cost: Double
}

struct TransactionHistoryElement: Identifiable, Decodable {
    var id: String
    var stock_ticker: String
    var stock_company: String
    var side: String
    var quantity: Int64
    var price: Double
    var gross_amount: Double
    var realized_pnl: Double
    var created_at: String

    var createdAtDate: Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: created_at) { return date }
        return ISO8601DateFormatter().date(from: created_at)
    }
}

func fetchDashboard(completion: @escaping (Result<PortfolioDashboard, Error>) -> Void) {
    APIClient.request("/api/v2/account/dashboard")
        .responseDecodable(of: PortfolioDashboard.self) { response in
            completion(response.result.mapError { $0 as Error })
        }
}

func fetchStockPortfolioAndWallet(stock_ticker: String, completion: @escaping (Result<StockPortfolioElement, Error>) -> Void) {
    APIClient.request("/api/v2/account/position/\(stock_ticker)")
        .responseDecodable(of: StockPortfolioElement.self) { response in
            completion(response.result.mapError { $0 as Error })
        }
}

func executeTrade(
    stock_ticker: String,
    stock_company: String,
    side: String,
    quantity: Int64,
    completion: @escaping (Result<TradeResponse, Error>) -> Void
) {
    let parameters: [String: Any] = [
        "ticker": stock_ticker,
        "company": stock_company,
        "side": side,
        "quantity": quantity
    ]

    APIClient.request(
        "/api/v2/account/trades",
        method: .post,
        parameters: parameters,
        encoding: JSONEncoding.default
    )
    .responseData { response in
        if let statusCode = response.response?.statusCode, !(200..<300).contains(statusCode) {
            let payload = response.data.flatMap { try? JSONDecoder().decode(APIErrorPayload.self, from: $0) }
            completion(.failure(JoshiStocksAPIError(
                message: payload?.message ?? "Trade could not be completed.",
                code: payload?.error
            )))
            return
        }

        if let error = response.error {
            completion(.failure(error))
            return
        }

        guard let data = response.data else {
            completion(.failure(JoshiStocksAPIError(message: "The server returned an empty trade response.", code: nil)))
            return
        }

        do {
            completion(.success(try JSONDecoder().decode(TradeResponse.self, from: data)))
        } catch {
            completion(.failure(error))
        }
    }
}

func fetchRecentTransactions(limit: Int = 10, completion: @escaping (Result<[TransactionHistoryElement], Error>) -> Void) {
    APIClient.request("/api/v2/account/transactions?limit=\(limit)")
        .responseDecodable(of: [TransactionHistoryElement].self) { response in
            completion(response.result.mapError { $0 as Error })
        }
}

func resetDemoAccount(completion: @escaping (Result<Void, Error>) -> Void) {
    APIClient.request("/api/v2/account/reset", method: .post, parameters: [:], encoding: JSONEncoding.default)
        .validate(statusCode: 200..<300)
        .response { response in
            if let error = response.error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
}

func getDefaultPortfolioElement(ticker: String, name: String) -> PortFolioElement {
    PortFolioElement(stock_ticker: ticker, quantity: 0, stock_company: name, total_cost: 0)
}
