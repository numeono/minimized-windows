#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MinimizedWindows"
DISPLAY_NAME="Minimized Windows"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$DISPLAY_NAME.app"

bash "$SCRIPT_DIR/scripts/prepare-sparkle.sh"
SPARKLE_DIR="$SCRIPT_DIR/.dependencies/Sparkle-2.10.1"

echo "🔨 Building $DISPLAY_NAME..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

ARCH="$(uname -m)"
swiftc \
    -target "$ARCH-apple-macosx12.0" \
    "$SCRIPT_DIR/Sources/AppDelegate.swift" \
    "$SCRIPT_DIR/Sources/MenuBarGesture.swift" \
    "$SCRIPT_DIR/Sources/WindowPicker.swift" \
    "$SCRIPT_DIR/Sources/main.swift" \
    -import-objc-header "$SCRIPT_DIR/Sources/BridgingHeader.h" \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -F "$SPARKLE_DIR" -framework Sparkle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -framework Cocoa \
    -framework ServiceManagement \
    -framework ApplicationServices \
    -O

cp "$SCRIPT_DIR/Sources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

ICONSET="$SCRIPT_DIR/Sources/AppIcon.iconset"
if [ -d "$ICONSET" ]; then
    iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" && echo "   ✅ Icon built" || echo "   ⚠️  iconutil failed"
fi

mkdir -p "$APP_BUNDLE/Contents/Frameworks"
ditto "$SPARKLE_DIR/Sparkle.framework" "$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
# Preserve Sparkle's upstream signatures, including its installer helpers.
codesign --force --sign - "$APP_BUNDLE"
echo "✅ Built: $APP_BUNDLE"
echo "Install: mv \"$APP_BUNDLE\" /Applications/"
