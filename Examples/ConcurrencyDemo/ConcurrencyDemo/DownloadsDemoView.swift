import Charts
import SwiftConcurrency
import SwiftUI

/// Simulated downloads through a TaskQueue with a limit of two, drawn as a timeline.
@MainActor @Observable
final class DownloadsDemoModel {
    struct Download: Identifiable {
        enum Status: String { case waiting = "Waiting", running = "Running", done = "Done", cancelled = "Cancelled" }

        let id: Int
        let size: Duration
        var status = Status.waiting
        var started: Duration?
        var finished: Duration?
        var task: Task<Void, any Error>?

        var name: String { "file-\(id).zip" }
    }

    private(set) var downloads: [Download] = []
    private let queue = TaskQueue(maxConcurrentOperations: 2)
    private let clock = ContinuousClock()
    private var origin: ContinuousClock.Instant?

    /// Durations of the simulated files, in milliseconds.
    private static let sizes = [900, 500, 700, 400, 800, 300]

    var isRunning: Bool { downloads.contains { $0.status == .waiting || $0.status == .running } }

    func start() {
        guard !isRunning else { return }
        origin = clock.now
        downloads = Self.sizes.enumerated().map { Download(id: $0.offset + 1, size: .milliseconds($0.element)) }
        for index in downloads.indices {
            let size = downloads[index].size
            downloads[index].task = queue.addOperation { [weak self, clock] in
                // Times are read here, not on the main actor, so the timeline shows when the
                // queue ran each file even while the main actor is busy drawing.
                await self?.mark(index, .running, at: clock.now)
                do {
                    try await Task.sleep(for: size)
                } catch {
                    await self?.mark(index, .cancelled, at: clock.now)
                    throw error
                }
                await self?.mark(index, .done, at: clock.now)
            }
        }
    }

    func cancel(_ download: Download) {
        download.task?.cancel()
        if download.status == .waiting { mark(download.id - 1, .cancelled, at: clock.now) }
    }

    private func mark(_ index: Int, _ status: Download.Status, at instant: ContinuousClock.Instant) {
        guard let origin, downloads.indices.contains(index) else { return }
        let now = origin.duration(to: instant)
        downloads[index].status = status
        switch status {
        case .running: downloads[index].started = now
        case .done, .cancelled: downloads[index].finished = now
        case .waiting: break
        }
    }
}

struct DownloadsDemoView: View {
    let autoplay: Bool
    @State private var model = DownloadsDemoModel()

    var body: some View {
        List {
            Section {
                Chart(model.downloads.filter { $0.started != nil }) { download in
                    BarMark(
                        xStart: .value("Start", download.started?.milliseconds ?? 0),
                        xEnd: .value("End", (download.finished ?? download.started)?.milliseconds ?? 0),
                        y: .value("File", download.name)
                    )
                    .foregroundStyle(download.status == .cancelled ? Color.gray : Color.blue)
                    .cornerRadius(4)
                }
                .chartXAxisLabel("milliseconds since start")
                .chartYScale(domain: model.downloads.map(\.name))
                .frame(height: 220)
            } header: {
                Text("Timeline")
            } footer: {
                Text("TaskQueue(maxConcurrentOperations: 2) starts the files in order; never more than two overlap.")
            }
            Section("Files") {
                ForEach(model.downloads) { download in
                    HStack {
                        Text(download.name).monospaced()
                        Spacer()
                        Text(download.status.rawValue)
                            .foregroundStyle(download.status == .running ? Color.blue : Color.secondary)
                        if download.status == .waiting || download.status == .running {
                            Button("Cancel", systemImage: "xmark.circle") { model.cancel(download) }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .toolbar {
            Button("Start", systemImage: "play.fill") { model.start() }
                .disabled(model.isRunning)
        }
        .navigationTitle("Download queue")
        .task {
            if autoplay { model.start() }
        }
    }
}

extension Duration {
    var milliseconds: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) * 1_000 + Double(attoseconds) / 1e15
    }
}
