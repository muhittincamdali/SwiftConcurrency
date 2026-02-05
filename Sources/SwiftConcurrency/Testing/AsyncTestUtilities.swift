// AsyncTestUtilities.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncExpectation

/// An expectation for async tests.
///
/// Similar to XCTestExpectation but designed for async/await.
///
/// ```swift
/// let expectation = AsyncExpectation(description: "Data loaded")
///
/// Task {
///     await loadData()
///     await expectation.fulfill()
/// }
///
/// try await expectation.wait(timeout: .seconds(5))
/// ```
public actor AsyncExpectation {
    
    /// Error thrown when expectation times out.
    public struct TimeoutError: Error, Sendable {
        public let description: String
        public let timeout: Duration
    }
    
    // MARK: - Properties
    
    /// Description of the expectation.
    public let description: String
    
    /// Number of times to expect fulfillment.
    public let expectedFulfillmentCount: Int
    
    /// Whether inverted (should not fulfill).
    public let isInverted: Bool
    
    private var fulfillmentCount = 0
    private var waiters: [CheckedContinuation<Void, Error>] = []
    private var isFulfilled = false
    
    // MARK: - Initialization
    
    /// Creates an expectation.
    ///
    /// - Parameters:
    ///   - description: Description for debugging.
    ///   - expectedCount: Expected fulfillment count.
    ///   - isInverted: If true, fails if fulfilled.
    public init(
        description: String,
        expectedFulfillmentCount: Int = 1,
        isInverted: Bool = false
    ) {
        self.description = description
        self.expectedFulfillmentCount = expectedFulfillmentCount
        self.isInverted = isInverted
    }
    
    // MARK: - Fulfillment
    
    /// Fulfills the expectation.
    public func fulfill() {
        fulfillmentCount += 1
        
        if fulfillmentCount >= expectedFulfillmentCount {
            isFulfilled = true
            
            if !isInverted {
                for waiter in waiters {
                    waiter.resume()
                }
                waiters.removeAll()
            }
        }
    }
    
    /// Checks if fulfilled.
    public var fulfilled: Bool {
        isFulfilled
    }
    
    /// Current fulfillment count.
    public var currentFulfillmentCount: Int {
        fulfillmentCount
    }
    
    // MARK: - Waiting
    
    /// Waits for fulfillment.
    ///
    /// - Parameter timeout: Maximum wait time.
    /// - Throws: `TimeoutError` if not fulfilled in time.
    public func wait(timeout: Duration = .seconds(10)) async throws {
        if isFulfilled && !isInverted {
            return
        }
        
        // Poll-based wait to avoid actor isolation issues
        let deadline = ContinuousClock.now.advanced(by: timeout)
        let checkInterval = Duration.milliseconds(10)
        
        while ContinuousClock.now < deadline {
            if isFulfilled {
                if isInverted {
                    throw InvertedExpectationError(description: description)
                }
                return
            }
            try await Task.sleep(for: checkInterval)
        }
        
        // Final check
        if isFulfilled {
            if isInverted {
                throw InvertedExpectationError(description: description)
            }
            return
        }
        
        throw TimeoutError(description: description, timeout: timeout)
    }
    
    /// Error for inverted expectations that were fulfilled.
    public struct InvertedExpectationError: Error, Sendable {
        public let description: String
    }
}

// MARK: - AsyncAssertions

/// Assertions for async tests.
public enum AsyncAssert {
    
