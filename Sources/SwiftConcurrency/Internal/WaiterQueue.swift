/// A first-in, first-out queue of suspended callers that also supports removing any entry by
/// its identifier, which is what a cancelled caller needs.
///
/// Removal by identifier leaves a stale identifier in `order`; stale identifiers are skipped by
/// `popFirst()` and compacted away once they outnumber the live entries, so the memory a queue
/// uses stays proportional to the number of callers that are still waiting, however many were
/// cancelled.
struct WaiterQueue<Value> {
    private var values: [UInt64: Value] = [:]
    private var order: [UInt64] = []
    private var head = 0
    private var nextID: UInt64 = 0

    /// The number of entries that are still waiting.
    var count: Int { values.count }

    var isEmpty: Bool { values.isEmpty }

    /// The number of identifiers kept in `order`, stale ones included. Tests use it to check
    /// that cancelled entries do not accumulate.
    var storedIdentifierCount: Int { order.count - head }

    /// Returns a new identifier. Identifiers are never reused within one queue.
    mutating func makeID() -> UInt64 {
        defer { nextID &+= 1 }
        return nextID
    }

    mutating func append(_ value: Value, id: UInt64) {
        values[id] = value
        order.append(id)
    }

    /// Removes and returns the entry with `id`, or `nil` when it was already removed.
    mutating func remove(id: UInt64) -> Value? {
        guard let value = values.removeValue(forKey: id) else { return nil }
        compactIfMostlyStale()
        return value
    }

    mutating func popFirst() -> (id: UInt64, value: Value)? {
        while head < order.count {
            let id = order[head]
            head += 1
            if let value = values.removeValue(forKey: id) {
                compactIfMostlyStale()
                return (id, value)
            }
        }
        compactIfMostlyStale()
        return nil
    }

    /// Removes and returns every entry in queue order.
    mutating func removeAll() -> [Value] {
        var result: [Value] = []
        result.reserveCapacity(values.count)
        while let entry = popFirst() {
            result.append(entry.value)
        }
        order.removeAll()
        head = 0
        return result
    }

    /// Removes and returns, in queue order, every entry for which `shouldRemove` is true.
    mutating func removeAll(where shouldRemove: (Value) -> Bool) -> [Value] {
        var removed: [Value] = []
        var kept: [UInt64] = []
        for id in order[head...] {
            guard let value = values[id] else { continue }
            if shouldRemove(value) {
                values[id] = nil
                removed.append(value)
            } else {
                kept.append(id)
            }
        }
        order = kept
        head = 0
        return removed
    }

    private static var compactionThreshold: Int { 32 }

    private mutating func compactIfMostlyStale() {
        if head == order.count {
            order.removeAll(keepingCapacity: order.count <= Self.compactionThreshold * 4)
            head = 0
            return
        }
        let pending = order.count - head
        let stale = pending - values.count
        guard head > Self.compactionThreshold || stale > Self.compactionThreshold else { return }
        guard head > pending || stale > values.count else { return }
        order = order[head...].filter { values[$0] != nil }
        head = 0
    }
}
