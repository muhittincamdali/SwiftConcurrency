import Testing
@testable import SwiftConcurrency

@Suite("TaskQueue")
struct TaskQueueTests {
    @Test("A serial queue runs operations one at a time, in the order they were added")
    func serialOrderWithoutOverlap() async throws {
        let queue = TaskQueue()
        let gauge = ConcurrencyGauge()
        let order = Recorder<Int>()
        for index in 0..<50 {
            queue.addOperation {
                await gauge.enter()
                await order.append(index)
                for _ in 0..<3 { await Task.yield() }
                await gauge.leave()
            }
        }
        try await queue.waitUntilIdle()
        #expect(await order.values == Array(0..<50))
        #expect(await gauge.maximum == 1)
    }

    @Test("A queue with a limit of 3 never runs more than 3 operations", arguments: [1, 3, 8])
    func respectsLimit(limit: Int) async throws {
        let queue = TaskQueue(maxConcurrentOperations: limit)
        let gauge = ConcurrencyGauge()
        let tasks = (0..<40).map { index in
            queue.addOperation { () -> Int in
                await gauge.enter()
                for _ in 0..<5 { await Task.yield() }
                await gauge.leave()
                return index * 2
            }
        }
        var results: [Int] = []
        for task in tasks { results.append(try await task.value) }
        #expect(results == (0..<40).map { $0 * 2 })
        #expect(await gauge.maximum <= limit)
        #expect(queue.runningCount == 0)
    }

    @Test("A failing operation does not stop the ones after it")
    func failureIsIsolated() async throws {
        let queue = TaskQueue()
        let failing = queue.addOperation { () -> Int in throw TestFailure(id: 1) }
        let next = queue.addOperation { 42 }
        await #expect(throws: TestFailure(id: 1)) { try await failing.value }
        #expect(try await next.value == 42)
    }

    @Test("An operation cancelled before its turn never runs and frees its place")
    func cancelWaitingOperation() async throws {
        let queue = TaskQueue()
        let gate = AsyncSemaphore(value: 0)
        let ran = Recorder<String>()

        let blocker = queue.addOperation {
            try await gate.wait()
            await ran.append("blocker")
        }
        await waitUntil("the blocker is running") { gate.waiterCount == 1 }
        let skipped = queue.addOperation { await ran.append("skipped") }
        let last = queue.addOperation { await ran.append("last") }

        skipped.cancel()
        await #expect(throws: CancellationError.self) { try await skipped.value }

        gate.signal()
        try await blocker.value
        try await last.value
        #expect(await ran.values == ["blocker", "last"])
    }

    @Test("cancelAll cancels the running operation and removes the waiting ones")
    func cancelAll() async throws {
        let queue = TaskQueue()
        let gate = AsyncSemaphore(value: 0)
        let ran = Recorder<String>()

        let running = queue.addOperation { try await gate.wait() }
        await waitUntil("the first operation is running") { gate.waiterCount == 1 }
        let waiting = queue.addOperation { await ran.append("waiting") }

        queue.cancelAll()
        await #expect(throws: CancellationError.self) { try await running.value }
        await #expect(throws: CancellationError.self) { try await waiting.value }
        try await queue.waitUntilIdle()
        #expect(await ran.values.isEmpty)

        let after = queue.addOperation { "runs" }
        #expect(try await after.value == "runs")
    }

    @Test("Cancelling a caller of perform cancels its operation")
    func performPropagatesCancellation() async throws {
        let queue = TaskQueue()
        let gate = AsyncSemaphore(value: 0)
        let caller = Task {
            try await queue.perform { try await gate.wait() }
        }
        await waitUntil("the operation is running") { gate.waiterCount == 1 }
        caller.cancel()
        await #expect(throws: CancellationError.self) { try await caller.value }
        try await queue.waitUntilIdle()
        #expect(queue.operationCount == 0)
    }

    @Test("waitUntilIdle returns at once for an empty queue and after the last operation otherwise")
    func waitUntilIdle() async throws {
        let queue = TaskQueue()
        try await queue.waitUntilIdle()

        let gate = AsyncSemaphore(value: 0)
        queue.addOperation { try await gate.wait() }
        let idle = Task { try await queue.waitUntilIdle() }
        await waitUntil("the operation is running") { gate.waiterCount == 1 }
        #expect(queue.operationCount == 1)
        gate.signal()
        try await idle.value
        #expect(queue.operationCount == 0)
    }

    @Test("Operations added from many tasks at once all run")
    func concurrentAdds() async throws {
        let queue = TaskQueue(maxConcurrentOperations: 2)
        let count = Recorder<Int>()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<200 {
                group.addTask { queue.addOperation { await count.append(index) } }
            }
        }
        try await queue.waitUntilIdle()
        #expect(await count.values.sorted() == Array(0..<200))
    }

    #if os(macOS)
    @Test("A limit of zero stops the process")
    func zeroLimitTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = TaskQueue(maxConcurrentOperations: 0)
        }
    }
    #endif
}
