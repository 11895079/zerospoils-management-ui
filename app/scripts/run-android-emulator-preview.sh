#!/usr/bin/env bash
# run-android-emulator-preview.sh
# One-click Android emulator preview for ZeroSpoils.
# Boots Pixel_8_API_35 if not running, then launches the app.

set -euo pipefail

# Resolve Android SDK root: honour ANDROID_SDK_ROOT / ANDROID_HOME if set,
# fall back to the default macOS location.
ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
EMULATOR="$ANDROID_SDK/emulator/emulator"
ADB="$ANDROID_SDK/platform-tools/adb"
AVD="${ZS_AVD:-Pixel_8_API_35}"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Checking Android emulator ($AVD)..."
DEVICE=$("$ADB" devices | awk '/emulator-/{print $1}' | head -1)

if [[ -z "$DEVICE" ]]; then
  echo "    Emulator not running — booting $AVD..."
  nohup "$EMULATOR" -avd "$AVD" -no-snapshot-load >/tmp/avd.log 2>&1 &
  echo "    Waiting for device (this may take ~30s)..."
  "$ADB" wait-for-device
  echo "    Waiting for boot to complete..."
  while [[ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null)" != "1" ]]; do
    sleep 3
  done
  DEVICE=$("$ADB" devices | awk '/emulator-/{print $1}' | head -1)
  echo "    Device ready: $DEVICE"
else
  echo "    Emulator already running: $DEVICE"
fi

echo "==> Launching app on $DEVICE..."
echo ""
cd "$APP_DIR"
flutter run -d "$DEVICE" --debug
