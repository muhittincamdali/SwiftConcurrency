import XCTest
@testable import SwiftConcurrency

final class ConcurrentMapTests: XCTestCase {

    // MARK: - concurrentMap

    func testConcurrentMapPreservesOrder() async throws {
        let input = Array(0..<20)

        let result = try await input.concurrentMap { value -> Int in
            // Simulate variable-duration work
            let delay = UInt64.random(in: 1_000_000...10_000_000)
            try await Task.sleep(nanoseconds: delay)
            return value * 2
        }

        XCTAssertEqual(result, input.map { $0 * 2 })
    }

    func testConcurrentMapWithEmptySequence() async throws {
        let input: [Int] = []
        let result = try await input.concurrentMap { $0 * 2 }
        XCTAssertTrue(result.isEmpty)
    }

    func testConcurrentMapPropagatesError() async {
        let input = [1, 2, 3, 4, 5]

        do {
            _ = try await input.concurrentMap { value -> Int in
                if value == 3 {
                    throw TestError.intentional
                }
                return value
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testConcurrentMapNonThrowingVariant() async {
        let input = [1, 2, 3, 4, 5]
        let result = await input.concurrentMap { $0 * 3 }
        XCTAssertEqual(result, [3, 6, 9, 12, 15])
    }

    // MARK: - concurrentCompactMap

    func testConcurrentCompactMapFiltersNils() async throws {
        let input = Array(0..<10)

        let result = try await input.concurrentCompactMap { value -> Int? in
            value.isMultiple(of: 2) ? value : nil
        }

        XCTAssertEqual(result, [0, 2, 4, 6, 8])
    }

    func testConcurrentMapSingleElement() async throws {
        let result = try await [42].concurrentMap { $0 + 1 }
        XCTAssertEqual(result, [43])
    }

    func testConcurrentMapLargeCollection() async throws {
        let input = Array(0..<100)
        let result = try await input.concurrentMap { $0 }
        XCTAssertEqual(result, input)
    }

    // MARK: - Helpers

    enum TestError: Error {
        case intentional
    }
}
