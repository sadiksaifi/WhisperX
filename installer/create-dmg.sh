#!/bin/bash
set -euo pipefail

# Creates a styled DMG installer with "drag to Applications" UI
# Usage: ./create-dmg.sh <app-path> <output-dmg-path>
# Example: ./create-dmg.sh build/Build/Products/Release/WhisperX.app WhisperX-v1.0.0.dmg

APP_PATH="${1:?Usage: $0 <app-path> <output-dmg-path>}"
OUTPUT_DMG="${2:?Usage: $0 <app-path> <output-dmg-path>}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKGROUND="$SCRIPT_DIR/dmg-background.png"

# Verify app exists
if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Verify background exists
if [[ ! -f "$BACKGROUND" ]]; then
    echo "Error: Background image not found at $BACKGROUND"
    echo "Run generate-background.sh first"
    exit 1
fi

# Remove existing DMG if present
rm -f "$OUTPUT_DMG"

# Build create-dmg arguments
ARGS=(
    --volname "WhisperX"
    --background "$BACKGROUND"
    --window-pos 200 120
    --window-size 660 400
    --icon-size 128
    --icon "WhisperX.app" 160 190
    --hide-extension "WhisperX.app"
    --app-drop-link 500 190
    --no-internet-enable
)

# Add volume icon if it exists
if [[ -f "$SCRIPT_DIR/volume-icon.icns" ]]; then
    ARGS+=(--volicon "$SCRIPT_DIR/volume-icon.icns")
fi

echo "Creating DMG installer..."
create-dmg "${ARGS[@]}" "$OUTPUT_DMG" "$APP_PATH"

echo "DMG created successfully: $OUTPUT_DMG"
