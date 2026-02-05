// SendableHelpers.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - UncheckedSendableBox

/// A box that marks a non-Sendable value as Sendable.
///
/// Use with extreme caution! Only when you can guarantee
/// the wrapped value won't be accessed concurrently.
///
/// ```swift
/// let unsafeBox = UncheckedSendableBox(nonSendableObject)
/// await Task {
///     // Access with caution
///     unsafeBox.value.doSomething()
/// }
/// ```
@frozen
public struct UncheckedSendableBox<Wrapped>: @unchecked Sendable {
    /// The wrapped value.
    public var value: Wrapped
    
    /// Creates an unchecked sendable box.
    ///
    /// - Warning: The wrapped value must not be accessed from multiple
    ///   concurrent contexts. This bypasses Swift's safety checks.
    public init(_ value: Wrapped) {
        self.value = value
    }
    
    /// Creates with an autoclosure.
    public init(_ factory: @autoclosure () -> Wrapped) {
        self.value = factory()
    }
}

// MARK: - SendableValue

/// A thread-safe wrapper for any Sendable value.
///
/// Provides actor-isolated storage for values that need
/// to be safely shared across concurrent contexts.
///
/// ```swift
/// let counter = SendableValue(0)
///
/// await counter.update { $0 += 1 }
/// let count = await counter.get()
/// ```
public actor SendableValue<T: Sendable> {
    
    private var _value: T
    
    /// Creates a sendable value.
    public init(_ value: T) {
        self._value = value
    }
    
    /// Gets the current value.
    public func get() -> T {
        _value
    }
    
    /// Sets a new value.
    public func set(_ newValue: T) {
        _value = newValue
    }
    
    /// Updates the value with a transform.
    @discardableResult
    public func update(_ transform: (inout T) -> Void) -> T {
        transform(&_value)
        return _value
    }
    
    /// Updates and returns new and old value.
    public func exchange(_ newValue: T) -> T {
        let old = _value
        _value = newValue
        return old
    }
    
    /// Modifies with a throwing transform.
    public func modify<R>(_ transform: (inout T) throws -> R) rethrows -> R {
        try transform(&_value)
    }
}

// MARK: - SendableArray

/// A thread-safe array wrapper.
public actor SendableArray<Element: Sendable> {
    
    private var storage: [Element]
    
    /// Creates an empty sendable array.
    public init() {
        self.storage = []
    }
    
    /// Creates with initial elements.
    public init(_ elements: [Element]) {
        self.storage = elements
    }
    
    /// Number of elements.
    public var count: Int { storage.count }
    
    /// Whether empty.
    public var isEmpty: Bool { storage.isEmpty }
    
    /// Gets all elements.
    public func getAll() -> [Element] { storage }
    
    /// Gets element at index.
    public func get(at index: Int) -> Element? {
        guard index >= 0 && index < storage.count else { return nil }
        return storage[index]
    }
    
    /// Appends an element.
    public func append(_ element: Element) {
        storage.append(element)
    }
    
    /// Appends multiple elements.
    public func append(contentsOf elements: [Element]) {
        storage.append(contentsOf: elements)
    }
    
    /// Removes and returns the first element.
    public func removeFirst() -> Element? {
        guard !storage.isEmpty else { return nil }
        return storage.removeFirst()
    }
    
    /// Removes and returns the last element.
    public func removeLast() -> Element? {
        guard !storage.isEmpty else { return nil }
        return storage.removeLast()
    }
    
    /// Removes element at index.
    @discardableResult
    public func remove(at index: Int) -> Element? {
        guard index >= 0 && index < storage.count else { return nil }
        return storage.remove(at: index)
    }
    
    /// Removes all elements.
    public func removeAll() {
        storage.removeAll()
    }
    
    /// Filters elements.
    public func filter(_ isIncluded: (Element) -> Bool) -> [Element] {
        storage.filter(isIncluded)
    }
    
    /// Maps elements.
    public func map<T: Sendable>(_ transform: (Element) -> T) -> [T] {
        storage.map(transform)
    }
    
    /// First element matching predicate.
    public func first(where predicate: (Element) -> Bool) -> Element? {
        storage.first(where: predicate)
    }
    
    /// Removes elements matching predicate.
    public func removeAll(where shouldRemove: (Element) -> Bool) {
        storage.removeAll(where: shouldRemove)
    }
}

// MARK: - SendableDictionary

