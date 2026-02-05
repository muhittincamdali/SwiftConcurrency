// DeadlockDetector.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import os.log

// MARK: - DeadlockDetector

/// Detects potential deadlocks and long-running async operations.
///
/// Monitors task execution and reports when operations exceed
/// expected durations, which may indicate deadlocks or performance issues.
///
/// ```swift
/// let detector = DeadlockDetector(threshold: .seconds(30))
/// detector.start()
///
/// // Monitor an operation
/// try await detector.monitor("Database query") {
///     try await db.query()
/// }
/// ```
public actor DeadlockDetector {
    
    // MARK: - Types
    
    /// A monitored operation.
    public struct MonitoredOperation: Identifiable, Sendable {
        public let id: UUID
        public let name: String
        public let startTime: ContinuousClock.Instant
        public let threshold: Duration
        public let stackTrace: String?
        public var warnings: [Warning]
        
        public struct Warning: Sendable {
            public let time: ContinuousClock.Instant
            public let duration: Duration
            public let message: String
        }
        
        public var elapsed: Duration {
            ContinuousClock.now - startTime
        }
        
        public var isOverThreshold: Bool {
            elapsed > threshold
        }
    }
    
    /// Alert level for detected issues.
    public enum AlertLevel: Sendable {
        case warning
        case critical
        case potential
    }
    
    /// Handler for deadlock alerts.
    public typealias AlertHandler = @Sendable (AlertLevel, String, MonitoredOperation) -> Void
    
    /// Configuration.
    public struct Configuration: Sendable {
        /// Default timeout threshold.
        public var defaultThreshold: Duration
        
        /// Check interval.
        public var checkInterval: Duration
        
        /// Whether to capture stack traces.
        public var captureStackTraces: Bool
        
        /// Maximum monitored operations.
        public var maxOperations: Int
        
        /// Alert handler.
        public var alertHandler: AlertHandler?
        
        public init(
            defaultThreshold: Duration = .seconds(30),
            checkInterval: Duration = .seconds(5),
            captureStackTraces: Bool = true,
            maxOperations: Int = 1000,
            alertHandler: AlertHandler? = nil
        ) {
            self.defaultThreshold = defaultThreshold
            self.checkInterval = checkInterval
            self.captureStackTraces = captureStackTraces
            self.maxOperations = maxOperations
            self.alertHandler = alertHandler
        }
    }
    
    // MARK: - Properties
    
    private var configuration: Configuration
    private var operations: [UUID: MonitoredOperation] = [:]
    private var monitorTask: Task<Void, Never>?
    private var isRunning = false
    private let logger = Logger(subsystem: "SwiftConcurrency", category: "DeadlockDetector")
    
    // Statistics
    private var totalWarnings = 0
    private var totalCriticals = 0
    private var longestOperation: MonitoredOperation?
    
    // MARK: - Initialization
    
    /// Creates a deadlock detector.
    ///
    /// - Parameter configuration: Detection configuration.
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    /// Convenience initializer with threshold.
    ///
    /// - Parameter threshold: Default threshold for operations.
    public init(threshold: Duration) {
        self.configuration = Configuration(defaultThreshold: threshold)
    }
    
    // MARK: - Lifecycle
    
    /// Starts the detector's monitoring loop.
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        monitorTask = Task {
            await monitorLoop()
        }
    }
    
    /// Stops the detector.
    public func stop() {
        isRunning = false
        monitorTask?.cancel()
        monitorTask = nil
    }
    
    // MARK: - Monitoring
    
    /// Monitors an async operation.
    ///
    /// - Parameters:
    ///   - name: Name of the operation.
    ///   - threshold: Custom threshold (uses default if nil).
    ///   - operation: The operation to monitor.
    /// - Returns: Operation result.
    public func monitor<T: Sendable>(
        _ name: String,
        threshold: Duration? = nil,
        operation: () async throws -> T
    ) async rethrows -> T {
        let id = UUID()
        let effectiveThreshold = threshold ?? configuration.defaultThreshold
        
        let stackTrace = configuration.captureStackTraces
            ? Thread.callStackSymbols.joined(separator: "\n")
            : nil
        
        let monitored = MonitoredOperation(
            id: id,
            name: name,
            startTime: .now,
            threshold: effectiveThreshold,
            stackTrace: stackTrace,
            warnings: []
        )
        
        operations[id] = monitored
        
        defer {
            if let op = operations.removeValue(forKey: id) {
                updateLongestOperation(op)
            }
        }
        
        return try await operation()
    }
    
    /// Begins monitoring a named operation.
    ///
    /// - Parameters:
    ///   - name: Operation name.
    ///   - threshold: Custom threshold.
    /// - Returns: Monitor handle.
    public func beginMonitoring(
        _ name: String,
        threshold: Duration? = nil
    ) -> MonitorHandle {
        let id = UUID()
        let effectiveThreshold = threshold ?? configuration.defaultThreshold
        
        let stackTrace = configuration.captureStackTraces
            ? Thread.callStackSymbols.joined(separator: "\n")
            : nil
        
        let monitored = MonitoredOperation(
            id: id,
            name: name,
            startTime: .now,
            threshold: effectiveThreshold,
            stackTrace: stackTrace,
            warnings: []
        )
        
        operations[id] = monitored
        
        return MonitorHandle(id: id, detector: self)
    }
    
    /// Ends monitoring for a handle.
    internal func endMonitoring(_ id: UUID) {
        if let op = operations.removeValue(forKey: id) {
            updateLongestOperation(op)
        }
    }
    
    // MARK: - Status
    
    /// Gets all currently monitored operations.
    public func getActiveOperations() -> [MonitoredOperation] {
        Array(operations.values)
    }
    
    /// Gets operations that have exceeded their threshold.
    public func getOverdueOperations() -> [MonitoredOperation] {
        operations.values.filter { $0.isOverThreshold }
    }
    
    /// Gets monitoring statistics.
    public func getStatistics() -> Statistics {
        Statistics(
            activeOperations: operations.count,
            overdueOperations: getOverdueOperations().count,
            totalWarnings: totalWarnings,
            totalCriticals: totalCriticals,
            longestOperationName: longestOperation?.name,
            longestOperationDuration: longestOperation?.elapsed
        )
    }
    
    /// Statistics structure.
    public struct Statistics: Sendable {
        public let activeOperations: Int
        public let overdueOperations: Int
        public let totalWarnings: Int
        public let totalCriticals: Int
        public let longestOperationName: String?
        public let longestOperationDuration: Duration?
    }
    
    // MARK: - Configuration
    
    /// Updates configuration.
    public func setConfiguration(_ config: Configuration) {
        self.configuration = config
    }
    
    /// Sets the alert handler.
    public func setAlertHandler(_ handler: @escaping AlertHandler) {
        configuration.alertHandler = handler
    }
    
    // MARK: - Private Methods
    
    private func monitorLoop() async {
        while isRunning && !Task.isCancelled {
            checkOperations()
            
            do {
                try await Task.sleep(for: configuration.checkInterval)
            } catch {
                break
            }
        }
    }
    
    private func checkOperations() {
        let now = ContinuousClock.now
        
        for (id, var operation) in operations {
            let elapsed = now - operation.startTime
            
            if elapsed > operation.threshold {
                let multiplier = Int(elapsed / operation.threshold)
                
                let level: AlertLevel
                let message: String
                
                if multiplier >= 3 {
                    level = .critical
                    message = "CRITICAL: '\(operation.name)' running for \(formatDuration(elapsed)) (>\(multiplier)x threshold)"
                    totalCriticals += 1
                } else {
                    level = .warning
                    message = "WARNING: '\(operation.name)' running for \(formatDuration(elapsed)) (>\(multiplier)x threshold)"
                    totalWarnings += 1
                }
                
                // Check if we already warned at this level
                let warningKey = "threshold_\(multiplier)"
                let alreadyWarned = operation.warnings.contains { w in
                    w.message.contains(warningKey)
                }
                
                if !alreadyWarned {
                    let warning = MonitoredOperation.Warning(
                        time: now,
                        duration: elapsed,
                        message: "\(warningKey): \(message)"
                    )
                    operation.warnings.append(warning)
                    operations[id] = operation
                    
                    logger.warning("\(message)")
                    
                    if let stackTrace = operation.stackTrace {
                        logger.debug("Stack trace:\n\(stackTrace)")
                    }
                    
                    configuration.alertHandler?(level, message, operation)
                }
            }
        }
    }
    
    private func updateLongestOperation(_ operation: MonitoredOperation) {
        if let longest = longestOperation {
            if operation.elapsed > longest.elapsed {
                longestOperation = operation
            }
        } else {
            longestOperation = operation
        }
    }
    
    private func formatDuration(_ duration: Duration) -> String {
        let seconds = duration.components.seconds
        let attoseconds = duration.components.attoseconds
        let totalSeconds = Double(seconds) + Double(attoseconds) / 1e18
        
        if totalSeconds < 1 {
            return String(format: "%.0fms", totalSeconds * 1000)
        } else if totalSeconds < 60 {
            return String(format: "%.1fs", totalSeconds)
        } else {
            let minutes = Int(totalSeconds) / 60
            let secs = Int(totalSeconds) % 60
            return "\(minutes)m \(secs)s"
        }
    }
}

