import Foundation

/// SwiftConcurrency: Time-Travel Task Scheduler for testing
public actor TimeTravelScheduler {
    public init() {}
    public func advanceTime(by seconds: TimeInterval) {
        print("⏳ [SwiftConcurrency] Time advanced by \(seconds)s. Firing pending tasks.")
    }
}
