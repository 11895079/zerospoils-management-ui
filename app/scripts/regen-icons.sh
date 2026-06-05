#!/usr/bin/env bash
# regen-icons.sh
# Regenerate all launcher icons from the assets/icon sources, then heal a known
# flutter_launcher_icons bug.
#
# THE BUG (flutter_launcher_icons <=0.14.4, also on upstream master):
#   Its iOS app-icon-name setter (changeIosLauncherIcon) matches *every*
#   build-setting line containing the string "ASSETCATALOG" and rewrites the
#   value to the icon-set name. It is meant to touch only
#   ASSETCATALOG_COMPILER_APPICON_NAME (= AppIcon, already correct), but the
#   over-broad match also clobbers the unrelated boolean
#   ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS, turning the
#   valid `YES` into the bogus value `AppIcon`. This script restores it.
#
# Prerequisites:
#   - You have already re-rendered the PNGs from the SVGs. qlmanage flattens
#     transparency to white, so the *monochrome* layer must be rendered with an
#     alpha-preserving tool (see ICON_README.md "Rasterising the SVGs").
#   - Flutter installed and in PATH. macOS (BSD sed) — consistent with the rest
#     of the icon pipeline, which already depends on qlmanage.
#
# Usage:
#   ./scripts/regen-icons.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_DIR"

echo "==> Regenerating launcher icons"
flutter pub get
dart run flutter_launcher_icons

PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
BAD='ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;'
if grep -q "$BAD" "$PBXPROJ"; then
  echo "==> Healing flutter_launcher_icons pbxproj corruption (…SYMBOL_EXTENSIONS = AppIcon -> YES)"
  # Surgical: only flip the corrupted boolean back, so a legitimate
  # APPICON_NAME change (e.g. flavoured builds) is preserved.
  sed -i '' \
    's/\(ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = \)AppIcon;/\1YES;/g' \
    "$PBXPROJ"
  echo "    ✓ Restored ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES"
fi

echo ""
echo "✅ Launcher icons regenerated"
echo "   Sanity check before committing:"
echo "     - foreground drawable corners are GREEN (not white)"
echo "     - monochrome drawable corners are TRANSPARENT"
echo "     - ios 1024 icon has no alpha (sips -g hasAlpha …Icon-App-1024x1024@1x.png)"
echo "     - git diff is icon files + pubspec only (no project.pbxproj churn)"
