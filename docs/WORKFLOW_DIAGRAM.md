# ZeroSpoils APK Update Fix - Visual Workflow

## The Problem (Before Fix)

```
┌─────────────────────────────────────────────────────────────┐
│  Build #1                    Build #2                       │
│  ┌──────────────┐           ┌──────────────┐               │
│  │ app-v1.apk   │           │ app-v2.apk   │               │
│  │              │           │              │               │
│  │ Signed with  │           │ Signed with  │               │
│  │ debug key A  │  ≠        │ debug key B  │  ← Different! │
│  └──────────────┘           └──────────────┘               │
└─────────────────────────────────────────────────────────────┘
                    ↓
         ┌──────────────────────┐
         │  Android Rejects:    │
         │  "Different apps!"   │
         │                      │
         │  Must uninstall      │
         │  → Data lost ❌      │
         └──────────────────────┘
```

## The Solution (After Fix)

```
┌─────────────────────────────────────────────────────────────┐
│  One-time Setup: Generate Permanent Keystore                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ zerospoils-release-key.jks (stored securely)          │  │
│  │ Password: ************                                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  All Future Builds Use Same Key                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ app-v1.apk   │    │ app-v2.apk   │    │ app-v3.apk   │  │
│  │              │    │              │    │              │  │
│  │ Signed with  │    │ Signed with  │    │ Signed with  │  │
│  │ release key  │ =  │ release key  │ =  │ release key  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                    ↓
         ┌──────────────────────┐
         │  Android Accepts:    │
         │  "Same app!"         │
         │                      │
         │  Smooth update       │
         │  → Data safe ✅      │
         └──────────────────────┘
```

## Your Action Plan

### Step 1: Save Current Data (One-time)

```
┌────────────────────┐
│ Your Phone         │
│ ┌────────────────┐ │      ADB Pull      ┌────────────────┐
│ │ ZeroSpoils App │ ├──────────────────→ │ Your Computer  │
│ │                │ │                    │                │
│ │ items.hive     │ │  Hive database     │ Backup folder  │
│ │ - Milk         │ │  files extracted   │ items.hive     │
│ │ - Eggs         │ │                    │ _metadata.hive │
│ │ - Bread        │ │                    │                │
│ └────────────────┘ │                    └────────────────┘
└────────────────────┘                           │
                                                 ↓
                                      ┌──────────────────┐
                                      │ Store safely:    │
                                      │ - Google Drive   │
                                      │ - Email yourself │
                                      │ - USB backup     │
                                      └──────────────────┘
```

**Guide:** `docs/MANUAL_DATA_BACKUP.md`  
**Time:** 20 minutes

### Step 2: Set Up Release Signing (One-time)

```
┌─────────────────────────────────────────────────────────────┐
│  Generate Keystore                                           │
│  $ keytool -genkey -v -keystore ~/zerospoils-release-key.jks│
│                                                              │
│  ┌──────────────────────────────────────────────┐           │
│  │ Enter password: **********                   │           │
│  │ Your name: John Doe                          │           │
│  │ Organization: ZeroSpoils                     │           │
│  └──────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Configure Build                                             │
│  app/android/key.properties:                                │
│  ┌──────────────────────────────────────────────┐           │
│  │ storePassword=your-password                  │           │
│  │ keyPassword=your-password                    │           │
│  │ keyAlias=zerospoils                          │           │
│  │ storeFile=/path/to/zerospoils-release-key.jks│           │
│  └──────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Build Release APK                                           │
│  $ flutter build apk --release                              │
│                                                              │
│  ✅ app-release.apk (signed with permanent key)             │
└─────────────────────────────────────────────────────────────┘
```

**Guide:** `docs/ANDROID_SIGNING_GUIDE.md`  
**Time:** 15 minutes

### Step 3: Restore Data (One-time)

```
┌────────────────┐                    ┌────────────────────┐
│ Your Computer  │                    │ Your Phone         │
│                │      ADB Push      │ ┌────────────────┐ │
│ Backup folder  ├──────────────────→ │ │ ZeroSpoils App │ │
│ items.hive     │                    │ │ (new version)  │ │
│ _metadata.hive │  Restore database  │ │                │ │
│                │  files             │ │ items.hive     │ │
└────────────────┘                    │ │ - Milk   ✅    │ │
                                      │ │ - Eggs   ✅    │ │
                                      │ │ - Bread  ✅    │ │
                                      │ └────────────────┘ │
                                      └────────────────────┘
```

**Guide:** `docs/MANUAL_DATA_BACKUP.md` (Part 7)  
**Time:** 10 minutes

### Step 4: Future Updates (Ongoing)

```
┌─────────────────────────────────────────────────────────────┐
│  Built-in Backup Feature (New Versions)                     │
│                                                              │
│  ┌─────────────────────────────────────┐                    │
│  │ Settings → Data Management          │                    │
│  │                                     │                    │
│  │ ┌─────────────────────────────────┐ │                    │
│  │ │ [Backup Data]                   │ │ → JSON file        │
│  │ └─────────────────────────────────┘ │   exported         │
│  │                                     │                    │
│  │ ┌─────────────────────────────────┐ │                    │
│  │ │ [Restore from Backup]           │ │ ← JSON file        │
│  │ └─────────────────────────────────┘ │   imported         │
│  └─────────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘

Backup Schedule:
├─ Before app updates
├─ Weekly (automated reminder)
└─ Before device changes
```

**Guide:** `docs/DATA_BACKUP_GUIDE.md`  
**Time:** 2 minutes per backup

## Result: Smooth Update Experience

### Before Fix
```
New APK available
    ↓
Must uninstall old app
    ↓
All data lost ❌
    ↓
Manually re-enter everything
    ↓
Frustrated user 😞
```

### After Fix
```
New APK available
    ↓
Install (or adb install -r)
    ↓
App updates smoothly ✅
    ↓
All data preserved ✅
    ↓
Happy user 😊
```

## Complete Documentation Map

```
docs/
│
├─ README_DATA_RESCUE.md ←───────────── START HERE
│  └─ Complete step-by-step walkthrough
│
├─ MANUAL_DATA_BACKUP.md
│  ├─ Part 1-4: Setup & Extract (ADB)
│  ├─ Part 5-6: Uninstall & Install
│  └─ Part 7-8: Restore & Verify
│
├─ ANDROID_SIGNING_GUIDE.md
│  ├─ Generate keystore
│  ├─ Configure build
│  ├─ Build & test
│  └─ CI/CD integration (optional)
│
├─ DATA_BACKUP_GUIDE.md
│  ├─ Built-in feature usage
│  ├─ Backup schedule
│  └─ Restore process
│
└─ APK_UPDATE_FIX.md
   └─ Quick reference summary
```

## Key Takeaways

✅ **One-time setup** (Steps 1-3): ~45 minutes  
✅ **Permanent solution**: All future builds work smoothly  
✅ **Backup protection**: Built-in feature for ongoing safety  
✅ **No data loss**: Your items are always safe  

📖 **Start here:** `docs/README_DATA_RESCUE.md`

---

**Questions?** All guides have detailed troubleshooting sections.