// MARK: - MonitorHandle

/// Handle for ending monitoring.
public struct MonitorHandle: Sendable {
    let id: UUID
    let detector: DeadlockDetector
    
    /// Ends monitoring.
    public func end() async {
        await detector.endMonitoring(id)
    }
}

// MARK: - TimeoutGuard

/// A guard that ensures operations complete within a timeout.
///
/// Unlike standard timeout, this provides detailed logging
/// and optional recovery actions.
///
/// ```swift
/// let guard = TimeoutGuard(timeout: .seconds(10)) { elapsed in
///     logger.error("Operation timed out after \(elapsed)")
/// }
///
/// try await guard.protect {
///     try await slowOperation()
/// }
/// ```
public actor TimeoutGuard {
    
    // MARK: - Types
    
    /// Error when timeout is exceeded.
    public struct TimeoutError: Error, Sendable {
        public let operationName: String?
        public let timeout: Duration
        public let actualDuration: Duration
        
        public var localizedDescription: String {
            let name = operationName ?? "Operation"
            return "\(name) timed out after \(timeout)"
        }
    }
    
    /// Handler called when timeout occurs (before throwing).
    public typealias TimeoutHandler = @Sendable (Duration) async -> Void
    
    // MARK: - Properties
    
    private let timeout: Duration
    private let onTimeout: TimeoutHandler?
    
    // MARK: - Initialization
    
    /// Creates a timeout guard.
    ///
    /// - Parameters:
    ///   - timeout: Maximum duration.
    ///   - onTimeout: Handler called on timeout.
    public init(
        timeout: Duration,
        onTimeout: TimeoutHandler? = nil
    ) {
        self.timeout = timeout
        self.onTimeout = onTimeout
    }
    
    // MARK: - Protection
    
    /// Protects an operation with a timeout.
    ///
    /// - Parameters:
    ///   - name: Optional operation name for errors.
    ///   - operation: The operation to protect.
    /// - Returns: Operation result.
    /// - Throws: `TimeoutError` if timeout exceeded.
    public func protect<T: Sendable>(
        named name: String? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let startTime = ContinuousClock.now
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: self.timeout)
                throw TimeoutError(
                    operationName: name,
                    timeout: self.timeout,
                    actualDuration: ContinuousClock.now - startTime
                )
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError(
                    operationName: name,
                    timeout: timeout,
                    actualDuration: ContinuousClock.now - startTime
                )
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Protects with optional fallback on timeout.
    ///
    /// - Parameters:
    ///   - name: Operation name.
    ///   - fallback: Value to return on timeout.
    ///   - operation: The operation.
    /// - Returns: Result or fallback value.
    public func protect<T: Sendable>(
        named name: String? = nil,
        fallback: @autoclosure @escaping @Sendable () -> T,
        operation: @escaping @Sendable () async throws -> T
    ) async -> T {
        do {
            return try await protect(named: name, operation: operation)
        } catch {
            if let handler = onTimeout {
                await handler(timeout)
            }
            return fallback()
        }
    }
}

