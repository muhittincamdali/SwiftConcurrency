import Foundation

// MARK: - Task Extensions

extension Task where Success == Never, Failure == Never {

    /// Sleeps for the given duration, throwing `CancellationError` if cancelled.
    ///
    /// Provides a checked sleep that verifies cancellation both before and after sleeping.
    ///
    /// - Parameter duration: The duration to sleep.
    /// - Throws: `CancellationError` if the task is cancelled.
    public static func sleepChecked(for duration: Duration) async throws {
        try Task.checkCancellation()
        try await Task.sleep(for: duration)
        try Task.checkCancellation()
    }

    /// Sleeps until the specified deadline.
    ///
    /// - Parameter deadline: The instant to sleep until.
    /// - Throws: `CancellationError` if the task is cancelled.
    public static func sleep(until deadline: ContinuousClock.Instant) async throws {
        let now = ContinuousClock.now
        guard deadline > now else { return }
        let duration = deadline - now
        try await Task.sleep(for: duration)
    }
}

extension Task where Failure == Never {

    /// Creates a detached task with the specified priority.
    ///
    /// - Parameters:
    ///   - priority: The task priority.
    ///   - operation: The async closure to execute.
    /// - Returns: The created task handle.
    @discardableResult
    public static func detachedWithPriority(
        _ priority: TaskPriority,
        operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        Task.detached(priority: priority) {
            await operation()
        }
    }
}

extension Task where Failure == Error {

    /// Creates a detached throwing task with the specified priority.
    ///
    /// - Parameters:
    ///   - priority: The task priority.
    ///   - operation: The async throwing closure to execute.
    /// - Returns: The created task handle.
    @discardableResult
    public static func detachedThrowingWithPriority(
        _ priority: TaskPriority,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        Task.detached(priority: priority) {
            try await operation()
        }
    }
}

extension Task where Success == Void, Failure == Never {

    /// Yields execution to allow other tasks to run.
    ///
    /// Equivalent to `Task.yield()` but more discoverable.
    public static func cooperate() async {
        await Task.yield()
    }
}
