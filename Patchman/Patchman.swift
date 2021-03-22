//
//  Patchman.swift
//  Patchman
//
//  Created by Praneet S on 16/03/21.
//

import Foundation

func retreiveDefaultPresets() -> [Preset] {
    if let presets = UserDefaults.standard.object(forKey: "presets") as? Data {
        let decoder = JSONDecoder()
        if let presetsArray = try? decoder.decode([Preset].self, from: presets) {
            return presetsArray
        }
    }
    return []
}

func retreiveDefaultProfiles() -> [Profile] {
    if let profiles = UserDefaults.standard.object(forKey: "profiles") as? Data {
        let decoder = JSONDecoder()
        if let profilesArray = try? decoder.decode([Profile].self, from: profiles) {
            return profilesArray
        }
    }
    return []
}

struct Preset: Codable {
    let presetType: Int
    let key: String
    let value: String
    let presetName: String
    
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode([self]) {
            let defaults = UserDefaults.standard
            if let presets = defaults.object(forKey: "presets") as? Data {
                let decoder = JSONDecoder()
                if var presetsArray = try? decoder.decode([Preset].self, from: presets) {
                    presetsArray.append(self)
                    if let presetsArrayObj = try? encoder.encode(presetsArray) {
                        defaults.set(presetsArrayObj, forKey: "presets")
                    }
                }
            } else {
                defaults.set(encoded, forKey: "presets")
            }
        }
    }
}

enum CodingKeys: CodingKey {
    case string
    case int
    case double
    case bool
    case object
    case array
}

public enum JSONValue: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let str):
            try container.encode(str, forKey: .string)
        case .int(let int):
            try container.encode(int, forKey: .int)
        case .double(let dbl):
            try container.encode(dbl, forKey: .double)
        case .bool(let bool):
            try container.encode(bool, forKey: .bool)
        case .object(let obj):
            try container.encode(obj, forKey: .object)
        case .array(let array):
            try container.encode(array, forKey: .array)
        }
    }
    
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON"))
        }
    }
}

struct Profile: Codable {
    let profileName: String
    let method: Int
    let url: String
    let headers: [String : String]
    let requestBody: [String : JSONValue]
    let isHeadersEnabled: Bool
    let isBulkRequest: Bool
    let bulkRequestBody: [[String : JSONValue]]
    
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode([self]) {
            let defaults = UserDefaults.standard
            if let presets = defaults.object(forKey: "profiles") as? Data {
                let decoder = JSONDecoder()
                if var presetsArray = try? decoder.decode([Profile].self, from: presets) {
                    presetsArray.append(self)
                    if let presetsArrayObj = try? encoder.encode(presetsArray) {
                        defaults.set(presetsArrayObj, forKey: "profiles")
                    }
                }
            } else {
                defaults.set(encoded, forKey: "profiles")
            }
        }
    }
    
}

enum RequestMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

enum cachePolicies: String, CaseIterable {
    case reloadIgnoringLocalAndRemoteCacheData = "Reload ignoring local and remote cache data"
    case reloadIgnoringLocalCacheData = "Reload ignoring local cache data"
    case reloadRevalidatingCacheData = "Reload revalidating cache data"
    case returnCacheDataDontLoad = "Return cache data don't load"
    case returnCacheDataElseLoad = "Return cache data else load"
    case useProtocolCachePolicy = "Use protocol cache policy"
    case reloadIgnoringCacheData = "Reload ignoring cache data"
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
        return Response(response: responseData ?? "Unknown error".data(using: .utf8)!, responseStatus: responseStatus)
    }
}
