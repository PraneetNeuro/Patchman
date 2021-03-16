//
//  Patchman.swift
//  Patchman
//
//  Created by Praneet S on 16/03/21.
//

import Foundation

enum RequestMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

struct Response{
    let response: Data
    let responseStatus: HTTPURLResponse?
}

class Request {
    public var url: URL?
    public var method: RequestMethod
    public var requestPolicy: URLRequest.CachePolicy
    public var requestBody: [String : Any]?
    public var requestHeaders: [String : String]?
    
    init(url: String, method: RequestMethod, cachingPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, requestBody: [String : Any], requestHeaders: Dictionary<String, String>) {
        self.url = URL(string: url)
        self.method = method
        self.requestPolicy = cachingPolicy
        if !requestBody.isEmpty {
            self.requestBody = requestBody
        }
        self.requestHeaders = requestHeaders
    }
    
    func executeRequest() -> Response {
        guard let instanceURL = url else { return Response(response: "Invalid URL".data(using: .utf8)!, responseStatus: nil) }
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: instanceURL, cachePolicy: requestPolicy)
        request.httpMethod = self.method.rawValue
        if let requestBody = self.requestBody {
            let jsonData = try? JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        }
        request.allHTTPHeaderFields = self.requestHeaders
        var responseData: Data?
        var responseStatus: HTTPURLResponse?
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let data = data {
                responseData = data
            } else {
                responseData = error?.localizedDescription.data(using: .utf8)
            }
            if let response = response {
                responseStatus = response as? HTTPURLResponse
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        print(responseStatus)
        return Response(response: responseData ?? "Unknown error".data(using: .utf8)!, responseStatus: responseStatus)
    }
}
