// Result+Async.swift
// SwiftConcurrency
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

// MARK: - Async Result Initialization

extension Result where Failure == Error {
    
    /// Creates a Result from an async throwing closure.
    ///
    /// ```swift
    /// let result = await Result.async {
    ///     try await fetchData()
    /// }
    /// ```
    ///
    /// - Parameter body: The async throwing closure.
    /// - Returns: Success with the value or failure with the error.
    public static func async(
        catching body: @Sendable () async throws -> Success
    ) async -> Result<Success, Failure> {
        do {
            return .success(try await body())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Async Map Operations

extension Result where Success: Sendable, Failure: Error {
    
    /// Transforms the success value using an async closure.
    ///
    /// ```swift
    /// let result = await userResult.asyncMap { user in
    ///     await fetchProfile(for: user)
    /// }
    /// ```
    ///
    /// - Parameter transform: Async transform for the success value.
    /// - Returns: Transformed result.
    public func asyncMap<NewSuccess: Sendable>(
        _ transform: @Sendable (Success) async -> NewSuccess
    ) async -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return .success(await transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Transforms the success value using a throwing async closure.
    ///
    /// - Parameter transform: Async throwing transform.
    /// - Returns: Transformed result or failure.
    public func asyncMap<NewSuccess: Sendable>(
        _ transform: @Sendable (Success) async throws -> NewSuccess
    ) async -> Result<NewSuccess, Error> {
        switch self {
        case .success(let value):
            do {
                return .success(try await transform(value))
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Transforms the failure using an async closure.
    ///
    /// - Parameter transform: Async transform for the failure.
    /// - Returns: Result with transformed failure.
    public func asyncMapError<NewFailure: Error>(
        _ transform: @Sendable (Failure) async -> NewFailure
    ) async -> Result<Success, NewFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(await transform(error))
        }
    }
}

// MARK: - Async FlatMap Operations

extension Result where Success: Sendable, Failure: Error {
    
    /// Flat maps the success value using an async closure.
    ///
    /// ```swift
    /// let result = await userIdResult.asyncFlatMap { id in
    ///     await Result.async { try await fetchUser(id: id) }
    /// }
    /// ```
    ///
    /// - Parameter transform: Async transform returning a Result.
    /// - Returns: The flattened result.
    public func asyncFlatMap<NewSuccess: Sendable>(
        _ transform: @Sendable (Success) async -> Result<NewSuccess, Failure>
    ) async -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return await transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Flat maps the success value, allowing different error types.
    ///
    /// - Parameter transform: Async transform returning a Result.
    /// - Returns: The flattened result.
    public func asyncFlatMap<NewSuccess: Sendable, NewFailure: Error>(
        _ transform: @Sendable (Success) async -> Result<NewSuccess, NewFailure>
    ) async -> Result<NewSuccess, Error> {
        switch self {
        case .success(let value):
            let result = await transform(value)
            return result.mapError { $0 as Error }
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Async Recovery

extension Result where Success: Sendable, Failure: Error {
    
    /// Recovers from failure using an async closure.
    ///
    /// ```swift
    /// let result = await cachedResult.asyncRecover { error in
    ///     await fetchFromNetwork()
    /// }
    /// ```
    ///
    /// - Parameter recovery: Async closure to recover from failure.
    /// - Returns: Original success or recovered value.
    public func asyncRecover(
        _ recovery: @Sendable (Failure) async -> Success
    ) async -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            return await recovery(error)
        }
    }
    
    /// Recovers from failure using a throwing async closure.
    ///
    /// - Parameter recovery: Async throwing recovery closure.
    /// - Returns: Original success, recovered value, or new failure.
    public func asyncRecover(
        _ recovery: @Sendable (Failure) async throws -> Success
    ) async -> Result<Success, Error> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            do {
                return .success(try await recovery(error))
            } catch {
                return .failure(error)
            }
        }
    }
}

// MARK: - Async Side Effects

extension Result where Success: Sendable, Failure: Error {
    
    /// Performs an async side effect on success.
    ///
    /// ```swift
    /// await result.asyncOnSuccess { value in
    ///     await logSuccess(value)
    /// }
    /// ```
    ///
    /// - Parameter action: Action to perform on success.
    /// - Returns: The original result.
    @discardableResult
    public func asyncOnSuccess(
        _ action: @Sendable (Success) async -> Void
    ) async -> Result<Success, Failure> {
        if case .success(let value) = self {
            await action(value)
        }
        return self
    }
    
    /// Performs an async side effect on failure.
    ///
    /// - Parameter action: Action to perform on failure.
    /// - Returns: The original result.
    @discardableResult
    public func asyncOnFailure(
        _ action: @Sendable (Failure) async -> Void
    ) async -> Result<Success, Failure> {
        if case .failure(let error) = self {
            await action(error)
        }
        return self
    }
}

// MARK: - Task Conversion

extension Result where Success: Sendable, Failure: Error {
    
    /// Converts to an async value, throwing on failure.
    ///
    /// ```swift
    /// let value = try await result.asyncGet()
    /// ```
    ///
    /// - Returns: The success value.
    /// - Throws: The failure error.
    public func asyncGet() async throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Returns the success value or a default.
    ///
    /// - Parameter defaultValue: Default value on failure.
    /// - Returns: Success value or default.
    public func asyncGet(
        default defaultValue: @autoclosure @Sendable () async -> Success
    ) async -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return await defaultValue()
        }
    }
}

// MARK: - Combining Results

extension Result where Success: Sendable {
    
    /// Combines two results into a tuple.
    ///
    /// ```swift
    /// let combined = await result1.asyncZip(with: result2)
    /// ```
    ///
    /// - Parameter other: Another result to combine with.
    /// - Returns: Combined result or first failure.
    public func asyncZip<OtherSuccess: Sendable, OtherFailure: Error>(
        with other: @Sendable @autoclosure () async -> Result<OtherSuccess, OtherFailure>
    ) async -> Result<(Success, OtherSuccess), Error> where Failure: Error {
        switch self {
        case .success(let value1):
            let otherResult = await other()
            switch otherResult {
            case .success(let value2):
                return .success((value1, value2))
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Sequence of Results

extension Sequence {
    
    /// Collects results from a sequence, failing fast.
    ///
    /// - Returns: Array of successes or first failure.
    public func collectResults<Success, Failure: Error>() -> Result<[Success], Failure>
    where Element == Result<Success, Failure> {
        var successes: [Success] = []
        for result in self {
            switch result {
            case .success(let value):
                successes.append(value)
            case .failure(let error):
                return .failure(error)
            }
        }
        return .success(successes)
    }
    
    /// Partitions results into successes and failures.
    ///
    /// - Returns: Tuple of successes and failures.
    public func partitionResults<Success, Failure: Error>() -> (successes: [Success], failures: [Failure])
    where Element == Result<Success, Failure> {
        var successes: [Success] = []
        var failures: [Failure] = []
        
        for result in self {
            switch result {
            case .success(let value):
                successes.append(value)
            case .failure(let error):
                failures.append(error)
            }
        }
        
        return (successes, failures)
    }
}
