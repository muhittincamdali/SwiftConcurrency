import Foundation

/// Main entry point for the SwiftConcurrency utility kit.
public enum SwiftConcurrency {
    public static let version = "2.0.0"
}

/// A thread-safe wrapper for mutable state using a Swift actor.
public actor AsyncState<T: Sendable> {
    private var value: T
    
    public init(_ value: T) {
        self.value = value
    }
    
    public func get() -> T {
        return value
    }
    
    public func set(_ newValue: T) {
        self.value = newValue
    }
    
    public func update(_ body: @Sendable (inout T) -> Void) {
        body(&value)
    }
}
