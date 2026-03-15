# Android Signing Setup Guide

## Overview

This guide explains how to set up **release signing for Android APKs** to enable app updates without requiring users to uninstall the existing version.

## The Problem

If Android release signing is not configured with a persistent keystore, release APKs can end up debug-signed and cause update incompatibilities. In `app/android/app/build.gradle.kts`, release signing now uses `key.properties` when present and can be explicitly gated for local-only fallback. The risk without stable signing is:

- Every new build has a different signature
- Android won't allow updating an app with a different signature
- Users must uninstall before installing new APK
- **All app data is lost** during uninstall (unless backed up manually)

## The Solution

Generate a **permanent release keystore** and configure the build to use it for release builds. Once set up:

✅ Same signing key across all future builds
✅ APK updates work normally (no uninstall needed)
✅ App data is preserved during updates
✅ Professional app signing for production releases

## Quick Start (3 Steps)

### Step 1: Generate Release Keystore

Run this command on your development machine:

```bash
keytool -genkey -v -keystore ~/zerospoils-release-key.jks -alias zerospoils -keyalg RSA -keysize 2048 -validity 10000
```

On Windows PowerShell, use an absolute path (or `$HOME`) instead of `~`:

```powershell
keytool -genkey -v -keystore "$HOME\\zerospoils-release-key.jks" -alias zerospoils -keyalg RSA -keysize 2048 -validity 10000
```

**Important:** the extension is `.jks` (not `.jsk`).

**You will be prompted for:**
- Keystore password (choose a strong password)
- Key password (can be same as keystore password)
- Your name/organization details

**Example session:**
```
Enter keystore password: [choose strong password]
Re-enter new password: [repeat password]
What is your first and last name?
  [Unknown]:  Your Name
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  ZeroSpoils
What is the name of your City or Locality?
  [Unknown]:  Your City
What is the name of your State or Province?
  [Unknown]:  Your State
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=Your Name, OU=Development, O=ZeroSpoils, L=Your City, ST=Your State, C=US correct?
  [no]:  yes

Enter key password for <zerospoils>
        (RETURN if same as keystore password):  [press enter or choose different password]
```

**Output:** `zerospoils-release-key.jks` file created in your home directory

⚠️ **CRITICAL:** Keep this keystore file safe and secret!
- Store it securely (password manager, encrypted backup)
- Never commit it to git (already in .gitignore)
- Never share it publicly
- **If you lose this keystore, you can NEVER update your app again**

### Step 2: Create key.properties File

1. Copy the template:
   ```bash
   cd app/android
   cp key.properties.template key.properties
   ```

2. Edit `key.properties` with your keystore information:
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=zerospoils
   storeFile=/Users/yourname/zerospoils-release-key.jks
   ```

   **Important:**
   - Use absolute path for `storeFile` (e.g., `/Users/yourname/zerospoils-release-key.jks` on Mac/Linux or `C:\\Users\\yourname\\zerospoils-release-key.jks` on Windows)
   - This file is gitignored - it will never be committed
   - Each developer needs their own copy with their keystore path

3. Verify `.gitignore` excludes this file:
   ```bash
   cat app/android/.gitignore | grep key.properties
   # Should show: key.properties
   ```

### Step 3: Build Release APK

Once `key.properties` is configured, build a release APK:

```bash
cd app
flutter build apk --release
```

**Output:**
```
Built build/app/outputs/flutter-apk/app-release.apk (18.2MB)
```

The APK is now signed with your release key!

## Detailed: Keystore Generation Options

### Basic Keystore (Recommended for Personal Use)

```bash
keytool -genkey -v \
  -keystore ~/zerospoils-release-key.jks \
  -alias zerospoils \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Windows PowerShell equivalent:

```powershell
keytool -genkey -v `
   -keystore "$HOME\\zerospoils-release-key.jks" `
   -alias zerospoils `
   -keyalg RSA `
   -keysize 2048 `
   -validity 10000
