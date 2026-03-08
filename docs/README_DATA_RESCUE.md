# Your ZeroSpoils Data - Step by Step Rescue Plan

## What You Need To Do

Hey! Here's your complete plan to save your data and fix the update issue permanently.

---

## 🚨 IMMEDIATE ACTION (Save Your Current Data)

Your current app version doesn't have the backup feature built in, so we need to manually extract your data from your phone.

### What You'll Need:
- ⏱️ Time: 20-30 minutes (first time)
- 💻 Your computer (Windows/Mac/Linux)
- 📱 Your Android phone with the app installed
- 🔌 USB cable to connect them
- 📋 The app data you want to save

### Step-by-Step Instructions:

**📖 Open this guide and follow it carefully:**  
[`docs/MANUAL_DATA_BACKUP.md`](./MANUAL_DATA_BACKUP.md)

**Quick overview of what you'll do:**

1. **Enable USB Debugging on your phone** (5 min)
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"

2. **Install ADB on your computer** (5 min)
   - Download Android Platform Tools
   - Or install via package manager (brew/choco/apt)

3. **Connect phone and backup Hive database** (5 min)
   ```bash
   mkdir ~/zerospoils-backup
   adb pull /data/data/com.zerospoils.zerospoils/app_flutter/ ~/zerospoils-backup/
   ```

4. **Verify backup files exist** (1 min)
   ```bash
   ls -lh ~/zerospoils-backup/items.hive
   # Should show file size > 0 bytes
   ```

5. **Copy backup to safe locations** (2 min)
   - Google Drive
   - Email to yourself
   - External USB drive

6. **NOW it's safe to uninstall the old app**
   ```bash
   adb uninstall com.zerospoils.zerospoils
   ```

---

## 🔧 PERMANENT FIX (So This Never Happens Again)

Set up proper Android release signing so future APK updates work smoothly.

### What You'll Need:
- ⏱️ Time: 10-15 minutes (one-time setup)
- 💻 Your computer
- 🔑 Ability to remember/store a strong password

### Step-by-Step Instructions:

**📖 Follow this guide:**  
[`docs/ANDROID_SIGNING_GUIDE.md`](./ANDROID_SIGNING_GUIDE.md)

**Quick overview of what you'll do:**

1. **Generate a permanent keystore** (5 min)
   ```bash
   keytool -genkey -v -keystore ~/zerospoils-release-key.jks \
     -alias zerospoils -keyalg RSA -keysize 2048 -validity 10000
   ```
   - Choose a **strong password** (save it in password manager!)
   - Answer the questions (name, organization, etc.)
   - **CRITICAL:** Store this keystore file safely - you can't update the app without it!

2. **Create key.properties file** (2 min)
   ```bash
   cd app/android
   cp key.properties.template key.properties
   # Edit key.properties with your keystore info
   ```

3. **Build new release APK** (3 min)
   ```bash
   cd app
   flutter build apk --release
   ```

4. **Install on your phone** (2 min)
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 📲 RESTORE YOUR DATA (After Installing New APK)

Now put your data back into the newly installed app.

### Using Manual Method (via ADB):

**📖 Continue in:**  
[`docs/MANUAL_DATA_BACKUP.md`](./MANUAL_DATA_BACKUP.md) - Part 7: Restore

**Quick commands:**
```bash
cd ~/zerospoils-backup
adb push items.hive /sdcard/Download/
adb shell monkey -p com.zerospoils.zerospoils 1
sleep 5
adb shell am force-stop com.zerospoils.zerospoils
adb shell run-as com.zerospoils.zerospoils cp /sdcard/Download/items.hive app_flutter/
```

**Then open the app and verify your items are there!**

---

## 🎯 GOING FORWARD (Future Backups)

The new app version has a built-in backup feature in Settings.

### How to use it:

**📖 See full guide:**  
[`docs/DATA_BACKUP_GUIDE.md`](./DATA_BACKUP_GUIDE.md)

**Quick usage:**

1. **Backup your data (before each update):**
   - Open ZeroSpoils app
   - Tap Settings (gear icon)
   - Scroll to "Data Management"
   - Tap "Backup Data"
   - Save to Downloads or Google Drive
   - **Store this file safely!**

