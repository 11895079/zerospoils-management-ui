# ZeroSpoils Data Backup & Restore Guide

## Overview

This guide explains how to **manually backup and restore your ZeroSpoils app data** to preserve your inventory items when reinstalling or updating the app.

## Why You Need This

When installing a new APK build that has a different signing key, Android requires you to uninstall the existing app first. This normally deletes all app data. **Using the backup/restore feature, you can preserve your data across reinstalls.**

## Quick Steps: Backup Before Reinstall

### 1. Export Your Data (Before Uninstalling)

1. Open ZeroSpoils app
2. Tap **Settings** (gear icon in bottom navigation)
3. Scroll to **Data Management** section
4. Tap **"Backup Data"** button
5. Choose where to save the backup file:
   - **Recommended:** Save to Downloads folder or Google Drive
   - **Default:** App will save to app documents directory
6. Wait for confirmation: "Backup saved to: [path]"
7. **IMPORTANT:** Note or share this backup file location

The backup file is named: `zerospoils_backup_YYYY-MM-DD.json`

### 2. Locate Your Backup File

The backup is saved as a JSON file. Default locations:
- **If you chose a location:** Where you saved it
- **If you used default:** `/storage/emulated/0/Android/data/com.zerospoils.zerospoils/files/zerospoils_backup_[timestamp].json`

**⚠️ CRITICAL:** The default app documents directory is deleted when you uninstall. **Before uninstalling:**
- Copy the backup file to a safe location like:
  - Downloads folder
  - Google Drive
  - Email it to yourself
  - Transfer via USB to your computer

### 3. Uninstall Old App

Now it's safe to uninstall the old version:
1. Long-press ZeroSpoils app icon
2. Select "Uninstall" or drag to uninstall area
3. Confirm deletion

### 4. Install New APK

1. Download the new APK file
2. Tap to install
3. Grant installation permissions if needed
4. Open the app after installation

### 5. Restore Your Data (After Installing New Version)

1. Open ZeroSpoils app (new version)
2. Tap **Settings** in bottom navigation
3. Scroll to **Data Management** section
4. Tap **"Restore from Backup"** button
5. Browse to where you saved your backup file
6. Select the `zerospoils_backup_[timestamp].json` file
7. Review the restore preview dialog:
   - Shows number of items to restore
   - Shows if migration is needed
   - **Warns that all existing data will be replaced**
8. Tap **"Restore"** to confirm
9. Wait for confirmation: "Restored X items"
10. Verify your items are back in the Inventory screen

## Backup File Details

### What's Included in the Backup

The backup file contains:
- ✅ All inventory items
- ✅ Item names, quantities, and units
- ✅ Categories and storage locations
- ✅ Expiry dates and prepared dates
- ✅ Item status (active/consumed/wasted)
- ✅ Waste reasons and purchase prices
- ✅ Created/updated timestamps

### Backup File Format

```json
{
  "metadata": {
    "backup_version": "1.0",
    "schema_version": "1.0.0",
    "app_version": "20260126.0.0",
    "exported_at": "2026-01-26T23:00:00.000Z",
    "item_count": 15
  },
  "data": {
    "items": [ /* array of items */ ]
  }
}
```

The file is human-readable JSON, so you can:
- View it in any text editor
- Share it via email, cloud storage, or USB
- Keep multiple versions for backup history

### File Size

Typical backup sizes:
- 10 items: ~2-5 KB
- 100 items: ~20-50 KB
- 1000 items: ~200-500 KB

Small enough to email or store anywhere.

## Troubleshooting

### "Backup failed" Error

**Cause:** File permission issues or insufficient storage

**Solution:**
1. Check that you have storage space available
2. Try saving to a different location (Downloads folder)
3. Grant file access permissions in Android Settings

### "Restore failed" Error

**Causes:**
- Invalid backup file (corrupted or wrong format)
- Backup from incompatible newer version

**Solutions:**
1. Verify the file is a valid JSON backup (open in text editor)
2. Try a different backup file if you have multiple
3. Check that app version is same or newer than backup version

### Can't Find Backup File After Uninstall

**Problem:** You saved to default location and already uninstalled

**Prevention:** Always copy backup to Downloads, Google Drive, or email before uninstalling

**Recovery:** If you have an Android backup solution (like Google Drive auto-backup), you may be able to recover the file. Otherwise, data is lost.

### Migration Warnings

If you see "Migration required from version X", this means:
- Backup was created with an older app version
- Data structure will be automatically updated during restore
- This is normal and safe

## Best Practices

1. **Backup Regularly:**
   - Before updating the app
   - After adding significant inventory
   - Before device factory reset or replacement

2. **Keep Multiple Backups:**
   - Email backups to yourself periodically
   - Store on cloud storage (Google Drive, Dropbox)
   - Keep at least 2 recent backups

3. **Test Restore:**
   - After creating a backup, test restoring it to verify it works
   - Verify all items are present after restore

4. **Safe Storage Locations:**
   - ✅ Downloads folder (survives uninstall)
   - ✅ Google Drive or cloud storage
   - ✅ Email to yourself
   - ✅ Computer via USB transfer
   - ❌ App documents directory (deleted on uninstall)

## Automatic Backup Tracking

The app automatically tracks your last backup:
- **Last backup time:** Shown in Settings → Data Management
- **Backup file size:** Displayed in KB
- **File path:** Full path to backup file

Use this to verify your backup is recent before uninstalling.

## Privacy & Security

- Backups are stored locally on your device (not uploaded to cloud automatically)
- Backup files contain your inventory data in plain text JSON
- Keep backup files secure if they contain sensitive information
- Delete old backups you no longer need

## Support

If you encounter issues:
1. Check this troubleshooting guide first
2. Verify backup file is valid JSON (open in text editor)
3. Try creating a fresh backup and restoring it
4. Report issues with app version and error message details

---

**Remember:** Always backup before uninstalling! The 30 seconds it takes to backup can save hours of re-entering your inventory.
