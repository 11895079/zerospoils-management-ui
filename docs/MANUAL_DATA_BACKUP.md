# Manual Data Backup - For Versions Without Backup Feature

## Overview

**Use this guide if your installed app version does NOT have the backup/restore feature in Settings.**

This guide shows how to manually extract your Hive database files from your phone before uninstalling the app, and then restore them after installing the new version.

## What You Need

- Android phone with USB debugging enabled
- Computer with ADB (Android Debug Bridge) installed
- USB cable to connect phone to computer

## Quick Summary

1. Enable USB debugging on your phone
2. Use ADB to pull Hive database files from phone
3. Store files safely on your computer
4. Uninstall old app and install new version
5. Use ADB to push database files back to phone

---

## Detailed Steps

### Part 1: Prepare Your Phone

#### Enable Developer Options

1. Open **Settings** on your phone
2. Scroll to **About phone**
3. Find **Build number**
4. Tap **Build number** 7 times rapidly
5. You'll see: "You are now a developer!"

#### Enable USB Debugging

1. Go back to main **Settings**
2. Find **Developer options** (usually under System or Advanced)
3. Turn on **USB debugging**
4. Confirm the security warning

### Part 2: Install ADB on Your Computer

#### Windows

**Option A: Download Platform Tools**
1. Download from: https://developer.android.com/studio/releases/platform-tools
2. Extract ZIP to `C:\platform-tools`
3. Add to PATH or use full path: `C:\platform-tools\adb.exe`

**Option B: Install via Package Manager**
```powershell
# Using Chocolatey
choco install adb

# Using Scoop
scoop install adb
```

#### Mac

```bash
# Using Homebrew
brew install android-platform-tools
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt-get install android-tools-adb

# Fedora
sudo dnf install android-tools
```

#### Verify Installation

```bash
adb version
# Should show: Android Debug Bridge version x.x.x
```

### Part 3: Connect Phone and Verify

1. **Connect phone to computer via USB**

2. **On phone:** Select "File Transfer" or "MTP" mode when prompted

3. **Verify ADB connection:**
   ```bash
   adb devices
   ```

4. **You should see:**
   ```
   List of devices attached
   ABC123XYZ    device
   ```

5. **If you see "unauthorized":**
   - Check your phone screen
   - Tap "Allow USB debugging" on the prompt
   - Check "Always allow from this computer"
   - Run `adb devices` again

### Part 4: Backup Hive Database Files

#### Find the Data Directory

The ZeroSpoils app stores data in Hive boxes at:
```
/data/data/com.zerospoils.zerospoils/app_flutter/
```

#### Extract the Database Files

**Option 1: Using ADB Pull (Recommended)**

```bash
# Create backup directory on your computer
mkdir ~/zerospoils-backup
cd ~/zerospoils-backup

# Pull all Hive data files from phone
adb pull /data/data/com.zerospoils.zerospoils/app_flutter/ .
```

**Expected output:**
```
/data/data/com.zerospoils.zerospoils/app_flutter/: 8 files pulled. X MB/s (XXXX bytes in X.XXXs)
```

**Files you should see in ~/zerospoils-backup/:**
- `items.hive` - Your inventory items database
- `items.lock` - Lock file (not critical)
- `_metadata.hive` - Schema version info
- `_metadata.lock` - Lock file (not critical)
- Possibly other `.hive` files depending on app version

**Option 2: Using ADB Backup (Legacy fallback; often unavailable on modern Android)**

`adb backup`/`adb restore` is deprecated and disabled on many devices (commonly Android 12+). Prefer `adb pull`, `run-as`, or the temporary-storage copy method first.

```bash
# Create a backup archive
adb backup -f zerospoils-backup.ab -noapk com.zerospoils.zerospoils

# This creates a file: zerospoils-backup.ab
```

On your phone, you'll need to:
- Confirm the backup operation
- Optionally enter a password (remember it!)

#### Verify Backup Files

```bash
# Check files were copied
ls -lh ~/zerospoils-backup/

# You should see items.hive and other .hive files
# Note the file sizes - items.hive should be > 0 bytes if you have data
```

