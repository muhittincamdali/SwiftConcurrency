extension Sequence where Element: Sendable {
    /// Transforms every element in parallel, with at most `maxConcurrency` transforms running at
    /// once, and returns the results in the order of the elements.
    ///
    /// ```swift
    /// let thumbnails = try await photos.concurrentMap(maxConcurrency: 4) { photo in
    ///     try await renderer.thumbnail(for: photo)
    /// }
    /// ```
    ///
    /// When a transform throws, the transforms that are still running are cancelled, no new ones
    /// start, and the error is rethrown.
    ///
    /// - Parameters:
    ///   - maxConcurrency: The largest number of transforms that run at the same time. Choose it
    ///     for the resource the transform uses (connections, memory, CPU cores); the limit keeps a
    ///     sequence of thousands of elements from starting thousands of tasks.
    ///   - transform: The work to run for each element.
    /// - Precondition: `maxConcurrency` is 1 or more.
    public func concurrentMap<Transformed: Sendable>(
        maxConcurrency: Int,
        _ transform: @escaping @Sendable (Element) async throws -> Transformed
    ) async throws -> [Transformed] {
        precondition(maxConcurrency >= 1, "concurrentMap needs maxConcurrency of 1 or more, got \(maxConcurrency)")
        let elements = Array(self)
        guard !elements.isEmpty else { return [] }
        return try await withThrowingTaskGroup(of: (Int, Transformed).self) { group in
            var results = [Transformed?](repeating: nil, count: elements.count)
            var nextIndex = 0
            func startNext() {
                let index = nextIndex
                let element = elements[index]
                nextIndex += 1
                group.addTask { (index, try await transform(element)) }
            }
            while nextIndex < Swift.min(maxConcurrency, elements.count) {
                startNext()
            }
            while let (index, value) = try await group.next() {
                results[index] = value
                if nextIndex < elements.count, !Task.isCancelled {
                    startNext()
                }
            }
            try Task.checkCancellation()
            return results.map { $0! }
        }
    }

    /// Runs `body` for every element in parallel, with at most `maxConcurrency` running at once.
    ///
    /// When `body` throws, the calls that are still running are cancelled, no new ones start,
    /// and the error is rethrown.
    public func concurrentForEach(
        maxConcurrency: Int,
        _ body: @escaping @Sendable (Element) async throws -> Void
    ) async throws {
        _ = try await concurrentMap(maxConcurrency: maxConcurrency, body)
    }
}
