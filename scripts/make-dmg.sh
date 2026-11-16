#!/bin/bash
#
# Packages "Safari Arcade.app" into a DMG installer: a disk image that shows
# the app next to a shortcut to the Applications folder, so installing is a
# single drag.
#
# Usage: scripts/make-dmg.sh "<path to Safari Arcade.app>" <output.dmg>

set -euo pipefail

APP="${1:?Usage: make-dmg.sh <path to .app> <output.dmg>}"
OUTPUT="${2:?Usage: make-dmg.sh <path to .app> <output.dmg>}"
VOLUME_NAME="Safari Arcade"

[ -d "${APP}" ] || { echo "error: app bundle not found at ${APP}" >&2; exit 1; }

STAGING=$(mktemp -d)
trap 'rm -rf "${STAGING}"' EXIT

# ditto preserves the code signature and extended attributes exactly.
ditto "${APP}" "${STAGING}/$(basename "${APP}")"
ln -s /Applications "${STAGING}/Applications"

mkdir -p "$(dirname "${OUTPUT}")"
rm -f "${OUTPUT}"

# hdiutil occasionally fails with "Resource busy" on shared build machines,
# so try a few times before giving up.
attempt=1
until hdiutil create -volname "${VOLUME_NAME}" -srcfolder "${STAGING}" -fs HFS+ -format UDZO -ov "${OUTPUT}"; do
  if [ "${attempt}" -ge 4 ]; then
    echo "error: hdiutil could not create the DMG after ${attempt} attempts" >&2
    exit 1
  fi
  echo "hdiutil failed (attempt ${attempt}), retrying in 5 seconds..."
  attempt=$((attempt + 1))
  sleep 5
done

hdiutil verify "${OUTPUT}"

# Mount the finished image and confirm the app inside still has a valid signature.
MOUNT_POINT=$(mktemp -d)
hdiutil attach "${OUTPUT}" -nobrowse -readonly -mountpoint "${MOUNT_POINT}" >/dev/null
MOUNTED_APP="${MOUNT_POINT}/$(basename "${APP}")"
RESULT=0
if [ ! -d "${MOUNTED_APP}" ] || ! codesign --verify --deep --strict "${MOUNTED_APP}"; then
  RESULT=1
fi
hdiutil detach "${MOUNT_POINT}" >/dev/null || true
rmdir "${MOUNT_POINT}" 2>/dev/null || true

if [ "${RESULT}" -ne 0 ]; then
  echo "error: the app inside the DMG is missing or its signature no longer verifies" >&2
  exit 1
fi

echo "Created ${OUTPUT} ($(du -h "${OUTPUT}" | cut -f1))"
