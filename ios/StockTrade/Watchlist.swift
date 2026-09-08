//
//  Watchlist.swift
//  StockTrade / JoshiStocks
//

import Foundation
import Alamofire

struct WatchListElement: Identifiable, Decodable {
    var id: String?
    var _id: String?
    var stock_ticker: String
    var stock_company: String
    var current_price: Double?
    var change_in_price: Double?
    var change_in_price_percentage: Double?

    private enum CodingKeys: String, CodingKey {
        case id, _id, stock_ticker, stock_company, current_price, change_in_price, change_in_price_percentage
    }
}

struct WatchlistInsertResponse: Decodable {
    var acknowledged: Bool
    var insertedId: String
}

func fetchFavourites(completion: @escaping (Result<[WatchListElement], Error>) -> Void) {
    APIClient.request("/api/v2/watchlist")
        .responseDecodable(of: [WatchListElement].self) { response in
            switch response.result {
            case .success(let watchlist):
                var modified = watchlist
                for i in 0..<modified.count {
                    modified[i].id = modified[i].id ?? modified[i]._id
                }
                completion(.success(modified))
            case .failure(let error):
                completion(.failure(error))
            }
        }
}

func fetchStockFavourite(stock_ticker: String, completion: @escaping (Result<WatchListElement?, Error>) -> Void) {
    APIClient.request("/api/v2/watchlist/\(stock_ticker)")
        .responseDecodable(of: WatchListElement?.self) { response in
            completion(response.result)
        }
}

func addToFavourite(stock_ticker: String, stock_company: String, completion: @escaping (Result<WatchlistInsertResponse, Error>) -> Void) {
    let parameters: [String: Any] = [
        "stock_ticker": stock_ticker,
        "stock_company": stock_company
    ]

    APIClient.request(
        "/api/v2/watchlist",
        method: .post,
        parameters: parameters,
        encoding: JSONEncoding.default
    )
    .validate(statusCode: 200..<300)
    .responseDecodable(of: WatchlistInsertResponse.self) { response in
        completion(response.result)
    }
}

func deleteFavourites(stock_ticker: String, completion: @escaping (Result<DeleteElement, Error>) -> Void) {
    APIClient.request("/api/v2/watchlist/\(stock_ticker)", method: .delete)
        .validate(statusCode: 200..<300)
        .responseDecodable(of: DeleteElement.self) { response in
            completion(response.result)
        }
}
