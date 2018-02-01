//
//  PoloniexAPI2.swift
//  Balance
//
//  Created by Benjamin Baron on 1/22/18.
//  Copyright © 2018 Balanced Software, Inc. All rights reserved.
//

import Foundation

// This is for example Poloniex
class PoloniexAPI2: AbstractApi {
    override var requestMethod: ApiRequestMethod { return .post }
    override var requestDataFormat: ApiRequestDataFormat { return .urlEncoded }
    override var requestEncoding: ApiRequestEncoding { return .simpleHmacSha512 }
    
    override func processErrors(requestType: ApiRequestType, response: URLResponse?, data: Data?, error: Error?) -> Error? {
        guard let response = response as? HTTPURLResponse else {
            return nil
        }

        if let error = processBaseErrors(response: response, error: error) {
            return error
        }
        
        if let dict = createDict(from: data), let errorDict = dict["error"] as? String {
            return ExchangeBaseError.other(message: errorDict)
        }
        
        return nil
    }
    
    override func processData(requestType: ApiRequestType, data: Data) -> Any {
        return requestType == .accounts ? buildAccounts(from: data) : buildTransacionts(from: data)
    }
    
    //MARK: Builder methods for Request
    override func createRequest(for action: APIAction) -> URLRequest? {
        
        switch action.type {
        case .accounts, .transactions:
            let message = createMessage(for: action)
            guard let messageSigned = generateMessageSigned(for: action),
                let url = action.url else {
                    return nil
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = requestMethod.rawValue
            request.setValue(action.credentials.apiKey, forHTTPHeaderField: "Key")
            request.setValue(messageSigned, forHTTPHeaderField: "Sign")
            request.httpBody = message?.data(using: .utf8)
            
            return request
        }
        
    }
    
    override func operation(for action: APIAction, session: URLSession, completion: @escaping ExchangeOperationCompletionHandler) -> Operation {
        guard let request = createRequest(for: action)
            else {
                completion(false, nil, nil)
                return Operation()
        }
        return ExchangeOperation.init(with: self, action: action, session: session, request: request)
    }
    
    override func createMessage(for action: APIAction) -> String? {
        return action.components.query
    }
    
}

extension PoloniexAPI2: RequestHandler {
    
    func handleResponseData(for action: APIAction?, data: Data?, error: Error?, ulrResponse: URLResponse?) -> Any {
        guard let action = action else {
            return ExchangeBaseError.other(message: "No action provided")
        }
        
        guard let data = data else {
            return ExchangeBaseError.other(message: "no data to manage")
        }
        
        if let error = processErrors(requestType: action.type, response: ulrResponse, data: data, error: error) {
            return error
        }
        
        return processData(requestType: action.type, data: data)
    }
    
}

private extension PoloniexAPI2 {
    
    func buildTransacionts(from data: Data) -> [Any] {
        guard let transactions = try? JSONDecoder().decode([NewPoloniexTransaction].self, from: data) else {
            return []
        }
        
        return transactions
    }
    
    func buildAccounts(from data: Data) -> [Any] {
        guard let accounts = try? JSONDecoder().decode([NewPoloniexAccount].self, from: data) else {
            return []
        }
        
        return accounts
    }
}
