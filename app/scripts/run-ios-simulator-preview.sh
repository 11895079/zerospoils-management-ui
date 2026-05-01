#!/usr/bin/env bash
# run-ios-simulator-preview.sh
# One-click iOS simulator preview for ZeroSpoils.
# Activates MLKit stubs (if needed), boots the simulator, and launches the app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# Override via env vars for team members with different simulator setups:
#   SIMULATOR_UDID=<udid> SIMULATOR_NAME=<name> ./scripts/run-ios-simulator-preview.sh
SIMULATOR_UDID="${SIMULATOR_UDID:-59D1C578-0ED7-4056-8258-634C27446C5E}"
SIMULATOR_NAME="${SIMULATOR_NAME:-ZS-iPhone-17}"

echo "==> Checking MLKit stub mode..."
if [[ ! -f "$APP_DIR/pubspec_overrides.yaml" ]]; then
  echo "    pubspec_overrides.yaml not found — enabling simulator stubs..."
  bash "$SCRIPT_DIR/use-ios-simulator-mlkit-stubs.sh"
else
  echo "    Stub mode already active (pubspec_overrides.yaml present)."
fi

echo "==> Booting simulator: $SIMULATOR_NAME ($SIMULATOR_UDID)..."
BOOT_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_UDID" | grep -o "Booted" || true)
if [[ "$BOOT_STATE" != "Booted" ]]; then
  xcrun simctl boot "$SIMULATOR_UDID" || true
  xcrun simctl bootstatus "$SIMULATOR_UDID" -b
fi
open -a Simulator

echo "==> Launching app on $SIMULATOR_NAME..."
echo "    NOTE: Run './scripts/use-real-mlkit-packages.sh' before building for a real device."
echo ""
cd "$APP_DIR"
flutter run -d "$SIMULATOR_UDID" --debug
