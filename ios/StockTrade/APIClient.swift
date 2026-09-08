//
//  APIClient.swift
//  JoshiStocks
//
//  V2 networking foundation added during the independent JoshiStocks upgrade.
//

import Foundation
import Alamofire

enum APIConfig {
    // For the iOS Simulator, localhost points to the Mac running the backend.
    // Before creating a forwardable device build, replace this with the deployed HTTPS API URL.
    static var baseURL: String {
        if let override = UserDefaults.standard.string(forKey: "JoshiStocks.APIBaseURL"),
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return override.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return "http://127.0.0.1:8080"
    }
}

enum DemoUser {
    static let id = "varad-demo-001"
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