**CRITICAL:** If `items.hive` is 0 bytes or missing, the backup failed. Try `run-as`/temporary-storage methods first; use Option 2 only if your device still supports it.

### Part 5: Safely Uninstall Old App

Now that your data is backed up:

1. **Verify backup files exist:**
   ```bash
   ls -lh ~/zerospoils-backup/items.hive
   ```

2. **Keep backup safe** - copy to multiple locations:
   ```bash
   # Copy to cloud/USB/second location
   cp -r ~/zerospoils-backup ~/Dropbox/zerospoils-backup
   ```

3. **Uninstall the app:**
   ```bash
   adb uninstall com.zerospoils.zerospoils
   ```
   
   Or uninstall manually from your phone:
   - Long-press app icon → Uninstall

### Part 6: Install New App Version

1. **Download new APK** to your computer

2. **Install via ADB:**
   ```bash
   adb install path/to/app-release.apk
   ```

3. **Verify installation:**
   ```bash
   adb shell pm list packages | grep zerospoils
   # Should show: package:com.zerospoils.zerospoils
   ```

4. **DO NOT open the app yet** - restore data first

### Part 7: Restore Hive Database Files

#### Method 1: Direct Push (Recommended)

```bash
# Navigate to your backup directory
cd ~/zerospoils-backup

# Push Hive files back to phone
adb push items.hive /data/data/com.zerospoils.zerospoils/app_flutter/
adb push _metadata.hive /data/data/com.zerospoils.zerospoils/app_flutter/

# Set proper permissions
adb shell run-as com.zerospoils.zerospoils chmod 644 app_flutter/items.hive
adb shell run-as com.zerospoils.zerospoils chmod 644 app_flutter/_metadata.hive
```

**If you get "Permission denied":**

Some Android versions don't allow direct push to app data. Use Method 2 instead.

#### Method 2: Via Temporary Storage

```bash
# Push to accessible location first
adb push items.hive /sdcard/Download/
adb push _metadata.hive /sdcard/Download/

# Open app once to initialize directories
adb shell monkey -p com.zerospoils.zerospoils 1

# Wait 5 seconds, then close app
adb shell am force-stop com.zerospoils.zerospoils

# Move files to app directory
adb shell run-as com.zerospoils.zerospoils cp /sdcard/Download/items.hive app_flutter/
adb shell run-as com.zerospoils.zerospoils cp /sdcard/Download/_metadata.hive app_flutter/

# Clean up
adb shell rm /sdcard/Download/items.hive
adb shell rm /sdcard/Download/_metadata.hive
```

#### Method 3: Restore from ADB Backup Archive (Legacy)

If you used `adb backup` to create `zerospoils-backup.ab`:

> Compatibility note: this restore flow may fail on newer Android versions where ADB backup/restore is blocked.

```bash
# Restore the backup
adb restore zerospoils-backup.ab
```

On your phone:
- Confirm the restore operation
- Enter password if you set one during backup
- Wait for "Restore finished" message

### Part 8: Verify Data Restored

1. **Open the ZeroSpoils app** on your phone

2. **Navigate to Inventory screen**

3. **Check if your items are there:**
   - All item names present?
   - Quantities correct?
   - Dates preserved?

