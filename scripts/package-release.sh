#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/build.sh"
APP="$ROOT/build/Minimized Windows.app"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
case "$(uname -m)" in
    arm64) ARCH=Apple-Silicon ;;
    x86_64) ARCH=Intel ;;
    *) echo 'Unsupported build architecture' >&2; exit 1 ;;
esac
codesign --verify --deep --strict "$APP"
mkdir -p "$ROOT/build/releases"
ARCHIVE="$ROOT/build/releases/Minimized-Windows-$VERSION-$ARCH.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
bash "$ROOT/scripts/sign-appcast.sh" \
    --download-url-prefix "https://github.com/numeono/minimized-windows/releases/download/v$VERSION/" \
    --maximum-deltas 0 "$ROOT/build/releases"
echo "Release archive: $ARCHIVE"
echo 'Publish the release archive before committing the generated appcast.xml.'