    /// Asserts a condition is true.
    public static func isTrue(
        _ condition: @autoclosure () async throws -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let result = try await condition()
        if !result {
            throw AssertionError(
                message: message().isEmpty ? "Expected true but got false" : message(),
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts a condition is false.
    public static func isFalse(
        _ condition: @autoclosure () async throws -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let result = try await condition()
        if result {
            throw AssertionError(
                message: message().isEmpty ? "Expected false but got true" : message(),
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts two values are equal.
    public static func areEqual<T: Equatable & Sendable>(
        _ lhs: @autoclosure () async throws -> T,
        _ rhs: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let lhsValue = try await lhs()
        let rhsValue = try await rhs()
        if lhsValue != rhsValue {
            throw AssertionError(
                message: message().isEmpty ? "Expected \(lhsValue) == \(rhsValue)" : message(),
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts two values are not equal.
    public static func areNotEqual<T: Equatable & Sendable>(
        _ lhs: @autoclosure () async throws -> T,
        _ rhs: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let lhsValue = try await lhs()
        let rhsValue = try await rhs()
        if lhsValue == rhsValue {
            throw AssertionError(
                message: message().isEmpty ? "Expected \(lhsValue) != \(rhsValue)" : message(),
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts a value is nil.
    public static func isNil<T: Sendable>(
        _ value: @autoclosure () async throws -> T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let result = try await value()
        if result != nil {
            throw AssertionError(
                message: message().isEmpty ? "Expected nil but got \(result!)" : message(),
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts a value is not nil.
    @discardableResult
    public static func isNotNil<T: Sendable>(
        _ value: @autoclosure () async throws -> T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        let result = try await value()
        guard let unwrapped = result else {
            throw AssertionError(
                message: message().isEmpty ? "Expected non-nil value" : message(),
                file: file,
                line: line
            )
        }
        return unwrapped
    }
    
    /// Asserts an operation throws.
    public static func throwsError<T: Sendable>(
        _ operation: () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        do {
            _ = try await operation()
            throw AssertionError(
                message: message().isEmpty ? "Expected error but operation succeeded" : message(),
                file: file,
                line: line
            )
        } catch is AssertionError {
            throw AssertionError(
                message: message().isEmpty ? "Expected error but operation succeeded" : message(),
                file: file,
                line: line
            )
        } catch {
            // Expected
        }
    }
    
    /// Asserts an operation throws a specific error type.
    @discardableResult
    public static func throwsError<T: Sendable, E: Error>(
        ofType type: E.Type,
        _ operation: () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> E {
        do {
            _ = try await operation()
            throw AssertionError(
                message: message().isEmpty ? "Expected \(type) but operation succeeded" : message(),
                file: file,
                line: line
            )
        } catch let error as E {
            return error
        } catch {
            throw AssertionError(
                message: message().isEmpty ? "Expected \(type) but got \(Swift.type(of: error))" : message(),
                file: file,
                line: line
            )
        }
    }
    
    /// Asserts an operation does not throw.
    @discardableResult
    public static func noThrow<T: Sendable>(
        _ operation: () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw AssertionError(
                message: message().isEmpty ? "Unexpected error: \(error)" : message(),
                file: file,
                line: line
            )
        }
    }
    
    /// Assertion error.
    public struct AssertionError: Error, CustomStringConvertible, Sendable {
        public let message: String
        public let file: StaticString
        public let line: UInt
        
        public var description: String {
            "Assertion failed at \(file):\(line): \(message)"
        }
    }
}

// MARK: - AsyncTestRunner

/// Runs async tests with timeout and cleanup.
public actor AsyncTestRunner {
    
    /// Test result.
    public struct Result: Sendable {
        public let name: String
        public let passed: Bool
        public let duration: Duration
        public let error: Error?
        
        var status: String {
            passed ? "✅ PASS" : "❌ FAIL"
        }
    }
    
    private var results: [Result] = []
    private let defaultTimeout: Duration
    
    /// Creates a test runner.
    public init(defaultTimeout: Duration = .seconds(30)) {
        self.defaultTimeout = defaultTimeout
    }
    
    /// Runs a test.
    @discardableResult
    public func test(
        _ name: String,
        timeout: Duration? = nil,
        _ body: @escaping @Sendable () async throws -> Void
    ) async -> Result {
        let effectiveTimeout = timeout ?? defaultTimeout
        let startTime = ContinuousClock.now
        
        var passed = false
        var testError: Error?
        
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await body()
                }
                
                group.addTask {
                    try await Task.sleep(for: effectiveTimeout)
                    throw TestTimeoutError(name: name, timeout: effectiveTimeout)
                }
                
                try await group.next()
                group.cancelAll()
            }
            passed = true
        } catch {
            testError = error
        }
        
        let result = Result(
            name: name,
            passed: passed,
            duration: ContinuousClock.now - startTime,
            error: testError
        )
        
        results.append(result)
        return result
    }
    
    /// Gets all results.
    public func getResults() -> [Result] {
        results
    }
    
    /// Generates a report.
    public func report() -> String {
        var lines: [String] = []
        lines.append("═══════════════════════════════════════════════════════════")
        lines.append("                       TEST RESULTS")
        lines.append("═══════════════════════════════════════════════════════════")
        
        let passed = results.filter { $0.passed }.count
        let failed = results.count - passed
        
        for result in results {
            let durationMs = Double(result.duration.components.seconds) * 1000 +
                            Double(result.duration.components.attoseconds) / 1_000_000_000_000_000
            var line = "\(result.status) \(result.name) (\(String(format: "%.2f", durationMs))ms)"
            if let error = result.error {
                line += "\n     Error: \(error)"
            }
            lines.append(line)
        }
        
        lines.append("───────────────────────────────────────────────────────────")
        lines.append("Total: \(results.count) | Passed: \(passed) | Failed: \(failed)")
        lines.append("═══════════════════════════════════════════════════════════")
        
        return lines.joined(separator: "\n")
    }
    
    /// Resets results.
    public func reset() {
        results.removeAll()
    }
    
    /// Test timeout error.
    public struct TestTimeoutError: Error, Sendable {
        public let name: String
        public let timeout: Duration
    }
}

// MARK: - AsyncEventRecorder

/// Records async events for testing.
///
/// ```swift
/// let recorder = AsyncEventRecorder<String>()
///
/// // In async code
/// await recorder.record("event1")
/// await recorder.record("event2")
///
/// // In test assertions
/// let events = await recorder.events
/// XCTAssertEqual(events, ["event1", "event2"])
/// ```
public actor AsyncEventRecorder<Event: Sendable> {
    
    /// Recorded event with timestamp.
    public struct RecordedEvent: Sendable {
        public let event: Event
        public let timestamp: ContinuousClock.Instant
    }
    
    private var recordedEvents: [RecordedEvent] = []
    private var eventWaiters: [((Event) -> Bool, CheckedContinuation<Event, Never>)] = []
    
    /// Creates an event recorder.
    public init() {}
    
    /// Records an event.
    public func record(_ event: Event) {
        let recorded = RecordedEvent(event: event, timestamp: .now)
        recordedEvents.append(recorded)
        
        // Check waiters
        for (index, (predicate, continuation)) in eventWaiters.enumerated().reversed() {
            if predicate(event) {
                continuation.resume(returning: event)
                eventWaiters.remove(at: index)
            }
        }
    }
    
    /// All recorded events.
    public var events: [Event] {
        recordedEvents.map { $0.event }
    }
    
    /// All recorded events with timestamps.
    public var timestampedEvents: [RecordedEvent] {
        recordedEvents
    }
    
    /// Number of events.
    public var count: Int {
        recordedEvents.count
    }
    
    /// Waits for an event matching predicate.
    public func waitFor(
        timeout: Duration = .seconds(5),
        where predicate: @escaping (Event) -> Bool
    ) async throws -> Event {
        // Check existing events
        if let existing = recordedEvents.first(where: { predicate($0.event) }) {
            return existing.event
        }
        
        // Poll-based wait
        let deadline = ContinuousClock.now.advanced(by: timeout)
        let checkInterval = Duration.milliseconds(10)
        
        while ContinuousClock.now < deadline {
            if let existing = recordedEvents.first(where: { predicate($0.event) }) {
                return existing.event
            }
            try await Task.sleep(for: checkInterval)
        }
        
        throw WaitTimeoutError()
    }
    
    /// Clears all recorded events.
    public func clear() {
        recordedEvents.removeAll()
    }
    
    /// Error when wait times out.
    public struct WaitTimeoutError: Error, Sendable {}
}

// MARK: - AsyncMock

/// A mock for async functions.
///
/// ```swift
/// let mock = AsyncMock<Int, String> { input in
///     "\(input * 2)"
/// }
///
/// let result = try await mock(5)  // "10"
/// let calls = await mock.calls    // [5]
/// ```
public actor AsyncMock<Input: Sendable, Output: Sendable> {
    
    /// A recorded call.
    public struct Call: Sendable {
        public let input: Input
        public let timestamp: ContinuousClock.Instant
    }
    
    private var implementation: @Sendable (Input) async throws -> Output
    private var recordedCalls: [Call] = []
    
    /// Creates a mock.
    public init(_ implementation: @escaping @Sendable (Input) async throws -> Output) {
        self.implementation = implementation
    }
    
    /// Creates a mock that returns a fixed value.
    public init(returning value: Output) {
        self.implementation = { _ in value }
    }
    
    /// Creates a mock that throws an error.
    public init(throwing error: Error) {
        self.implementation = { _ in throw error }
    }
    
    /// Invokes the mock.
    public func callAsFunction(_ input: Input) async throws -> Output {
        recordedCalls.append(Call(input: input, timestamp: .now))
        return try await implementation(input)
    }
    
    /// All recorded calls.
    public var calls: [Call] {
        recordedCalls
    }
    
    /// All inputs that were called with.
    public var inputs: [Input] {
        recordedCalls.map { $0.input }
    }
    
    /// Number of calls.
    public var callCount: Int {
        recordedCalls.count
    }
    
    /// Whether mock was called.
    public var wasCalled: Bool {
        !recordedCalls.isEmpty
    }
    
    /// Changes the implementation.
    public func setImplementation(_ impl: @escaping @Sendable (Input) async throws -> Output) {
        implementation = impl
    }
    
    /// Resets call history.
    public func reset() {
        recordedCalls.removeAll()
    }
}

// MARK: - AsyncSpy

/// Spies on async calls while passing through to real implementation.
public actor AsyncSpy<Input: Sendable, Output: Sendable> {
    
    private let realImplementation: @Sendable (Input) async throws -> Output
    private var recordedCalls: [(input: Input, output: Result<Output, Error>)] = []
    
    /// Creates a spy.
    public init(_ realImplementation: @escaping @Sendable (Input) async throws -> Output) {
        self.realImplementation = realImplementation
    }
    
    /// Invokes and records.
    public func callAsFunction(_ input: Input) async throws -> Output {
        do {
            let output = try await realImplementation(input)
            recordedCalls.append((input, .success(output)))
            return output
        } catch {
            recordedCalls.append((input, .failure(error)))
            throw error
        }
    }
    
    /// All recorded calls with results.
    public var calls: [(input: Input, output: Result<Output, Error>)] {
        recordedCalls
    }
    
    /// Number of calls.
    public var callCount: Int {
        recordedCalls.count
    }
    
    /// Resets.
    public func reset() {
        recordedCalls.removeAll()
    }
}
