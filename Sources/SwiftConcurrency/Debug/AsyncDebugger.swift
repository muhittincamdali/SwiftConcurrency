// AsyncDebugger.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import os.log

// MARK: - AsyncDebugger

/// Debug logging and tracing for async operations.
///
/// Provides structured logging, execution tracing, and performance
/// metrics for debugging concurrent code.
///
/// ```swift
/// let debugger = AsyncDebugger(subsystem: "com.app", category: "network")
///
/// let result = try await debugger.trace("API call") {
///     try await api.fetchData()
/// }
/// ```
public actor AsyncDebugger {
    
    // MARK: - Types
    
    /// Log level for debug output.
    public enum LogLevel: Int, Comparable, Sendable {
        case trace = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        case critical = 5
        
        public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        var emoji: String {
            switch self {
            case .trace: return "🔍"
            case .debug: return "🐛"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🔥"
            }
        }
    }
    
    /// A trace span for async operations.
    public struct TraceSpan: Identifiable, Sendable {
        public let id: UUID
        public let name: String
        public let startTime: ContinuousClock.Instant
        public var endTime: ContinuousClock.Instant?
        public var status: Status
        public var metadata: [String: String]
        public let parentId: UUID?
        
        public enum Status: Sendable {
            case running
            case completed
            case failed(Error)
            case cancelled
        }
        
        public var duration: Duration? {
            guard let end = endTime else { return nil }
            return end - startTime
        }
    }
    
    /// Configuration for the debugger.
    public struct Configuration: Sendable {
        public var minimumLogLevel: LogLevel
        public var includeStackTrace: Bool
        public var includeTaskInfo: Bool
        public var maxStoredSpans: Int
        public var logOutput: LogOutput
        
        public enum LogOutput: Sendable {
            case osLog
            case print
            case custom(@Sendable (String) -> Void)
        }
        
        public init(
            minimumLogLevel: LogLevel = .debug,
            includeStackTrace: Bool = false,
            includeTaskInfo: Bool = true,
            maxStoredSpans: Int = 1000,
            logOutput: LogOutput = .osLog
        ) {
            self.minimumLogLevel = minimumLogLevel
            self.includeStackTrace = includeStackTrace
            self.includeTaskInfo = includeTaskInfo
            self.maxStoredSpans = maxStoredSpans
            self.logOutput = logOutput
        }
        
        public static var `default`: Configuration { Configuration() }
        public static var verbose: Configuration {
            Configuration(minimumLogLevel: .trace, includeStackTrace: true)
        }
    }
    
    // MARK: - Properties
    
    private let subsystem: String
    private let category: String
    private var configuration: Configuration
    private let logger: Logger?
    
    private var spans: [UUID: TraceSpan] = [:]
    private var completedSpans: [TraceSpan] = []
    private var activeSpanStack: [UUID] = []
    private var metrics: Metrics = Metrics()
    
    // MARK: - Initialization
    
    /// Creates an async debugger.
    ///
    /// - Parameters:
    ///   - subsystem: Bundle identifier or subsystem name.
    ///   - category: Category for log messages.
    ///   - configuration: Debug configuration.
    public init(
        subsystem: String,
        category: String,
        configuration: Configuration = .default
    ) {
        self.subsystem = subsystem
        self.category = category
        self.configuration = configuration
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - Logging
    
    /// Logs a message at the specified level.
    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        guard level >= configuration.minimumLogLevel else { return }
        
        var output = "\(level.emoji) [\(category)] \(message())"
        
        if configuration.includeTaskInfo {
            let taskInfo = "Task: \(Task.currentPriority)"
            output += " | \(taskInfo)"
        }
        
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
        output += " @ \(location)"
        
        emit(output, level: level)
    }
    
    /// Logs at trace level.
    public func trace(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(.trace, message(), file: file, line: line)
    }
    
    /// Logs at debug level.
    public func debug(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(.debug, message(), file: file, line: line)
    }
    
    /// Logs at info level.
    public func info(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(.info, message(), file: file, line: line)
    }
    
    /// Logs at warning level.
    public func warning(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(.warning, message(), file: file, line: line)
    }
    
    /// Logs at error level.
    public func error(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
        log(.error, message(), file: file, line: line)
    }
    
    // MARK: - Tracing
    
    /// Traces an async operation.
    ///
    /// Records start/end time, success/failure, and allows nested traces.
    ///
    /// - Parameters:
    ///   - name: Name for the trace span.
    ///   - metadata: Additional metadata.
    ///   - operation: The operation to trace.
    /// - Returns: The operation result.
    public func trace<T: Sendable>(
        _ name: String,
        metadata: [String: String] = [:],
        operation: () async throws -> T
    ) async rethrows -> T {
        let spanId = UUID()
        let parentId = activeSpanStack.last
        
        let span = TraceSpan(
            id: spanId,
            name: name,
            startTime: .now,
            status: .running,
            metadata: metadata,
            parentId: parentId
        )
        
        spans[spanId] = span
        activeSpanStack.append(spanId)
        metrics.totalSpansStarted += 1
        
        log(.trace, "▶️ Starting: \(name)")
        
        do {
            let result = try await operation()
            
            completeSpan(spanId, status: .completed)
            return result
        } catch is CancellationError {
            completeSpan(spanId, status: .cancelled)
            throw CancellationError()
        } catch {
            completeSpan(spanId, status: .failed(error))
            throw error
        }
    }
    
    /// Begins a manual trace span.
    ///
    /// Use this for operations that can't be wrapped in a closure.
    ///
    /// - Parameters:
    ///   - name: Span name.
    ///   - metadata: Additional metadata.
    /// - Returns: Span ID for ending the trace.
    public func beginSpan(
        _ name: String,
        metadata: [String: String] = [:]
    ) -> UUID {
        let spanId = UUID()
        let parentId = activeSpanStack.last
        
        let span = TraceSpan(
            id: spanId,
            name: name,
            startTime: .now,
            status: .running,
            metadata: metadata,
            parentId: parentId
        )
        
        spans[spanId] = span
        activeSpanStack.append(spanId)
        metrics.totalSpansStarted += 1
        
        log(.trace, "▶️ Begin: \(name)")
        return spanId
    }
    
    /// Ends a manual trace span.
    public func endSpan(_ spanId: UUID, error: Error? = nil) {
        let status: TraceSpan.Status
        if let error = error {
            if error is CancellationError {
                status = .cancelled
            } else {
                status = .failed(error)
            }
        } else {
            status = .completed
        }
        
        completeSpan(spanId, status: status)
    }
    
    // MARK: - Metrics
    
    /// Performance metrics.
    public struct Metrics: Sendable {
        public var totalSpansStarted: Int = 0
        public var totalSpansCompleted: Int = 0
        public var totalSpansFailed: Int = 0
        public var totalSpansCancelled: Int = 0
        public var averageDuration: Duration = .zero
        public var maxDuration: Duration = .zero
        public var minDuration: Duration = .nanoseconds(Int64.max)
    }
    
    /// Gets current metrics.
    public func getMetrics() -> Metrics {
        metrics
    }
    
    /// Gets all completed spans.
    public func getCompletedSpans() -> [TraceSpan] {
        completedSpans
    }
    
    /// Gets active spans.
    public func getActiveSpans() -> [TraceSpan] {
        activeSpanStack.compactMap { spans[$0] }
    }
    
    /// Clears all stored spans and resets metrics.
    public func reset() {
        spans.removeAll()
        completedSpans.removeAll()
        activeSpanStack.removeAll()
        metrics = Metrics()
    }
    
    // MARK: - Configuration
    
    /// Updates configuration.
    public func setConfiguration(_ config: Configuration) {
        self.configuration = config
    }
    
    // MARK: - Private Methods
    
    private func completeSpan(_ spanId: UUID, status: TraceSpan.Status) {
        guard var span = spans[spanId] else { return }
        
        span.endTime = .now
        span.status = status
        
        if let duration = span.duration {
            updateMetrics(duration: duration, status: status)
            
            let durationMs = Double(duration.components.seconds) * 1000 +
                            Double(duration.components.attoseconds) / 1_000_000_000_000_000
            
            switch status {
            case .completed:
                log(.trace, "✅ Completed: \(span.name) (\(String(format: "%.2f", durationMs))ms)")
            case .failed(let error):
                log(.error, "❌ Failed: \(span.name) - \(error)")
            case .cancelled:
                log(.warning, "⏹️ Cancelled: \(span.name)")
            case .running:
                break
            }
        }
        
        spans.removeValue(forKey: spanId)
        activeSpanStack.removeAll { $0 == spanId }
        
        completedSpans.append(span)
        if completedSpans.count > configuration.maxStoredSpans {
            completedSpans.removeFirst()
        }
    }
    
    private func updateMetrics(duration: Duration, status: TraceSpan.Status) {
        switch status {
        case .completed:
            metrics.totalSpansCompleted += 1
        case .failed:
            metrics.totalSpansFailed += 1
        case .cancelled:
            metrics.totalSpansCancelled += 1
        case .running:
            break
        }
        
        if duration > metrics.maxDuration {
            metrics.maxDuration = duration
        }
        if duration < metrics.minDuration {
            metrics.minDuration = duration
        }
        
        let total = metrics.totalSpansCompleted + metrics.totalSpansFailed
        if total > 0 {
            // Simplified average calculation
            let currentTotal = metrics.averageDuration * (total - 1)
            metrics.averageDuration = (currentTotal + duration) / total
        }
    }
    
    private func emit(_ message: String, level: LogLevel) {
        switch configuration.logOutput {
        case .osLog:
            switch level {
            case .trace, .debug:
                logger?.debug("\(message)")
            case .info:
                logger?.info("\(message)")
            case .warning:
                logger?.warning("\(message)")
            case .error:
                logger?.error("\(message)")
            case .critical:
                logger?.critical("\(message)")
            }
        case .print:
            print(message)
        case .custom(let handler):
            handler(message)
        }
    }
}

