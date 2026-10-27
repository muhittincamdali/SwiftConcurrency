import Testing
@testable import SwiftConcurrency

/// Runs the README samples in ReadmeSamples.swift against fakes.
@Suite("README samples")
struct ReadmeSamplesTests {
    /// Fails the first call for each id, then answers; counts calls per id.
    actor FlakyAPI: ProfileAPI {
        private(set) var calls: [Int: Int] = [:]
        private let gate: AsyncSemaphore?

        init(gate: AsyncSemaphore? = nil) {
            self.gate = gate
        }

        func profile(id: Int) async throws -> Profile {
            calls[id, default: 0] += 1
            if let gate { try await gate.withPermit {} }
            if calls[id] == 1, gate == nil { throw TestFailure(id: id) }
            return Profile(id: id, name: "User \(id)")
        }
    }

    @Test("Quick start: loads every profile in order, retrying the failed first calls")
    func quickStart() async throws {
        let api = FlakyAPI()
        let profiles = try await loadProfiles(ids: Array(1...12), from: api)
        #expect(profiles.map(\.id) == Array(1...12))
        #expect(await api.calls.values.allSatisfy { $0 == 2 })
    }

    @MainActor
    @Test("Search: only the final query is searched")
    func search() async throws {
        let clock = TestClock()
        let searched = Recorder<String>()
        let controller = SearchController(clock: clock) { query in
            await searched.append(query)
            return ["\(query) result"]
        }
        for query in ["t", "ta", "tas", "task"] {
            controller.queryChanged(query)
        }
        try await clock.waitForSleepers()
        clock.advance(by: .milliseconds(300))
        #expect(await searched.wait(forCount: 1) == ["task"])
        await waitUntil("results are shown") { controller.searchCount == 1 }
        #expect(controller.results == ["task result"])
    }

    @Test("Autosave: writes run one after the other, in order")
    func autosave() async throws {
        let written = Recorder<String>()
        let gauge = ConcurrencyGauge()
        let saver = Autosaver { text in
            await gauge.enter()
            await Task.yield()
            await written.append(text)
            await gauge.leave()
        }
        for version in 1...20 { saver.save("v\(version)") }
        try await saver.waitForPendingSaves()
        #expect(await written.values == (1...20).map { "v\($0)" })
        #expect(await gauge.maximum == 1)
    }

    @Test("Profiles: overlapping requests for one id send one call")
    func profileLoader() async throws {
        let gate = AsyncSemaphore(value: 0)
        let api = FlakyAPI(gate: gate)
        let loader = ProfileLoader(api: api, clock: TestClock())
        let screens = (0..<4).map { _ in Task { try await loader.profile(id: 7) } }
        await waitUntil("every screen waits for the one call") {
            gate.waiterCount == 1 && loader.inFlight.waiterCount(for: 7) == 4
        }
        gate.signal()
        for screen in screens {
            #expect(try await screen.value == Profile(id: 7, name: "User 7"))
        }
        #expect(await api.calls[7] == 1)
    }
}
