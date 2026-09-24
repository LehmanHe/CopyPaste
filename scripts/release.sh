#!/bin/bash
# Publishes a GitHub release that existing installs pick up through Sparkle.
#
# Usage: scripts/release.sh <release-notes.md>
#
# Before running:
#   - bump MARKETING_VERSION and CURRENT_PROJECT_VERSION in Xcode,
#   - commit and push everything to origin,
#   - make sure the Sparkle private key is in the login keychain (scripts/release.sh
#     signs with it; `generate_keys -x <file>` exports a backup, `-f <file>` imports it).
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

REPO="LehmanHe/CopyPaste"
APP_NAME="CopyPaste"
PROJECT="CopyPaste.xcodeproj"
SCHEME="CopyPaste"
APPCAST="appcast.xml"
NOTES_FILE="${1:?usage: scripts/release.sh <release-notes.md>}"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -f "$NOTES_FILE" ] || die "release notes not found: $NOTES_FILE"
command -v gh >/dev/null || die "GitHub CLI (gh) is required"

SETTINGS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null)
setting() { echo "$SETTINGS" | awk -v key="$1" '$1 == key { print $3; exit }'; }
VERSION=$(setting MARKETING_VERSION)
BUILD=$(setting CURRENT_PROJECT_VERSION)
MIN_SYSTEM=$(setting MACOSX_DEPLOYMENT_TARGET)
TAG="v${VERSION}"
DMG="build/${APP_NAME}-${VERSION}.dmg"
DMG_URL="https://github.com/${REPO}/releases/download/${TAG}/${APP_NAME}-${VERSION}.dmg"

echo "Releasing ${APP_NAME} ${VERSION} (build ${BUILD}) as ${TAG}"

# Sparkle only offers an update when the build number grows.
LAST_BUILD=$(grep -o '<sparkle:version>[0-9]*' "$APPCAST" | grep -o '[0-9]*$' | sort -n | tail -1 || true)
if [ -n "$LAST_BUILD" ] && [ "$BUILD" -le "$LAST_BUILD" ]; then
  die "build ${BUILD} must be greater than the last published build ${LAST_BUILD}"
fi

if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
  die "release ${TAG} already exists"
fi

[ -z "$(git status --porcelain)" ] || die "working tree is not clean"
git fetch -q origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse '@{u}')" ] || die "HEAD is not pushed to its upstream"

SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -path "*/artifacts/sparkle/Sparkle/bin/sign_update" 2>/dev/null | head -1)
[ -x "$SIGN_UPDATE" ] || die "sign_update not found, build the project in Xcode once to fetch Sparkle"

./scripts/build_dmg.sh
[ -f "$DMG" ] || die "${DMG} was not created"

echo ""
echo "Signing update..."
SIGNATURE_ATTRS=$("$SIGN_UPDATE" "$DMG") \
  || die "sign_update failed; allow keychain access to the Sparkle private key (choose Always Allow) and retry"
[[ "$SIGNATURE_ATTRS" == *"sparkle:edSignature="* ]] || die "unexpected sign_update output: ${SIGNATURE_ATTRS}"

echo "Updating ${APPCAST}..."
NOTES_HTML=$(gh api -X POST /markdown -f text="$(cat "$NOTES_FILE")" -f mode=gfm -f context="$REPO")
PUB_DATE=$(LC_ALL=C date -u +"%a, %d %b %Y %H:%M:%S +0000")

ITEM="    <item>
      <title>${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${BUILD}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>${MIN_SYSTEM}</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/${REPO}/releases/tag/${TAG}</sparkle:releaseNotesLink>
      <description><![CDATA[${NOTES_HTML}]]></description>
      <enclosure url=\"${DMG_URL}\" ${SIGNATURE_ATTRS} type=\"application/octet-stream\"/>
    </item>"

ITEM="$ITEM" python3 - "$APPCAST" <<'PY'
import os, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
anchor = "</language>\n"
if anchor not in text:
    sys.exit("appcast.xml has no <language> element to insert after")
text = text.replace(anchor, anchor + os.environ["ITEM"] + "\n", 1)
open(path, "w", encoding="utf-8").write(text)
PY
xmllint --noout "$APPCAST"

echo "Publishing ${TAG}..."
gh release create "$TAG" "$DMG" "$APPCAST" \
  -R "$REPO" \
  --target "$(git rev-parse HEAD)" \
  --title "${APP_NAME} ${VERSION}" \
  --notes-file "$NOTES_FILE" \
  --latest

git add "$APPCAST"
git commit -q -m "appcast: ${VERSION}"
git push -q origin HEAD

echo ""
echo "Published https://github.com/${REPO}/releases/tag/${TAG}"