// MARK: - Global Debug Functions

/// Shared debug instance for quick logging.
public let asyncDebug = AsyncDebugger(
    subsystem: "SwiftConcurrency",
    category: "Debug"
)

/// Quick trace for async operations.
///
/// ```swift
/// let data = try await asyncTrace("fetch") {
///     try await api.fetchData()
/// }
/// ```
public func asyncTrace<T: Sendable>(
    _ name: String,
    operation: () async throws -> T
) async rethrows -> T {
    try await asyncDebug.trace(name, operation: operation)
}

// MARK: - Task Debug Extension

extension Task where Success: Sendable {
    
    /// Adds debug logging to a task.
    ///
    /// - Parameter name: Debug name for the task.
    /// - Returns: A task with debug logging.
    public static func debug(
        name: String,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, Error> {
        Task<Success, Error>(priority: priority) {
            try await asyncDebug.trace(name) {
                try await operation()
            }
        }
    }
}

// MARK: - AsyncSequence Debug Extension

extension AsyncSequence where Self: Sendable, Element: Sendable {
    
    /// Logs each element as it's received.
    ///
    /// - Parameters:
    ///   - label: Label for log messages.
    ///   - debugger: Debugger to use.
    public func debug(
        _ label: String = "Element",
        using debugger: AsyncDebugger = asyncDebug
    ) -> AsyncDebugSequence<Self> {
        AsyncDebugSequence(base: self, label: label, debugger: debugger)
    }
}

/// Debug wrapper for async sequences.
public struct AsyncDebugSequence<Base: AsyncSequence>: AsyncSequence, Sendable
where Base: Sendable, Base.Element: Sendable {
    
    public typealias Element = Base.Element
    
    private let base: Base
    private let label: String
    private let debugger: AsyncDebugger
    
    init(base: Base, label: String, debugger: AsyncDebugger) {
        self.base = base
        self.label = label
        self.debugger = debugger
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: base.makeAsyncIterator(),
            label: label,
            debugger: debugger
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let label: String
        private let debugger: AsyncDebugger
        private var index = 0
        
        init(iterator: Base.AsyncIterator, label: String, debugger: AsyncDebugger) {
            self.iterator = iterator
            self.label = label
            self.debugger = debugger
        }
        
        public mutating func next() async throws -> Element? {
            let element = try await iterator.next()
            
            if let element = element {
                await debugger.debug("\(label)[\(index)]: \(element)")
                index += 1
            } else {
                await debugger.debug("\(label): sequence completed after \(index) elements")
            }
            
            return element
        }
    }
}
