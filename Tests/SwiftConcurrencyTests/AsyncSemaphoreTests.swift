import Testing
@testable import SwiftConcurrency

@Suite("AsyncSemaphore")
struct AsyncSemaphoreTests {
    @Test("tryWait takes the available permits and no more")
    func tryWaitCountsPermits() {
        let semaphore = AsyncSemaphore(value: 2)
        #expect(semaphore.tryWait())
        #expect(semaphore.tryWait())
        #expect(!semaphore.tryWait())
        semaphore.signal()
        #expect(semaphore.availablePermits == 1)
        #expect(semaphore.tryWait())
    }

    @Test("wait suspends until signal")
    func waitSuspendsUntilSignal() async throws {
        let semaphore = AsyncSemaphore(value: 0)
        let waiter = Task { try await semaphore.wait() }
        await waitUntil("the waiter is suspended") { semaphore.waiterCount == 1 }

        semaphore.signal()
        try await waiter.value
        #expect(semaphore.availablePermits == 0)
        #expect(semaphore.waiterCount == 0)
    }

    @Test("Waiters are resumed in the order they started waiting")
    func waitersAreFirstInFirstOut() async throws {
        let semaphore = AsyncSemaphore(value: 0)
        let order = Recorder<Int>()
        var tasks: [Task<Void, any Error>] = []
        for index in 0..<5 {
            tasks.append(Task {
                try await semaphore.wait()
                await order.append(index)
            })
            await waitUntil("waiter \(index) is suspended") { semaphore.waiterCount == index + 1 }
        }

        for index in 0..<5 {
            semaphore.signal()
            let values = await order.wait(forCount: index + 1)
            #expect(values == Array(0...index))
        }
        for task in tasks { try await task.value }
    }

    @Test("A cancelled waiter throws, leaves the queue and takes no permit")
    func cancelledWaiterTakesNoPermit() async {
        let semaphore = AsyncSemaphore(value: 0)
        let waiter = Task { try await semaphore.wait() }
        await waitUntil("the waiter is suspended") { semaphore.waiterCount == 1 }

        waiter.cancel()
        await #expect(throws: CancellationError.self) { try await waiter.value }
        #expect(semaphore.waiterCount == 0)

        semaphore.signal()
        #expect(semaphore.availablePermits == 1, "the permit goes to nobody, not to the cancelled waiter")
    }

    @Test("A task that is already cancelled does not take a free permit")
    func alreadyCancelledTaskTakesNoPermit() async {
        let semaphore = AsyncSemaphore(value: 1)
        let waiter = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await semaphore.wait()
        }
        await #expect(throws: CancellationError.self) { try await waiter.value }
        #expect(semaphore.availablePermits == 1)
    }

    @Test("A cancelled waiter does not block the waiters behind it")
    func cancelledWaiterInTheMiddle() async throws {
        let semaphore = AsyncSemaphore(value: 0)
        let first = Task { try await semaphore.wait() }
        await waitUntil("first waits") { semaphore.waiterCount == 1 }
        let second = Task { try await semaphore.wait() }
        await waitUntil("second waits") { semaphore.waiterCount == 2 }

        first.cancel()
        await #expect(throws: CancellationError.self) { try await first.value }
        semaphore.signal()
        try await second.value
    }

    @Test("withPermit never lets more tasks in than the semaphore's value")
    func withPermitLimitsConcurrency() async throws {
        let semaphore = AsyncSemaphore(value: 3)
        let gauge = ConcurrencyGauge()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<40 {
                group.addTask {
                    try await semaphore.withPermit {
                        await gauge.enter()
                        for _ in 0..<5 { await Task.yield() }
                        await gauge.leave()
                    }
                }
            }
            try await group.waitForAll()
        }
        #expect(await gauge.maximum <= 3)
        #expect(semaphore.availablePermits == 3)
    }

    @Test("withPermit returns the permit when the operation throws")
    func withPermitReleasesOnError() async {
        let semaphore = AsyncSemaphore(value: 1)
        await #expect(throws: TestFailure.self) {
            try await semaphore.withPermit { throw TestFailure() }
        }
        #expect(semaphore.availablePermits == 1)
    }

    @MainActor
    @Test("withPermit runs the operation on the caller's actor")
    func withPermitKeepsIsolation() async throws {
        let semaphore = AsyncSemaphore(value: 1)
        var counter = 0 // main-actor state, not Sendable to capture elsewhere
        try await semaphore.withPermit {
            MainActor.assertIsolated()
            counter += 1
        }
        #expect(counter == 1)
    }

    @Test("signal saturates at Int.max instead of overflowing")
    func signalSaturates() {
        let semaphore = AsyncSemaphore(value: .max)
        semaphore.signal()
        #expect(semaphore.availablePermits == .max)
    }

    @Test("Thousands of cancelled waiters do not accumulate in memory")
    func cancelledWaitersAreCompacted() async throws {
        let semaphore = AsyncSemaphore(value: 0)
        let keeper = Task { try await semaphore.wait() }
        await waitUntil("the long waiter is suspended") { semaphore.waiterCount == 1 }

        for _ in 0..<2_000 {
            let waiter = Task { try await semaphore.wait() }
            await waitUntil("a waiter is suspended") { semaphore.waiterCount == 2 }
            waiter.cancel()
            _ = await waiter.result
        }
        #expect(semaphore.waiterCount == 1)
        #expect(semaphore.storedWaiterIdentifierCount <= 66)

        semaphore.signal()
        try await keeper.value
    }

    #if os(macOS)
    @Test("A negative value stops the process")
    func negativeValueTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = AsyncSemaphore(value: -1)
        }
    }
    #endif
}
