import Foundation

/// SwiftConcurrency: Yielding Task Scheduler.
/// 
/// A high-integrity scheduler that automatically yields control back to the 
/// system during heavy loops to prevent MainActor hangs and starvation.
public actor YieldingScheduler {
    public static let shared = YieldingScheduler()
    
    private var iterationCount = 0
    private let yieldThreshold = 100
    
    private init() {}
    
    /// Increments the work counter and yields if the threshold is met.
    public func work() async {
        iterationCount += 1
        if iterationCount >= yieldThreshold {
            iterationCount = 0
            await Task.yield()
            print("⏳ [SwiftConcurrency] Yielded control to system to prevent thread starvation.")
        }
    }
}
