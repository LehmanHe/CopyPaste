#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCHEME="CopyPaste"
CONFIGURATION="${1:-Debug}"
BUILD_DIR="$PROJECT_DIR/build"

echo "=== CopyPaste Local Build ==="
echo "Configuration: $CONFIGURATION"
echo "Build directory: $BUILD_DIR"
echo ""

if ! command -v xcodebuild &>/dev/null; then
    echo "Error: xcodebuild not found."
    echo "Install Xcode from the App Store, then run:"
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

echo "Resolving Swift Package Manager dependencies..."
xcodebuild -project "$PROJECT_DIR/CopyPaste.xcodeproj" \
    -scheme "$SCHEME" \
    -resolvePackageDependencies \
    2>&1 | tail -5

echo ""
echo "Building $SCHEME ($CONFIGURATION)..."
xcodebuild -project "$PROJECT_DIR/CopyPaste.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$BUILD_DIR" \
    build \
    2>&1

BUILD_EXIT=$?

APP_PATH=$(find "$BUILD_DIR" -name "CopyPaste.app" -type d 2>/dev/null | head -1)

if [ $BUILD_EXIT -eq 0 ] && [ -n "$APP_PATH" ]; then
    echo ""
    echo "=== Build Succeeded ==="
    echo "App location: $APP_PATH"
    echo ""
    echo "To run the app:"
    echo "  open \"$APP_PATH\""
else
    echo ""
    echo "=== Build Failed (exit code: $BUILD_EXIT) ==="
    exit 1
fi
