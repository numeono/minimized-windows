#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/scripts/prepare-sparkle.sh"
# The key stays in Keychain; export only to a private temporary file for this run.
umask 077
KEY_DIR=$(mktemp -d -t minimized-windows-signing)
KEY_FILE="$KEY_DIR/key"
trap 'rm -rf "$KEY_DIR"' EXIT
TOOLS="$ROOT/.dependencies/Sparkle-2.10.1/bin"
"$TOOLS/generate_keys" --account minimized-windows -x "$KEY_FILE"
"$TOOLS/generate_appcast" --ed-key-file "$KEY_FILE" "$@"
