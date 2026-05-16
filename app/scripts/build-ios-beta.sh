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
#
# Optional env vars:
#   BUILD_MODE=validate|signed (default: validate)
#     - validate: no-codesign archive validation only (recommended local pre-CI)
#     - signed:   signed local IPA export (requires full local signing setup)
#   SIGNED_LOCAL_BUILD=true  Backward-compatible alias for BUILD_MODE=signed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_MODE="${BUILD_MODE:-validate}"
if [[ "${SIGNED_LOCAL_BUILD:-false}" == "true" ]]; then
  BUILD_MODE="signed"
fi

if [[ "$BUILD_MODE" != "validate" && "$BUILD_MODE" != "signed" ]]; then
  echo "❌ Invalid BUILD_MODE='$BUILD_MODE'. Use BUILD_MODE=validate or BUILD_MODE=signed."
  exit 1
fi

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

if [[ "$BUILD_MODE" == "signed" ]]; then
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

  DEV_IDENTITIES=$(security find-identity -v -p codesigning | grep -Ei 'Apple Development|iPhone Developer' || true)
  if [[ -z "$DEV_IDENTITIES" ]]; then
    HAS_DEV_CERT=false
    echo "    ⚠️  No Apple Development certificate found."
    echo "       flutter build ipa may fail locally without Development provisioning."
  else
    HAS_DEV_CERT=true
  fi
  echo ""
fi

if [[ "$BUILD_MODE" == "signed" ]]; then
  echo "==> Checking provisioning profile..."
  PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
  if [[ ! -d "$PROFILES_DIR" ]] || [[ -z "$(ls -A "$PROFILES_DIR")" ]]; then
    echo "⚠️  No provisioning profiles found in $PROFILES_DIR"
    echo "    Download and install from Apple Developer portal."
    exit 1
  fi
  PROFILE_COUNT=$(ls -1 "$PROFILES_DIR" | wc -l)
  echo "    ✓ Found $PROFILE_COUNT provisioning profile(s)"

  PROFILE_FILE=$(find "$PROFILES_DIR" -maxdepth 1 -type f -name "*.mobileprovision" | head -1)
  if [[ -z "$PROFILE_FILE" ]]; then
    echo "⚠️  No .mobileprovision files found in $PROFILES_DIR"
    exit 1
  fi

  security cms -D -i "$PROFILE_FILE" > /tmp/zs-local-profile.plist
  TEAM_ID=$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' /tmp/zs-local-profile.plist 2>/dev/null || true)
  PROFILE_NAME=$(/usr/libexec/PlistBuddy -c 'Print :Name' /tmp/zs-local-profile.plist 2>/dev/null || true)

  if [[ -z "$TEAM_ID" ]]; then
    echo "⚠️  Could not read Team ID from provisioning profile: $PROFILE_FILE"
    exit 1
  fi

  echo "    Using profile: $PROFILE_NAME"
  echo "    Team ID: $TEAM_ID"
  echo ""
fi

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
if [[ "$BUILD_MODE" == "signed" ]]; then
  echo "    Mode: signed (local IPA export)"
else
  echo "    Mode: validate (unsigned archive only)"
fi
echo "    Flags: --no-pub (exclude dev_dependencies), --dart-define=BETA_BUILD=true"
echo ""
cd "$APP_DIR"

if [[ "$BUILD_MODE" == "signed" && "$HAS_DEV_CERT" == "true" ]]; then
  EXPORT_OPTIONS_PLIST="$APP_DIR/build/ios/export-options.plist"
  mkdir -p "$APP_DIR/build/ios"
  cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM_ID}</string>
</dict>
</plist>
EOF

  flutter build ipa \
    --release \
    --no-pub \
    --dart-define=BETA_BUILD=true \
    --export-options-plist="$EXPORT_OPTIONS_PLIST" \
    -v
else
  if [[ "$BUILD_MODE" == "signed" && "$HAS_DEV_CERT" != "true" ]]; then
    echo "    ⚠️  BUILD_MODE=signed but no Development certificate found."
    echo "       Falling back to unsigned validation (--no-codesign)."
  fi

  flutter build ipa \
    --release \
    --no-codesign \
    --no-pub \
    --dart-define=BETA_BUILD=true \
    -v
fi

if [[ $? -ne 0 ]]; then
  echo ""
  echo "❌ Build failed. Check errors above."
  exit 1
fi

if [[ "$BUILD_MODE" == "signed" && "$HAS_DEV_CERT" == "true" ]]; then
  IPA_PATH=$(find "$APP_DIR/build/ios/ipa" -maxdepth 1 -name "*.ipa" | head -1)
  if [[ ! -f "$IPA_PATH" ]]; then
    echo ""
    echo "❌ IPA artifact not found in $APP_DIR/build/ios/ipa"
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
else
  ARCHIVE_PATH="$APP_DIR/build/ios/archive/Runner.xcarchive"
  if [[ ! -d "$ARCHIVE_PATH" ]]; then
    echo ""
    echo "❌ Unsigned archive not found at $ARCHIVE_PATH"
    exit 1
  fi

  echo ""
  echo "✅ iOS unsigned archive validation succeeded"
  echo "   Path: $ARCHIVE_PATH"
  echo "   Note: No Development cert installed, so this run used --no-codesign."
  echo "   You can still use this as a local pre-CI build validation step."
fi
