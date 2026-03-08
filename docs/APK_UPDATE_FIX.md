# ZeroSpoils APK Update Issue - Quick Fix Guide

## Problem

When you try to install a new APK build of ZeroSpoils, Android requires you to **uninstall the existing app first**, which causes:
- ❌ Loss of all inventory data
- ❌ Unable to update app smoothly
- ❌ Frustrating user experience

## Root Cause

The app is using **debug signing keys** for release builds. Debug keys change between builds, making Android think each APK is from a different source.

## Solutions

You need to do **TWO things**:

### 1. Preserve Your Existing Data (Immediate Need)

**If your installed build doesn't have backup/restore options under `Settings -> PRIVACY & DATA`**, you'll need to manually extract the data:

📖 **Follow this guide:** [`docs/MANUAL_DATA_BACKUP.md`](./MANUAL_DATA_BACKUP.md)

**Quick summary:**
1. Enable USB debugging on your phone
2. Install ADB on your computer
3. Use `adb pull` to extract Hive database files
4. Store files safely on computer
5. Uninstall old app, install new APK
6. Use `adb push` to restore database files
7. Verify data in app

⏱️ **Time needed:** 15-20 minutes (first time setup)

### 2. Fix the Signing Issue (Permanent Fix)

Configure proper **release signing** so future updates work smoothly:

📖 **Follow this guide:** [`docs/ANDROID_SIGNING_GUIDE.md`](./ANDROID_SIGNING_GUIDE.md)

**Quick summary:**
1. Generate permanent keystore: `keytool -genkey -v -keystore ~/zerospoils-release-key.jks ...`
2. Create `app/android/key.properties` with keystore credentials
3. Build release APK: `flutter build apk --release`
4. All future builds will use same signing key
5. Updates will work without uninstalling ✅

⏱️ **Time needed:** 10 minutes (one-time setup)

## Quick Decision Tree

### If you have data in the current app:

1. **First:** Use manual backup method to save your data
2. **Then:** Set up release signing for future builds
3. **Result:** Data preserved AND future updates work smoothly

### If you have no data yet (fresh install):

1. **Skip manual backup** (nothing to preserve)
2. **Set up release signing** immediately
3. **Result:** All future updates will work smoothly

## After You've Fixed Everything

Once you have the new app version installed with data restored:

### Use Built-in Backup Feature (Going Forward)

The app has a **Settings -> PRIVACY & DATA** section with:
- ✅ **Export My Data** tile -> Exports to JSON file
- ✅ **Restore Backup** tile -> Imports JSON file

📖 **See:** [`docs/DATA_BACKUP_GUIDE.md`](./DATA_BACKUP_GUIDE.md) for details

**Recommended workflow:**
1. Backup data regularly (before app updates, weekly)
2. Store backups in Google Drive or email to yourself
3. If anything goes wrong, restore from JSON backup

## Technical Details

### Why Debug Signing Causes This

- Debug keystores are auto-generated per machine/build
- Each debug keystore has different signing certificates
- Android uses signatures to verify app updates
- Different signature = different app = must uninstall first

### Why Release Signing Fixes This

- Release keystore is permanent and manually created
- Same keystore used for all builds (stored in `key.properties`)
- All APKs have identical signature
- Android recognizes updates as same app
- Smooth updates with data preservation

## Files Changed

This fix adds/modifies:

- ✅ `app/android/app/build.gradle.kts` - Release signing configuration
- ✅ `app/android/key.properties.template` - Template for your keystore credentials
- ✅ `app/android/key.properties` - Your actual credentials (gitignored, you create this)
- ✅ `docs/ANDROID_SIGNING_GUIDE.md` - Complete signing setup guide
- ✅ `docs/MANUAL_DATA_BACKUP.md` - Manual data extraction guide (ADB)
- ✅ `docs/DATA_BACKUP_GUIDE.md` - Built-in backup feature guide

## Security Notes

⚠️ **Your keystore is critical:**
- Store it securely (encrypted backup)
- Never commit to git (already in `.gitignore`)
- If lost, you **cannot** update published apps
- Back it up in 2+ secure locations

✅ **What's safe to commit:**
- `build.gradle.kts` changes
- `key.properties.template` (template only)
- All documentation

❌ **Never commit:**
- `key.properties` (has your passwords)
- `*.jks` or `*.keystore` files (your signing keys)

## Need Help?

### For manual data backup:
- See detailed troubleshooting in [`docs/MANUAL_DATA_BACKUP.md`](./MANUAL_DATA_BACKUP.md)
- Check ADB connection: `adb devices`
- Verify files pulled: `ls -lh ~/zerospoils-backup/items.hive`

### For signing setup:
- See detailed troubleshooting in [`docs/ANDROID_SIGNING_GUIDE.md`](./ANDROID_SIGNING_GUIDE.md)
- Test keystore: `keytool -list -v -keystore ~/zerospoils-release-key.jks`
- Verify APK signature: `unzip -p app-release.apk META-INF/CERT.RSA | keytool -printcert`

## Summary

**Right now (to save your current data):**
```bash
# Follow MANUAL_DATA_BACKUP.md to extract Hive files via ADB
```

**For all future builds (permanent fix):**
```bash
# Generate keystore (once)
keytool -genkey -v -keystore ~/zerospoils-release-key.jks -alias zerospoils -keyalg RSA -keysize 2048 -validity 10000

# Create key.properties (once)
cp app/android/key.properties.template app/android/key.properties
# Edit key.properties with your keystore details

# Build release APK (every time)
flutter build apk --release
```

**Result:** Smooth updates, no data loss, happy users! 🎉
