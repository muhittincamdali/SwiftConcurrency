import Foundation

// MARK: - ConcurrentMap

/// Provides concurrent mapping capabilities on sequences using Swift task groups.
///
/// Transforms each element of the sequence concurrently while preserving
/// the original order of elements in the output array.
extension Sequence where Element: Sendable {

    /// Concurrently maps each element of the sequence using the provided transform closure.
    ///
    /// Elements are processed in parallel using a `TaskGroup`, and results are
    /// collected in the original sequence order.
    ///
    /// - Parameter transform: An async throwing closure that transforms each element.
    /// - Returns: An array of transformed elements in their original order.
    /// - Throws: Rethrows any error from the transform closure.
    ///
    /// ```swift
    /// let urls: [URL] = [/* ... */]
    /// let data = try await urls.concurrentMap { url in
    ///     let (data, _) = try await URLSession.shared.data(from: url)
    ///     return data
    /// }
    /// ```
    public func concurrentMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let indexedElements = Array(self).enumerated().map { ($0.offset, $0.element) }

        return try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for (index, element) in indexedElements {
                group.addTask {
                    let result = try await transform(element)
                    return (index, result)
                }
            }

            var results = [(Int, T)]()
            results.reserveCapacity(indexedElements.count)

            for try await indexedResult in group {
                results.append(indexedResult)
            }

            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }

    /// Concurrently maps each element using a non-throwing transform.
    ///
    /// - Parameter transform: An async closure that transforms each element.
    /// - Returns: An array of transformed elements in their original order.
    public func concurrentMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async -> T
    ) async -> [T] {
        let indexedElements = Array(self).enumerated().map { ($0.offset, $0.element) }

        return await withTaskGroup(of: (Int, T).self) { group in
            for (index, element) in indexedElements {
                group.addTask {
                    let result = await transform(element)
                    return (index, result)
                }
            }

            var results = [(Int, T)]()
            results.reserveCapacity(indexedElements.count)

            for await indexedResult in group {
                results.append(indexedResult)
            }

            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }

    /// Concurrently performs a `compactMap` over the sequence.
    ///
    /// - Parameter transform: An async throwing closure returning an optional value.
    /// - Returns: An array of non-nil results in their original order.
    public func concurrentCompactMap<T: Sendable>(
        _ transform: @Sendable @escaping (Element) async throws -> T?
    ) async throws -> [T] {
        let mapped = try await concurrentMap(transform)
        return mapped.compactMap { $0 }
    }
}
