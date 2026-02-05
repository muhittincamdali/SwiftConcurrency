// StateActor.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - StateActor

/// A generic actor for managing state with subscriptions and snapshots.
///
/// Provides thread-safe state management with the ability to subscribe
/// to changes, take snapshots, and perform transactional updates.
///
/// ```swift
/// struct AppState: Equatable, Sendable {
///     var count: Int = 0
///     var user: User?
/// }
///
/// let store = StateActor(initialState: AppState())
///
/// // Subscribe to changes
/// for await state in await store.subscribe() {
///     print("Count: \(state.count)")
/// }
///
/// // Update state
/// await store.update { state in
///     state.count += 1
/// }
/// ```
public actor StateActor<State: Sendable> {
    
    // MARK: - Types
    
    /// A change event containing old and new state.
    public struct StateChange: Sendable {
        public let oldState: State
        public let newState: State
        public let timestamp: ContinuousClock.Instant
        
        init(old: State, new: State) {
            self.oldState = old
            self.newState = new
            self.timestamp = .now
        }
    }
    
    /// Options for state updates.
    public struct UpdateOptions: Sendable {
        /// Whether to notify subscribers.
        public let notifySubscribers: Bool
        
        /// Whether to record in history.
        public let recordHistory: Bool
        
        /// Creates update options.
        public init(notifySubscribers: Bool = true, recordHistory: Bool = true) {
            self.notifySubscribers = notifySubscribers
            self.recordHistory = recordHistory
        }
        
        /// Default options.
        public static var `default`: UpdateOptions { UpdateOptions() }
        
        /// Silent update (no notifications).
        public static var silent: UpdateOptions {
            UpdateOptions(notifySubscribers: false, recordHistory: true)
        }
    }
    
    // MARK: - Properties
    
    /// Current state.
    private var state: State
    
    /// Subscribers to state changes.
    private var subscribers: [UUID: AsyncStream<State>.Continuation] = [:]
    
    /// Change subscribers.
    private var changeSubscribers: [UUID: AsyncStream<StateChange>.Continuation] = [:]
    
    /// State history for undo support.
    private var history: [State] = []
    
    /// Maximum history size.
    private let maxHistorySize: Int
    
    /// Current history index (for undo/redo).
    private var historyIndex: Int = -1
    
    // MARK: - Initialization
    
    /// Creates a state actor.
    ///
    /// - Parameters:
    ///   - initialState: Initial state value.
    ///   - maxHistorySize: Maximum history entries to keep.
    public init(initialState: State, maxHistorySize: Int = 100) {
        self.state = initialState
        self.maxHistorySize = maxHistorySize
    }
    
    // MARK: - State Access
    
    /// Gets the current state.
    public var currentState: State {
        state
    }
    
    /// Gets a property from the state.
    ///
    /// - Parameter keyPath: Key path to the property.
    /// - Returns: The property value.
    public func get<T>(_ keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }
    
    /// Gets the state with a selector.
    ///
    /// - Parameter selector: Function to extract a value.
    /// - Returns: The selected value.
    public func select<T>(_ selector: (State) -> T) -> T {
        selector(state)
    }
    
    // MARK: - State Updates
    
    /// Updates the state with a mutation closure.
    ///
    /// - Parameters:
    ///   - options: Update options.
    ///   - mutation: Closure that mutates the state.
    public func update(
        options: UpdateOptions = .default,
        _ mutation: (inout State) -> Void
    ) {
        let oldState = state
        mutation(&state)
        
        if options.recordHistory {
            recordHistory(oldState)
        }
        
        if options.notifySubscribers {
            notifySubscribers(old: oldState, new: state)
        }
    }
    
    /// Updates the state with an async mutation.
    ///
    /// - Parameters:
    ///   - options: Update options.
    ///   - mutation: Async closure that transforms the state.
    public func updateAsync(
        options: UpdateOptions = .default,
        _ mutation: (State) async -> State
    ) async {
        let oldState = state
        state = await mutation(state)
        
        if options.recordHistory {
            recordHistory(oldState)
        }
        
        if options.notifySubscribers {
            notifySubscribers(old: oldState, new: state)
        }
    }
    
    /// Sets a property value.
    ///
    /// - Parameters:
    ///   - keyPath: Key path to the property.
    ///   - value: New value.
    public func set<T>(_ keyPath: WritableKeyPath<State, T>, to value: T) {
        let oldState = state
        state[keyPath: keyPath] = value
        recordHistory(oldState)
        notifySubscribers(old: oldState, new: state)
    }
    
    /// Replaces the entire state.
    ///
    /// - Parameters:
    ///   - newState: New state value.
    ///   - options: Update options.
    public func replace(
        with newState: State,
        options: UpdateOptions = .default
    ) {
        let oldState = state
        state = newState
        
        if options.recordHistory {
            recordHistory(oldState)
        }
        
        if options.notifySubscribers {
            notifySubscribers(old: oldState, new: state)
        }
    }
    
    /// Performs a transactional update.
    ///
    /// If the operation throws, the state is rolled back.
    ///
    /// - Parameter operation: Operation that may modify state.
    /// - Returns: The operation result.
    public func transaction<T>(
        _ operation: (inout State) throws -> T
    ) rethrows -> T {
        let snapshot = state
        
        do {
            let result = try operation(&state)
            recordHistory(snapshot)
            notifySubscribers(old: snapshot, new: state)
            return result
        } catch {
            state = snapshot
            throw error
        }
    }
    
    // MARK: - Subscriptions
    
    /// Subscribes to state changes.
    ///
    /// - Returns: An async stream of state values.
    public func subscribe() -> AsyncStream<State> {
        let id = UUID()
        
        return AsyncStream { continuation in
            // Send current state immediately
            continuation.yield(state)
            
            // Store for future updates
            subscribers[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeSubscriber(id: id)
                }
            }
        }
    }
    
    /// Subscribes to state changes with change events.
    ///
    /// - Returns: An async stream of state changes.
    public func subscribeToChanges() -> AsyncStream<StateChange> {
        let id = UUID()
        
        return AsyncStream { continuation in
            changeSubscribers[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeChangeSubscriber(id: id)
                }
            }
        }
    }
    
    /// Subscribes to a specific property.
    ///
    /// - Parameter keyPath: Key path to observe.
    /// - Returns: An async stream of property values.
    public func subscribe<T: Equatable>(
        to keyPath: KeyPath<State, T>
    ) -> AsyncStream<T> where State: Equatable {
        var lastValue = state[keyPath: keyPath]
        
        return AsyncStream { continuation in
            // Send current value
            continuation.yield(lastValue)
            
            Task { [weak self] in
                guard let self = self else { return }
                for await newState in await self.subscribe() {
                    let newValue = newState[keyPath: keyPath]
                    if newValue != lastValue {
                        lastValue = newValue
                        continuation.yield(newValue)
                    }
                }
            }
        }
    }
    
    // MARK: - History
    
    /// Undoes the last state change.
    ///
    /// - Returns: `true` if undo was successful.
    @discardableResult
    public func undo() -> Bool {
        guard !history.isEmpty, historyIndex >= 0 else {
            return false
        }
        
        let oldState = state
        state = history[historyIndex]
        historyIndex -= 1
        
        notifySubscribers(old: oldState, new: state)
        return true
    }
    
    /// Redoes the last undone change.
    ///
    /// - Returns: `true` if redo was successful.
    @discardableResult
    public func redo() -> Bool {
        guard historyIndex < history.count - 1 else {
            return false
        }
        
        historyIndex += 1
        let oldState = state
        state = history[historyIndex]
        
        notifySubscribers(old: oldState, new: state)
        return true
    }
    
    /// Whether undo is available.
    public var canUndo: Bool {
        !history.isEmpty && historyIndex >= 0
    }
    
    /// Whether redo is available.
    public var canRedo: Bool {
        historyIndex < history.count - 1
    }
    
    /// Clears the history.
    public func clearHistory() {
        history.removeAll()
        historyIndex = -1
    }
    
    /// Takes a snapshot of the current state.
    public func snapshot() -> State {
        state
    }
    
    /// Restores from a snapshot.
    ///
    /// - Parameter snapshot: State to restore.
    public func restore(from snapshot: State) {
        let oldState = state
        state = snapshot
        recordHistory(oldState)
        notifySubscribers(old: oldState, new: state)
    }
    
    // MARK: - Private Methods
    
    private func recordHistory(_ oldState: State) {
        // Remove any redo history
        if historyIndex < history.count - 1 {
            history.removeLast(history.count - historyIndex - 1)
        }
        
        history.append(oldState)
        historyIndex = history.count - 1
        
        // Trim if over limit
        if history.count > maxHistorySize {
            history.removeFirst()
            historyIndex -= 1
        }
    }
    
    private func notifySubscribers(old: State, new: State) {
        // Notify state subscribers
        for (_, continuation) in subscribers {
            continuation.yield(new)
        }
        
        // Notify change subscribers
        let change = StateChange(old: old, new: new)
        for (_, continuation) in changeSubscribers {
            continuation.yield(change)
        }
    }
    
    private func removeSubscriber(id: UUID) {
        subscribers.removeValue(forKey: id)
    }
    
    private func removeChangeSubscriber(id: UUID) {
        changeSubscribers.removeValue(forKey: id)
    }
}

