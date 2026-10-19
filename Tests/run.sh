#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_BINARY=$(mktemp /tmp/minimized-windows-tests.XXXXXX)
trap 'rm -f "$TEST_BINARY"' EXIT
swiftc Sources/AppDelegate.swift Sources/MenuBarGesture.swift Sources/WindowPicker.swift Sources/UpdateChecker.swift Tests/main.swift \
    -import-objc-header Sources/BridgingHeader.h \
    -framework Cocoa -framework ServiceManagement -framework ApplicationServices \
    -o "$TEST_BINARY"
"$TEST_BINARY" "$@"