4. **If items are missing:**
   - Close app: `adb shell am force-stop com.zerospoils.zerospoils`
   - Try restore Method 2 or 3 (whichever you didn't use)
   - Open app again

---

## Troubleshooting

### "Permission denied" when using adb pull

**Cause:** Android security prevents direct access to app data

**Solution 1: Use run-as**
```bash
# Copy to accessible location first
adb shell run-as com.zerospoils.zerospoils cp app_flutter/items.hive /sdcard/Download/
adb pull /sdcard/Download/items.hive ~/zerospoils-backup/
adb shell rm /sdcard/Download/items.hive
```

**Solution 2: Use adb backup (legacy fallback)**

This may be unsupported on newer Android versions.
```bash
adb backup -f zerospoils-backup.ab -noapk com.zerospoils.zerospoils
```

### "Device unauthorized"

**Solution:**
1. Check your phone screen for USB debugging prompt
2. Tap "Allow" and check "Always allow from this computer"
3. Run `adb devices` again

### "No devices/emulators found"

**Solution:**
1. Reconnect USB cable
2. Try different USB port
3. Install/update USB drivers (Windows)
4. Enable "File Transfer" mode on phone
5. Run: `adb kill-server && adb start-server`

### "items.hive is 0 bytes" or empty

**Cause:** App might not have initialized database yet

**Solution:**
1. Open app and add one test item
2. Close app completely
3. Retry backup command
4. Check file size again

### App crashes after restoring data

**Cause:** Database corruption or version incompatibility

**Solution:**
1. Uninstall app: `adb uninstall com.zerospoils.zerospoils`
2. Reinstall app
3. Open app to create fresh database
4. Use the new backup feature in Settings to restore from JSON backup (if you have one)

### Can't restore because new app version has backup feature

**Great news!** If new version has backup feature:

1. First, convert your Hive backup to JSON manually:
   - Install the new app
   - Use Settings → Backup to create a sample backup
   - Note the JSON structure
   - Or just restore Hive files using this guide, then create JSON backup for future

2. Or simply restore Hive files first using this guide, then use built-in backup feature going forward

---

## Alternative: Root Required Method

**If your phone is rooted**, you have easier access:

```bash
# Backup
adb shell su -c "cp -r /data/data/com.zerospoils.zerospoils/app_flutter ~/sdcard/zerospoils-backup"
adb pull /sdcard/zerospoils-backup ~/zerospoils-backup

# Restore (after reinstalling app)
adb push ~/zerospoils-backup /sdcard/
adb shell su -c "cp -r /sdcard/zerospoils-backup/* /data/data/com.zerospoils.zerospoils/app_flutter/"
adb shell su -c "chown -R u0_aXXX:u0_aXXX /data/data/com.zerospoils.zerospoils/app_flutter/"
```

(Replace `u0_aXXX` with actual app user from `adb shell ls -la /data/data/`)

---

## Quick Command Reference

### Setup
```bash
# Enable debugging, install ADB, connect phone
adb devices
```

### Backup
```bash
mkdir ~/zerospoils-backup
adb pull /data/data/com.zerospoils.zerospoils/app_flutter/ ~/zerospoils-backup/
# OR
adb backup -f zerospoils-backup.ab -noapk com.zerospoils.zerospoils
```

### Uninstall & Install
```bash
adb uninstall com.zerospoils.zerospoils
adb install path/to/new-app-release.apk
```

### Restore
```bash
cd ~/zerospoils-backup
adb push items.hive /sdcard/Download/
adb shell monkey -p com.zerospoils.zerospoils 1
sleep 5
adb shell am force-stop com.zerospoils.zerospoils
adb shell run-as com.zerospoils.zerospoils cp /sdcard/Download/items.hive app_flutter/
```

---

## After Successful Restore

Once you have the new app version with backup feature installed and data restored:

1. **Test the built-in backup feature:**
   - Open Settings -> PRIVACY & DATA
   - Tap "Export My Data"
   - Save backup to Downloads or Google Drive

2. **Verify backup works:**
   - Check backup file was created
   - Note file location

3. **From now on, use the built-in backup feature** instead of this manual process

4. **Keep this guide** for reference in case you need manual access again

---

## Summary Checklist

- [ ] USB debugging enabled on phone
- [ ] ADB installed on computer
- [ ] Phone connected and authorized (`adb devices` shows "device")
- [ ] Hive files backed up to computer (`items.hive` size > 0)
- [ ] Backup copied to second location (cloud/USB)
- [ ] Old app uninstalled
- [ ] New APK installed
- [ ] Database files restored to new app
- [ ] App opened and data verified
- [ ] New backup created using built-in feature (for future)

---

**Need Help?**

If you encounter issues:
1. Check Troubleshooting section above
2. Verify each command output matches expected results
3. Try alternative methods if one doesn't work
4. Keep backup files safe until you confirm restore worked
