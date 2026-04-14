#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

APP_NAME="CopyPaste"
SCHEME="CopyPaste"
PROJECT="CopyPaste.xcodeproj"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
DMG_DIR="${BUILD_DIR}/dmg"
MARKETING_VERSION=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
    | grep 'MARKETING_VERSION' | head -1 | awk '{print $NF}')
DMG_NAME="${APP_NAME}-${MARKETING_VERSION}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"

echo "============================================"
echo "  Building ${APP_NAME} v${MARKETING_VERSION}"
echo "============================================"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# --- Step 1: Archive ---
echo ""
echo "[1/4] Archiving..."
DEVELOPMENT_TEAM=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
    | grep 'DEVELOPMENT_TEAM' | head -1 | awk '{print $NF}')

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="Apple Development" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    -quiet

echo "  Archive created at ${ARCHIVE_PATH}"

# --- Step 2: Export ---
echo ""
echo "[2/4] Exporting..."

EXPORT_OPTIONS="${BUILD_DIR}/ExportOptions.plist"
cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -quiet 2>/dev/null || {
    echo "  Developer ID export failed (expected without distribution cert)."
    echo "  Falling back to direct .app extraction from archive..."
    mkdir -p "$EXPORT_DIR"
    cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "$EXPORT_DIR/"
}

APP_PATH="${EXPORT_DIR}/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: ${APP_PATH} not found."
    exit 1
fi

echo "  App exported to ${APP_PATH}"

# --- Step 3: Create DMG ---
echo ""
echo "[3/4] Creating DMG..."

rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    -quiet

echo "  DMG created at ${DMG_PATH}"

# --- Step 4: Summary ---
echo ""
echo "[4/4] Done!"
echo "============================================"
echo "  Output: ${DMG_PATH}"
DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
echo "  Size:   ${DMG_SIZE}"
echo "============================================"
echo ""
echo "To install: open the DMG and drag ${APP_NAME} to Applications."