2. **Restore if needed:**
   - Open ZeroSpoils app
   - Tap Settings
   - Scroll to "Data Management"
   - Tap "Restore from Backup"
   - Select your JSON backup file
   - Confirm restore

---

## ✅ Success Checklist

Complete these in order:

### Phase 1: Save Current Data
- [ ] USB debugging enabled on phone
- [ ] ADB installed and working (`adb devices` shows your phone)
- [ ] Hive database backed up (`items.hive` file exists and is > 0 bytes)
- [ ] Backup copied to 2+ safe locations (Google Drive, email, USB)
- [ ] Verified backup files are accessible

### Phase 2: Fix Signing Issue
- [ ] Generated permanent keystore (`zerospoils-release-key.jks`)
- [ ] Keystore stored securely with password in password manager
- [ ] Created `app/android/key.properties` with credentials
- [ ] Built release APK successfully
- [ ] Verified APK file exists: `app/build/app/outputs/flutter-apk/app-release.apk`

### Phase 3: Install & Restore
- [ ] Old app uninstalled (after backup verified)
- [ ] New APK installed on phone
- [ ] Data restored using ADB push method
- [ ] App opened and items verified present
- [ ] Created new backup using built-in feature (Settings → Backup)

### Phase 4: Future Proofing
- [ ] Know where keystore file is stored
- [ ] Have backup of keystore in secure location
- [ ] Passwords saved in password manager
- [ ] Understand how to use built-in backup feature
- [ ] Regular backup schedule planned (weekly or before updates)

---

## 🆘 If Something Goes Wrong

### Data backup failed (items.hive is 0 bytes or missing)

**Try:**
1. Open the app and navigate through a few screens
2. Force close the app
3. Try the backup command again
4. Alternative: Use `adb backup` method (see MANUAL_DATA_BACKUP.md)

### Can't connect phone via ADB

**Check:**
- USB debugging is enabled
- Approve "Allow USB debugging" prompt on phone
- Try different USB cable or port
- Run `adb kill-server && adb start-server`

### Restore failed (data not appearing in app)

**Try:**
1. Close app completely
2. Try alternative restore method (run-as vs temp storage)
3. Verify backup files are not corrupted (check file sizes)
4. Start over with restore commands

### Keystore generation failed

**Try:**
- Verify keytool is installed: `keytool -version`
- On Mac: keytool comes with Java, install Java if missing
- On Windows: Install JDK from Oracle or OpenJDK
- Check you have write permissions in target directory

### Build failed after adding signing config

**Check:**
- `key.properties` file exists in `app/android/`
- Path to keystore in `key.properties` is absolute and correct
- Keystore password is correct
- File permissions allow reading keystore

---

## 📚 All Documentation Available

1. **[`APK_UPDATE_FIX.md`](./APK_UPDATE_FIX.md)** - Quick overview (you are here)
2. **[`MANUAL_DATA_BACKUP.md`](./MANUAL_DATA_BACKUP.md)** - ADB backup/restore (for current version)
3. **[`ANDROID_SIGNING_GUIDE.md`](./ANDROID_SIGNING_GUIDE.md)** - Complete signing setup guide
4. **[`DATA_BACKUP_GUIDE.md`](./DATA_BACKUP_GUIDE.md)** - Built-in backup feature guide

---

## 💡 Why This Happened

**The Problem:**
- App was using debug signing keys for release builds
- Debug keys are auto-generated and change with each build
- Android sees different keys as different apps
- Different apps can't update each other (must uninstall first)

**The Fix:**
- Generate permanent release keystore (one-time)
- Configure app to use it for all release builds
- Same signature on every build = smooth updates
- Your data stays safe during updates

**The Bonus:**
- Built-in backup/restore feature in new versions
- JSON export format (human-readable)
- Easy to store, share, and version
- Works across reinstalls and device changes

---

## 🎉 After Everything Works

Once you're up and running with the new app and your data restored:

1. **Test the built-in backup feature** - make sure it works
2. **Create a backup schedule** - weekly or before updates
3. **Store keystore safely** - you'll need it for every future build
4. **Enjoy smooth updates** - no more uninstall/reinstall dance!

---

**Questions or stuck on a step?**  
All the detailed guides have extensive troubleshooting sections. Start there, and the solution is probably documented!

Good luck! 🚀
