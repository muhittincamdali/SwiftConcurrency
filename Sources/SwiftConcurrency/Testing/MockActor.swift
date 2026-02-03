// MockActor.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// A mock actor for testing async interactions.
///
/// `MockActor` records all method calls and allows configuring
/// return values and behaviors for testing.
///
/// ## Overview
///
/// Use `MockActor` to verify async interactions and control
/// behavior in unit tests.
///
/// ```swift
/// let mock = MockActor<String>()
///
/// // Configure behavior
/// await mock.whenCalled("fetchUser", return: "John")
///
/// // Use in test
/// let result = await mock.call("fetchUser")
/// XCTAssertEqual(result, "John")
///
/// // Verify calls
/// let calls = await mock.calls(to: "fetchUser")
/// XCTAssertEqual(calls.count, 1)
/// ```
///
/// ## Topics
///
/// ### Creating Mocks
/// - ``init()``
///
/// ### Configuring Behavior
/// - ``whenCalled(_:return:)``
/// - ``whenCalled(_:throw:)``
/// - ``whenCalled(_:perform:)``
///
/// ### Verification
/// - ``calls(to:)``
/// - ``wasCalled(_:)``
/// - ``callCount(_:)``
public actor MockActor<ReturnType: Sendable> {
    
    // MARK: - Types
    
    /// A recorded method call.
    public struct Call: Sendable {
        /// The method name.
        public let method: String
        /// Arguments passed (as Any).
        public let arguments: [Any]
        /// When the call occurred.
        public let timestamp: Date
        
        /// Creates a call record.
        internal init(method: String, arguments: [Any] = []) {
            self.method = method
            self.arguments = arguments
            self.timestamp = Date()
        }
    }
    
    /// Behavior configuration.
    private enum Behavior: Sendable {
        case returnValue(@Sendable () async -> ReturnType)
        case throwError(@Sendable () async -> Error)
        case custom(@Sendable ([Any]) async throws -> ReturnType)
    }
    
    // MARK: - Properties
    
    /// Recorded calls.
    private var recordedCalls: [Call] = []
    
    /// Configured behaviors.
    private var behaviors: [String: Behavior] = [:]
    
    /// Default return value.
    private var defaultReturn: ReturnType?
    
    // MARK: - Initialization
    
    /// Creates a mock actor.
    public init() {}
    
    /// Creates a mock with a default return value.
    ///
    /// - Parameter defaultReturn: Default value for unconfigured methods.
    public init(defaultReturn: ReturnType) {
        self.defaultReturn = defaultReturn
    }
    
    // MARK: - Configuration
    
    /// Configures a method to return a value.
    ///
    /// - Parameters:
    ///   - method: Method name.
    ///   - value: Value to return.
    public func whenCalled(_ method: String, return value: ReturnType) {
        behaviors[method] = .returnValue { value }
    }
    
    /// Configures a method to return a value from a closure.
    ///
    /// - Parameters:
    ///   - method: Method name.
    ///   - closure: Closure returning the value.
    public func whenCalled(
        _ method: String,
        returnUsing closure: @escaping @Sendable () async -> ReturnType
    ) {
        behaviors[method] = .returnValue(closure)
    }
    
    /// Configures a method to throw an error.
    ///
    /// - Parameters:
    ///   - method: Method name.
    ///   - error: Error to throw.
    public func whenCalled(_ method: String, throw error: Error) {
        behaviors[method] = .throwError { error }
    }
    
    /// Configures a method with custom behavior.
    ///
    /// - Parameters:
    ///   - method: Method name.
    ///   - handler: Custom handler receiving arguments.
    public func whenCalled(
        _ method: String,
        perform handler: @escaping @Sendable ([Any]) async throws -> ReturnType
    ) {
        behaviors[method] = .custom(handler)
    }
    
    /// Sets the default return value.
    ///
    /// - Parameter value: Default value for unconfigured methods.
    public func setDefaultReturn(_ value: ReturnType) {
        defaultReturn = value
    }
    
    // MARK: - Calling
    
    /// Calls a mock method.
    ///
    /// - Parameters:
    ///   - method: Method name.
    ///   - arguments: Arguments to pass.
    /// - Returns: Configured return value.
    /// - Throws: Configured error or if no behavior configured.
    public func call(_ method: String, arguments: [Any] = []) async throws -> ReturnType {
        recordedCalls.append(Call(method: method, arguments: arguments))
        
        guard let behavior = behaviors[method] else {
            if let defaultReturn = defaultReturn {
                return defaultReturn
            }
            throw MockError.noBehaviorConfigured(method)
        }
        
        switch behavior {
        case .returnValue(let closure):
            return await closure()
        case .throwError(let closure):
            throw await closure()
        case .custom(let handler):
            return try await handler(arguments)
        }
    }
    
    /// Calls a mock method without throwing.
    ///
    /// - Parameters:
    ///   - method: Method name.
    ///   - arguments: Arguments to pass.
    /// - Returns: Configured return value or default.
    public func callNoThrow(_ method: String, arguments: [Any] = []) async -> ReturnType? {
        try? await call(method, arguments: arguments)
    }
    
    // MARK: - Verification
    
    /// Returns all calls to a method.
    ///
    /// - Parameter method: Method name to filter by.
    /// - Returns: Array of calls.
    public func calls(to method: String) -> [Call] {
        recordedCalls.filter { $0.method == method }
    }
    
    /// Returns all recorded calls.
    public var allCalls: [Call] {
        recordedCalls
    }
    
    /// Checks if a method was called.
    ///
    /// - Parameter method: Method name.
    /// - Returns: `true` if called at least once.
    public func wasCalled(_ method: String) -> Bool {
        recordedCalls.contains { $0.method == method }
    }
    
    /// Returns the number of calls to a method.
    ///
    /// - Parameter method: Method name.
    /// - Returns: Call count.
    public func callCount(_ method: String) -> Int {
        recordedCalls.filter { $0.method == method }.count
    }
    
    /// Verifies a method was called exactly n times.
    ///
    /// - Parameters:
    ///   - method: Method name.
    ///   - times: Expected call count.
    /// - Returns: `true` if called exactly n times.
    public func verify(_ method: String, calledTimes times: Int) -> Bool {
        callCount(method) == times
    }
    
    /// Resets all recorded calls.
    public func reset() {
        recordedCalls.removeAll()
    }
    
    /// Resets calls and behaviors.
    public func resetAll() {
        recordedCalls.removeAll()
        behaviors.removeAll()
    }
}

