# ZeroSpoils Data Rescue Index

Use this page as the entry point for Android update, signing, and recovery tasks. The detailed step-by-step instructions live in the specialized guides below.

## Which Guide To Use

1. Use [docs/APK_UPDATE_FIX.md](./APK_UPDATE_FIX.md) if you want the shortest path to diagnose why Android updates require uninstalling first.
2. Use [docs/MANUAL_DATA_BACKUP.md](./MANUAL_DATA_BACKUP.md) if the installed app does not expose backup and restore in Settings and you need to preserve existing local data before uninstalling.
3. Use [docs/ANDROID_SIGNING_GUIDE.md](./ANDROID_SIGNING_GUIDE.md) to set up stable release signing so future APK updates work without forced uninstall.
4. Use [docs/DATA_BACKUP_GUIDE.md](./DATA_BACKUP_GUIDE.md) for the built-in JSON export and restore flow in current app versions.

## Recommended Order

1. Preserve current data first.
2. Fix signing next.
3. Restore data after installing the newly signed build.
4. Use the built-in backup flow for future updates.

## Quick Decision Guide

- Installed app has no backup and restore UI: start with [docs/MANUAL_DATA_BACKUP.md](./MANUAL_DATA_BACKUP.md).
- Installed app already supports export and restore: start with [docs/DATA_BACKUP_GUIDE.md](./DATA_BACKUP_GUIDE.md).
- New APK still requires uninstall before install: review [docs/APK_UPDATE_FIX.md](./APK_UPDATE_FIX.md) and then complete [docs/ANDROID_SIGNING_GUIDE.md](./ANDROID_SIGNING_GUIDE.md).

## Scope

This file is intentionally short to avoid duplicating instructions already maintained in the detailed guides.
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
2. **[`MANUAL_DATA_BACKUP.md`](./MANUAL_DATA_BACKUP.md)** - ADB pull/run-as recovery (legacy adb backup noted)
3. **[`ANDROID_SIGNING_GUIDE.md`](./ANDROID_SIGNING_GUIDE.md)** - Complete signing setup guide
4. **[`DATA_BACKUP_GUIDE.md`](./DATA_BACKUP_GUIDE.md)** - Built-in backup feature guide

---

## 💡 Why This Happened

**The Problem:**
- Without stable release signing, APK signatures can differ between builds
- Different signatures make Android treat builds as different apps
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
