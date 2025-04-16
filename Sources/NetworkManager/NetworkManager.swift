// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, data: Data?)
    
    public var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "The provided URL is invalid."
            case .requestFailed(let error):
                return "The request failed with error: \(error.localizedDescription)"
            case .invalidResponse:
                return "The server response is invalid."
            case .decodingError(let error):
                return "Failed to decode the response: \(error.localizedDescription)"
            case .serverError(let statusCode, _):
                return "Server returned an error with status code: \(statusCode)"
        }
    }
}

public protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(endpoint: String) async throws -> T
}

public final class NetworkService: NetworkServiceProtocol {
    
    private let baseURL: URL
    private let session: URLSession
    
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    public func fetch<T: Decodable>(endpoint: String) async throws -> T {
        guard let fullURL = URL(string: endpoint, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: fullURL)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
            }
            
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
}
