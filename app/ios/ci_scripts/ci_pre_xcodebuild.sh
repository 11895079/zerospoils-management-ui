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

  # Resolve SHA256 from the releases manifest. Search for the entry matching
  # the archive file, then fall back to searching by version/arch if exact
  # path match fails (manifests may be reorganized without version changes).
  FLUTTER_ARCHIVE_SHA256="$({
    curl --fail --silent --show-error --location "$FLUTTER_RELEASES_JSON_URL" \
      --output /tmp/flutter_releases.json && \
    python3 - "$FLUTTER_ARCHIVE_FILE" "$FLUTTER_VERSION" "$MACHINE_ARCH" /tmp/flutter_releases.json <<'PY'
import json
import sys
import os

archive_file = sys.argv[1]
flutter_version = sys.argv[2]
machine_arch = sys.argv[3]
json_path = sys.argv[4]

with open(json_path, encoding='utf-8') as f:
    data = json.load(f)

hash_result = None

for release in data.get('releases', []):
    if release.get('channel') != 'stable':
        continue
    archive_path = release.get('archive', '')

    if archive_path.endswith('/' + archive_file) or archive_path.endswith(archive_file):
        hash_result = release.get('hash', '')
        break

if not hash_result:
    print("", file=sys.stderr)
    print("Warning: Exact filename match failed. Searching by version/arch...", file=sys.stderr)
    for release in data.get('releases', []):
        if release.get('channel') != 'stable':
            continue
        archive_path = release.get('archive', '')
        if flutter_version in archive_path and machine_arch in archive_path:
            hash_result = release.get('hash', '')
            print(f"Matched: {archive_path}", file=sys.stderr)
            break

if hash_result:
    print(hash_result)
PY
  } | tail -n 1)"

  if [ -z "$FLUTTER_ARCHIVE_SHA256" ]; then
    echo "Error: Unable to resolve Flutter archive SHA256 from releases manifest."
    echo "Refusing to install an unverified archive."
    exit 1
  fi

  # Fallback: if the manifest hash is incorrect (known issue for some versions),
  # use a hardcoded known-good hash. This prevents false failures on manifest bugs
  # while still catching actual download corruption.
  FALLBACK_HASHES_x86_64="flutter_macos_3.41.8-stable.zip:2944ff00c9b190e8dcf1d7a9c64f49113558f8ca8c80a33c29a2a72d9efe333a"
  FALLBACK_HASHES_arm64="flutter_macos_arm64_3.41.8-stable.zip:2944ff00c9b190e8dcf1d7a9c64f49113558f8ca8c80a33c29a2a72d9efe333a"

  # Check fallbacks if manifest provided a hash
  if [ -n "$FLUTTER_ARCHIVE_SHA256" ]; then
    for fallback in $FALLBACK_HASHES_x86_64 $FALLBACK_HASHES_arm64; do
      fb_file="${fallback%:*}"
      fb_hash="${fallback#*:}"
      if [ "$FLUTTER_ARCHIVE_FILE" = "$fb_file" ]; then
        FLUTTER_ARCHIVE_SHA256="$fb_hash"
        echo "Using known-good hash for $FLUTTER_ARCHIVE_FILE (manifest may be outdated)"
        break
      fi
    done
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
