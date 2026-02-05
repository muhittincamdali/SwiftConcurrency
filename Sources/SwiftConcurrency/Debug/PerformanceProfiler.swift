// PerformanceProfiler.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - PerformanceProfiler

/// Profiles performance of async operations.
///
/// Collects detailed timing information, memory usage estimates,
/// and concurrency metrics.
///
/// ```swift
/// let profiler = PerformanceProfiler()
///
/// let result = try await profiler.measure("API Call") {
///     try await api.fetchData()
/// }
///
/// print(profiler.report())
/// ```
public actor PerformanceProfiler {
    
    // MARK: - Types
    
    /// A performance measurement.
    public struct Measurement: Identifiable, Sendable {
        public let id: UUID
        public let name: String
        public let startTime: ContinuousClock.Instant
        public let endTime: ContinuousClock.Instant
        public let duration: Duration
        public let metadata: [String: String]
        
        /// Duration in milliseconds.
        public var milliseconds: Double {
            Double(duration.components.seconds) * 1000 +
            Double(duration.components.attoseconds) / 1_000_000_000_000_000
        }
    }
    
    /// Aggregated statistics for a named operation.
    public struct Statistics: Sendable {
        public let name: String
        public let count: Int
        public let totalDuration: Duration
        public let averageDuration: Duration
        public let minDuration: Duration
        public let maxDuration: Duration
        public let standardDeviation: Duration
        public let percentile95: Duration
        public let percentile99: Duration
        
        public var averageMs: Double {
            Double(averageDuration.components.seconds) * 1000 +
            Double(averageDuration.components.attoseconds) / 1_000_000_000_000_000
        }
    }
    
    /// Concurrency metrics.
    public struct ConcurrencyMetrics: Sendable {
        public var peakConcurrentTasks: Int = 0
        public var totalTasksStarted: Int = 0
        public var totalTasksCompleted: Int = 0
        public var currentRunningTasks: Int = 0
    }
    
    // MARK: - Properties
    
    private var measurements: [Measurement] = []
    private var measurementsByName: [String: [Measurement]] = [:]
    private var concurrencyMetrics = ConcurrencyMetrics()
    private var activeTasks: Set<UUID> = []
    private let maxMeasurements: Int
    
    // MARK: - Initialization
    
    /// Creates a profiler.
    ///
    /// - Parameter maxMeasurements: Maximum measurements to store.
    public init(maxMeasurements: Int = 10000) {
        self.maxMeasurements = maxMeasurements
    }
    
    // MARK: - Measurement
    
    /// Measures an async operation.
    ///
    /// - Parameters:
    ///   - name: Name of the operation.
    ///   - metadata: Additional metadata.
    ///   - operation: The operation to measure.
    /// - Returns: The operation result.
    public func measure<T: Sendable>(
        _ name: String,
        metadata: [String: String] = [:],
        operation: () async throws -> T
    ) async rethrows -> T {
        let taskId = UUID()
        let startTime = ContinuousClock.now
        
        activeTasks.insert(taskId)
        concurrencyMetrics.currentRunningTasks = activeTasks.count
        concurrencyMetrics.totalTasksStarted += 1
        
        if activeTasks.count > concurrencyMetrics.peakConcurrentTasks {
            concurrencyMetrics.peakConcurrentTasks = activeTasks.count
        }
        
        defer {
            let endTime = ContinuousClock.now
            let duration = endTime - startTime
            
            let measurement = Measurement(
                id: taskId,
                name: name,
                startTime: startTime,
                endTime: endTime,
                duration: duration,
                metadata: metadata
            )
            
            recordMeasurement(measurement)
            
            activeTasks.remove(taskId)
            concurrencyMetrics.currentRunningTasks = activeTasks.count
            concurrencyMetrics.totalTasksCompleted += 1
        }
        
        return try await operation()
    }
    
    /// Records a pre-measured result.
    public func record(name: String, duration: Duration, metadata: [String: String] = [:]) {
        let now = ContinuousClock.now
        let measurement = Measurement(
            id: UUID(),
            name: name,
            startTime: now - duration,
            endTime: now,
            duration: duration,
            metadata: metadata
        )
        recordMeasurement(measurement)
    }
    
    // MARK: - Statistics
    
    /// Gets statistics for a named operation.
    public func statistics(for name: String) -> Statistics? {
        guard let measures = measurementsByName[name], !measures.isEmpty else {
            return nil
        }
        
        let durations = measures.map { $0.duration }
        let sorted = durations.sorted { $0 < $1 }
        
        let total = durations.reduce(Duration.zero, +)
        let average = total / durations.count
        
        let minDuration = sorted.first ?? .zero
        let maxDuration = sorted.last ?? .zero
        
        // Standard deviation
        let avgNanos = average.profilerNanoseconds
        let variance = durations.map { d -> Double in
            let diff = Double(d.profilerNanoseconds - avgNanos)
            return diff * diff
        }.reduce(0, +) / Double(durations.count)
        let stdDevNanos = Int64(sqrt(variance))
        
        // Percentiles
        let p95Index = Int(Double(sorted.count) * 0.95)
        let p99Index = Int(Double(sorted.count) * 0.99)
        
        return Statistics(
            name: name,
            count: measures.count,
            totalDuration: total,
            averageDuration: average,
            minDuration: minDuration,
            maxDuration: maxDuration,
            standardDeviation: .nanoseconds(stdDevNanos),
            percentile95: sorted[min(p95Index, sorted.count - 1)],
            percentile99: sorted[min(p99Index, sorted.count - 1)]
        )
    }
    
    /// Gets statistics for all operations.
    public func allStatistics() -> [Statistics] {
        measurementsByName.keys.compactMap { statistics(for: $0) }
    }
    
    /// Gets concurrency metrics.
    public func getConcurrencyMetrics() -> ConcurrencyMetrics {
        concurrencyMetrics
    }
    
    // MARK: - Reporting
    
    /// Generates a text report.
    public func report() -> String {
        var lines: [String] = []
        lines.append("═══════════════════════════════════════════════════════════")
        lines.append("                    PERFORMANCE REPORT")
        lines.append("═══════════════════════════════════════════════════════════")
        lines.append("")
        
        // Concurrency metrics
        lines.append("📊 Concurrency Metrics:")
        lines.append("  Peak concurrent tasks: \(concurrencyMetrics.peakConcurrentTasks)")
        lines.append("  Total tasks started: \(concurrencyMetrics.totalTasksStarted)")
        lines.append("  Total tasks completed: \(concurrencyMetrics.totalTasksCompleted)")
        lines.append("  Currently running: \(concurrencyMetrics.currentRunningTasks)")
        lines.append("")
        
        // Per-operation statistics
        lines.append("⏱️ Operation Statistics:")
        lines.append("───────────────────────────────────────────────────────────")
        
        let stats = allStatistics().sorted { $0.totalDuration > $1.totalDuration }
        
        for stat in stats {
            lines.append("")
            lines.append("  \(stat.name):")
            lines.append("    Count: \(stat.count)")
            lines.append("    Total: \(formatDuration(stat.totalDuration))")
            lines.append("    Average: \(formatDuration(stat.averageDuration))")
            lines.append("    Min: \(formatDuration(stat.minDuration))")
            lines.append("    Max: \(formatDuration(stat.maxDuration))")
            lines.append("    Std Dev: \(formatDuration(stat.standardDeviation))")
            lines.append("    P95: \(formatDuration(stat.percentile95))")
            lines.append("    P99: \(formatDuration(stat.percentile99))")
        }
        
        lines.append("")
        lines.append("═══════════════════════════════════════════════════════════")
        
        return lines.joined(separator: "\n")
    }
    
    /// Exports measurements as JSON.
    public func exportJSON() throws -> Data {
        struct Export: Encodable {
            let timestamp: String
            let concurrency: ConcurrencyExport
            let measurements: [MeasurementExport]
        }
        
        struct ConcurrencyExport: Encodable {
            let peakConcurrentTasks: Int
            let totalTasksStarted: Int
            let totalTasksCompleted: Int
        }
        
        struct MeasurementExport: Encodable {
            let id: String
            let name: String
            let durationMs: Double
            let metadata: [String: String]
        }
        
        let formatter = ISO8601DateFormatter()
        
        let export = Export(
            timestamp: formatter.string(from: Date()),
            concurrency: ConcurrencyExport(
                peakConcurrentTasks: concurrencyMetrics.peakConcurrentTasks,
                totalTasksStarted: concurrencyMetrics.totalTasksStarted,
                totalTasksCompleted: concurrencyMetrics.totalTasksCompleted
            ),
            measurements: measurements.map { m in
                MeasurementExport(
                    id: m.id.uuidString,
                    name: m.name,
                    durationMs: m.milliseconds,
                    metadata: m.metadata
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }
    
    /// Resets all data.
    public func reset() {
        measurements.removeAll()
        measurementsByName.removeAll()
        concurrencyMetrics = ConcurrencyMetrics()
        activeTasks.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func recordMeasurement(_ measurement: Measurement) {
        measurements.append(measurement)
        if measurements.count > maxMeasurements {
            let removed = measurements.removeFirst()
            measurementsByName[removed.name]?.removeFirst()
        }
        
        measurementsByName[measurement.name, default: []].append(measurement)
    }
    
    private func formatDuration(_ duration: Duration) -> String {
        let ms = Double(duration.components.seconds) * 1000 +
                 Double(duration.components.attoseconds) / 1_000_000_000_000_000
        
        if ms < 1 {
            return String(format: "%.3fms", ms)
        } else if ms < 1000 {
            return String(format: "%.2fms", ms)
        } else {
            return String(format: "%.2fs", ms / 1000)
        }
    }
}

// MARK: - Duration Extensions

extension Duration {
    fileprivate var profilerNanoseconds: Int64 {
        let (seconds, attoseconds) = self.components
        return seconds * 1_000_000_000 + attoseconds / 1_000_000_000
    }
}

// MARK: - Benchmark

/// Quick benchmarking utility.
///
/// ```swift
/// let result = await Benchmark.run("Sort", iterations: 1000) {
///     array.sorted()
/// }
/// print(result.summary)
/// ```
public enum Benchmark {
    
    /// Benchmark result.
    public struct Result: Sendable {
        public let name: String
        public let iterations: Int
        public let totalDuration: Duration
        public let averageDuration: Duration
        public let minDuration: Duration
        public let maxDuration: Duration
        
        public var summary: String {
            let avgMs = Double(averageDuration.components.seconds) * 1000 +
                       Double(averageDuration.components.attoseconds) / 1_000_000_000_000_000
            let minMs = Double(minDuration.components.seconds) * 1000 +
                       Double(minDuration.components.attoseconds) / 1_000_000_000_000_000
            let maxMs = Double(maxDuration.components.seconds) * 1000 +
                       Double(maxDuration.components.attoseconds) / 1_000_000_000_000_000
            
            return """
            Benchmark: \(name)
              Iterations: \(iterations)
              Average: \(String(format: "%.3f", avgMs))ms
              Min: \(String(format: "%.3f", minMs))ms
              Max: \(String(format: "%.3f", maxMs))ms
            """
        }
    }
    
    /// Runs a benchmark.
    ///
    /// - Parameters:
    ///   - name: Benchmark name.
    ///   - iterations: Number of iterations.
    ///   - warmup: Warmup iterations.
    ///   - operation: Operation to benchmark.
    /// - Returns: Benchmark result.
    public static func run<T>(
        _ name: String,
        iterations: Int = 100,
        warmup: Int = 10,
        operation: @escaping () async throws -> T
    ) async rethrows -> Result {
        // Warmup
        for _ in 0..<warmup {
            _ = try await operation()
        }
        
        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let start = ContinuousClock.now
            _ = try await operation()
            let end = ContinuousClock.now
            durations.append(end - start)
        }
        
        let sorted = durations.sorted { $0 < $1 }
        let total = durations.reduce(Duration.zero, +)
        
        return Result(
            name: name,
            iterations: iterations,
            totalDuration: total,
            averageDuration: total / iterations,
            minDuration: sorted.first ?? .zero,
            maxDuration: sorted.last ?? .zero
        )
    }
    
    /// Compares two operations.
    public static func compare<T, U>(
        _ name1: String,
        _ op1: @escaping () async throws -> T,
        _ name2: String,
        _ op2: @escaping () async throws -> U,
        iterations: Int = 100
    ) async throws -> String {
        let result1 = try await run(name1, iterations: iterations, operation: op1)
        let result2 = try await run(name2, iterations: iterations, operation: op2)
        
        let avg1 = result1.averageDuration.profilerNanoseconds
        let avg2 = result2.averageDuration.profilerNanoseconds
        
        let ratio = Double(avg1) / Double(avg2)
        let faster = ratio > 1 ? name2 : name1
        let speedup = ratio > 1 ? ratio : (1 / ratio)
        
        return """
        ═══════════════════════════════════════════════════════════
        BENCHMARK COMPARISON
        ═══════════════════════════════════════════════════════════
        
        \(result1.summary)
        
        \(result2.summary)
        
        Result: \(faster) is \(String(format: "%.2f", speedup))x faster
        ═══════════════════════════════════════════════════════════
        """
    }
}
