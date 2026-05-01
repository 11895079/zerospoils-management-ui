#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERRIDES_FILE="$ROOT_DIR/pubspec_overrides.yaml"

cat > "$OVERRIDES_FILE" <<'YAML'
dependency_overrides:
  google_mlkit_image_labeling:
    path: tooling_stubs/google_mlkit_image_labeling
  google_mlkit_text_recognition:
    path: tooling_stubs/google_mlkit_text_recognition
YAML

echo "Created pubspec_overrides.yaml with MLKit stubs."

cd "$ROOT_DIR"
flutter pub get

cd "$ROOT_DIR/ios"
pod install

echo "Simulator MLKit stub mode is now active."
echo "Run: flutter run -d ios --debug"
