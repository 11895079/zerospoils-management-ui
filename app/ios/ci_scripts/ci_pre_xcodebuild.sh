#!/bin/sh
# Xcode Cloud pre-build hook for Flutter + CocoaPods.
#
# Xcode Cloud calls this before `xcodebuild archive`.
# It must:
#   1. Install Flutter (not pre-installed on Xcode Cloud agents)
#   2. Run `flutter pub get` to generate Flutter/Generated.xcconfig
#      (required by the Podfile's flutter_root helper)
#   3. Run `pod install` to regenerate the Pods project and keep
#      Podfile.lock in sync (required by the sandbox-check build phase)
#
# CI_PRIMARY_REPOSITORY_PATH is set by Xcode Cloud to the repo root.

set -e

FLUTTER_VERSION="3.41.7"
FLUTTER_HOME="$HOME/flutter"

# ---------------------------------------------------------------------------
# 1. Install Flutter
# ---------------------------------------------------------------------------
if ! command -v flutter > /dev/null 2>&1; then
  echo "Flutter not found — installing $FLUTTER_VERSION (stable, arm64)"
  curl --fail --silent --show-error --location \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_${FLUTTER_VERSION}-stable.tar.xz" \
    --output /tmp/flutter.tar.xz
  tar -xf /tmp/flutter.tar.xz -C "$HOME"
  rm /tmp/flutter.tar.xz
fi

export PATH="$PATH:$FLUTTER_HOME/bin"
flutter --version

# ---------------------------------------------------------------------------
# 2. flutter pub get  →  generates Flutter/Generated.xcconfig
# ---------------------------------------------------------------------------
cd "$CI_PRIMARY_REPOSITORY_PATH/app"
flutter pub get

# ---------------------------------------------------------------------------
# 3. pod install  →  regenerates Pods project and Podfile.lock
# ---------------------------------------------------------------------------
cd ios

# Xcode Cloud agents ship with CocoaPods pre-installed.
# Disable analytics to avoid network delays.
export COCOAPODS_DISABLE_STATS=true

pod install --repo-update

echo "ci_pre_xcodebuild: done"
