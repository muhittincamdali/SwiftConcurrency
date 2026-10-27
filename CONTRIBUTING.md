# Contributing to SwiftConcurrency

Thank you for helping. This guide covers what you need to build, test and change the package.

## Ground rules

- Be kind; the [code of conduct](CODE_OF_CONDUCT.md) applies everywhere in the project.
- Report security problems privately, as described in [SECURITY.md](SECURITY.md).
- Open an issue before a large change, so we can agree on the API first.

## Set up

You need Xcode 26 or later (Swift 6.2).

```sh
git clone https://github.com/muhittincamdali/SwiftConcurrency.git
cd SwiftConcurrency
swift build
swift test
```

Open `Package.swift` in Xcode to work on the library, and
`Examples/ConcurrencyDemo/ConcurrencyDemo.xcodeproj` to run the example app.

## Checks to run before a pull request

```sh
swift test                                    # macOS, including the exit tests
xcodebuild test -scheme SwiftConcurrency \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild docbuild -scheme SwiftConcurrency -destination 'generic/platform=iOS'
xcodebuild build -project Examples/ConcurrencyDemo/ConcurrencyDemo.xcodeproj \
  -scheme ConcurrencyDemo -destination 'generic/platform=iOS Simulator'
```

CI runs the same steps, builds for tvOS, watchOS and visionOS, and checks links.

## Writing code

- Every public type is `Sendable` and compiles in the Swift 6 language mode without warnings.
- Every wait must end when its task is cancelled. Register the waiter and check
  `Task.isCancelled` under the same lock, and let the cancellation handler remove the waiter
  under that lock (see `AsyncSemaphore.wait()`).
- Anything that waits for time takes a `Clock`, so it can be tested with `TestClock`.
- Reject invalid configuration with a `precondition` that names the value, and add an exit
  test for it.
- Document every public symbol; `xcodebuild docbuild` must report no warnings.

## Writing tests

- Use Swift Testing. Drive time with `TestClock` and `waitForSleepers()`, never with
  `Task.sleep` on the real clock.
- Wait for results through a task's `value` or the `Recorder` actor in
  `Tests/SwiftConcurrencyTests/Support.swift`; poll with `waitUntil` only for a state that has
  no hook of its own.
- Test the edge cases: cancellation before and during a wait, a limit of 1, empty input, and
  values at the limits of `Int` and `Duration`.

## README samples

The README's code comes from `Examples/ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift`,
which the tests compile through a symlink. Change the sample there first, then copy it into
the README. Regenerate the screenshots with `scripts/capture-example-screens.sh` when a demo
screen changes.

## Commits and pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`,
  `test:`, `ci:`), one change per commit, with a body that says why.
- Add a line to the `Unreleased` section of [CHANGELOG.md](CHANGELOG.md) for every change a
  user would notice.