/// A thread-safe dictionary wrapper.
public actor SendableDictionary<Key: Hashable & Sendable, Value: Sendable> {
    
    private var storage: [Key: Value]
    
    /// Creates an empty sendable dictionary.
    public init() {
        self.storage = [:]
    }
    
    /// Creates with initial values.
    public init(_ dictionary: [Key: Value]) {
        self.storage = dictionary
    }
    
    /// Number of key-value pairs.
    public var count: Int { storage.count }
    
    /// Whether empty.
    public var isEmpty: Bool { storage.isEmpty }
    
    /// All keys.
    public var keys: [Key] { Array(storage.keys) }
    
    /// All values.
    public var values: [Value] { Array(storage.values) }
    
    /// Gets value for key.
    public func get(_ key: Key) -> Value? {
        storage[key]
    }
    
    /// Gets value for key or returns default.
    public func get(_ key: Key, default defaultValue: Value) -> Value {
        storage[key] ?? defaultValue
    }
    
    /// Sets value for key.
    public func set(_ key: Key, to value: Value) {
        storage[key] = value
    }
    
    /// Removes value for key.
    @discardableResult
    public func remove(_ key: Key) -> Value? {
        storage.removeValue(forKey: key)
    }
    
    /// Removes all values.
    public func removeAll() {
        storage.removeAll()
    }
    
    /// Updates value with transform.
    public func update(_ key: Key, transform: (Value?) -> Value?) {
        storage[key] = transform(storage[key])
    }
    
    /// Gets all key-value pairs.
    public func getAll() -> [Key: Value] {
        storage
    }
    
    /// Checks if key exists.
    public func contains(_ key: Key) -> Bool {
        storage[key] != nil
    }
    
    /// Merges another dictionary.
    public func merge(_ other: [Key: Value]) {
        storage.merge(other) { _, new in new }
    }
}

// MARK: - SendableSet

/// A thread-safe set wrapper.
public actor SendableSet<Element: Hashable & Sendable> {
    
    private var storage: Set<Element>
    
    /// Creates an empty sendable set.
    public init() {
        self.storage = []
    }
    
    /// Creates with initial elements.
    public init(_ elements: Set<Element>) {
        self.storage = elements
    }
    
    /// Number of elements.
    public var count: Int { storage.count }
    
    /// Whether empty.
    public var isEmpty: Bool { storage.isEmpty }
    
    /// Checks if element is contained.
    public func contains(_ element: Element) -> Bool {
        storage.contains(element)
    }
    
    /// Inserts an element.
    @discardableResult
    public func insert(_ element: Element) -> Bool {
        storage.insert(element).inserted
    }
    
    /// Removes an element.
    @discardableResult
    public func remove(_ element: Element) -> Element? {
        storage.remove(element)
    }
    
    /// Removes all elements.
    public func removeAll() {
        storage.removeAll()
    }
    
    /// Gets all elements.
    public func getAll() -> Set<Element> {
        storage
    }
    
    /// Filters elements.
    public func filter(_ isIncluded: (Element) -> Bool) -> Set<Element> {
        storage.filter(isIncluded)
    }
    
    /// Union with another set.
    public func union(_ other: Set<Element>) {
        storage.formUnion(other)
    }
    
    /// Intersection with another set.
    public func intersection(_ other: Set<Element>) {
        storage.formIntersection(other)
    }
}

// MARK: - SendableLazy

/// A lazy-initialized thread-safe value.
///
/// The value is computed once on first access and cached.
///
/// ```swift
/// let expensive = SendableLazy {
///     await computeExpensiveValue()
/// }
///
/// let value = await expensive.get()
/// ```
public actor SendableLazy<T: Sendable> {
    
    private enum State {
        case uninitialized
        case initializing
        case initialized(T)
    }
    
    private var state: State = .uninitialized
    private let factory: @Sendable () async throws -> T
    private var waiters: [CheckedContinuation<T, Error>] = []
    
    /// Creates a lazy value.
    public init(_ factory: @escaping @Sendable () async throws -> T) {
        self.factory = factory
    }
    
    /// Gets the value, initializing if needed.
    public func get() async throws -> T {
        switch state {
        case .initialized(let value):
            return value
        case .initializing:
            // Wait for initialization to complete
            return try await withCheckedThrowingContinuation { continuation in
                waiters.append(continuation)
            }
        case .uninitialized:
            state = .initializing
            do {
                let value = try await factory()
                state = .initialized(value)
                
                // Resume waiters
                for waiter in waiters {
                    waiter.resume(returning: value)
                }
                waiters.removeAll()
                
                return value
            } catch {
                state = .uninitialized
                
                // Resume waiters with error
                for waiter in waiters {
                    waiter.resume(throwing: error)
                }
                waiters.removeAll()
                
                throw error
            }
        }
    }
    
    /// Checks if initialized without triggering initialization.
    public var isInitialized: Bool {
        if case .initialized = state {
            return true
        }
        return false
    }
    
    /// Resets to uninitialized state.
    public func reset() {
        state = .uninitialized
    }
}

