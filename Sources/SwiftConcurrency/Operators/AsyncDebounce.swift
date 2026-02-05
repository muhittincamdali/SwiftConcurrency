// AsyncDebounce.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - AsyncDebounceSequence

/// Debounces an async sequence, emitting only after a quiet period.
///
/// When an element arrives, waits for the specified duration. If no new
/// elements arrive during that time, emits the element. If a new element
/// arrives, restarts the timer with the new element.
///
/// ```swift
/// let searchQueries = AsyncStream<String> { ... }
/// let debouncedQueries = searchQueries.debounce(for: .milliseconds(300))
/// for await query in debouncedQueries {
///     await performSearch(query)
/// }
/// ```
public struct AsyncDebounceSequence<Base: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    private let duration: Duration
    
    /// Creates a debounce sequence.
    ///
    /// - Parameters:
    ///   - base: The source sequence.
    ///   - duration: Quiet period before emission.
    public init(_ base: Base, duration: Duration) {
        self.base = base
        self.duration = duration
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeAsyncIterator(), duration: duration)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private let duration: Duration
        private var pendingElement: Element?
        private var lastReceived: ContinuousClock.Instant?
        private var finished = false
        
        init(base: Base.AsyncIterator, duration: Duration) {
            self.baseIterator = base
            self.duration = duration
        }
        
        public mutating func next() async -> Element? {
            while !finished {
                // If we have a pending element and enough time has passed, emit it
                if let pending = pendingElement, let last = lastReceived {
                    let elapsed = ContinuousClock.now - last
                    if elapsed >= duration {
                        pendingElement = nil
                        lastReceived = nil
                        return pending
                    }
                    
                    // Wait for remaining time
                    let remaining = duration - elapsed
                    do {
                        try await Task.sleep(for: remaining)
                        // After sleep, emit if still pending
                        if let p = pendingElement {
                            pendingElement = nil
                            lastReceived = nil
                            return p
                        }
                    } catch {
                        finished = true
                        return pendingElement
                    }
                }
                
                // Get next element
                do {
                    if let element = try await baseIterator.next() {
                        pendingElement = element
                        lastReceived = ContinuousClock.now
                    } else {
                        finished = true
                        return pendingElement
                    }
                } catch {
                    finished = true
                    return nil
                }
            }
            
            return nil
        }
    }
}

// MARK: - AsyncThrottleSequence

/// Throttles an async sequence, limiting emission rate.
///
/// Emits at most one element per interval.
public struct AsyncThrottleSequence<Base: AsyncSequence>: AsyncSequence
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    private let interval: Duration
    private let latest: Bool
    
    /// Creates a throttle sequence.
    ///
    /// - Parameters:
    ///   - base: The source sequence.
    ///   - interval: Minimum time between emissions.
    ///   - latest: If true, emit latest value; if false, emit first.
    public init(_ base: Base, interval: Duration, latest: Bool = true) {
        self.base = base
        self.interval = interval
        self.latest = latest
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeAsyncIterator(), interval: interval, latest: latest)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var baseIterator: Base.AsyncIterator
        private let interval: Duration
        private let latest: Bool
        private var lastEmitted: ContinuousClock.Instant?
        
        init(base: Base.AsyncIterator, interval: Duration, latest: Bool) {
            self.baseIterator = base
            self.interval = interval
            self.latest = latest
        }
        
        public mutating func next() async -> Element? {
            while true {
                do {
                    guard let element = try await baseIterator.next() else {
                        return nil
                    }
                    
                    let now = ContinuousClock.now
                    
                    if let last = lastEmitted {
                        let elapsed = now - last
                        if elapsed >= interval {
                            lastEmitted = now
                            return element
                        }
                        // Skip this element (throttled)
                    } else {
                        // First element
                        lastEmitted = now
                        return element
                    }
                } catch {
                    return nil
                }
            }
        }
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Debounces the sequence.
    ///
    /// - Parameter duration: Quiet period before emission.
    /// - Returns: Debounced sequence.
    public func debounce(
        for duration: Duration
    ) -> AsyncDebounceSequence<Self> {
        AsyncDebounceSequence(self, duration: duration)
    }
    
    /// Throttles the sequence.
    ///
    /// - Parameters:
    ///   - interval: Minimum time between emissions.
    ///   - latest: If true, emit latest value; if false, emit first.
    /// - Returns: Throttled sequence.
    public func throttle(
        for interval: Duration,
        latest: Bool = true
    ) -> AsyncThrottleSequence<Self> {
        AsyncThrottleSequence(self, interval: interval, latest: latest)
    }
}

// MARK: - Debouncer

/// A debouncer for non-sequence use cases.
///
/// ```swift
/// let debouncer = Debouncer<String>(delay: .milliseconds(300)) { query in
///     await performSearch(query)
/// }
///
/// debouncer.send("h")
/// debouncer.send("he")
/// debouncer.send("hel")
/// debouncer.send("hell")
/// debouncer.send("hello")
/// // Only "hello" triggers the action
/// ```
public actor Debouncer<Input: Sendable> {
    
    private let delay: Duration
    private let action: @Sendable (Input) async -> Void
    private var pendingTask: Task<Void, Never>?
    private var pendingInput: Input?
    
    /// Creates a debouncer.
    ///
    /// - Parameters:
    ///   - delay: Debounce delay.
    ///   - action: Action to perform after debounce.
    public init(
        delay: Duration,
        action: @escaping @Sendable (Input) async -> Void
    ) {
        self.delay = delay
        self.action = action
    }
    
    /// Sends an input to be debounced.
    public func send(_ input: Input) {
        pendingInput = input
        pendingTask?.cancel()
        
        pendingTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await Task.sleep(for: self.delay)
                if let input = await self.pendingInput {
                    await self.action(input)
                    await self.clearPending()
                }
            } catch {
                // Cancelled
            }
        }
    }
    
    /// Executes immediately without waiting.
    public func flush() async {
        pendingTask?.cancel()
        if let input = pendingInput {
            pendingInput = nil
            await action(input)
        }
    }
    
    /// Cancels any pending execution.
    public func cancel() {
        pendingTask?.cancel()
        pendingInput = nil
    }
    
    private func clearPending() {
        pendingInput = nil
    }
}

// MARK: - Throttler

/// A throttler for non-sequence use cases.
public actor Throttler<Input: Sendable> {
    
    private let interval: Duration
    private let action: @Sendable (Input) async -> Void
    private var lastExecuted: ContinuousClock.Instant?
    private var pendingInput: Input?
    private var pendingTask: Task<Void, Never>?
    
    /// Creates a throttler.
    public init(
        interval: Duration,
        action: @escaping @Sendable (Input) async -> Void
    ) {
        self.interval = interval
        self.action = action
    }
    
    /// Sends an input to be throttled.
    public func send(_ input: Input) async {
        let now = ContinuousClock.now
        
        if let last = lastExecuted {
            let elapsed = now - last
            if elapsed >= interval {
                lastExecuted = now
                await action(input)
            } else {
                // Schedule for later
                pendingInput = input
                if pendingTask == nil {
                    let remaining = interval - elapsed
                    pendingTask = Task { [weak self] in
                        guard let self = self else { return }
                        do {
                            try await Task.sleep(for: remaining)
                            await self.executeAndClear()
                        } catch {
                            // Cancelled
                        }
                    }
                }
            }
        } else {
            lastExecuted = now
            await action(input)
        }
    }
    
    private func clearPending() {
        pendingInput = nil
        pendingTask = nil
    }
    
    private func executeAndClear() async {
        if let input = pendingInput {
            lastExecuted = .now
            await action(input)
            clearPending()
        }
    }
}
