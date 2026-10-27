#!/usr/bin/env bash
# Captures the README screenshots from the ConcurrencyDemo example app on an iPhone simulator.
#
# The script builds and installs the app, opens each demo with `-demo <name>` (the demo then
# plays its scenario with the real library: a debounced search, six downloads through a
# TaskQueue, requests through retry and a CircuitBreaker), waits for it to finish and takes a
# simulator screenshot in light and dark appearance with a fixed status bar.
#
# Usage: scripts/capture-example-screens.sh [simulator name or UDID]
# Without an argument it uses the first available iPhone simulator. Output: docs/images/
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
device="${1:-}"
if [[ -z "$device" ]]; then
  device="$(xcrun simctl list devices available | grep -m1 -oE 'iPhone [^(]+' | sed 's/ *$//')"
fi
if [[ -z "$device" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

bundle_id="io.github.muhittincamdali.ConcurrencyDemo"
# demo name and the seconds its scenario needs before the screenshot
demos=("search 4" "downloads 5" "retry 9")
output_dir="$repo_root/docs/images"
build_dir="$repo_root/.build/example-screens"
mkdir -p "$output_dir"

echo "Building ConcurrencyDemo for '$device'"
destination="platform=iOS Simulator,name=$device"
if [[ "$device" =~ ^[0-9A-F-]{36}$ ]]; then
  destination="platform=iOS Simulator,id=$device"
fi
xcodebuild build \
  -project "$repo_root/Examples/ConcurrencyDemo/ConcurrencyDemo.xcodeproj" \
  -scheme ConcurrencyDemo \
  -destination "$destination" \
  -derivedDataPath "$build_dir" \
  -quiet
app="$(find "$build_dir/Build/Products" -maxdepth 2 -name 'ConcurrencyDemo.app' -path '*iphonesimulator*' | head -1)"

xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b >/dev/null
xcrun simctl status_bar "$device" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 --operatorName ""
xcrun simctl install "$device" "$app"

for appearance in light dark; do
  xcrun simctl ui "$device" appearance "$appearance"
  for entry in "${demos[@]}"; do
    read -r demo wait_seconds <<< "$entry"
    xcrun simctl launch --terminate-running-process "$device" "$bundle_id" -demo "$demo" \
      -AppleLanguages "(en)" -AppleLocale en_US >/dev/null
    sleep "$wait_seconds"
    file="$output_dir/demo-$demo-$appearance.png"
    xcrun simctl io "$device" screenshot --type=png "$file" >/dev/null 2>&1
    # Half the width of an iPhone screenshot keeps the README light.
    sips --resampleWidth 603 "$file" >/dev/null
    echo "$file"
  done
done

xcrun simctl status_bar "$device" clear
xcrun simctl terminate "$device" "$bundle_id" 2>/dev/null || true
