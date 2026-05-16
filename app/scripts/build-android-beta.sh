#!/usr/bin/env bash
# build-android-beta.sh
# Build signed Android APK for beta testing locally.
# Matches CI workflow: distribute-beta-android.yml
#
# Prerequisites:
#   - Android keystore configured in android/key.properties
#   - Flutter installed and in PATH
#   - Gradle cache available (~/.gradle/wrapper/dists)
#
# Usage:
#   ./scripts/build-android-beta.sh
#   # Output: build/app/outputs/flutter-apk/app-release.apk

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> ZeroSpoils Android Beta Build (Local)"
echo ""

# Check prerequisites
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found. Install Flutter and add to PATH."
  exit 1
fi

if [[ ! -f "$APP_DIR/android/key.properties" ]]; then
  echo "❌ android/key.properties not found."
  echo "   Configure your Android keystore and ensure key.properties exists."
  exit 1
fi

echo "==> Checking Flutter version..."
FLUTTER_VERSION=$(flutter --version | head -1)
echo "    $FLUTTER_VERSION"
echo ""

echo "==> Cleaning previous builds..."
cd "$APP_DIR"
rm -rf build/ .dart_tool/
echo "    ✓ Clean complete"
echo ""

echo "==> Running flutter pub get..."
flutter pub get
echo "    ✓ Dependencies downloaded"
echo ""

echo "==> Running flutter analyze..."
flutter analyze --no-pub
echo "    ✓ Analysis passed"
echo ""

echo "==> Deleting generated plugin registrant..."
# Prevents integration_test plugin from being included in release APK.
# Plugin binary is not available in release context, causing compile failure.
rm -f "$APP_DIR/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
echo "    ✓ Registrant deleted"
echo ""

echo "==> Building release APK (beta flavour)..."
echo "    Flags: --no-pub (exclude dev_dependencies), --dart-define=BETA_BUILD=true"
echo ""
cd "$APP_DIR"
flutter build apk \
  --release \
  --no-pub \
  --dart-define=BETA_BUILD=true \
  -v

if [[ $? -ne 0 ]]; then
  echo ""
  echo "❌ Build failed. Check errors above."
  exit 1
fi

APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo ""
  echo "❌ APK not found at $APK_PATH"
  exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo ""
echo "✅ Android Beta APK built successfully"
echo "   Path: $APK_PATH"
echo "   Size: $APK_SIZE"
echo ""
echo "   Next: Test locally on Android emulator/device, or upload to Firebase App Distribution:"
echo "   $ firebase appdistribution:distribute \"$APK_PATH\" \\"
echo "     --app=1:123456789:android:abcdef123456 \\"
echo "     --testers-file=testers.txt"
