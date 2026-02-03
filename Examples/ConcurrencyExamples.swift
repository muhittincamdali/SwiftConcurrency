// ConcurrencyExamples.swift
// SwiftConcurrency Examples
//
// Demonstrates async/await utilities and patterns

import Foundation
import SwiftConcurrency

// MARK: - Retry Task Examples

func retryExamples() async throws {
    // Basic retry
    let result = try await RetryTask(maxAttempts: 3) {
        try await fetchData()
    }.execute()
    
    // Retry with exponential backoff
    let dataWithBackoff = try await RetryTask(
        maxAttempts: 5,
        initialDelay: .seconds(1),
        backoff: .exponential(multiplier: 2, maxDelay: .seconds(30))
    ) {
        try await unreliableOperation()
    }.execute()
    
    // Retry with custom condition
    let customRetry = try await RetryTask(
        maxAttempts: 3,
        shouldRetry: { error in
            if let networkError = error as? NetworkError {
                return networkError.isRetryable
            }
            return false
        }
    ) {
        try await networkRequest()
    }.execute()
}

// MARK: - Throttle & Debounce Examples

func throttleDebounceExamples() async {
    // Throttled API calls
    let throttle = ThrottledTask(interval: .seconds(1))
    
    for id in 1...100 {
        await throttle.execute {
            try? await api.fetch(id: id)
        }
    }
    // Executes at most once per second
    
    // Debounced search
    let debounce = DebouncedTask<String>(delay: .milliseconds(300))
    
    for query in ["S", "Sw", "Swi", "Swif", "Swift"] {
        await debounce.execute(value: query) { finalQuery in
            await performSearch(finalQuery)
        }
    }
    // Only searches for "Swift"
}

// MARK: - Timeout Examples

func timeoutExamples() async throws {
    // Simple timeout
    let result = try await TimeoutTask(timeout: .seconds(10)) {
        try await longRunningOperation()
    }.execute()
    
    // Timeout with fallback
    let withFallback = try await TimeoutTask(
        timeout: .seconds(5),
        fallback: cachedData()
    ) {
        try await fetchFreshData()
    }.execute()
    
    // Timeout with cancellation
    let cancellable = TimeoutTask(timeout: .seconds(30)) {
        try await downloadLargeFile()
    }
    
    // Can cancel from elsewhere
    // cancellable.cancel()
    
    let downloadResult = try await cancellable.execute()
}

// MARK: - Async Sequence Examples

func asyncSequenceExamples() async {
    // Throttle stream
    let numbers = AsyncStream<Int> { continuation in
        for i in 1...100 {
            continuation.yield(i)
        }
        continuation.finish()
    }
    
    for await number in numbers.throttle(for: .milliseconds(100)) {
        print("Throttled: \(number)")
    }
    
    // Merge multiple streams
    let stream1 = numberStream(prefix: "A", count: 5)
    let stream2 = numberStream(prefix: "B", count: 5)
    
    for await value in merge(stream1, stream2) {
        print("Merged: \(value)")
    }
    
    // Buffer with chunking
    let fastStream = rapidDataStream()
    
    for await chunk in fastStream.buffer(policy: .bounded(100)).chunks(of: 10) {
        await processChunk(chunk)
    }
}

// MARK: - Actor Examples

func actorExamples() async {
    // Async Cache
    let cache = AsyncCache<String, Data>(ttl: .minutes(5))
    
    // Get or fetch
    let userData = await cache.get("user_123") {
        try? await api.fetchUser(id: "123")
    }
    
    // Invalidate
    await cache.remove("user_123")
    await cache.clear()
    
    // Async Queue with concurrency limit
    let queue = AsyncQueue(maxConcurrent: 3)
    
    for url in urls {
        await queue.enqueue {
            try? await download(url)
        }
    }
    
    // Wait for all to complete
    await queue.waitUntilEmpty()
    
    // Semaphore for resource limiting
    let semaphore = AsyncSemaphore(limit: 5)
    
    await withTaskGroup(of: Void.self) { group in
        for i in 1...20 {
            group.addTask {
                await semaphore.wait()
                defer { semaphore.signal() }
                
                try? await useExpensiveResource(i)
            }
        }
    }
}

