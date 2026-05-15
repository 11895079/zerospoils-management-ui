#!/usr/bin/env bash
# build-ios-beta.sh
# Build signed iOS IPA for beta testing locally.
# Matches CI workflow: distribute-beta-ios.yml
#
# Prerequisites:
#   - Xcode installed
#   - Apple Developer certificate & provisioning profile installed in Keychain/Library
#   - Flutter installed and in PATH
#   - CocoaPods installed
#
# Usage:
#   ./scripts/build-ios-beta.sh
#   # Output: build/ios/ipa/ZeroSpoils.ipa

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> ZeroSpoils iOS Beta Build (Local)"
echo ""

# Check prerequisites
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found. Install Flutter and add to PATH."
  exit 1
fi

if ! command -v xcode-select &> /dev/null; then
  echo "❌ Xcode not found. Install Xcode from App Store."
  exit 1
fi

if ! command -v pod &> /dev/null; then
  echo "❌ CocoaPods not found. Install via: sudo gem install cocoapods"
  exit 1
fi

echo "==> Checking Flutter version..."
FLUTTER_VERSION=$(flutter --version | head -1)
echo "    $FLUTTER_VERSION"
echo ""

echo "==> Checking Xcode installation..."
XCODE_PATH=$(xcode-select -p)
echo "    $XCODE_PATH"
echo ""

echo "==> Checking signing identities in system keychain..."
IDENTITIES=$(security find-identity -v -p codesigning | grep -Ei 'Apple Distribution|iPhone Distribution' || true)
if [[ -z "$IDENTITIES" ]]; then
  echo "⚠️  No Apple Distribution certificate found in keychain."
  echo "    Install your certificate: security import cert.p12 -k ~/Library/Keychains/login.keychain-db"
  echo "    Or ensure provisioning profile is installed."
  exit 1
fi
echo "    ✓ Found certificate(s):"
echo "$IDENTITIES" | sed 's/^/      /'
echo ""

echo "==> Checking provisioning profile..."
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [[ ! -d "$PROFILES_DIR" ]] || [[ -z "$(ls -A "$PROFILES_DIR")" ]]; then
  echo "⚠️  No provisioning profiles found in $PROFILES_DIR"
  echo "    Download and install from Apple Developer portal."
  exit 1
fi
PROFILE_COUNT=$(ls -1 "$PROFILES_DIR" | wc -l)
echo "    ✓ Found $PROFILE_COUNT provisioning profile(s)"
echo ""

echo "==> Cleaning previous builds..."
cd "$APP_DIR"
rm -rf build/ .dart_tool/ ios/Pods ios/Podfile.lock
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

echo "==> Installing CocoaPods dependencies..."
cd "$APP_DIR/ios"
pod install --repo-update
echo "    ✓ CocoaPods updated"
echo ""

echo "==> Building release IPA (beta flavour)..."
echo "    Flags: --no-pub (exclude dev_dependencies), --dart-define=BETA_BUILD=true"
echo ""
cd "$APP_DIR"
flutter build ipa \
  --release \
  --no-pub \
  --dart-define=BETA_BUILD=true \
  --export-options-template=ios/ExportOptions.plist \
  -v

if [[ $? -ne 0 ]]; then
  echo ""
  echo "❌ Build failed. Check errors above."
  exit 1
fi

IPA_PATH="$APP_DIR/build/ios/ipa/ZeroSpoils.ipa"
if [[ ! -f "$IPA_PATH" ]]; then
  echo ""
  echo "❌ IPA not found at $IPA_PATH"
  exit 1
fi

IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
echo ""
echo "✅ iOS Beta IPA built successfully"
echo "   Path: $IPA_PATH"
echo "   Size: $IPA_SIZE"
echo ""
echo "   Next: Upload to TestFlight via Transporter or:"
echo "   $ xcrun altool --upload-app --type ios --file \"$IPA_PATH\" \\"
echo "     --username <apple-id> --password @keychain:AC_PASSWORD"
