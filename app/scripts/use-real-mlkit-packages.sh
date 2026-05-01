#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERRIDES_FILE="$ROOT_DIR/pubspec_overrides.yaml"

if [[ -f "$OVERRIDES_FILE" ]]; then
  rm "$OVERRIDES_FILE"
  echo "Removed pubspec_overrides.yaml."
else
  echo "No pubspec_overrides.yaml found; already using real packages."
fi

cd "$ROOT_DIR"
flutter pub get

cd "$ROOT_DIR/ios"
pod install

echo "Real MLKit package mode is now active."
echo "Run device/release builds as usual."
