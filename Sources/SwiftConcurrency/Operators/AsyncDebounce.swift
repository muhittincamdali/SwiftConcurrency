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
public struct AsyncDebounceSequence<Base: AsyncSequence, C: Clock>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    private let duration: C.Duration
    private let clock: C
    
    /// Creates a debounce sequence.
    ///
    /// - Parameters:
    ///   - base: The source sequence.
    ///   - duration: Quiet period before emission.
    ///   - clock: Clock for timing.
    public init(_ base: Base, duration: C.Duration, clock: C) {
        self.base = base
        self.duration = duration
        self.clock = clock
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, duration: duration, clock: clock)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let actor: DebounceActor<Base, C>
        
        init(base: Base, duration: C.Duration, clock: C) {
            self.actor = DebounceActor(base: base, duration: duration, clock: clock)
        }
        
        public mutating func next() async -> Element? {
            await actor.next()
        }
    }
}

/// Actor managing debounce state.
private actor DebounceActor<Base: AsyncSequence, C: Clock>
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    typealias Element = Base.Element
    
    private let duration: C.Duration
    private let clock: C
    private var pendingElement: Element?
    private var lastReceived: C.Instant?
    private var iterator: Base.AsyncIterator
    private var finished = false
    
    init(base: Base, duration: C.Duration, clock: C) {
        self.duration = duration
        self.clock = clock
        self.iterator = base.makeAsyncIterator()
    }
    
    func next() async -> Element? {
        while !finished {
            // If we have a pending element, wait for quiet period
            if let pending = pendingElement, let last = lastReceived {
                let deadline = last.advanced(by: duration)
                let now = clock.now
                
                if now >= deadline {
                    // Quiet period elapsed, emit
                    pendingElement = nil
                    lastReceived = nil
                    return pending
                }
                
                // Wait for remaining time or new element
                let remaining = deadline.duration(to: now)
                
                do {
                    // Race between timer and next element
                    try await withThrowingTaskGroup(of: Element?.self) { group in
                        group.addTask {
                            try await self.clock.sleep(until: deadline)
                            return nil // Timer signal
                        }
                        
                        group.addTask {
                            try await self.iterator.next()
                        }
                        
                        if let result = try await group.next() {
                            group.cancelAll()
                            
                            if let element = result {
                                // New element arrived, update pending
                                self.pendingElement = element
                                self.lastReceived = self.clock.now
                            }
                            // Timer expired - will emit on next iteration
                        }
                    }
                } catch {
                    finished = true
                    if let pending = pendingElement {
                        pendingElement = nil
                        return pending
                    }
                    return nil
                }
            } else {
                // No pending element, wait for next
                do {
                    if let element = try await iterator.next() {
                        pendingElement = element
                        lastReceived = clock.now
                    } else {
                        finished = true
                        return nil
                    }
                } catch {
                    finished = true
                    return nil
                }
            }
        }
        
        return nil
    }
}

// MARK: - AsyncLeadingDebounceSequence

/// Debounces with leading edge emission.
///
/// Emits immediately on first element, then waits for quiet period
/// before allowing next emission.
public struct AsyncLeadingDebounceSequence<Base: AsyncSequence, C: Clock>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    private let duration: C.Duration
    private let clock: C
    
    /// Creates a leading debounce sequence.
    public init(_ base: Base, duration: C.Duration, clock: C) {
        self.base = base
        self.duration = duration
        self.clock = clock
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, duration: duration, clock: clock)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let duration: C.Duration
        private let clock: C
        private var lastEmitted: C.Instant?
        
        init(base: Base, duration: C.Duration, clock: C) {
            self.iterator = base.makeAsyncIterator()
            self.duration = duration
            self.clock = clock
        }
        
        public mutating func next() async throws -> Element? {
            while let element = try await iterator.next() {
                let now = clock.now
                
                if let last = lastEmitted {
                    let elapsed = last.duration(to: now)
                    if elapsed >= duration {
                        lastEmitted = now
                        return element
                    }
                    // Still in debounce window, skip
                } else {
                    // First element, emit immediately
                    lastEmitted = now
                    return element
                }
            }
            
            return nil
        }
    }
}

// MARK: - AsyncLeadingTrailingDebounceSequence

/// Debounces with both leading and trailing edge emission.
///
/// Emits on leading edge, then again on trailing edge after quiet period.
public struct AsyncLeadingTrailingDebounceSequence<Base: AsyncSequence, C: Clock>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    private let duration: C.Duration
    private let clock: C
    
    /// Creates a leading-trailing debounce sequence.
    public init(_ base: Base, duration: C.Duration, clock: C) {
        self.base = base
        self.duration = duration
        self.clock = clock
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, duration: duration, clock: clock)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let actor: LeadingTrailingDebounceActor<Base, C>
        
        init(base: Base, duration: C.Duration, clock: C) {
            self.actor = LeadingTrailingDebounceActor(
                base: base,
                duration: duration,
                clock: clock
            )
        }
        
        public mutating func next() async -> Element? {
            await actor.next()
        }
    }
}

