#!/bin/bash
#
# Checks that a built "Safari Arcade.app" is complete before it is packaged.
# A build that compiles but is missing the extension, or has the wrong
# version, must fail loudly here rather than ship as a broken installer.
#
# Usage: scripts/verify-app.sh "<path to Safari Arcade.app>" <expected version>

set -euo pipefail

APP="${1:?Usage: verify-app.sh <path to .app> <expected version>}"
EXPECTED_VERSION="${2:?Usage: verify-app.sh <path to .app> <expected version>}"

APPEX="${APP}/Contents/PlugIns/Safari Arcade Extension.appex"
RESOURCES="${APPEX}/Contents/Resources"
PLIST_BUDDY=/usr/libexec/PlistBuddy

fail() {
  echo "::error::$1"
  echo "VERIFY FAILED: $1" >&2
  exit 1
}

pass() {
  echo "ok: $1"
}

[ -d "${APP}" ] || fail "App bundle not found at ${APP}"
pass "app bundle exists"

[ -d "${APPEX}" ] || fail "Safari extension is not embedded in the app (expected ${APPEX})"
pass "extension is embedded in Contents/PlugIns"

for file in manifest.json index.html background.js; do
  [ -f "${RESOURCES}/${file}" ] || fail "${file} is missing from the extension's Resources folder"
done
pass "manifest.json, index.html and background.js are inside the extension"

ls "${RESOURCES}/assets/"*.js >/dev/null 2>&1 || fail "the built JavaScript bundle is missing from Resources/assets"
ls "${RESOURCES}/icons/"*.png >/dev/null 2>&1 || fail "the icons are missing from Resources/icons"
pass "app bundle assets and icons are inside the extension"

WEB="${APP}/Contents/Resources/web"
[ -f "${WEB}/index.html" ] || fail "index.html is missing from the app's Resources/web folder, so the app window would be empty"
ls "${WEB}/assets/"*.js >/dev/null 2>&1 || fail "the built JavaScript bundle is missing from the app's Resources/web/assets"
ls "${WEB}/assets/"*.css >/dev/null 2>&1 || fail "the built stylesheet is missing from the app's Resources/web/assets"
pass "the web app is packaged inside the Mac app"

plutil -lint "${APP}/Contents/Info.plist" >/dev/null || fail "the app's Info.plist is not valid"
plutil -lint "${APPEX}/Contents/Info.plist" >/dev/null || fail "the extension's Info.plist is not valid"
pass "both Info.plist files are valid"

EXTENSION_POINT=$("${PLIST_BUDDY}" -c "Print :NSExtension:NSExtensionPointIdentifier" "${APPEX}/Contents/Info.plist")
[ "${EXTENSION_POINT}" = "com.apple.Safari.web-extension" ] ||
  fail "extension point is '${EXTENSION_POINT}', expected com.apple.Safari.web-extension"
pass "extension is declared as a Safari Web Extension"

APP_ID=$("${PLIST_BUDDY}" -c "Print :CFBundleIdentifier" "${APP}/Contents/Info.plist")
APPEX_ID=$("${PLIST_BUDDY}" -c "Print :CFBundleIdentifier" "${APPEX}/Contents/Info.plist")
case "${APPEX_ID}" in
  "${APP_ID}".*) pass "bundle identifiers are ${APP_ID} and ${APPEX_ID}" ;;
  *) fail "extension identifier '${APPEX_ID}' does not start with the app identifier '${APP_ID}'" ;;
esac

APP_VERSION=$("${PLIST_BUDDY}" -c "Print :CFBundleShortVersionString" "${APP}/Contents/Info.plist")
APPEX_VERSION=$("${PLIST_BUDDY}" -c "Print :CFBundleShortVersionString" "${APPEX}/Contents/Info.plist")
MANIFEST_VERSION=$(plutil -extract version raw -o - "${RESOURCES}/manifest.json")
[ "${APP_VERSION}" = "${EXPECTED_VERSION}" ] || fail "app version is ${APP_VERSION}, expected ${EXPECTED_VERSION}"
[ "${APPEX_VERSION}" = "${EXPECTED_VERSION}" ] || fail "extension version is ${APPEX_VERSION}, expected ${EXPECTED_VERSION}"
[ "${MANIFEST_VERSION}" = "${EXPECTED_VERSION}" ] || fail "manifest version is ${MANIFEST_VERSION}, expected ${EXPECTED_VERSION}"
pass "app, extension and manifest all report version ${EXPECTED_VERSION}"

EXECUTABLE="${APP}/Contents/MacOS/Safari Arcade"
[ -x "${EXECUTABLE}" ] || fail "app executable is missing"
ARCHS=$(lipo -archs "${EXECUTABLE}")
case "${ARCHS}" in
  *arm64*x86_64* | *x86_64*arm64*) pass "app is universal (${ARCHS})" ;;
  *) fail "app is not universal, it only contains: ${ARCHS}" ;;
esac

codesign --verify --deep --strict "${APP}" || fail "code signature does not verify"
pass "code signature verifies"

ENTITLEMENTS=$(codesign -d --entitlements - --xml "${APPEX}" 2>/dev/null || true)
case "${ENTITLEMENTS}" in
  *com.apple.security.app-sandbox*) ;;
  *) fail "the extension is not sandboxed, so Safari would refuse to load it" ;;
esac
pass "extension is sandboxed"

echo
echo "Signature details:"
codesign -dv "${APP}" 2>&1 | grep -E "^(Identifier|Signature|TeamIdentifier|Format)" || true
echo
echo "All checks passed for ${APP}"
