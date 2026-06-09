#!/usr/bin/env bash
# smoke-test-multi-device.sh
# Runs a launch smoke test on Android + selected iOS simulators.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
EMULATOR="$ANDROID_SDK/emulator/emulator"
ADB="$ANDROID_SDK/platform-tools/adb"

IOS_RUNTIME_ID="${IOS_RUNTIME_ID:-$(xcrun simctl list runtimes | sed -n 's/.*- \(com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]*\)$/\1/p' | tail -n 1)}"
ANDROID_AVD="${ANDROID_AVD:-}"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-420}"

FAILURES=0
SKIPS=0

log() {
  echo "[$(date '+%H:%M:%S')] $*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "ERROR: Missing command: $1"
    exit 1
  fi
}

ensure_android_device() {
  require_cmd flutter
  require_cmd xcrun

  if [[ ! -x "$ADB" || ! -x "$EMULATOR" ]]; then
    log "ERROR: Android SDK tools not found under $ANDROID_SDK"
    return 1
  fi

  local device
  device=$("$ADB" devices | awk '/emulator-/{print $1}' | head -1)
  if [[ -n "$device" ]]; then
    echo "$device"
    return 0
  fi

  local avd="$ANDROID_AVD"
  if [[ -z "$avd" ]]; then
    avd=$("$EMULATOR" -list-avds | head -1)
  fi
  if [[ -z "$avd" ]]; then
    log "ERROR: No Android AVD found. Create one in Android Studio Device Manager."
    return 1
  fi

  log "Booting Android emulator: $avd"
  nohup "$EMULATOR" -avd "$avd" -no-snapshot-load >/tmp/avd_smoke.log 2>&1 &
  "$ADB" wait-for-device

  local deadline=$((SECONDS + 180))
  while [[ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]]; do
    if (( SECONDS >= deadline )); then
      log "ERROR: Android emulator boot timed out"
      return 1
    fi
    sleep 2
  done

  device=$("$ADB" devices | awk '/emulator-/{print $1}' | head -1)
  if [[ -z "$device" ]]; then
    log "ERROR: Android emulator booted but no device is reported by adb"
    return 1
  fi

  echo "$device"
}

simulator_udid_for_name() {
  local sim_name="$1"
  local line
  line=$(xcrun simctl list devices available | grep -F "$sim_name (" | head -1 || true)
  if [[ -z "$line" ]]; then
    return 1
  fi
  echo "$line" | sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p'
}

ensure_ios_simulator() {
  local iphone_model="$1"
  local sim_name="ZS-${iphone_model}-Smoke"

  if [[ -z "$IOS_RUNTIME_ID" ]]; then
    log "ERROR: No iOS simulator runtime found"
    return 1
  fi

  local devtype_id
  devtype_id=$(xcrun simctl list devicetypes | sed -n "s/^${iphone_model} (\(com\.apple\.CoreSimulator\.SimDeviceType\.[^)][^)]*\))$/\1/p" | head -1)
  if [[ -z "$devtype_id" ]]; then
    log "SKIP: Device type '${iphone_model}' is not installed in Xcode runtimes"
    return 2
  fi

  local udid
  udid=$(simulator_udid_for_name "$sim_name" || true)
  if [[ -z "$udid" ]]; then
    log "Creating simulator: $sim_name ($iphone_model, $IOS_RUNTIME_ID)"
    udid=$(xcrun simctl create "$sim_name" "$devtype_id" "$IOS_RUNTIME_ID")
  fi

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  open -a Simulator >/dev/null 2>&1 || true

  echo "$udid"
}

run_smoke_for_device() {
  local label="$1"
  local device_id="$2"
  local log_file
  local pid
  local deadline

  log "Smoke test start: $label ($device_id)"

  log_file="$(mktemp -t zs-smoke-XXXXXX.log)"
  (
    cd "$APP_DIR"
    flutter run --machine -d "$device_id"
  ) >"$log_file" 2>&1 &
  pid=$!
  deadline=$((SECONDS + SMOKE_TIMEOUT_SECONDS))

  while true; do
    if grep -q '"event":"app.started"' "$log_file"; then
      log "PASS: $label launched"
      kill -INT "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
      rm -f "$log_file"
      return 0
    fi

    if grep -Eiq '(^Error:|Unhandled exception|Xcode build failed|Gradle task .* failed)' "$log_file"; then
      log "FAIL: $label failed to launch"
      tail -n 80 "$log_file"
      kill -INT "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
      rm -f "$log_file"
      return 1
    fi

    if ! kill -0 "$pid" >/dev/null 2>&1; then
      log "FAIL: $label process exited before launch"
      tail -n 80 "$log_file"
      rm -f "$log_file"
      return 1
    fi

    if (( SECONDS >= deadline )); then
      log "FAIL: $label timed out after ${SMOKE_TIMEOUT_SECONDS}s"
      tail -n 80 "$log_file"
      kill -INT "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
      rm -f "$log_file"
      return 1
    fi

    sleep 2
  done
}

main() {
  require_cmd flutter
  require_cmd xcrun

  log "Using app directory: $APP_DIR"
  log "Using iOS runtime: $IOS_RUNTIME_ID"

  local android_id
  if android_id=$(ensure_android_device); then
    run_smoke_for_device "Android" "$android_id" || FAILURES=$((FAILURES + 1))
  else
    FAILURES=$((FAILURES + 1))
  fi

  local iphone_models=("iPhone 22" "iPhone 11" "iPhone 17")
  local model
  local sim_udid
  local rc
  for model in "${iphone_models[@]}"; do
    set +e
    sim_udid=$(ensure_ios_simulator "$model")
    rc=$?
    set -e

    if [[ $rc -eq 2 ]]; then
      SKIPS=$((SKIPS + 1))
      continue
    fi
    if [[ $rc -ne 0 ]]; then
      FAILURES=$((FAILURES + 1))
      continue
    fi

    run_smoke_for_device "$model" "$sim_udid" || FAILURES=$((FAILURES + 1))
  done

  log "Smoke test summary: failures=$FAILURES skipped=$SKIPS"
  if (( FAILURES > 0 )); then
    exit 1
  fi
}

main "$@"
