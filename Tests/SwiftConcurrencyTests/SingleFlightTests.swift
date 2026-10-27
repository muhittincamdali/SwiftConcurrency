import Testing
@testable import SwiftConcurrency

@Suite("SingleFlight")
struct SingleFlightTests {
    @Test("Overlapping calls for one key share a single operation")
    func sharesOperation() async throws {
        let flights = SingleFlight<String, Int>()
        let gate = AsyncSemaphore(value: 0)
        let calls = Recorder<String>()

        let callers = (0..<5).map { _ in
            Task {
                try await flights.value(for: "user-1") {
                    await calls.append("user-1")
                    try await gate.wait()
                    return 42
                }
            }
        }
        await waitUntil("all callers wait") { flights.waiterCount(for: "user-1") == 5 }
        gate.signal()

        for caller in callers { #expect(try await caller.value == 42) }
        #expect(await calls.values == ["user-1"])
        #expect(flights.inFlightCount == 0)
    }

    @Test("Every caller gets the operation's error")
    func sharesError() async {
        let flights = SingleFlight<Int, Int>()
        let gate = AsyncSemaphore(value: 0)
        let callers = (0..<3).map { _ in
            Task {
                try await flights.value(for: 1) {
                    try await gate.wait()
                    throw TestFailure(id: 9)
                }
            }
        }
        await waitUntil("all callers wait") { flights.waiterCount(for: 1) == 3 }
        gate.signal()
        for caller in callers {
            await #expect(throws: TestFailure(id: 9)) { try await caller.value }
        }
    }

    @Test("A call after the operation finished starts a new one")
    func notACache() async throws {
        let flights = SingleFlight<String, Int>()
        let runs = Recorder<Int>()
        for expected in 1...3 {
            let value = try await flights.value(for: "key") {
                await runs.append(expected)
                return expected
            }
            #expect(value == expected)
        }
        #expect(await runs.values == [1, 2, 3])
    }

    @Test("Different keys run separately")
    func separateKeys() async throws {
        let flights = SingleFlight<Int, Int>()
        async let first = flights.value(for: 1) { 10 }
        async let second = flights.value(for: 2) { 20 }
        #expect(try await [first, second] == [10, 20])
    }

    @Test("A cancelled caller stops waiting; the others still get the result")
    func oneCallerCancelled() async throws {
        let flights = SingleFlight<String, Int>()
        let gate = AsyncSemaphore(value: 0)
        let operation: @Sendable () async throws -> Int = {
            try await gate.wait()
            return 7
        }
        let cancelled = Task { try await flights.value(for: "k", operation: operation) }
        let kept = Task { try await flights.value(for: "k", operation: operation) }
        await waitUntil("both callers wait") { flights.waiterCount(for: "k") == 2 }

        cancelled.cancel()
        await #expect(throws: CancellationError.self) { try await cancelled.value }
        #expect(gate.waiterCount == 1, "the shared operation keeps running")

        gate.signal()
        #expect(try await kept.value == 7)
    }

    @Test("When every caller is cancelled the operation is cancelled")
    func allCallersCancelled() async {
        let flights = SingleFlight<String, Int>()
        let gate = AsyncSemaphore(value: 0)
        let outcome = Recorder<String>()
        let caller = Task {
            try await flights.value(for: "k") {
                do {
                    try await gate.wait()
                } catch {
                    await outcome.append("operation cancelled")
                    throw error
                }
                return 1
            }
        }
        await waitUntil("the operation runs") { gate.waiterCount == 1 }
        caller.cancel()
        await #expect(throws: CancellationError.self) { try await caller.value }
        #expect(await outcome.wait(forCount: 1) == ["operation cancelled"])
        #expect(flights.inFlightCount == 0)
    }
}
