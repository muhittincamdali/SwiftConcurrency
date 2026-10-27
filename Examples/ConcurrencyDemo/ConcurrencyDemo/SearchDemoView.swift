import SwiftConcurrency
import SwiftUI

/// Debounced search over a local word list, with a counter of keystrokes and searches.
@MainActor @Observable
final class SearchDemoModel {
    private(set) var results: [String] = []
    private(set) var keystrokes = 0
    private(set) var searches = 0
    private(set) var lastQuery = ""
    private let debouncer = Debouncer(for: .milliseconds(300))

    nonisolated static let words = [
        "actor", "async", "await", "cancellation", "checked continuation", "clock", "concurrency",
        "continuation", "deadline", "detached task", "executor", "global actor", "isolation",
        "main actor", "nonisolated", "priority", "Sendable", "sending", "structured concurrency",
        "suspension point", "task", "task group", "task local", "timeout", "yield",
    ]

    func queryChanged(_ query: String) {
        keystrokes += 1
        debouncer.submit {
            // Stands in for a network search that takes a moment.
            try? await Task.sleep(for: .milliseconds(120))
            let matches = Self.words.filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }
            await self.show(matches, for: query)
        }
    }

    private func show(_ matches: [String], for query: String) {
        results = matches
        lastQuery = query
        searches += 1
    }

    /// Types "task" one letter at a time, faster than the debounce interval.
    func typeDemoQuery(into text: Binding<String>) async {
        for prefix in ["t", "ta", "tas", "task"] {
            text.wrappedValue = prefix
            try? await Task.sleep(for: .milliseconds(90))
        }
    }
}

struct SearchDemoView: View {
    let autoplay: Bool
    @State private var model = SearchDemoModel()
    @State private var query = ""

    var body: some View {
        List {
            Section {
                HStack {
                    Stat(value: model.keystrokes, label: "keystrokes")
                    Divider()
                    Stat(value: model.searches, label: "searches")
                }
                .frame(maxWidth: .infinity)
            } footer: {
                Text("Debouncer(for: .milliseconds(300)) runs the search once typing has paused for 300 ms.")
            }
            Section(model.lastQuery.isEmpty ? "Results" : "Results for “\(model.lastQuery)”") {
                ForEach(model.results, id: \.self) { word in
                    Text(word)
                }
            }
        }
        .searchable(text: $query, prompt: "Search concurrency terms")
        .onChange(of: query) { _, newValue in
            model.queryChanged(newValue)
        }
        .navigationTitle("Search as you type")
        .task {
            if autoplay { await model.typeDemoQuery(into: $query) }
        }
    }
}

struct Stat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack {
            Text(value, format: .number)
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(.blue)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