```

**Parameters:**
- `-keystore`: Where to save keystore file
- `-alias`: Friendly name for the key (used in key.properties)
- `-keyalg RSA`: Encryption algorithm
- `-keysize 2048`: Key length (2048 or 4096 recommended)
- `-validity 10000`: Days until expiration (~27 years)

### Production Keystore (For Store Publishing)

For Google Play Store releases, use stronger settings:

```bash
keytool -genkeypair -v \
  -keystore ~/zerospoils-release-key.jks \
  -alias zerospoils \
  -keyalg RSA \
  -keysize 4096 \
  -validity 25000 \
  -storetype JKS
```

Windows PowerShell equivalent:

```powershell
keytool -genkeypair -v `
   -keystore "$HOME\\zerospoils-release-key.jks" `
   -alias zerospoils `
   -keyalg RSA `
   -keysize 4096 `
   -validity 25000 `
   -storetype JKS
```

**Differences:**
- `4096-bit key` instead of 2048 (more secure)
- `25000 days validity` (~68 years)
- Explicit `-storetype JKS` for compatibility

### Verify Your Keystore

Check keystore details:

```bash
keytool -list -v -keystore ~/zerospoils-release-key.jks
```

Windows PowerShell:

```powershell
keytool -list -v -keystore "$HOME\\zerospoils-release-key.jks"
```

Shows:
- Alias name
- Creation date
- Expiration date
- Certificate fingerprints (SHA1, SHA256)

## Build Configuration Details

The `app/android/app/build.gradle.kts` file is configured to:

1. **Check for key.properties file**
2. **Load signing credentials** if file exists
3. **Use release signing** for release builds (when configured)
4. **Fail release tasks by default** if `key.properties` is missing
5. **Allow explicit local fallback** only when `-PALLOW_DEBUG_SIGNING_FOR_RELEASE=true` is set

This allows:
- ✅ Developers without keystore can still build debug APKs
- ✅ Release builds automatically use proper signing when configured
- ✅ Accidental distributable debug-signed release builds are blocked by default

## Distributing Your APK

### Installing Release APK on Device

1. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

2. **Transfer to phone:**
   - USB: `adb install build/app/outputs/flutter-apk/app-release.apk`
   - Email/Drive: Send APK file, download on phone, tap to install

3. **Grant installation permission:**
   - Android may prompt "Install unknown apps"
   - Grant permission for Chrome/Files/Drive (whatever you used to open APK)

4. **Install:**
   - Tap the APK file
   - Tap "Install"
   - Wait for completion
   - Tap "Open"

### Updating to New Version

With proper release signing, updates are smooth:

1. Build new APK with same keystore
2. Send to users
3. Users tap APK → "Update" (not "Install")
4. **App data is preserved automatically** ✅
5. No uninstall needed ✅

## Testing Your Setup

### Verify Signing is Configured

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Check APK signature:
   ```bash
   # Extract APK signature
   unzip -p build/app/outputs/flutter-apk/app-release.apk META-INF/CERT.RSA | keytool -printcert
   ```

3. Verify output shows your keystore details (Owner: CN=..., Valid from: ...)

### Test Update Flow

1. **Install initial version:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Add some data** in the app (create inventory items)

3. **Make a code change** (e.g., change app name in pubspec.yaml)

4. **Build new APK:**
   ```bash
   flutter build apk --release
   ```

5. **Install as update:**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   # -r flag = replace existing app
   ```

6. **Verify:**
   - App updates successfully (no "uninstall required" error) ✅
   - Data is still there ✅

## Security Best Practices

### Keystore Storage

**DO:**
- ✅ Store in home directory with restrictive permissions (`chmod 600`)
- ✅ Keep encrypted backup in password manager
- ✅ Store backup in secure cloud storage (encrypted)
- ✅ Document where keystore is stored (for team access)

**DON'T:**
- ❌ Commit to version control
- ❌ Share via email or messaging
- ❌ Store in shared/public folders
- ❌ Use weak passwords

### Password Management

**DO:**
- ✅ Use strong, unique passwords (20+ characters)
- ✅ Store passwords in password manager
- ✅ Use same password for store and key (simplifies management)

**DON'T:**
- ❌ Use simple passwords
- ❌ Store passwords in plain text files
- ❌ Share passwords insecurely

### Team Development

For team with multiple developers:

