#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/prepare-sparkle.sh
SPARKLE_DIR="$PWD/.dependencies/Sparkle-2.10.1"
TEST_BINARY=$(mktemp /tmp/minimized-windows-tests.XXXXXX)
trap 'rm -f "$TEST_BINARY"' EXIT
swiftc Sources/AppDelegate.swift Sources/MenuBarGesture.swift Sources/WindowPicker.swift Tests/main.swift \
    -import-objc-header Sources/BridgingHeader.h \
    -F "$SPARKLE_DIR" -framework Sparkle \
    -Xlinker -rpath -Xlinker "$SPARKLE_DIR" \
    -framework Cocoa -framework ServiceManagement -framework ApplicationServices \
    -o "$TEST_BINARY"
"$TEST_BINARY" "$@"
