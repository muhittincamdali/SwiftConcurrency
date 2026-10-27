/// How long ``retry(maxAttempts:backoff:clock:shouldRetry:operation:)`` waits before each new
/// attempt.
///
/// ```swift
/// .exponential(initial: .milliseconds(200), multiplier: 2, maxDelay: .seconds(10))
/// // 0.2 s, 0.4 s, 0.8 s, 1.6 s … never more than 10 s
///
/// .exponential().jittered(.full)
/// // a random delay between 0 and the exponential one, so that many clients that failed at
/// // the same moment do not all retry at the same moment
/// ```
///
/// Delays are computed in floating point and capped at `maxDelay` before they become a
/// `Duration`, so no retry number, however large, overflows or traps.
public struct Backoff: Sendable, Hashable {
    /// Random variation added to each delay.
    public enum Jitter: Sendable, Hashable {
        /// The delay is used as computed.
        case none
        /// A random delay between zero and the computed one ("full jitter").
        case full
        /// Half the computed delay plus a random part of up to the other half ("equal jitter").
        case equal
    }

    private enum Curve: Sendable, Hashable {
        case constant(Duration)
        case linear(initial: Duration, increment: Duration, maxDelay: Duration)
        case exponential(initial: Duration, multiplier: Double, maxDelay: Duration)
    }

    private let curve: Curve

    /// The jitter applied by ``delay(forRetry:using:)``.
    public let jitter: Jitter

    private init(curve: Curve, jitter: Jitter = .none) {
        self.curve = curve
        self.jitter = jitter
    }

    /// Retry at once, without waiting.
    public static let immediate = Backoff(curve: .constant(.zero))

    /// The same delay before every retry.
    ///
    /// - Precondition: `delay` is not negative.
    public static func constant(_ delay: Duration) -> Backoff {
        precondition(delay >= .zero, "Backoff.constant needs a delay of zero or more, got \(delay)")
        return Backoff(curve: .constant(delay))
    }

    /// A delay that grows by `increment` after each retry: `initial`, `initial + increment`, …
    ///
    /// - Precondition: All durations are zero or more.
    public static func linear(
        initial: Duration,
        increment: Duration,
        maxDelay: Duration = .seconds(60)
    ) -> Backoff {
        precondition(initial >= .zero && increment >= .zero && maxDelay >= .zero,
                     "Backoff.linear needs durations of zero or more")
        return Backoff(curve: .linear(initial: initial, increment: increment, maxDelay: maxDelay))
    }

    /// A delay that is multiplied by `multiplier` after each retry: `initial`,
    /// `initial × multiplier`, `initial × multiplier²`, … capped at `maxDelay`.
    ///
    /// - Precondition: The durations are zero or more, and `multiplier` is a finite number of
    ///   1 or more.
    public static func exponential(
        initial: Duration = .milliseconds(200),
        multiplier: Double = 2,
        maxDelay: Duration = .seconds(30)
    ) -> Backoff {
        precondition(initial >= .zero && maxDelay >= .zero, "Backoff.exponential needs durations of zero or more")
        precondition(multiplier.isFinite && multiplier >= 1,
                     "Backoff.exponential needs a finite multiplier of 1 or more, got \(multiplier)")
        return Backoff(curve: .exponential(initial: initial, multiplier: multiplier, maxDelay: maxDelay))
    }

    /// The same backoff with random variation added to each delay.
    public func jittered(_ jitter: Jitter) -> Backoff {
        Backoff(curve: curve, jitter: jitter)
    }

    /// The delay before retry number `retry` (1 is the retry after the first failure), without
    /// jitter.
    ///
    /// Retry numbers below 1 are treated as 1.
    public func baseDelay(forRetry retry: Int) -> Duration {
        let index = Double(max(retry, 1) - 1)
        switch curve {
        case .constant(let delay):
            return delay
        case let .linear(initial, increment, maxDelay):
            let seconds = initial.seconds + increment.seconds * index
            return Self.duration(seconds: seconds, cappedAt: maxDelay)
        case let .exponential(initial, multiplier, maxDelay):
            let seconds = initial.seconds * Self.power(multiplier, index)
            return Self.duration(seconds: seconds, cappedAt: maxDelay)
        }
    }

    /// The delay before retry number `retry`, with ``jitter`` applied using `generator`.
    public func delay<Generator: RandomNumberGenerator>(
        forRetry retry: Int,
        using generator: inout Generator
    ) -> Duration {
        let base = baseDelay(forRetry: retry)
        let seconds = base.seconds
        guard seconds > 0 else { return .zero }
        let jittered: Double
        switch jitter {
        case .none:
            return base
        case .full:
            jittered = Double.random(in: 0...seconds, using: &generator)
        case .equal:
            let half = seconds / 2
            jittered = half + Double.random(in: 0...half, using: &generator)
        }
        // Never more than the base delay; this also keeps the conversion below in range when
        // the base delay is close to the largest `Duration`.
        return jittered < seconds ? .seconds(jittered) : base
    }

    /// The delay before retry number `retry`, with ``jitter`` applied using the system's random
    /// number generator.
    public func delay(forRetry retry: Int) -> Duration {
        var generator = SystemRandomNumberGenerator()
        return delay(forRetry: retry, using: &generator)
    }

    /// `base` raised to `exponent`, computed by repeated squaring so that it stays exact for
    /// small exponents and becomes `+infinity` (not NaN) when it overflows.
    private static func power(_ base: Double, _ exponent: Double) -> Double {
        if base == 1 || exponent == 0 { return 1 }
        // `exponent` is a whole number of at most Int.max - 1, and base >= 1.
        if exponent > 2048 { return .infinity }
        var result = 1.0
        var factor = base
        var remaining = Int(exponent)
        while remaining > 0 {
            if remaining & 1 == 1 { result *= factor }
            factor *= factor
            remaining >>= 1
        }
        return result
    }

    private static func duration(seconds: Double, cappedAt maxDelay: Duration) -> Duration {
        guard seconds.isFinite, seconds < maxDelay.seconds else { return maxDelay }
        return seconds > 0 ? .seconds(seconds) : .zero
    }
}

extension Duration {
    /// The duration in seconds as a floating-point number.
    ///
    /// Division works on the full 128-bit value; `components` would trap for durations longer
    /// than `Int64.max` seconds, which `Duration` can hold.
    var seconds: Double {
        self / .seconds(1)
    }
}
