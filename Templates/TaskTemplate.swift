// TaskTemplate.swift
// SwiftConcurrency
//
// Template for creating task utilities

import Foundation

// MARK: - Task Wrapper Template

/// A template for creating reusable async task wrappers.
///
/// ## Example
///
/// ```swift
/// let task = CustomTask(configuration: .default) {
///     try await performOperation()
/// }
/// let result = try await task.execute()
/// ```
public struct CustomTask<T: Sendable>: Sendable {
    // MARK: - Configuration
    
    public struct Configuration: Sendable {
        public let timeout: Duration
        public let priority: TaskPriority?
        public let retryCount: Int
        
        public static let `default` = Configuration(
            timeout: .seconds(30),
            priority: nil,
            retryCount: 0
        )
        
        public init(
            timeout: Duration = .seconds(30),
            priority: TaskPriority? = nil,
            retryCount: Int = 0
        ) {
            self.timeout = timeout
            self.priority = priority
            self.retryCount = retryCount
        }
    }
    
    // MARK: - Properties
    
    private let configuration: Configuration
    private let operation: @Sendable () async throws -> T
    
    // MARK: - Initialization
    
    /// Creates a new custom task.
    ///
    /// - Parameters:
    ///   - configuration: Task configuration options.
    ///   - operation: The async operation to execute.
    public init(
        configuration: Configuration = .default,
        operation: @Sendable @escaping () async throws -> T
    ) {
        self.configuration = configuration
        self.operation = operation
    }
    
    // MARK: - Execution
    
    /// Executes the task and returns the result.
    ///
    /// - Returns: The operation result.
    /// - Throws: Any error from the operation, or `CancellationError`.
    public func execute() async throws -> T {
        var lastError: Error?
        
        for attempt in 0...configuration.retryCount {
            do {
                try Task.checkCancellation()
                
                let result = try await withTimeout(configuration.timeout) {
                    try await operation()
                }
                
                return result
            } catch {
                lastError = error
                
                if error is CancellationError {
                    throw error
                }
                
                if attempt < configuration.retryCount {
                    let delay = calculateBackoff(attempt: attempt)
                    try await Task.sleep(for: delay)
                }
            }
        }
        
        throw lastError ?? CancellationError()
    }
    
    // MARK: - Private Helpers
    
    private func withTimeout(
        _ timeout: Duration,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: timeout)
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw CancellationError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private func calculateBackoff(attempt: Int) -> Duration {
        let seconds = pow(2.0, Double(attempt))
        return .seconds(min(seconds, 60))
    }
}

// MARK: - Errors

public struct TimeoutError: Error, Sendable {
    public init() {}
}

// MARK: - Async Sequence Template

/// A template for creating custom async sequences.
public struct CustomAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = Iterator
    
    private let makeStream: @Sendable () -> AsyncStream<Element>
    
    public init(
        _ makeStream: @Sendable @escaping () -> AsyncStream<Element>
    ) {
        self.makeStream = makeStream
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(stream: makeStream())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        var iterator: AsyncStream<Element>.AsyncIterator
        
        init(stream: AsyncStream<Element>) {
            self.iterator = stream.makeAsyncIterator()
        }
        
        public mutating func next() async -> Element? {
            await iterator.next()
        }
    }
}

// MARK: - Actor Template

/// A template for creating custom actors.
public actor CustomActor<Value: Sendable> {
    // MARK: - Properties
    
    private var storage: [String: Value] = [:]
    private var accessCount: Int = 0
    
    // MARK: - Public Methods
    
    /// Gets a value from storage.
    public func get(_ key: String) -> Value? {
        accessCount += 1
        return storage[key]
    }
    
    /// Sets a value in storage.
    public func set(_ key: String, value: Value) {
        accessCount += 1
        storage[key] = value
    }
    
    /// Removes a value from storage.
    @discardableResult
    public func remove(_ key: String) -> Value? {
        accessCount += 1
        return storage.removeValue(forKey: key)
    }
    
    /// Clears all storage.
    public func clear() {
        accessCount += 1
        storage.removeAll()
    }
    
    /// Returns the total access count.
    public func getAccessCount() -> Int {
        accessCount
    }
    
    /// Performs an operation with the stored value.
    public func withValue<T>(
        _ key: String,
        operation: (Value?) throws -> T
    ) rethrows -> T {
        try operation(storage[key])
    }
}

// MARK: - Extension Template

extension Task where Success == Never, Failure == Never {
    /// Sleeps for the specified duration with cancellation support.
    public static func sleepWithCancellation(
        for duration: Duration
    ) async throws {
        try await withTaskCancellationHandler {
            try await Task.sleep(for: duration)
        } onCancel: {
            // Handle cancellation cleanup if needed
        }
    }
}

// MARK: - Preview / Testing

#if DEBUG
@available(iOS 16.0, macOS 13.0, *)
func testCustomTask() async {
    do {
        let task = CustomTask(
            configuration: .init(timeout: .seconds(5), retryCount: 2)
        ) {
            // Simulate async work
            try await Task.sleep(for: .seconds(1))
            return "Success"
        }
        
        let result = try await task.execute()
        print("Result: \(result)")
    } catch {
        print("Error: \(error)")
    }
}

@available(iOS 16.0, macOS 13.0, *)
func testCustomActor() async {
    let actor = CustomActor<String>()
    
    await actor.set("key1", value: "value1")
    let value = await actor.get("key1")
    print("Value: \(value ?? "nil")")
    
    let count = await actor.getAccessCount()
    print("Access count: \(count)")
}
#endif
