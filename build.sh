#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MinimizedWindows"
DISPLAY_NAME="Minimized Windows"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$DISPLAY_NAME.app"

echo "🔨 Building $DISPLAY_NAME..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc \
    "$SCRIPT_DIR/Sources/AppDelegate.swift" \
    "$SCRIPT_DIR/Sources/main.swift" \
    -import-objc-header "$SCRIPT_DIR/Sources/BridgingHeader.h" \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework Cocoa \
    -framework ServiceManagement \
    -framework ApplicationServices \
    -O

cp "$SCRIPT_DIR/Sources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

ICONSET="$SCRIPT_DIR/Sources/AppIcon.iconset"
if [ -d "$ICONSET" ]; then
    iconutil -c icns "$ICONSET" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" && echo "   ✅ Icon built" || echo "   ⚠️  iconutil failed"
fi

codesign --force --deep --sign - "$APP_BUNDLE"
echo "✅ Built: $APP_BUNDLE"
echo "Install: mv \"$APP_BUNDLE\" /Applications/"