// MARK: - Derived State

extension StateActor {
    
    /// Creates a derived state actor that transforms this state.
    ///
    /// - Parameter transform: Transformation function.
    /// - Returns: A new state actor with derived state.
    public func derived<DerivedState: Sendable>(
        _ transform: @escaping @Sendable (State) -> DerivedState
    ) -> DerivedStateActor<State, DerivedState> {
        DerivedStateActor(source: self, transform: transform)
    }
}

// MARK: - DerivedStateActor

/// An actor that derives its state from another state actor.
public actor DerivedStateActor<SourceState: Sendable, DerivedState: Sendable> {
    
    // MARK: - Properties
    
    private let source: StateActor<SourceState>
    private let transform: @Sendable (SourceState) -> DerivedState
    private var subscribers: [UUID: AsyncStream<DerivedState>.Continuation] = [:]
    
    // MARK: - Initialization
    
    init(source: StateActor<SourceState>, transform: @escaping @Sendable (SourceState) -> DerivedState) {
        self.source = source
        self.transform = transform
    }
    
    // MARK: - Public Methods
    
    /// Current derived state.
    public var currentState: DerivedState {
        get async {
            transform(await source.currentState)
        }
    }
    
    /// Subscribes to derived state changes.
    public func subscribe() -> AsyncStream<DerivedState> {
        let transform = self.transform
        let sourceStream = Task { await source.subscribe() }
        
        return AsyncStream { continuation in
            Task {
                for await sourceState in await sourceStream.value {
                    continuation.yield(transform(sourceState))
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - StateActor + Equatable

extension StateActor where State: Equatable {
    
    /// Updates only if the new state differs.
    ///
    /// - Parameter mutation: Mutation closure.
    /// - Returns: `true` if state changed.
    @discardableResult
    public func updateIfChanged(_ mutation: (inout State) -> Void) -> Bool {
        let oldState = state
        mutation(&state)
        
        if state != oldState {
            recordHistory(oldState)
            notifySubscribers(old: oldState, new: state)
            return true
        }
        
        return false
    }
}

// MARK: - CompositeStateActor

/// Combines multiple state actors into a composite state.
public actor CompositeStateActor<A: Sendable, B: Sendable> {
    
    // MARK: - Properties
    
    private let stateA: StateActor<A>
    private let stateB: StateActor<B>
    
    // MARK: - Initialization
    
    /// Creates a composite state actor.
    public init(a: StateActor<A>, b: StateActor<B>) {
        self.stateA = a
        self.stateB = b
    }
    
    // MARK: - Public Methods
    
    /// Current combined state.
    public var currentState: (A, B) {
        get async {
            (await stateA.currentState, await stateB.currentState)
        }
    }
    
    /// Subscribes to combined state changes.
    public func subscribe() -> AsyncStream<(A, B)> {
        let capturedStateA = stateA
        let capturedStateB = stateB
        
        return AsyncStream { continuation in
            Task {
                var latestA = await capturedStateA.currentState
                var latestB = await capturedStateB.currentState
                
                continuation.yield((latestA, latestB))
                
                // Use separate tasks instead of async let in task group
                let streamA = await capturedStateA.subscribe()
                let streamB = await capturedStateB.subscribe()
                
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for await a in streamA {
                            latestA = a
                            continuation.yield((latestA, latestB))
                        }
                    }
                    
                    group.addTask {
                        for await b in streamB {
                            latestB = b
                            continuation.yield((latestA, latestB))
                        }
                    }
                }
                
                continuation.finish()
            }
        }
    }
}

// MARK: - MiddlewareStateActor

/// A state actor with middleware support.
public actor MiddlewareStateActor<State: Sendable, Action: Sendable> {
    
    // MARK: - Types
    
    /// Middleware function type.
    public typealias Middleware = @Sendable (
        _ state: State,
        _ action: Action,
        _ next: @Sendable (Action) async -> Void
    ) async -> Void
    
    /// Reducer function type.
    public typealias Reducer = @Sendable (inout State, Action) -> Void
    
    // MARK: - Properties
    
    private var state: State
    private let reducer: Reducer
    private var middlewares: [Middleware] = []
    private var subscribers: [UUID: AsyncStream<State>.Continuation] = [:]
    
    // MARK: - Initialization
    
    /// Creates a middleware state actor.
    ///
    /// - Parameters:
    ///   - initialState: Initial state.
    ///   - reducer: Function to apply actions to state.
    public init(initialState: State, reducer: @escaping Reducer) {
        self.state = initialState
        self.reducer = reducer
    }
    
    // MARK: - Public Methods
    
    /// Adds middleware.
    ///
    /// - Parameter middleware: Middleware to add.
    public func addMiddleware(_ middleware: @escaping Middleware) {
        middlewares.append(middleware)
    }
    
    /// Current state.
    public var currentState: State {
        state
    }
    
    /// Dispatches an action.
    ///
    /// - Parameter action: Action to dispatch.
    public func dispatch(_ action: Action) async {
        await runMiddlewares(action: action, index: 0)
    }
    
    /// Subscribes to state changes.
    public func subscribe() -> AsyncStream<State> {
        let id = UUID()
        
        return AsyncStream { continuation in
            continuation.yield(state)
            subscribers[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeSubscriber(id: id)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func runMiddlewares(action: Action, index: Int) async {
        if index >= middlewares.count {
            // Apply action
            let oldState = state
            reducer(&state, action)
            
            for (_, continuation) in subscribers {
                continuation.yield(state)
            }
        } else {
            await middlewares[index](state, action) { [self] nextAction in
                await runMiddlewares(action: nextAction, index: index + 1)
            }
        }
    }
    
    private func removeSubscriber(id: UUID) {
        subscribers.removeValue(forKey: id)
    }
}
