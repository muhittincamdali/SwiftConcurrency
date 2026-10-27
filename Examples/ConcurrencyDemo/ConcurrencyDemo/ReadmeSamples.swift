// The code samples of the README. The example app runs them, and the package's tests compile and
// run this same file through the symlink Tests/SwiftConcurrencyTests/ReadmeSamples.swift, so
// every sample in the README is checked on each build.

import SwiftConcurrency

// MARK: - Shared sample types

/// A user profile, as a server would return it.
struct Profile: Sendable, Hashable {
    let id: Int
    let name: String
}

/// Stands in for a network API in the samples.
protocol ProfileAPI: Sendable {
    func profile(id: Int) async throws -> Profile
}

// MARK: - Quick start

/// Loads many profiles: four requests at a time, each with a 10-second timeout and up to three
/// attempts with exponential backoff.
func loadProfiles(ids: [Int], from api: some ProfileAPI) async throws -> [Profile] {
    try await ids.concurrentMap(maxConcurrency: 4) { id in
        try await retry(maxAttempts: 3, backoff: .exponential().jittered(.full)) { _ in
            try await withTimeout(.seconds(10)) {
                try await api.profile(id: id)
            }
        }
    }
}

// MARK: - Search as you type

/// Searches only after the user has stopped typing for 300 ms.
@MainActor
final class SearchController {
    private(set) var results: [String] = []
    private(set) var searchCount = 0
    private let debouncer: Debouncer
    private let search: @Sendable (String) async -> [String]

    init(
        clock: some Clock<Duration> = ContinuousClock(),
        search: @escaping @Sendable (String) async -> [String]
    ) {
        self.debouncer = Debouncer(for: .milliseconds(300), clock: clock)
        self.search = search
    }

    func queryChanged(_ query: String) {
        debouncer.submit { [search] in
            let results = await search(query)
            await self.show(results)
        }
    }

    private func show(_ results: [String]) {
        self.results = results
        searchCount += 1
    }
}

// MARK: - Saves that never overlap

/// Writes documents one after the other, in the order they were saved.
final class Autosaver: Sendable {
    private let queue = TaskQueue()
    private let write: @Sendable (String) async throws -> Void

    init(write: @escaping @Sendable (String) async throws -> Void) {
        self.write = write
    }

    func save(_ text: String) {
        queue.addOperation { [write] in
            try await write(text)
        }
    }

    func waitForPendingSaves() async throws {
        try await queue.waitUntilIdle()
    }
}

// MARK: - One request for many callers

/// Sends one request per profile, however many screens ask for it at the same time, and stops
/// calling a server that keeps failing.
final class ProfileLoader: Sendable {
    private let api: any ProfileAPI
    let inFlight = SingleFlight<Int, Profile>()
    private let breaker: CircuitBreaker

    init(api: any ProfileAPI, clock: some Clock<Duration> = ContinuousClock()) {
        self.api = api
        self.breaker = CircuitBreaker(failureThreshold: 5, resetTimeout: .seconds(30), clock: clock)
    }

    func profile(id: Int) async throws -> Profile {
        try await inFlight.value(for: id) { [api, breaker] in
            try await breaker.run {
                try await api.profile(id: id)
            }
        }
    }
}
