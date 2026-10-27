import SwiftConcurrency
import SwiftUI

/// A server that fails a set share of requests, called through retry, a timeout and a circuit
/// breaker; every attempt is logged.
@MainActor @Observable
final class RetryDemoModel {
    struct Entry: Identifiable {
        let id: Int
        let text: String
        let isFailure: Bool
    }

    struct ServerError: Error {}

    var failureRate = 0.7
    private(set) var log: [Entry] = []
    private(set) var breakerState = CircuitBreaker.State.closed
    private(set) var isRequesting = false
    private let breaker = CircuitBreaker(failureThreshold: 3, resetTimeout: .seconds(5))
    private var requestNumber = 0

    func request() async {
        isRequesting = true
        defer {
            isRequesting = false
            breakerState = breaker.state
        }
        requestNumber += 1
        let number = requestNumber
        let failureRate = failureRate
        do {
            let reply = try await breaker.run {
                try await retry(maxAttempts: 3, backoff: .exponential(initial: .milliseconds(250))) { attempt in
                    self.append("Request \(number), attempt \(attempt)…", isFailure: false)
                    return try await withTimeout(.seconds(1)) {
                        try await Task.sleep(for: .milliseconds(150))
                        if Double.random(in: 0..<1) < failureRate { throw ServerError() }
                        return "200 OK"
                    }
                }
            }
            append("Request \(number): \(reply)", isFailure: false)
        } catch let error as CircuitOpenError {
            append("Request \(number): refused, circuit open for \(error.retryAfter.formatted(.units(allowed: [.seconds])))", isFailure: true)
        } catch {
            append("Request \(number): failed after 3 attempts", isFailure: true)
        }
    }

    /// Sends a few requests with a high failure rate so that the breaker opens.
    func playScenario() async {
        failureRate = 1
        for _ in 0..<5 { await request() }
    }

    private func append(_ text: String, isFailure: Bool) {
        log.insert(Entry(id: log.count, text: text, isFailure: isFailure), at: 0)
        breakerState = breaker.state
    }
}

struct RetryDemoView: View {
    let autoplay: Bool
    @State private var model = RetryDemoModel()

    var body: some View {
        List {
            Section {
                LabeledContent("Circuit", value: label(for: model.breakerState))
                VStack(alignment: .leading) {
                    Text("Server failure rate: \(model.failureRate, format: .percent.precision(.fractionLength(0)))")
                    Slider(value: $model.failureRate, in: 0...1)
                }
                Button("Send request") {
                    Task { await model.request() }
                }
                .disabled(model.isRequesting)
            } footer: {
                Text("Three attempts with exponential backoff, one-second timeout each; three failed requests open the circuit for five seconds.")
            }
            Section("Log") {
                ForEach(model.log) { entry in
                    Text(entry.text)
                        .font(.callout.monospaced())
                        .foregroundStyle(entry.isFailure ? Color.secondary : Color.primary)
                }
            }
        }
        .navigationTitle("Retry")
        .task {
            if autoplay { await model.playScenario() }
        }
    }

    private func label(for state: CircuitBreaker.State) -> String {
        switch state {
        case .closed: "Closed"
        case .open: "Open"
        case .halfOpen: "Half-open"
        }
    }
}