// MARK: - Structured Concurrency Examples

func structuredConcurrencyExamples() async throws {
    // Parallel fetch with error handling
    async let users = fetchUsers()
    async let posts = fetchPosts()
    async let comments = fetchComments()
    
    let (allUsers, allPosts, allComments) = try await (users, posts, comments)
    
    // Task group with results
    let results = try await withThrowingTaskGroup(of: User.self) { group in
        for id in userIds {
            group.addTask {
                try await fetchUser(id: id)
            }
        }
        
        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
    
    // Task group with cancellation
    try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask {
                try await download(url)
            }
        }
        
        // Cancel all if one fails
        do {
            for try await data in group {
                process(data)
            }
        } catch {
            group.cancelAll()
            throw error
        }
    }
}

// MARK: - MainActor Examples

@MainActor
func mainActorExamples() async {
    // Already on main actor
    updateUI()
    
    // Run background work and return to main
    let data = await Task.detached {
        try? await heavyComputation()
    }.value
    
    // Update UI with result
    display(data)
}

func fromBackgroundToMain() async {
    // Explicit main actor
    await MainActor.run {
        updateUI()
    }
    
    // With priority
    await MainActor.run(priority: .userInitiated) {
        criticalUIUpdate()
    }
}

// MARK: - Cancellation Examples

func cancellationExamples() async throws {
    // Check cancellation
    try Task.checkCancellation()
    
    // Cooperative cancellation
    for item in largeCollection {
        try Task.checkCancellation()
        await process(item)
    }
    
    // With handler
    try await withTaskCancellationHandler {
        try await longOperation()
    } onCancel: {
        // Cleanup resources
        cleanupResources()
    }
    
    // Manual cancellation
    let task = Task {
        try await veryLongOperation()
    }
    
    // Cancel after timeout
    try await Task.sleep(for: .seconds(10))
    task.cancel()
}

// MARK: - Helper Functions

func fetchData() async throws -> Data {
    try await Task.sleep(for: .milliseconds(100))
    return Data()
}

func unreliableOperation() async throws -> String {
    if Bool.random() { throw NetworkError.timeout }
    return "success"
}

func networkRequest() async throws -> Data {
    Data()
}

func performSearch(_ query: String) async {
    print("Searching: \(query)")
}

func longRunningOperation() async throws -> Data {
    try await Task.sleep(for: .seconds(5))
    return Data()
}

func cachedData() -> Data { Data() }
func fetchFreshData() async throws -> Data { Data() }
func downloadLargeFile() async throws -> Data { Data() }

func numberStream(prefix: String, count: Int) -> AsyncStream<String> {
    AsyncStream { continuation in
        for i in 1...count {
            continuation.yield("\(prefix)\(i)")
        }
        continuation.finish()
    }
}

func rapidDataStream() -> AsyncStream<Int> {
    AsyncStream { continuation in
        for i in 1...1000 {
            continuation.yield(i)
        }
        continuation.finish()
    }
}

func processChunk(_ chunk: [Int]) async {}
func download(_ url: URL) async throws -> Data { Data() }
func useExpensiveResource(_ id: Int) async throws {}
func fetchUsers() async throws -> [User] { [] }
func fetchPosts() async throws -> [Post] { [] }
func fetchComments() async throws -> [Comment] { [] }
func fetchUser(id: String) async throws -> User { User() }
func heavyComputation() async throws -> Data { Data() }
func updateUI() {}
func display(_ data: Data?) {}
func criticalUIUpdate() {}
func process(_ item: Any) async {}
func cleanupResources() {}
func veryLongOperation() async throws {}

let api = API()
let urls: [URL] = []
let userIds: [String] = []
let largeCollection: [Int] = []

struct API {
    func fetch(id: Int) async throws {}
    func fetchUser(id: String) async throws -> Data { Data() }
}

enum NetworkError: Error {
    case timeout
    case connectionFailed
    
    var isRetryable: Bool {
        switch self {
        case .timeout: return true
        case .connectionFailed: return true
        }
    }
}

struct User {}
struct Post {}
struct Comment {}
