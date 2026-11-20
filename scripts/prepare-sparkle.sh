#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=2.10.1
SHA256=1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27
CACHE="$ROOT/.dependencies"
ARCHIVE="$CACHE/Sparkle-$VERSION.tar.xz"
DEST="$CACHE/Sparkle-$VERSION"
mkdir -p "$CACHE"
if [ ! -f "$ARCHIVE" ]; then
    curl --fail --location --silent --show-error \
        "https://github.com/sparkle-project/Sparkle/releases/download/$VERSION/Sparkle-$VERSION.tar.xz" \
        -o "$ARCHIVE.tmp"
    mv "$ARCHIVE.tmp" "$ARCHIVE"
fi
printf '%s  %s\n' "$SHA256" "$ARCHIVE" | shasum -a 256 --check --status
if [ ! -d "$DEST/Sparkle.framework" ]; then
    mkdir -p "$DEST"
    tar -xf "$ARCHIVE" -C "$DEST"
fi
