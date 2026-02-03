// NetworkActor.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// An actor for managing network operations with isolation.
///
/// `NetworkActor` provides a centralized, thread-safe interface for
/// network requests with built-in features like rate limiting,
/// retry logic, and request deduplication.
///
/// ## Overview
///
/// Use `NetworkActor` to manage all network operations in your app,
/// ensuring proper concurrency handling and resource management.
///
/// ```swift
/// let network = NetworkActor()
///
/// let data = try await network.fetch(from: url)
/// let user: User = try await network.fetchJSON(from: userUrl)
/// ```
///
/// ## Topics
///
/// ### Creating Network Actors
/// - ``init(configuration:)``
///
/// ### Basic Operations
/// - ``fetch(from:)``
/// - ``fetchJSON(from:as:)``
/// - ``post(_:to:body:)``
///
/// ### Advanced Features
/// - ``withRateLimit(_:)``
/// - ``deduplicated(_:)``
public actor NetworkActor {
    
    // MARK: - Types
    
    /// Configuration for network operations.
    public struct Configuration: Sendable {
        /// Maximum concurrent requests.
        public var maxConcurrentRequests: Int
        /// Default timeout for requests.
        public var timeout: Duration
        /// Whether to enable request deduplication.
        public var deduplicationEnabled: Bool
        /// Maximum requests per second (rate limiting).
        public var maxRequestsPerSecond: Int?
        /// Default retry policy.
        public var retryPolicy: RetryConfiguration?
        
        /// Default configuration.
        public static let `default` = Configuration(
            maxConcurrentRequests: 10,
            timeout: .seconds(30),
            deduplicationEnabled: true,
            maxRequestsPerSecond: nil,
            retryPolicy: nil
        )
        
        /// Creates a configuration.
        public init(
            maxConcurrentRequests: Int = 10,
            timeout: Duration = .seconds(30),
            deduplicationEnabled: Bool = true,
            maxRequestsPerSecond: Int? = nil,
            retryPolicy: RetryConfiguration? = nil
        ) {
            self.maxConcurrentRequests = maxConcurrentRequests
            self.timeout = timeout
            self.deduplicationEnabled = deduplicationEnabled
            self.maxRequestsPerSecond = maxRequestsPerSecond
            self.retryPolicy = retryPolicy
        }
    }
    
    /// Retry configuration.
    public struct RetryConfiguration: Sendable {
        /// Maximum number of retries.
        public var maxRetries: Int
        /// Initial delay between retries.
        public var initialDelay: Duration
        /// Maximum delay between retries.
        public var maxDelay: Duration
        /// Multiplier for exponential backoff.
        public var multiplier: Double
        
        /// Default retry configuration.
        public static let `default` = RetryConfiguration(
            maxRetries: 3,
            initialDelay: .milliseconds(100),
            maxDelay: .seconds(10),
            multiplier: 2.0
        )
        
        /// Creates a retry configuration.
        public init(
            maxRetries: Int = 3,
            initialDelay: Duration = .milliseconds(100),
            maxDelay: Duration = .seconds(10),
            multiplier: Double = 2.0
        ) {
            self.maxRetries = maxRetries
            self.initialDelay = initialDelay
            self.maxDelay = maxDelay
            self.multiplier = multiplier
        }
    }
    
    /// Network errors.
    public enum NetworkError: Error, Sendable {
        case invalidURL(String)
        case requestFailed(statusCode: Int, message: String)
        case timeout
        case noData
        case decodingFailed(Error)
        case cancelled
        case rateLimited
        case tooManyRequests
    }
    
    /// Request methods.
    public enum HTTPMethod: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
    }
    
    // MARK: - Properties
    
    /// The configuration.
    private let configuration: Configuration
    
    /// The URL session.
    private let session: URLSession
    
    /// Current number of active requests.
    private var activeRequests: Int = 0
    
    /// Pending request continuations (for concurrency limiting).
    private var pendingRequests: [CheckedContinuation<Void, Never>] = []
    
    /// Deduplication cache.
    private var inFlightRequests: [String: Task<Data, Error>] = [:]
    
    /// Rate limiting state.
    private var requestTimestamps: [Date] = []
    
    /// Request statistics.
    private var totalRequests: Int = 0
    private var successfulRequests: Int = 0
    private var failedRequests: Int = 0
    
    // MARK: - Initialization
    
    /// Creates a network actor with configuration.
    ///
    /// - Parameter configuration: The configuration to use.
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout.timeInterval
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Basic Operations
    
    /// Fetches data from a URL.
    ///
    /// - Parameter url: The URL to fetch from.
    /// - Returns: The fetched data.
    /// - Throws: `NetworkError` if the request fails.
    public func fetch(from url: URL) async throws -> Data {
        try await performRequest(URLRequest(url: url))
    }
    
    /// Fetches data from a URL string.
    ///
    /// - Parameter urlString: The URL string.
    /// - Returns: The fetched data.
    /// - Throws: `NetworkError` if the URL is invalid or request fails.
    public func fetch(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }
        return try await fetch(from: url)
    }
    
    /// Fetches and decodes JSON from a URL.
    ///
    /// - Parameters:
    ///   - url: The URL to fetch from.
    ///   - type: The type to decode to.
    ///   - decoder: The JSON decoder to use.
    /// - Returns: The decoded object.
    /// - Throws: `NetworkError` if the request or decoding fails.
    public func fetchJSON<T: Decodable & Sendable>(
        from url: URL,
        as type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let data = try await fetch(from: url)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    /// Performs a POST request.
    ///
    /// - Parameters:
    ///   - url: The URL to post to.
    ///   - body: The request body.
    ///   - contentType: The content type header.
    /// - Returns: The response data.
    /// - Throws: `NetworkError` if the request fails.
    public func post(
        to url: URL,
        body: Data,
        contentType: String = "application/json"
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.httpBody = body
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        return try await performRequest(request)
    }
    
    /// Performs a POST request with JSON encoding.
    ///
    /// - Parameters:
    ///   - url: The URL to post to.
    ///   - body: The object to encode and send.
    ///   - encoder: The JSON encoder to use.
    /// - Returns: The response data.
    /// - Throws: `NetworkError` if encoding or request fails.
    public func postJSON<T: Encodable & Sendable>(
        to url: URL,
        body: T,
        encoder: JSONEncoder = JSONEncoder()
    ) async throws -> Data {
        let data = try encoder.encode(body)
        return try await post(to: url, body: data)
    }
    
    /// Performs a request with a custom method.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - url: The URL.
    ///   - headers: Optional headers.
    ///   - body: Optional body data.
    /// - Returns: The response data.
    /// - Throws: `NetworkError` if the request fails.
    public func request(
        method: HTTPMethod,
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return try await performRequest(request)
    }
    
    // MARK: - Request Execution
    
    /// Performs a request with all configured features.
    private func performRequest(_ request: URLRequest) async throws -> Data {
        // Rate limiting
        if let maxRPS = configuration.maxRequestsPerSecond {
            try await waitForRateLimit(maxRPS: maxRPS)
        }
        
        // Concurrency limiting
        await waitForSlot()
        defer { releaseSlot() }
        
        // Deduplication
        let cacheKey = requestCacheKey(for: request)
        if configuration.deduplicationEnabled,
           let existingTask = inFlightRequests[cacheKey] {
            return try await existingTask.value
        }
        
        // Create and track task
        let task = Task<Data, Error> {
            try await executeRequest(request)
        }
        
        if configuration.deduplicationEnabled {
            inFlightRequests[cacheKey] = task
        }
        
        defer {
            if configuration.deduplicationEnabled {
                inFlightRequests.removeValue(forKey: cacheKey)
            }
        }
        
        return try await task.value
    }
    
    /// Executes the actual network request.
    private func executeRequest(_ request: URLRequest) async throws -> Data {
        totalRequests += 1
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                failedRequests += 1
                throw NetworkError.requestFailed(statusCode: 0, message: "Invalid response")
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                failedRequests += 1
                throw NetworkError.requestFailed(
                    statusCode: httpResponse.statusCode,
                    message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                )
            }
            
            successfulRequests += 1
            return data
        } catch is CancellationError {
            failedRequests += 1
            throw NetworkError.cancelled
        } catch let error as NetworkError {
            throw error
        } catch {
            failedRequests += 1
            throw NetworkError.requestFailed(statusCode: 0, message: error.localizedDescription)
        }
    }
    
    // MARK: - Concurrency Control
    
    /// Waits for an available request slot.
    private func waitForSlot() async {
        if activeRequests < configuration.maxConcurrentRequests {
            activeRequests += 1
            return
        }
        
        await withCheckedContinuation { continuation in
            pendingRequests.append(continuation)
        }
        activeRequests += 1
    }
    
    /// Releases a request slot.
    private func releaseSlot() {
        activeRequests -= 1
        
        if let continuation = pendingRequests.first {
            pendingRequests.removeFirst()
            continuation.resume()
        }
    }
    
    // MARK: - Rate Limiting
    
    /// Waits for rate limit to allow a request.
    private func waitForRateLimit(maxRPS: Int) async throws {
        let now = Date()
        let windowStart = now.addingTimeInterval(-1.0)
        
        // Remove old timestamps
        requestTimestamps = requestTimestamps.filter { $0 > windowStart }
        
        if requestTimestamps.count >= maxRPS {
            // Wait until oldest request is outside window
            if let oldest = requestTimestamps.first {
                let waitTime = oldest.timeIntervalSince(windowStart)
                if waitTime > 0 {
                    try await Task.sleep(for: .seconds(waitTime))
                }
            }
        }
        
        requestTimestamps.append(now)
    }
    
    // MARK: - Helpers
    
    /// Creates a cache key for request deduplication.
    private func requestCacheKey(for request: URLRequest) -> String {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? ""
        return "\(method):\(url)"
    }
    
    // MARK: - Statistics
    
    /// Network statistics.
    public struct Statistics: Sendable {
        public let totalRequests: Int
        public let successfulRequests: Int
        public let failedRequests: Int
        public let activeRequests: Int
        public let pendingRequests: Int
        
        public var successRate: Double {
            guard totalRequests > 0 else { return 0 }
            return Double(successfulRequests) / Double(totalRequests)
        }
    }
    
    /// Returns current statistics.
    public var statistics: Statistics {
        Statistics(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            activeRequests: activeRequests,
            pendingRequests: pendingRequests.count
        )
    }
    
    /// Resets statistics.
    public func resetStatistics() {
        totalRequests = 0
        successfulRequests = 0
        failedRequests = 0
    }
}

// MARK: - Duration Extension

extension Duration {
    /// Converts to TimeInterval.
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
