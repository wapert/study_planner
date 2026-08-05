#!/bin/bash
# Build, sign, notarize and package the macOS app as a distributable .dmg.
#
# Prerequisites (one-time, see docs/MACOS_DMG.md):
#   1. A "Developer ID Application" certificate in your keychain.
#   2. A stored notarytool credential profile named "notary":
#        xcrun notarytool store-credentials notary \
#          --apple-id <你的 Apple ID> \
#          --team-id NR6H8UUF43 \
#          --password <app-specific password>
#
# Usage:  ./scripts/release_dmg.sh
set -euo pipefail

APP_NAME="讀書計畫"
BUNDLE="study_planner"
TEAM_ID="NR6H8UUF43"
NOTARY_PROFILE="notary"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP="build/macos/Build/Products/Release/${BUNDLE}.app"
DIST="build/dist"
DMG="${DIST}/${APP_NAME}.dmg"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
fail() { printf '\033[1;31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

# ── 0. Preflight ──────────────────────────────────────────────────────────
step "Checking prerequisites"
CERT=$(security find-identity -v -p codesigning \
       | grep "Developer ID Application" | head -1 \
       | sed -E 's/.*"(.*)"/\1/') || true
[ -n "${CERT:-}" ] || fail "No 'Developer ID Application' certificate found.
  Create one in Xcode: Settings → Accounts → Manage Certificates → + →
  Developer ID Application."
echo "  signing identity: $CERT"

xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 \
  || fail "No notarytool profile '$NOTARY_PROFILE'. Create it with:
  xcrun notarytool store-credentials $NOTARY_PROFILE \\
    --apple-id <your-apple-id> --team-id $TEAM_ID --password <app-specific-password>"
echo "  notarytool profile: $NOTARY_PROFILE"

# ── 1. Build ──────────────────────────────────────────────────────────────
step "Building release app"
flutter build macos --release

# ── 2. Sign ───────────────────────────────────────────────────────────────
# Sign inner binaries first, then the app bundle. Hardened runtime is required
# for notarization and is set via Release.xcconfig.
step "Signing with Developer ID"
find "$APP/Contents/Frameworks" -name "*.dylib" -o -name "*.framework" -maxdepth 1 2>/dev/null \
  | while read -r f; do
      codesign --force --timestamp --options runtime --sign "$CERT" "$f" 2>/dev/null || true
    done
codesign --force --deep --timestamp --options runtime \
  --entitlements macos/Runner/Release.entitlements \
  --sign "$CERT" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

# ── 3. Package ────────────────────────────────────────────────────────────
step "Creating disk image"
rm -rf "$DIST"; mkdir -p "$DIST"
create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 --window-size 660 420 \
  --icon-size 120 \
  --icon "${BUNDLE}.app" 165 190 \
  --app-drop-link 495 190 \
  --no-internet-enable \
  "$DMG" "$APP" >/dev/null

# ── 4. Notarize ───────────────────────────────────────────────────────────
step "Submitting to Apple for notarization (usually 1–5 minutes)"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

# ── 5. Staple ─────────────────────────────────────────────────────────────
# Stapling attaches the notarization ticket so Gatekeeper accepts the app
# even when the user is offline.
step "Stapling ticket"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

step "Done"
echo "  $DMG"
ls -lh "$DMG"
