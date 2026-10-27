# Examples

## ConcurrencyDemo

A small iOS and macOS app with one screen per tool:

- **Search as you type** — a `Debouncer` runs the search once typing has paused for 300 ms; the
  screen counts keystrokes and searches.
- **Download queue** — six simulated downloads go through a `TaskQueue` with a limit of two;
  a Swift Charts timeline shows when each one ran, and each file can be cancelled while it
  waits or runs.
- **Retry and circuit breaker** — requests to a simulated server whose failure rate you set
  go through `retry` with exponential backoff, a one-second `withTimeout` and a
  `CircuitBreaker`; the log shows every attempt and every refused call.

It uses the package from this checkout (a local package reference to `../..`), so it always
shows the current code.

Run it:

1. Open `Examples/ConcurrencyDemo/ConcurrencyDemo.xcodeproj` in Xcode 26 or later.
2. Choose the **ConcurrencyDemo** scheme and an iPhone simulator or **My Mac** as the run
   destination.
3. Press **Run** (⌘R).

From the command line:

```sh
cd Examples/ConcurrencyDemo
xcodebuild build -scheme ConcurrencyDemo -destination 'generic/platform=iOS Simulator'
xcodebuild build -scheme ConcurrencyDemo -destination 'platform=macOS'
```

The README samples live in
[`ConcurrencyDemo/ReadmeSamples.swift`](ConcurrencyDemo/ConcurrencyDemo/ReadmeSamples.swift).
The README copies its code from that file, and the package's test target compiles and runs the
same file through the symlink `Tests/SwiftConcurrencyTests/ReadmeSamples.swift`.

The screenshots in the README come from this app:
[`scripts/capture-example-screens.sh`](../scripts/capture-example-screens.sh) opens each screen
with `-demo search`, `-demo downloads` or `-demo retry`, lets it play its scenario and takes a
simulator screenshot in light and dark appearance.

The project file is made with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from
[`project.yml`](ConcurrencyDemo/project.yml) and committed, so you only need XcodeGen after
editing `project.yml`.
