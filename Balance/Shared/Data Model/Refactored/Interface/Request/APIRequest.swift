//
//  APIRequestProtocol.swift
//  BalancemacOS
//
//  Created by Eli Pacheco Hoyos on 1/24/18.
//  Copyright © 2018 Balanced Software, Inc. All rights reserved.
//

import Foundation

public enum ApiRequestType {
    case accounts
    case transactions(input: Any?)
}

extension ApiRequestType: Equatable {
    
    public static func ==(left: ApiRequestType, right: ApiRequestType) -> Bool {
        switch (left, right) {
        case (.accounts, .accounts):
            return true
        case (.transactions(let leftInput), .transactions(let rightInput)):
            return inputTransactionsAreEquals(left: leftInput, right: rightInput)
        default:
            return false
        }
    }
    
    static func inputTransactionsAreEquals(left: Any?, right: Any?) -> Bool {
        
        if let leftString = left as? String,
            let rightString = right as? String {
            return leftString == rightString
        }
        
        return false
    }
    
}

public enum ApiRequestMethod: String {
    case get = "GET"
    case post = "POST"
    
    // These may be needed later
    case put = "PUT"
    case delete = "DELETE"
}

public enum ApiRequestDataFormat {
    // Always used for GET requests, can be used for POST requests when using "application/x-www-form-urlencoded" content type
    case urlEncoded
    
    // Can be used for POST requests
    case json
}

public enum ApiRequestEncoding {
    case none
    case simpleHmacSha512
    case hmac(hmacAlgorithm: CCHmacAlgorithm, digestLength: Int)
}

public enum ApiEncondingMessageType {
    case none
    case base64
    case concatenate(format: String)
}

public protocol APIAction {
    var host: String { get }
    var path: String { get }
    var url: URL? { get }
    var nonce: Int64 { get }
    var components: URLComponents { get }
    var type: ApiRequestType { get }
    var credentials: Credentials { get }

    init(type: ApiRequestType, credentials: Credentials)
}

extension APIAction {
    
    func getBasicURLComponents(from params: [String: String]) -> URLComponents {
        var queryItems = [URLQueryItem]()
        
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
        }
        
        var components = URLComponents()
        components.queryItems = queryItems
        
        return components
    }
    
}

public protocol RequestHandler: class {    
    func handleResponseData(for action: APIAction?, data: Data?, error: Error?, ulrResponse: URLResponse?) -> Any
}

extension APIAction {
    var query: String? {
        return components.query
    }
}