/// Actor for leading-trailing debounce.
private actor LeadingTrailingDebounceActor<Base: AsyncSequence, C: Clock>
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    typealias Element = Base.Element
    
    private var iterator: Base.AsyncIterator
    private let duration: C.Duration
    private let clock: C
    
    private var pendingTrailing: Element?
    private var lastEmitted: C.Instant?
    private var finished = false
    
    init(base: Base, duration: C.Duration, clock: C) {
        self.iterator = base.makeAsyncIterator()
        self.duration = duration
        self.clock = clock
    }
    
    func next() async -> Element? {
        while !finished {
            // Check for trailing emission
            if let trailing = pendingTrailing, let last = lastEmitted {
                let now = clock.now
                let elapsed = last.duration(to: now)
                
                if elapsed >= duration {
                    pendingTrailing = nil
                    lastEmitted = now
                    return trailing
                }
            }
            
            do {
                if let element = try await iterator.next() {
                    let now = clock.now
                    
                    if let last = lastEmitted {
                        let elapsed = last.duration(to: now)
                        
                        if elapsed >= duration {
                            // Past debounce window, emit leading
                            lastEmitted = now
                            pendingTrailing = nil
                            return element
                        } else {
                            // In window, update trailing
                            pendingTrailing = element
                        }
                    } else {
                        // First element
                        lastEmitted = now
                        return element
                    }
                } else {
                    finished = true
                    
                    // Emit any pending trailing
                    if let trailing = pendingTrailing {
                        pendingTrailing = nil
                        return trailing
                    }
                }
            } catch {
                finished = true
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - AsyncTimeoutDebounceSequence

/// Debounces with a maximum wait time.
///
/// Elements are debounced but guaranteed to emit within maxWait.
public struct AsyncTimeoutDebounceSequence<Base: AsyncSequence, C: Clock>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    private let duration: C.Duration
    private let maxWait: C.Duration
    private let clock: C
    
    /// Creates a timeout debounce sequence.
    ///
    /// - Parameters:
    ///   - base: Source sequence.
    ///   - duration: Debounce duration.
    ///   - maxWait: Maximum time before forced emission.
    ///   - clock: Clock for timing.
    public init(_ base: Base, duration: C.Duration, maxWait: C.Duration, clock: C) {
        self.base = base
        self.duration = duration
        self.maxWait = maxWait
        self.clock = clock
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, duration: duration, maxWait: maxWait, clock: clock)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let actor: TimeoutDebounceActor<Base, C>
        
        init(base: Base, duration: C.Duration, maxWait: C.Duration, clock: C) {
            self.actor = TimeoutDebounceActor(
                base: base,
                duration: duration,
                maxWait: maxWait,
                clock: clock
            )
        }
        
        public mutating func next() async -> Element? {
            await actor.next()
        }
    }
}

/// Actor for timeout debounce.
private actor TimeoutDebounceActor<Base: AsyncSequence, C: Clock>
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    typealias Element = Base.Element
    
    private var iterator: Base.AsyncIterator
    private let duration: C.Duration
    private let maxWait: C.Duration
    private let clock: C
    
    private var pendingElement: Element?
    private var lastReceived: C.Instant?
    private var windowStart: C.Instant?
    private var finished = false
    
    init(base: Base, duration: C.Duration, maxWait: C.Duration, clock: C) {
        self.iterator = base.makeAsyncIterator()
        self.duration = duration
        self.maxWait = maxWait
        self.clock = clock
    }
    
    func next() async -> Element? {
        while !finished {
            let now = clock.now
            
            // Check if max wait exceeded
            if let start = windowStart, let pending = pendingElement {
                let elapsed = start.duration(to: now)
                if elapsed >= maxWait {
                    pendingElement = nil
                    windowStart = nil
                    lastReceived = nil
                    return pending
                }
            }
            
            // Check if debounce period elapsed
            if let last = lastReceived, let pending = pendingElement {
                let elapsed = last.duration(to: now)
                if elapsed >= duration {
                    pendingElement = nil
                    windowStart = nil
                    lastReceived = nil
                    return pending
                }
            }
            
            // Get next element
            do {
                if let element = try await iterator.next() {
                    let now = clock.now
                    
                    if windowStart == nil {
                        windowStart = now
                    }
                    
                    pendingElement = element
                    lastReceived = now
                } else {
                    finished = true
                    
                    if let pending = pendingElement {
                        pendingElement = nil
                        return pending
                    }
                }
            } catch {
                finished = true
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - AsyncGroupedDebounceSequence

/// Debounces and groups elements received during the debounce window.
public struct AsyncGroupedDebounceSequence<Base: AsyncSequence, C: Clock>: AsyncSequence
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    public typealias Element = [Base.Element]
    
    private let base: Base
    private let duration: C.Duration
    private let clock: C
    
    /// Creates a grouped debounce sequence.
    public init(_ base: Base, duration: C.Duration, clock: C) {
        self.base = base
        self.duration = duration
        self.clock = clock
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base, duration: duration, clock: clock)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private let actor: GroupedDebounceActor<Base, C>
        
        init(base: Base, duration: C.Duration, clock: C) {
            self.actor = GroupedDebounceActor(base: base, duration: duration, clock: clock)
        }
        
        public mutating func next() async -> Element? {
            await actor.next()
        }
    }
}

/// Actor for grouped debounce.
private actor GroupedDebounceActor<Base: AsyncSequence, C: Clock>
where Base: Sendable, Base.Element: Sendable, C: Sendable {
    
    typealias Element = [Base.Element]
    
    private var iterator: Base.AsyncIterator
    private let duration: C.Duration
    private let clock: C
    
    private var buffer: [Base.Element] = []
    private var lastReceived: C.Instant?
    private var finished = false
    
    init(base: Base, duration: C.Duration, clock: C) {
        self.iterator = base.makeAsyncIterator()
        self.duration = duration
        self.clock = clock
    }
    
    func next() async -> Element? {
        while !finished {
            // Check if debounce period elapsed
            if !buffer.isEmpty, let last = lastReceived {
                let now = clock.now
                let elapsed = last.duration(to: now)
                
                if elapsed >= duration {
                    let result = buffer
                    buffer = []
                    lastReceived = nil
                    return result
                }
            }
            
            do {
                if let element = try await iterator.next() {
                    buffer.append(element)
                    lastReceived = clock.now
                } else {
                    finished = true
                    
                    if !buffer.isEmpty {
                        let result = buffer
                        buffer = []
                        return result
                    }
                }
            } catch {
                finished = true
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - AsyncSequence Extensions

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Debounces the sequence using ContinuousClock.
    ///
    /// - Parameter duration: Quiet period before emission.
    /// - Returns: Debounced sequence.
    public func debounce(
        for duration: Duration
    ) -> AsyncDebounceSequence<Self, ContinuousClock> {
        AsyncDebounceSequence(self, duration: duration, clock: ContinuousClock())
    }
    
    /// Debounces with a custom clock.
    ///
    /// - Parameters:
    ///   - duration: Quiet period.
    ///   - clock: Clock for timing.
    public func debounce<C: Clock & Sendable>(
        for duration: C.Duration,
        clock: C
    ) -> AsyncDebounceSequence<Self, C> {
        AsyncDebounceSequence(self, duration: duration, clock: clock)
    }
    
    /// Leading-edge debounce.
    ///
    /// - Parameter duration: Minimum time between emissions.
    public func debounceLeading(
        for duration: Duration
    ) -> AsyncLeadingDebounceSequence<Self, ContinuousClock> {
        AsyncLeadingDebounceSequence(self, duration: duration, clock: ContinuousClock())
    }
    
    /// Leading and trailing edge debounce.
    ///
    /// - Parameter duration: Debounce duration.
    public func debounceLeadingTrailing(
        for duration: Duration
    ) -> AsyncLeadingTrailingDebounceSequence<Self, ContinuousClock> {
        AsyncLeadingTrailingDebounceSequence(self, duration: duration, clock: ContinuousClock())
    }
    
    /// Debounce with maximum wait time.
    ///
    /// - Parameters:
    ///   - duration: Debounce duration.
    ///   - maxWait: Maximum time before forced emission.
    public func debounce(
        for duration: Duration,
        maxWait: Duration
    ) -> AsyncTimeoutDebounceSequence<Self, ContinuousClock> {
        AsyncTimeoutDebounceSequence(
            self,
            duration: duration,
            maxWait: maxWait,
            clock: ContinuousClock()
        )
    }
    
    /// Debounce and group elements.
    ///
    /// - Parameter duration: Grouping window duration.
    public func debounceGrouped(
        for duration: Duration
    ) -> AsyncGroupedDebounceSequence<Self, ContinuousClock> {
        AsyncGroupedDebounceSequence(self, duration: duration, clock: ContinuousClock())
    }
}
