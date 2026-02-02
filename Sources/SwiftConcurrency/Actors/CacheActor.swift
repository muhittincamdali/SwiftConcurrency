import Foundation

// MARK: - CacheActor

/// A thread-safe, actor-isolated in-memory cache with optional size limits.
///
/// Uses LRU eviction when the maximum entry count is exceeded.
///
/// ```swift
/// let cache = CacheActor<String, Data>(maxCount: 100)
/// await cache.set("key", value: data)
/// let value = await cache.get("key")
/// ```
public actor CacheActor<Key: Hashable & Sendable, Value: Sendable> {

    /// Internal entry tracking access order for LRU eviction.
    private struct Entry {
        let value: Value
        var lastAccess: ContinuousClock.Instant
    }

    /// The underlying storage.
    private var storage: [Key: Entry] = [:]

    /// Maximum number of entries. `nil` means unlimited.
    private let maxCount: Int?

    /// Creates a cache with an optional maximum entry count.
    ///
    /// - Parameter maxCount: Maximum number of entries before eviction begins.
    ///   Pass `nil` for an unbounded cache.
    public init(maxCount: Int? = nil) {
        self.maxCount = maxCount
    }

    /// Retrieves the value for the given key, updating its access time.
    ///
    /// - Parameter key: The key to look up.
    /// - Returns: The cached value, or `nil` if not found.
    public func get(_ key: Key) -> Value? {
        guard var entry = storage[key] else { return nil }
        entry.lastAccess = .now
        storage[key] = entry
        return entry.value
    }

    /// Stores a value for the given key, evicting the oldest entry if needed.
    ///
    /// - Parameters:
    ///   - key: The key to store the value under.
    ///   - value: The value to cache.
    public func set(_ key: Key, value: Value) {
        storage[key] = Entry(value: value, lastAccess: .now)
        evictIfNeeded()
    }

    /// Removes the value for the given key.
    ///
    /// - Parameter key: The key to remove.
    /// - Returns: The removed value, or `nil` if not found.
    @discardableResult
    public func remove(_ key: Key) -> Value? {
        storage.removeValue(forKey: key)?.value
    }

    /// Removes all cached entries.
    public func removeAll() {
        storage.removeAll()
    }

    /// The number of entries currently in the cache.
    public var count: Int {
        storage.count
    }

    /// Whether the cache contains a value for the given key.
    public func contains(_ key: Key) -> Bool {
        storage[key] != nil
    }

    /// All keys currently in the cache.
    public var keys: [Key] {
        Array(storage.keys)
    }

    // MARK: - Private

    /// Evicts the least recently accessed entry if over capacity.
    private func evictIfNeeded() {
        guard let maxCount, storage.count > maxCount else { return }
        let sortedKeys = storage.sorted { $0.value.lastAccess < $1.value.lastAccess }
        let evictCount = storage.count - maxCount
        for (key, _) in sortedKeys.prefix(evictCount) {
            storage.removeValue(forKey: key)
        }
    }
}
