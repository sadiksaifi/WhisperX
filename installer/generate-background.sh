#!/bin/bash
set -euo pipefail

# Generates a placeholder DMG background image
# Requires: ImageMagick (brew install imagemagick)
# Usage: ./generate-background.sh [output-path]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-$SCRIPT_DIR/dmg-background.png}"

echo "Generating DMG background image..."

# Create a 660x400 gradient background with arrow and text
convert -size 660x400 \
    -define gradient:direction=south \
    gradient:'#f5f5f7-#e8e8ed' \
    -font "Helvetica-Bold" -pointsize 18 -fill '#666666' \
    -gravity center -annotate +0+140 "Drag WhisperX to Applications" \
    -stroke '#999999' -strokewidth 2 \
    -draw "line 240,200 420,200" \
    -draw "line 400,185 420,200" \
    -draw "line 400,215 420,200" \
    "$OUTPUT"

echo "Generated: $OUTPUT"