**Option 1: Shared Keystore (Small Team)**
- Store keystore in secure shared location (encrypted cloud storage)
- All developers use same keystore
- Shared password via password manager

**Option 2: CI/CD Signing (Recommended)**
- Store keystore in CI/CD secrets (GitHub Actions, etc.)
- Developers build debug APKs only
- CI builds and signs release APKs
- More secure, centralized control

### Keystore Recovery Plan

**If you lose the keystore:**
- You **cannot** update the published app
- You must create new keystore
- Publish as completely new app (different package name)
- Users must uninstall old app and install new one

**Prevention:**
1. Create backup immediately after generating keystore
2. Store backup in 2+ locations
3. Test backup by restoring it
4. Document keystore location for team

## CI/CD Integration (Advanced)

For automated builds with GitHub Actions:

1. **Encode keystore to base64:**
   ```bash
   base64 -i zerospoils-release-key.jks | pbcopy
   # Copies base64 to clipboard
   ```

2. **Add GitHub secrets:**
   - `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore
   - `ANDROID_KEYSTORE_PASSWORD`: Keystore password
   - `ANDROID_KEY_PASSWORD`: Key password
   - `ANDROID_KEY_ALIAS`: Key alias (e.g., "zerospoils")

3. **CI workflow decodes and uses keystore:**
   ```yaml
   - name: Decode keystore
     run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/release.jks
   
   - name: Create key.properties
     run: |
       echo "storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}" > android/key.properties
       echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties
       echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
       echo "storeFile=../release.jks" >> android/key.properties
   
   - name: Build release APK
     run: flutter build apk --release
   ```

See `planning/issues/030-set-up-build-pipelines-android-ios-on-tags.md` for full CI/CD setup.

## Troubleshooting

### "key.properties file not found"

**Symptom:** Release build fails with missing `key.properties`

**Solution:**
1. Create `app/android/key.properties` from template
2. Fill in your keystore details
3. Rebuild: `flutter build apk --release`

**Local-only override (not for distribution):**
```bash
flutter build apk --release -PALLOW_DEBUG_SIGNING_FOR_RELEASE=true
```

### "Keystore file not found"

**Error:** `java.io.FileNotFoundException: /path/to/keystore.jks`

**Solution:**
1. Check `storeFile` path in `key.properties` is correct
2. Use absolute path, not relative
3. Verify file exists: `ls -la /path/to/keystore.jks`

### "Wrong password"

**Error:** `Keystore was tampered with, or password was incorrect`

**Solution:**
1. Verify password in `key.properties` matches keystore password
2. Re-enter password when generating keystore
3. If forgotten, you must generate new keystore (cannot recover)

### "INSTALL_FAILED_UPDATE_INCOMPATIBLE"

**Error when installing:** Package signatures do not match previously installed version

**Cause:** Different signing key between old and new APK

**Solution:**
1. Uninstall old app: `adb uninstall com.zerospoils.zerospoils`
2. Backup data first (see `docs/DATA_BACKUP_GUIDE.md`)
3. Install new APK
4. Restore data
5. All future builds from same keystore will update smoothly

## Summary Checklist

- [ ] Generated release keystore with `keytool`
- [ ] Stored keystore in secure location
- [ ] Created backup of keystore
- [ ] Created `app/android/key.properties` from template
- [ ] Filled in keystore credentials in `key.properties`
- [ ] Verified `.gitignore` excludes `key.properties` and `*.jks`
- [ ] Built release APK: `flutter build apk --release`
- [ ] Tested APK installs on device
- [ ] Tested update flow (build → install again → data preserved)
- [ ] Documented keystore location for team
- [ ] Stored passwords in password manager

---

**Next Steps:**
1. Follow this guide to generate and configure your release keystore
2. Build a release APK and install on your phone
3. Test the update flow to verify it works
4. If you have existing users, they will need to uninstall once and restore data (see `docs/DATA_BACKUP_GUIDE.md`)
5. All future updates will work smoothly without data loss

**Need Help?**
- Check Troubleshooting section above
- Review Android's official [Sign your app](https://developer.android.com/studio/publish/app-signing) guide
- See `planning/issues/030-set-up-build-pipelines-android-ios-on-tags.md` for CI/CD setup
