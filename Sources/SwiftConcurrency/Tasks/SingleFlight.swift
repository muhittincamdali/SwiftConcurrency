/// Shares one running operation among all callers that ask for the same key at the same time.
///
/// When three views ask for the same user profile at once, only one request goes to the server
/// and all three get its result:
///
/// ```swift
/// let profiles = SingleFlight<User.ID, Profile>()
///
/// func profile(for id: User.ID) async throws -> Profile {
///     try await profiles.value(for: id) {
///         try await api.profile(id)
///     }
/// }
/// ```
///
/// - Only calls that overlap share work. Once the operation finishes, its result is handed to
///   the callers waiting for it and forgotten: the next call for the key starts a new operation.
///   `SingleFlight` is not a cache, and holds nothing for keys that are not in flight.
/// - A caller that is cancelled stops waiting and throws `CancellationError`; the operation
///   keeps running for the other callers. When every caller of a key has been cancelled, the
///   operation is cancelled too.
public final class SingleFlight<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    private typealias Waiter = CheckedContinuation<Value, any Error>

    private struct Flight {
        let id: UInt64
        let task: Task<Void, Never>
        var waiters: WaiterQueue<Waiter>
    }

    private struct State {
        var flights: [Key: Flight] = [:]
        var nextID: UInt64 = 0

        mutating func makeID() -> UInt64 {
            defer { nextID &+= 1 }
            return nextID
        }
    }

    private let state = Locked(State())

    public init() {}

    /// The number of keys with an operation in flight.
    public var inFlightCount: Int {
        state.withLock { $0.flights.count }
    }

    /// The number of callers waiting for the operation of `key` (for tests).
    func waiterCount(for key: Key) -> Int {
        state.withLock { $0.flights[key]?.waiters.count ?? 0 }
    }

    /// Returns the result of the operation in flight for `key`, starting `operation` when there
    /// is none.
    ///
    /// - Throws: The operation's error, delivered to every caller that shared it, or
    ///   `CancellationError` when this caller is cancelled.
    public func value(
        for key: Key,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let waiterID = state.withLock { $0.makeID() }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: Waiter) in
                let cancelled: Bool = state.withLock { state in
                    if Task.isCancelled { return true }
                    if var flight = state.flights[key] {
                        flight.waiters.append(continuation, id: waiterID)
                        state.flights[key] = flight
                        return false
                    }
                    let flightID = state.makeID()
                    var waiters = WaiterQueue<Waiter>()
                    waiters.append(continuation, id: waiterID)
                    let task = Task {
                        let result: Result<Value, any Error>
                        do {
                            result = .success(try await operation())
                        } catch {
                            result = .failure(error)
                        }
                        self.finish(key: key, flightID: flightID, with: result)
                    }
                    state.flights[key] = Flight(id: flightID, task: task, waiters: waiters)
                    return false
                }
                if cancelled {
                    continuation.resume(throwing: CancellationError())
                }
            }
        } onCancel: {
            let (waiter, orphanedTask) = state.withLock { state -> (Waiter?, Task<Void, Never>?) in
                guard var flight = state.flights[key],
                      let waiter = flight.waiters.remove(id: waiterID) else { return (nil, nil) }
                if flight.waiters.isEmpty {
                    state.flights[key] = nil
                    return (waiter, flight.task)
                }
                state.flights[key] = flight
                return (waiter, nil)
            }
            orphanedTask?.cancel()
            waiter?.resume(throwing: CancellationError())
        }
    }

    private func finish(key: Key, flightID: UInt64, with result: Result<Value, any Error>) {
        let waiters = state.withLock { state -> [Waiter] in
            guard var flight = state.flights[key], flight.id == flightID else { return [] }
            state.flights[key] = nil
            return flight.waiters.removeAll()
        }
        for waiter in waiters {
            waiter.resume(with: result)
        }
    }
}
