//
//  APIClient.swift
//  JoshiStocks
//
//  V2 networking foundation added during the independent JoshiStocks upgrade.
//

import Foundation
import Alamofire

struct APIErrorPayload: Decodable {
    let error: String?
    let message: String?
}

struct JoshiStocksAPIError: LocalizedError {
    let message: String
    let code: String?

    var errorDescription: String? { message }
}

enum APIConfig {
    static var baseURL: String {
        if let override = UserDefaults.standard.string(forKey: "JoshiStocks.APIBaseURL"),
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return override.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        if let configured = Bundle.main.object(forInfoDictionaryKey: "JOSHISTOCKS_API_BASE_URL") as? String,
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configured.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        // Simulator development fallback. Release/device builds should set
        // JOSHISTOCKS_API_BASE_URL to the deployed HTTPS backend URL.
        return "http://127.0.0.1:8080"
    }
}

enum DemoUser {
    private static let key = "JoshiStocks.DemoUserID"

    static var id: String {
        if let override = UserDefaults.standard.string(forKey: "JoshiStocks.DemoUserIDOverride"),
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return override
        }

        #if DEBUG
        // Keeps the existing local demo portfolio available during development.
        return "varad-demo-001"
        #else
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let generated = "ios_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        UserDefaults.standard.set(generated, forKey: key)
        return generated
        #endif
    }
}

enum APIClient {
    static func url(_ path: String) -> String {
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        return APIConfig.baseURL + normalizedPath
    }

    static func request(
        _ path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default
    ) -> DataRequest {
        let headers: HTTPHeaders = [
            "X-User-ID": DemoUser.id,
            "Accept": "application/json"
        ]
        return AF.request(
            url(path),
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers
        )
    }
}
