/// Runs async operations in the order they were added, with at most a fixed number running at
/// the same time.
///
/// With the default limit of 1, a `TaskQueue` runs one operation after the other. That is the
/// tool for work that must not overlap, such as writing a file or refreshing a token: an actor
/// alone does not give you that, because an actor method that awaits lets the next call start
/// before it finishes (actor reentrancy).
///
/// ```swift
/// let saves = TaskQueue()
///
/// func save(_ document: Document) {
///     saves.addOperation {
///         try await storage.write(document)   // never overlaps another write
///     }
/// }
/// ```
///
/// With a higher limit it works like `OperationQueue.maxConcurrentOperationCount` for async
/// code, for example to download at most four files at a time:
///
/// ```swift
/// let downloads = TaskQueue(maxConcurrentOperations: 4)
/// let data = try await downloads.perform { try await fetch(url) }
/// ```
///
/// - Operations start in the order they were added. With a limit of 1 each operation starts
///   after the previous one has returned or thrown.
/// - An operation that is cancelled before its turn never runs; its task throws
///   `CancellationError` and frees its place in the queue.
/// - Each operation runs in its own task, so a failing operation does not affect the others.
public final class TaskQueue: Sendable {
    private struct State {
        var nextTicket = 0
        var nextToAdmit = 0
        var running = 0
        /// Tickets admitted before their task reached `admit(_:)`.
        var admittedEarly: Set<Int> = []
        /// Tickets cancelled before their turn; skipped when their turn comes.
        var skipped: Set<Int> = []
        var waiting: [Int: CheckedContinuation<Void, any Error>] = [:]
        var cancellers: [Int: @Sendable () -> Void] = [:]
        var idleWaiters = WaiterQueue<CheckedContinuation<Void, any Error>>()
    }

    /// The largest number of operations that run at the same time.
    public let maxConcurrentOperations: Int

    private let state = Locked(State())

    /// Creates a queue.
    ///
    /// - Parameter maxConcurrentOperations: How many operations may run at the same time. The
    ///   default, 1, runs them one after the other.
    /// - Precondition: `maxConcurrentOperations` is 1 or more.
    public init(maxConcurrentOperations: Int = 1) {
        precondition(
            maxConcurrentOperations >= 1,
            "TaskQueue needs maxConcurrentOperations of 1 or more, got \(maxConcurrentOperations)"
        )
        self.maxConcurrentOperations = maxConcurrentOperations
    }

    /// The number of operations that are running.
    public var runningCount: Int {
        state.withLock { $0.running }
    }

    /// The number of operations that were added and have not finished, running ones included.
    public var operationCount: Int {
        state.withLock { $0.cancellers.count }
    }

    /// Adds an operation to the end of the queue.
    ///
    /// - Parameters:
    ///   - priority: The priority of the task that runs the operation. `nil` uses the priority of
    ///     the current task.
    ///   - operation: The work to run when its turn comes.
    /// - Returns: The task that runs the operation. Await its `value` for the result, or cancel
    ///   it to remove the operation from the queue.
    @discardableResult
    public func addOperation<Success: Sendable>(
        priority: TaskPriority? = nil,
        _ operation: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, any Error> {
        state.withLock { state in
            let ticket = state.nextTicket
            state.nextTicket += 1
            let task = Task(priority: priority) {
                defer { self.operationEnded(ticket) }
                try await self.admit(ticket)
                defer { self.releaseSlot() }
                return try await operation()
            }
            state.cancellers[ticket] = { task.cancel() }
            return task
        }
    }

    /// Adds an operation and waits for its result.
    ///
    /// Cancelling the calling task cancels the operation: it is removed from the queue if it
    /// has not started, or receives the cancellation if it is running.
    public func perform<Success: Sendable>(
        priority: TaskPriority? = nil,
        _ operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        let task = addOperation(priority: priority, operation)
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    /// Cancels every operation in the queue: waiting ones are removed, running ones receive the
    /// cancellation. Operations added afterwards run normally.
    public func cancelAll() {
        let cancellers = state.withLock { Array($0.cancellers.values) }
        for cancel in cancellers { cancel() }
    }

    /// Suspends until every operation added so far, and every operation added while waiting,
    /// has finished.
    ///
    /// - Throws: `CancellationError` when the waiting task is cancelled.
    public func waitUntilIdle() async throws {
        try Task.checkCancellation()
        let id = state.withLock { $0.idleWaiters.makeID() }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let outcome: Bool? = state.withLock { state in
                    if Task.isCancelled { return nil }
                    if state.cancellers.isEmpty { return true }
                    state.idleWaiters.append(continuation, id: id)
                    return false
                }
                switch outcome {
                case nil: continuation.resume(throwing: CancellationError())
                case true?: continuation.resume()
                case false?: break
                }
            }
        } onCancel: {
            let waiter = state.withLock { $0.idleWaiters.remove(id: id) }
            waiter?.resume(throwing: CancellationError())
        }
    }