/// Errors from mock operations.
public enum MockError: Error, Sendable {
    case noBehaviorConfigured(String)
}

// MARK: - Typed Mock Actor

/// A mock actor with strongly typed method calls.
public actor TypedMockActor<Input: Sendable, Output: Sendable> {
    
    /// A typed call record.
    public struct TypedCall: Sendable {
        public let input: Input
        public let timestamp: Date
    }
    
    /// Recorded calls.
    private var calls: [TypedCall] = []
    
    /// The handler for calls.
    private var handler: (@Sendable (Input) async throws -> Output)?
    
    /// Creates a typed mock actor.
    public init() {}
    
    /// Creates a typed mock with a handler.
    ///
    /// - Parameter handler: Handler for calls.
    public init(handler: @escaping @Sendable (Input) async throws -> Output) {
        self.handler = handler
    }
    
    /// Sets the handler.
    ///
    /// - Parameter handler: Handler for calls.
    public func setHandler(_ handler: @escaping @Sendable (Input) async throws -> Output) {
        self.handler = handler
    }
    
    /// Calls the mock.
    ///
    /// - Parameter input: Input value.
    /// - Returns: Output from handler.
    /// - Throws: Error from handler.
    public func call(_ input: Input) async throws -> Output {
        calls.append(TypedCall(input: input, timestamp: Date()))
        
        guard let handler = handler else {
            throw MockError.noBehaviorConfigured("call")
        }
        
        return try await handler(input)
    }
    
    /// All recorded calls.
    public var recordedCalls: [TypedCall] {
        calls
    }
    
    /// The number of calls.
    public var callCount: Int {
        calls.count
    }
    
    /// Resets recorded calls.
    public func reset() {
        calls.removeAll()
    }
}

// MARK: - Spy Actor

/// An actor that wraps another and records calls.
public actor SpyActor<Wrapped: Actor> {
    
    /// The wrapped actor.
    public let wrapped: Wrapped
    
    /// Method call log.
    private var log: [(method: String, timestamp: Date)] = []
    
    /// Creates a spy wrapping another actor.
    ///
    /// - Parameter wrapped: Actor to spy on.
    public init(wrapping wrapped: Wrapped) {
        self.wrapped = wrapped
    }
    
    /// Logs a method call.
    ///
    /// - Parameter method: Method name.
    public func logCall(_ method: String) {
        log.append((method, Date()))
    }
    
    /// Returns logged calls.
    public var calls: [(method: String, timestamp: Date)] {
        log
    }
    
    /// Resets the log.
    public func reset() {
        log.removeAll()
    }
}
