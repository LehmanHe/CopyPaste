#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

APP_PATH=$(find "$BUILD_DIR" -name "CopyPaste.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "CopyPaste.app not found. Building first..."
    "$SCRIPT_DIR/build.sh"
    APP_PATH=$(find "$BUILD_DIR" -name "CopyPaste.app" -type d 2>/dev/null | head -1)
fi

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find CopyPaste.app after build."
    exit 1
fi

# Kill existing instance if running
pkill -x CopyPaste 2>/dev/null || true
sleep 0.5

echo "Launching CopyPaste from: $APP_PATH"
open "$APP_PATH"