    // MARK: - Admission

    /// Suspends until it is `ticket`'s turn and a slot is free.
    private func admit(_ ticket: Int) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                enum Outcome {
                    case run
                    case cancel(admitted: [CheckedContinuation<Void, any Error>])
                    case wait(admitted: [CheckedContinuation<Void, any Error>])
                }
                let outcome: Outcome = state.withLock { state in
                    if state.admittedEarly.remove(ticket) != nil {
                        guard Task.isCancelled else { return .run }
                        state.running -= 1
                        return .cancel(admitted: Self.admitNext(&state, limit: maxConcurrentOperations))
                    }
                    if Task.isCancelled {
                        state.skipped.insert(ticket)
                        return .cancel(admitted: Self.admitNext(&state, limit: maxConcurrentOperations))
                    }
                    state.waiting[ticket] = continuation
                    return .wait(admitted: Self.admitNext(&state, limit: maxConcurrentOperations))
                }
                switch outcome {
                case .run:
                    continuation.resume()
                case .cancel(let admitted):
                    continuation.resume(throwing: CancellationError())
                    for next in admitted { next.resume() }
                case .wait(let admitted):
                    // `admitted` can contain `continuation` itself when it is this ticket's turn.
                    for next in admitted { next.resume() }
                }
            }
        } onCancel: {
            let cancelled: CheckedContinuation<Void, any Error>? = state.withLock { state in
                guard let continuation = state.waiting.removeValue(forKey: ticket) else { return nil }
                state.skipped.insert(ticket)
                return continuation
            }
            cancelled?.resume(throwing: CancellationError())
        }
    }

    private func releaseSlot() {
        let admitted = state.withLock { state in
            state.running -= 1
            return Self.admitNext(&state, limit: maxConcurrentOperations)
        }
        for next in admitted { next.resume() }
    }

    private func operationEnded(_ ticket: Int) {
        let idleWaiters = state.withLock { state -> [CheckedContinuation<Void, any Error>] in
            state.cancellers[ticket] = nil
            guard state.cancellers.isEmpty else { return [] }
            return state.idleWaiters.removeAll()
        }
        for waiter in idleWaiters { waiter.resume() }
    }

    /// Admits tickets in order while slots are free and returns the continuations to resume.
    private static func admitNext(_ state: inout State, limit: Int) -> [CheckedContinuation<Void, any Error>] {
        var ready: [CheckedContinuation<Void, any Error>] = []
        while state.running < limit, state.nextToAdmit < state.nextTicket {
            let ticket = state.nextToAdmit
            state.nextToAdmit += 1
            if state.skipped.remove(ticket) != nil { continue }
            state.running += 1
            if let continuation = state.waiting.removeValue(forKey: ticket) {
                ready.append(continuation)
            } else {
                state.admittedEarly.insert(ticket)
            }
        }
        return ready
    }
}
