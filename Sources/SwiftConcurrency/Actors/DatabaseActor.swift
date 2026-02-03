// DatabaseActor.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// An actor for serializing database operations.
///
/// `DatabaseActor` provides a thread-safe interface for database operations,
/// ensuring all database access is serialized to prevent data corruption.
///
/// ## Overview
///
/// Use `DatabaseActor` to wrap your database connection and ensure
/// all operations are executed serially on the actor's executor.
///
/// ```swift
/// let db = DatabaseActor(connection: myConnection)
///
/// // All operations are automatically serialized
/// let users = try await db.query("SELECT * FROM users")
/// try await db.execute("INSERT INTO users (name) VALUES (?)", params: ["John"])
/// ```
///
/// ## Topics
///
/// ### Creating Database Actors
/// - ``init(connection:)``
///
/// ### Query Operations
/// - ``query(_:params:)``
/// - ``querySingle(_:params:)``
///
/// ### Mutation Operations
/// - ``execute(_:params:)``
/// - ``executeReturningId(_:params:)``
///
/// ### Transaction Support
/// - ``transaction(_:)``
/// - ``savepoint(_:body:)``
public actor DatabaseActor<Connection: DatabaseConnection> {
    
    // MARK: - Types
    
    /// Database operation result.
    public struct QueryResult: Sendable {
        /// Number of rows affected.
        public let rowsAffected: Int
        /// Last inserted row ID (if applicable).
        public let lastInsertId: Int64?
        /// The rows returned by the query.
        public let rows: [[String: DatabaseValue]]
        
        /// Creates a query result.
        internal init(
            rowsAffected: Int = 0,
            lastInsertId: Int64? = nil,
            rows: [[String: DatabaseValue]] = []
        ) {
            self.rowsAffected = rowsAffected
            self.lastInsertId = lastInsertId
            self.rows = rows
        }
    }
    
    /// Transaction isolation levels.
    public enum IsolationLevel: String, Sendable {
        case readUncommitted = "READ UNCOMMITTED"
        case readCommitted = "READ COMMITTED"
        case repeatableRead = "REPEATABLE READ"
        case serializable = "SERIALIZABLE"
    }
    
    /// Database errors.
    public enum DatabaseError: Error, Sendable {
        case connectionClosed
        case queryFailed(String)
        case transactionFailed(String)
        case savepointFailed(String)
        case constraintViolation(String)
        case timeout
    }
    
    // MARK: - Properties
    
    /// The underlying database connection.
    private var connection: Connection
    
    /// Whether the connection is open.
    private var isOpen: Bool = true
    
    /// Current transaction depth (for nested transactions).
    private var transactionDepth: Int = 0
    
    /// Query statistics.
    private var queryCount: Int = 0
    
    // MARK: - Initialization
    
    /// Creates a database actor with the specified connection.
    ///
    /// - Parameter connection: The database connection to use.
    public init(connection: Connection) {
        self.connection = connection
    }
    
    // MARK: - Query Operations
    
    /// Executes a query and returns all matching rows.
    ///
    /// - Parameters:
    ///   - sql: The SQL query string.
    ///   - params: Query parameters for prepared statements.
    /// - Returns: Array of rows as dictionaries.
    /// - Throws: `DatabaseError` if the query fails.
    public func query(
        _ sql: String,
        params: [DatabaseValue] = []
    ) async throws -> [[String: DatabaseValue]] {
        guard isOpen else {
            throw DatabaseError.connectionClosed
        }
        
        queryCount += 1
        return try await connection.query(sql, params: params)
    }
    
    /// Executes a query and returns the first matching row.
    ///
    /// - Parameters:
    ///   - sql: The SQL query string.
    ///   - params: Query parameters.
    /// - Returns: The first row, or `nil` if no rows match.
    /// - Throws: `DatabaseError` if the query fails.
    public func querySingle(
        _ sql: String,
        params: [DatabaseValue] = []
    ) async throws -> [String: DatabaseValue]? {
        let results = try await query(sql, params: params)
        return results.first
    }
    
    /// Executes a query and returns a single value.
    ///
    /// - Parameters:
    ///   - sql: The SQL query string.
    ///   - params: Query parameters.
    /// - Returns: The value from the first column of the first row.
    /// - Throws: `DatabaseError` if the query fails.
    public func queryScalar<T: DatabaseValue>(
        _ sql: String,
        params: [DatabaseValue] = []
    ) async throws -> T? {
        guard let row = try await querySingle(sql, params: params),
              let firstValue = row.values.first else {
            return nil
        }
        return firstValue as? T
    }
    
    // MARK: - Mutation Operations
    
    /// Executes a non-query SQL statement.
    ///
    /// - Parameters:
    ///   - sql: The SQL statement.
    ///   - params: Statement parameters.
    /// - Returns: The number of rows affected.
    /// - Throws: `DatabaseError` if execution fails.
    @discardableResult
    public func execute(
        _ sql: String,
        params: [DatabaseValue] = []
    ) async throws -> Int {
        guard isOpen else {
            throw DatabaseError.connectionClosed
        }
        
        queryCount += 1
        return try await connection.execute(sql, params: params)
    }
    
    /// Executes an INSERT and returns the new row ID.
    ///
    /// - Parameters:
    ///   - sql: The INSERT statement.
    ///   - params: Statement parameters.
    /// - Returns: The ID of the inserted row.
    /// - Throws: `DatabaseError` if execution fails.
    public func executeReturningId(
        _ sql: String,
        params: [DatabaseValue] = []
    ) async throws -> Int64 {
        guard isOpen else {
            throw DatabaseError.connectionClosed
        }
        
        queryCount += 1
        return try await connection.executeReturningId(sql, params: params)
    }
    
    /// Executes multiple statements in a batch.
    ///
    /// - Parameter statements: Array of SQL statements with parameters.
    /// - Returns: Total number of rows affected.
    /// - Throws: `DatabaseError` if any statement fails.
    @discardableResult
    public func executeBatch(
        _ statements: [(sql: String, params: [DatabaseValue])]
    ) async throws -> Int {
        var totalAffected = 0
        for (sql, params) in statements {
            totalAffected += try await execute(sql, params: params)
        }
        return totalAffected
    }
    
    // MARK: - Transaction Support
    
    /// Executes operations within a transaction.
    ///
    /// The transaction is automatically committed on success or
    /// rolled back on failure.
    ///
    /// ```swift
    /// try await db.transaction { db in
    ///     try await db.execute("INSERT INTO users (name) VALUES (?)", params: ["Alice"])
    ///     try await db.execute("INSERT INTO profiles (user_id) VALUES (?)", params: [1])
    /// }
    /// ```
    ///
    /// - Parameter body: The operations to perform within the transaction.
    /// - Returns: The result of the body closure.
    /// - Throws: `DatabaseError` if the transaction fails.
    public func transaction<T: Sendable>(
        isolation: IsolationLevel = .serializable,
        _ body: @Sendable (isolated DatabaseActor) async throws -> T
    ) async throws -> T {
        try await beginTransaction(isolation: isolation)
        
        do {
            let result = try await body(self)
            try await commitTransaction()
            return result
        } catch {
            try await rollbackTransaction()
            throw error
        }
    }
    
    /// Begins a new transaction.
    private func beginTransaction(isolation: IsolationLevel) async throws {
        if transactionDepth == 0 {
            try await execute("SET TRANSACTION ISOLATION LEVEL \(isolation.rawValue)")
            try await execute("BEGIN TRANSACTION")
        }
        transactionDepth += 1
    }
    
    /// Commits the current transaction.
    private func commitTransaction() async throws {
        transactionDepth -= 1
        if transactionDepth == 0 {
            try await execute("COMMIT")
        }
    }
    
    /// Rolls back the current transaction.
    private func rollbackTransaction() async throws {
        transactionDepth = 0
        try await execute("ROLLBACK")
    }
    
    /// Executes operations within a savepoint.
    ///
    /// - Parameters:
    ///   - name: The savepoint name.
    ///   - body: The operations to perform.
    /// - Returns: The result of the body closure.
    /// - Throws: `DatabaseError` if the operation fails.
    public func savepoint<T: Sendable>(
        _ name: String,
        body: @Sendable (isolated DatabaseActor) async throws -> T
    ) async throws -> T {
        try await execute("SAVEPOINT \(name)")
        
        do {
            let result = try await body(self)
            try await execute("RELEASE SAVEPOINT \(name)")
            return result
        } catch {
            try await execute("ROLLBACK TO SAVEPOINT \(name)")
            throw error
        }
    }
    
    // MARK: - Connection Management
    
    /// Closes the database connection.
    public func close() async throws {
        guard isOpen else { return }
        try await connection.close()
        isOpen = false
    }
    
    /// Checks if the connection is alive.
    public func ping() async throws -> Bool {
        guard isOpen else { return false }
        return try await connection.ping()
    }
    
    /// The total number of queries executed.
    public var totalQueries: Int {
        queryCount
    }
    
    /// Whether currently in a transaction.
    public var inTransaction: Bool {
        transactionDepth > 0
    }
}

// MARK: - Protocols

/// Protocol for database connections.
public protocol DatabaseConnection: Sendable {
    /// Executes a query and returns rows.
    func query(_ sql: String, params: [DatabaseValue]) async throws -> [[String: DatabaseValue]]
    
    /// Executes a statement and returns rows affected.
    func execute(_ sql: String, params: [DatabaseValue]) async throws -> Int
    
    /// Executes an INSERT and returns the new ID.
    func executeReturningId(_ sql: String, params: [DatabaseValue]) async throws -> Int64
    
    /// Closes the connection.
    func close() async throws
    
    /// Checks if connection is alive.
    func ping() async throws -> Bool
}

/// Protocol for database-compatible values.
public protocol DatabaseValue: Sendable {}

extension String: DatabaseValue {}
extension Int: DatabaseValue {}
extension Int64: DatabaseValue {}
extension Double: DatabaseValue {}
extension Bool: DatabaseValue {}
extension Data: DatabaseValue {}
extension Date: DatabaseValue {}

/// Represents a NULL database value.
public struct DatabaseNull: DatabaseValue {
    public init() {}
}
