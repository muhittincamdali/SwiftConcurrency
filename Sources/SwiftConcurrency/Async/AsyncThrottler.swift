import Foundation

// MARK: - AsyncThrottler

/// Throttles async operations so they execute at most once per interval.
///
/// Useful for debouncing rapid events like search queries or UI updates.
///
/// ```swift
/// let throttler = AsyncThrottler(interval: .milliseconds(300))
/// await throttler.submit {
///     await performSearch(query)
/// }
/// ```
public actor AsyncThrottler {

    /// The minimum interval between consecutive executions.
    private let interval: Duration

    /// The currently scheduled task, if any.
    private var pendingTask: Task<Void, Never>?

    /// Timestamp of the last execution.
    private var lastExecutionTime: ContinuousClock.Instant?

    /// Creates a throttler with the given interval.
    ///
    /// - Parameter interval: Minimum time between consecutive executions.
    public init(interval: Duration) {
        self.interval = interval
    }

    /// Submits work to the throttler.
    ///
    /// If called within the throttle interval, the previous pending work is
    /// cancelled and replaced. Only the latest submission executes.
    ///
    /// - Parameter operation: The async closure to execute.
    public func submit(operation: @Sendable @escaping () async -> Void) {
        pendingTask?.cancel()

        let delay = computeDelay()
        pendingTask = Task { [delay] in
            if let delay {
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled else { return }
            await operation()
            await markExecuted()
        }
    }

    /// Computes the delay needed before the next execution.
    private func computeDelay() -> Duration? {
        guard let last = lastExecutionTime else { return nil }
        let elapsed = ContinuousClock.now - last
        if elapsed >= interval {
            return nil
        }
        return interval - elapsed
    }

    /// Records the execution timestamp.
    private func markExecuted() {
        lastExecutionTime = .now
    }

    /// Cancels any pending throttled work.
    public func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }

    /// Resets the throttler state, clearing the last execution time.
    public func reset() {
        cancel()
        lastExecutionTime = nil
    }
}
