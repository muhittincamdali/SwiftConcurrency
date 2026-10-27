import SwiftUI

@main
struct ConcurrencyDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(initialDemo: Demo.fromLaunchArguments())
        }
    }
}

/// The screens of the app.
enum Demo: String, CaseIterable, Identifiable, Hashable {
    case search
    case downloads
    case retry

    var id: Self { self }

    var title: String {
        switch self {
        case .search: "Search as you type"
        case .downloads: "Download queue"
        case .retry: "Retry and circuit breaker"
        }
    }

    var summary: String {
        switch self {
        case .search: "Debouncer waits until typing stops"
        case .downloads: "TaskQueue runs two at a time, in order"
        case .retry: "retry with backoff, CircuitBreaker, withTimeout"
        }
    }

    var systemImage: String {
        switch self {
        case .search: "magnifyingglass"
        case .downloads: "arrow.down.circle"
        case .retry: "arrow.clockwise"
        }
    }

    /// `-demo downloads` opens a screen directly and runs its scenario; the screenshot script
    /// uses it.
    static func fromLaunchArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Demo? {
        guard let index = arguments.firstIndex(of: "-demo"), index + 1 < arguments.count else { return nil }
        return Demo(rawValue: arguments[index + 1])
    }
}

struct ContentView: View {
    let initialDemo: Demo?
    @State private var path: [Demo] = []

    var body: some View {
        NavigationStack(path: $path) {
            List(Demo.allCases) { demo in
                NavigationLink(value: demo) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(demo.title)
                            Text(demo.summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: demo.systemImage)
                    }
                }
            }
            .navigationTitle("SwiftConcurrency")
            .navigationDestination(for: Demo.self) { demo in
                switch demo {
                case .search: SearchDemoView(autoplay: demo == initialDemo)
                case .downloads: DownloadsDemoView(autoplay: demo == initialDemo)
                case .retry: RetryDemoView(autoplay: demo == initialDemo)
                }
            }
        }
        .tint(.blue)
        .onAppear {
            if let initialDemo, path.isEmpty { path = [initialDemo] }
        }
    }
}
