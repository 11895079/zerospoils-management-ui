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

FLUTTER_VERSION="3.41.8"
FLUTTER_HOME="$HOME/flutter"
FLUTTER_RELEASES_BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases"
FLUTTER_RELEASES_JSON_URL="${FLUTTER_RELEASES_BASE_URL}/releases_macos.json"

MACHINE_ARCH="$(uname -m)"
case "$MACHINE_ARCH" in
  arm64)
    FLUTTER_ARCHIVE_FILE="flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"
    ;;
  x86_64)
    FLUTTER_ARCHIVE_FILE="flutter_macos_${FLUTTER_VERSION}-stable.zip"
    ;;
  *)
    echo "Unsupported macOS architecture: $MACHINE_ARCH"
    exit 1
    ;;
esac

FLUTTER_ARCHIVE_URL="${FLUTTER_RELEASES_BASE_URL}/stable/macos/${FLUTTER_ARCHIVE_FILE}"

# ---------------------------------------------------------------------------
# 1. Install Flutter
# ---------------------------------------------------------------------------
if ! command -v flutter > /dev/null 2>&1; then
  echo "Flutter not found — installing $FLUTTER_VERSION (stable, $MACHINE_ARCH)"

  # Resolve SHA256 from the releases manifest. The manifest includes a 'sha256'
  # field per entry (distinct from 'hash' which is the git commit hash).
  # Filter to channel==stable for a deterministic match.
  FLUTTER_ARCHIVE_SHA256="$({
    curl --fail --silent --show-error --location "$FLUTTER_RELEASES_JSON_URL" \
      --output /tmp/flutter_releases.json && \
    python3 - "$FLUTTER_ARCHIVE_FILE" /tmp/flutter_releases.json <<'PY'
import json
import sys

archive_file = sys.argv[1]
json_path = sys.argv[2]

with open(json_path, encoding='utf-8') as f:
    data = json.load(f)

for release in data.get('releases', []):
    if release.get('channel') != 'stable':
        continue
    archive_path = release.get('archive', '')
    if archive_path.endswith('/' + archive_file) or archive_path.endswith(archive_file):
        print(release.get('sha256', ''))
        break
PY
  } | tail -n 1)"

  if [ -z "$FLUTTER_ARCHIVE_SHA256" ]; then
    echo "Error: Unable to resolve Flutter archive SHA256 from releases manifest."
    echo "Refusing to install an unverified archive."
    exit 1
  fi

  curl --fail --silent --show-error --location \
    "$FLUTTER_ARCHIVE_URL" \
    --output /tmp/flutter.zip
  echo "$FLUTTER_ARCHIVE_SHA256  /tmp/flutter.zip" | shasum -a 256 -c -
  unzip -q /tmp/flutter.zip -d "$HOME"
  rm /tmp/flutter.zip
  rm -f /tmp/flutter_releases.json
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

pod install --no-repo-update

echo "ci_pre_xcodebuild: done"
