import XCTest
@testable import SwiftConcurrency

final class AsyncChannelTests: XCTestCase {

    func testBasicSendAndReceive() async {
        let channel = AsyncChannel<Int>(capacity: 3)

        await channel.send(1)
        await channel.send(2)
        await channel.send(3)

        Task {
            try? await Task.sleep(for: .milliseconds(50))
            await channel.finish()
        }

        var received: [Int] = []
        for await value in channel {
            received.append(value)
        }

        XCTAssertEqual(received, [1, 2, 3])
    }

    func testChannelFinishEndsIteration() async {
        let channel = AsyncChannel<String>(capacity: 1)

        Task {
            await channel.send("hello")
            await channel.finish()
        }

        var messages: [String] = []
        for await message in channel {
            messages.append(message)
        }

        XCTAssertEqual(messages, ["hello"])
    }

    func testEmptyChannelFinishesImmediately() async {
        let channel = AsyncChannel<Int>(capacity: 5)

        Task {
            await channel.finish()
        }

        var count = 0
        for await _ in channel {
            count += 1
        }

        XCTAssertEqual(count, 0)
    }

    func testMultipleProducers() async {
        let channel = AsyncChannel<Int>(capacity: 10)

        Task {
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<5 {
                    group.addTask {
                        await channel.send(i)
                    }
                }
                await group.waitForAll()
                await channel.finish()
            }
        }

        var received: [Int] = []
        for await value in channel {
            received.append(value)
        }

        XCTAssertEqual(received.sorted(), [0, 1, 2, 3, 4])
    }

    func testChannelCount() async {
        let channel = AsyncChannel<Int>(capacity: 5)
        await channel.send(1)
        await channel.send(2)

        let count = await channel.count
        XCTAssertEqual(count, 2)
        await channel.finish()
    }
}
