import Testing
import SwiftConcurrency

@Suite("concurrentMap")
struct ConcurrentMapTests {
    @Test("Results keep the order of the elements")
    func keepsOrder() async throws {
        let results = try await Array(0..<100).concurrentMap(maxConcurrency: 8) { value in
            // Later elements finish first.
            for _ in 0..<(100 - value) % 7 { await Task.yield() }
            return value * value
        }
        #expect(results == (0..<100).map { $0 * $0 })
    }

    @Test("No more transforms run at once than maxConcurrency", arguments: [1, 4, 16])
    func respectsLimit(limit: Int) async throws {
        let gauge = ConcurrencyGauge()
        try await (0..<64).concurrentForEach(maxConcurrency: limit) { _ in
            await gauge.enter()
            for _ in 0..<4 { await Task.yield() }
            await gauge.leave()
        }
        #expect(await gauge.maximum <= limit)
    }

    @Test("An empty sequence returns an empty array")
    func empty() async throws {
        let results = try await [Int]().concurrentMap(maxConcurrency: 4) { $0 }
        #expect(results.isEmpty)
    }

    @Test("A failure is rethrown and no further transforms start")
    func failureStopsTheRest() async {
        let started = Recorder<Int>()
        await #expect(throws: TestFailure(id: 2)) {
            _ = try await Array(0..<1_000).concurrentMap(maxConcurrency: 2) { value -> Int in
                await started.append(value)
                if value == 2 { throw TestFailure(id: 2) }
                return value
            }
        }
        let count = await started.values.count
        #expect(count < 10, "started \(count) transforms after the failure")
    }

    @Test("Optional results stay in place")
    func optionalResults() async throws {
        let halves: [Int?] = try await Array(1...6).concurrentMap(maxConcurrency: 3) {
            $0.isMultiple(of: 2) ? $0 / 2 : nil
        }
        #expect(halves == [nil, 1, nil, 2, nil, 3])
        #expect(halves.compactMap { $0 } == [1, 2, 3])
    }

    @Test("A cancelled caller gets CancellationError")
    func cancelledCaller() async {
        let gate = AsyncSemaphore(value: 0)
        let call = Task {
            try await Array(0..<10).concurrentMap(maxConcurrency: 2) { _ in try await gate.wait() }
        }
        await waitUntil("two transforms wait") { gate.waiterCount == 2 }
        call.cancel()
        await #expect(throws: CancellationError.self) { try await call.value }
    }

    #if os(macOS)
    @Test("A limit of zero stops the process")
    func zeroLimitTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = try? await [1].concurrentMap(maxConcurrency: 0) { $0 }
        }
    }
    #endif
}
