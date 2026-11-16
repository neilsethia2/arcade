#!/bin/bash
#
# Starts the built app for real and checks that it works.
#
# The app is launched twice in self-test mode (see macos-app/App/SelfTest.swift).
# Each time it loads the arcade, reports what the page found, saves a picture
# of the window and quits. This script then checks that:
#
#   - the page loaded with no errors
#   - it knows it is running inside the Mac app
#   - it is saving through the app, to a file
#   - the saved launch counter was 1 on the first run and 2 on the second,
#     which proves saved data survives quitting the app
#
# A temporary folder is used for saved data, so real scores are never touched.
#
# Usage: scripts/self-test.sh "<path to Safari Arcade.app>" [output folder]

set -euo pipefail

APP="${1:?Usage: self-test.sh <path to .app> [output folder]}"
OUT="${2:-build/self-test}"
EXECUTABLE="${APP}/Contents/MacOS/Safari Arcade"
LIMIT_SECONDS=90

fail() {
  echo "::error::$1"
  echo "SELF-TEST FAILED: $1" >&2
  exit 1
}

[ -x "${EXECUTABLE}" ] || fail "app executable not found at ${EXECUTABLE}"

mkdir -p "${OUT}"
OUT="$(cd "${OUT}" && pwd)"
STORAGE="$(mktemp -d)"
trap 'rm -rf "${STORAGE}"' EXIT

field() {
  # Reads one value out of a result file, e.g. field run-1.json probe.launchCount
  plutil -extract "$2" raw -o - "$1" 2>/dev/null || echo "(missing)"
}

run_once() {
  local number="$1"
  local result="${OUT}/run-${number}.json"
  local log="${OUT}/run-${number}.log"
  rm -f "${result}" "${OUT}/run-${number}.png"

  echo "--- Launch ${number}"
  ARCADE_STORAGE_DIR="${STORAGE}" \
    ARCADE_SELF_TEST_OUTPUT="${result}" \
    ARCADE_SELF_TEST_SNAPSHOT="${OUT}/run-${number}.png" \
    "${EXECUTABLE}" >"${log}" 2>&1 &
  local pid=$!

  # The app has its own 30 second limit. This outer limit only matters if
  # the app hangs so badly that its own limit never fires.
  local waited=0
  while kill -0 "${pid}" 2>/dev/null; do
    if [ "${waited}" -ge "${LIMIT_SECONDS}" ]; then
      kill -9 "${pid}" 2>/dev/null || true
      cat "${log}" || true
      fail "launch ${number}: the app was still running after ${LIMIT_SECONDS} seconds"
    fi
    sleep 1
    waited=$((waited + 1))
  done

  local status=0
  wait "${pid}" || status=$?
  cat "${log}" || true

  [ -f "${result}" ] || fail "launch ${number}: the app exited with status ${status} without writing a result"
  cat "${result}"
  echo

  [ "$(field "${result}" ok)" = "true" ] || fail "launch ${number}: $(field "${result}" failure)"
  [ "${status}" -eq 0 ] || fail "launch ${number}: the app exited with status ${status}"

  local environment storage count
  environment="$(field "${result}" probe.environment)"
  storage="$(field "${result}" probe.storage)"
  count="$(field "${result}" probe.launchCount)"

  [ "${environment}" = "native" ] || fail "launch ${number}: the page thinks it is running in '${environment}', expected 'native'"
  [ "${storage}" = "native" ] || fail "launch ${number}: the page is saving to '${storage}', expected 'native'"
  [ "${count}" = "${number}" ] || fail "launch ${number}: the saved launch count is ${count}, expected ${number}"
  echo "ok: launch ${number} loaded with no errors, saving through the app, launch count ${count}"
}

run_once 1
run_once 2

echo
echo "Saved data file after both launches:"
cat "${STORAGE}/storage.json"
echo
echo
echo "Self-test passed: the app loads the arcade and saved data survives quitting."