// MARK: - ProgressMonitor

/// Monitors progress of long-running operations.
///
/// Reports when operations don't make progress for extended periods.
public actor ProgressMonitor<Progress: Sendable & Equatable> {
    
    // MARK: - Types
    
    /// Handler for stalled progress.
    public typealias StallHandler = @Sendable (Progress, Duration) async -> Void
    
    // MARK: - Properties
    
    private let stallThreshold: Duration
    private let onStall: StallHandler?
    
    private var currentProgress: Progress?
    private var lastProgressTime: ContinuousClock.Instant?
    private var monitorTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Creates a progress monitor.
    ///
    /// - Parameters:
    ///   - stallThreshold: Time without progress before alert.
    ///   - onStall: Handler for stalled progress.
    public init(
        stallThreshold: Duration = .seconds(30),
        onStall: StallHandler? = nil
    ) {
        self.stallThreshold = stallThreshold
        self.onStall = onStall
    }
    
    // MARK: - Monitoring
    
    /// Updates progress.
    public func update(_ progress: Progress) {
        if currentProgress != progress {
            currentProgress = progress
            lastProgressTime = .now
        }
    }
    
    /// Starts monitoring.
    public func start() {
        monitorTask?.cancel()
        monitorTask = Task {
            await monitorLoop()
        }
    }
    
    /// Stops monitoring.
    public func stop() {
        monitorTask?.cancel()
        monitorTask = nil
    }
    
    /// Resets the monitor.
    public func reset() {
        currentProgress = nil
        lastProgressTime = nil
    }
    
    // MARK: - Private
    
    private func monitorLoop() async {
        while !Task.isCancelled {
            if let lastTime = lastProgressTime,
               let progress = currentProgress {
                let elapsed = ContinuousClock.now - lastTime
                if elapsed > stallThreshold {
                    await onStall?(progress, elapsed)
                }
            }
            
            do {
                try await Task.sleep(for: stallThreshold / 2)
            } catch {
                break
            }
        }
    }
}
