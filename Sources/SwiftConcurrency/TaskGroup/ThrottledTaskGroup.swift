import Foundation

// MARK: - ThrottledTaskGroup

/// Executes async tasks with a bounded concurrency limit.
///
/// Prevents resource exhaustion by ensuring no more than `maxConcurrency`
/// tasks run simultaneously. Results are returned in the original input order.
///
/// ```swift
/// let results = try await ThrottledTaskGroup.run(
///     maxConcurrency: 4,
///     tasks: urls
/// ) { url in
///     try await fetchData(from: url)
/// }
/// ```
public struct ThrottledTaskGroup: Sendable {

    /// Concurrency limiter backed by an actor.
    private actor Semaphore {
        private let limit: Int
        private var current: Int = 0
        private var waiters: [CheckedContinuation<Void, Never>] = []

        init(limit: Int) {
            self.limit = limit
        }

        /// Acquires a slot, suspending if the limit is reached.
        func acquire() async {
            if current < limit {
                current += 1
                return
            }
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
            current += 1
        }

        /// Releases a slot, resuming the next waiter if any.
        func release() {
            current -= 1
            if !waiters.isEmpty {
                let next = waiters.removeFirst()
                next.resume()
            }
        }
    }

    /// Runs the given tasks with bounded concurrency, returning results in order.
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum number of tasks running simultaneously.
    ///   - tasks: The input elements to process.
    ///   - operation: An async throwing closure to apply to each element.
    /// - Returns: An ordered array of results.
    /// - Throws: Rethrows any error from the operation closure.
    public static func run<Input: Sendable, Output: Sendable>(
        maxConcurrency: Int,
        tasks inputs: [Input],
        operation: @Sendable @escaping (Input) async throws -> Output
    ) async throws -> [Output] {
        precondition(maxConcurrency > 0, "maxConcurrency must be greater than zero")

        let semaphore = Semaphore(limit: maxConcurrency)

        return try await withThrowingTaskGroup(of: (Int, Output).self) { group in
            for (index, input) in inputs.enumerated() {
                await semaphore.acquire()

                group.addTask {
                    defer { Task { await semaphore.release() } }
                    let result = try await operation(input)
                    return (index, result)
                }
            }

            var results = [(Int, Output)]()
            results.reserveCapacity(inputs.count)

            for try await pair in group {
                results.append(pair)
            }

            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }

    /// Runs the given tasks with bounded concurrency, discarding results.
    ///
    /// - Parameters:
    ///   - maxConcurrency: Maximum number of tasks running simultaneously.
    ///   - tasks: The input elements to process.
    ///   - operation: An async throwing closure to apply to each element.
    public static func forEach<Input: Sendable>(
        maxConcurrency: Int,
        tasks inputs: [Input],
        operation: @Sendable @escaping (Input) async throws -> Void
    ) async throws {
        precondition(maxConcurrency > 0, "maxConcurrency must be greater than zero")

        let semaphore = Semaphore(limit: maxConcurrency)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for input in inputs {
                await semaphore.acquire()

                group.addTask {
                    defer { Task { await semaphore.release() } }
                    try await operation(input)
                }
            }

            try await group.waitForAll()
        }
    }
}
