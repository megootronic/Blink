#!/bin/bash
#
# build-dmg.sh
# Creates a styled DMG installer for Blink
#
# Usage: ./Scripts/build-dmg.sh path/to/Blink.app
#

set -e

APP_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/build"
DMG_NAME="Blink"

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "Usage: ./Scripts/build-dmg.sh path/to/Blink.app"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Remove old DMG if exists
rm -f "$OUTPUT_DIR/$DMG_NAME.dmg"

create-dmg \
    --volname "$DMG_NAME" \
    --background "$SCRIPT_DIR/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 120 \
    --icon "Blink.app" 125 151 \
    --app-drop-link 465 150 \
    --no-internet-enable \
    "$OUTPUT_DIR/$DMG_NAME.dmg" \
    "$APP_PATH"

echo ""
echo "DMG created: $OUTPUT_DIR/$DMG_NAME.dmg"