// MARK: - SendableResult

/// A thread-safe result storage.
public actor SendableResult<Success: Sendable, Failure: Error & Sendable> {
    
    private var result: Result<Success, Failure>?
    private var waiters: [CheckedContinuation<Success, Error>] = []
    
    /// Creates an empty result storage.
    public init() {
        self.result = nil
    }
    
    /// Creates with an initial result.
    public init(_ result: Result<Success, Failure>) {
        self.result = result
    }
    
    /// Sets a success value.
    public func succeed(_ value: Success) {
        guard result == nil else { return }
        result = .success(value)
        
        for waiter in waiters {
            waiter.resume(returning: value)
        }
        waiters.removeAll()
    }
    
    /// Sets a failure.
    public func fail(_ error: Failure) {
        guard result == nil else { return }
        result = .failure(error)
        
        for waiter in waiters {
            waiter.resume(throwing: error)
        }
        waiters.removeAll()
    }
    
    /// Gets the result, waiting if not yet set.
    public func get() async throws -> Success {
        if let result = result {
            return try result.get()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    /// Checks if result is set.
    public var isSet: Bool {
        result != nil
    }
    
    /// Gets current result without waiting.
    public func current() -> Result<Success, Failure>? {
        result
    }
}

// MARK: - Sendable Closure Wrappers

/// A sendable wrapper for void closures.
public struct SendableClosure: @unchecked Sendable {
    private let closure: () -> Void
    
    /// Creates a sendable closure.
    public init(_ closure: @escaping @Sendable () -> Void) {
        self.closure = closure
    }
    
    /// Invokes the closure.
    public func callAsFunction() {
        closure()
    }
}

/// A sendable wrapper for async void closures.
public struct SendableAsyncClosure: Sendable {
    private let closure: @Sendable () async -> Void
    
    /// Creates a sendable async closure.
    public init(_ closure: @escaping @Sendable () async -> Void) {
        self.closure = closure
    }
    
    /// Invokes the closure.
    public func callAsFunction() async {
        await closure()
    }
}

/// A sendable wrapper for throwing async closures.
public struct SendableThrowingAsyncClosure<T: Sendable>: Sendable {
    private let closure: @Sendable () async throws -> T
    
    /// Creates a sendable throwing async closure.
    public init(_ closure: @escaping @Sendable () async throws -> T) {
        self.closure = closure
    }
    
    /// Invokes the closure.
    public func callAsFunction() async throws -> T {
        try await closure()
    }
}

// MARK: - AtomicCounter

/// A thread-safe counter using actor isolation.
public actor AtomicCounter {
    
    private var value: Int
    
    /// Creates a counter.
    public init(_ initialValue: Int = 0) {
        self.value = initialValue
    }
    
    /// Gets the current value.
    public func get() -> Int { value }
    
    /// Increments and returns new value.
    @discardableResult
    public func increment() -> Int {
        value += 1
        return value
    }
    
    /// Decrements and returns new value.
    @discardableResult
    public func decrement() -> Int {
        value -= 1
        return value
    }
    
    /// Adds amount and returns new value.
    @discardableResult
    public func add(_ amount: Int) -> Int {
        value += amount
        return value
    }
    
    /// Resets to initial value.
    public func reset(to newValue: Int = 0) {
        value = newValue
    }
    
    /// Atomically exchanges value.
    public func exchange(_ newValue: Int) -> Int {
        let old = value
        value = newValue
        return old
    }
    
    /// Compare and swap.
    @discardableResult
    public func compareAndSwap(expected: Int, desired: Int) -> Bool {
        if value == expected {
            value = desired
            return true
        }
        return false
    }
}

// MARK: - AtomicFlag

/// A thread-safe boolean flag.
public actor AtomicFlag {
    
    private var flag: Bool
    
    /// Creates a flag.
    public init(_ initialValue: Bool = false) {
        self.flag = initialValue
    }
    
    /// Gets the current value.
    public func get() -> Bool { flag }
    
    /// Sets the flag.
    public func set(_ value: Bool) {
        flag = value
    }
    
    /// Toggles and returns new value.
    @discardableResult
    public func toggle() -> Bool {
        flag.toggle()
        return flag
    }
    
    /// Sets to true and returns old value.
    public func testAndSet() -> Bool {
        let old = flag
        flag = true
        return old
    }
    
    /// Sets to false and returns old value.
    public func testAndClear() -> Bool {
        let old = flag
        flag = false
        return old
    }
}
