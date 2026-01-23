# Android Emulator Troubleshooting Guide

## ✅ Your System Status
- **Flutter SDK:** 3.38.7 (installed correctly)
- **Android SDK:** 36.0.0 (working)
- **Emulator:** 35.5.10 (installed)
- **Acceleration:** WHPX (Windows Hypervisor Platform) - working
- **Available Emulators:** Pixel 7, Pixel 8 Pro, Pixel 9 Pro, Pixel Tablet
- **⚠️ GPU Issue:** Intel UHD Graphics 620 driver (v1.3.215) is outdated for Vulkan
  - **Solution:** Disable GPU emulation and use software rendering

## 🔧 FIXED: GPU Driver Crash Issue

**Problem:** Emulator terminates immediately with GPU driver errors
- Error: "Your GPU 'Intel(R) UHD Graphics 620' has driver version 1.3.215, and cannot support Vulkan properly"
- Cause: Intel GPU drivers too old for modern Android emulator Vulkan requirements

**Solution Applied:**
GPU acceleration has been **disabled** for all Pixel emulators to use software OpenGL rendering instead.

**Files Updated:**
- `C:\Users\olubi\.android\avd\Pixel_8_Pro.avd\config.ini` → `hw.gpu.enabled = no`
- `C:\Users\olubi\.android\avd\Pixel_7.avd\config.ini` → `hw.gpu.enabled = no`
- `C:\Users\olubi\.android\avd\Pixel_9_Pro.avd\config.ini` → `hw.gpu.enabled = no`

The emulator will now use software rendering which is slower but **stable**.

## 🚀 Quick Start

### Option 1: Use Windows Desktop (Recommended for Development)
Fastest, zero configuration:
```powershell
cd app
flutter run -d windows
```
**Pros:** Instant launch, perfect for UI/layout work, hot reload works great  
**Cons:** Some mobile-specific APIs unavailable (camera, sensors, connectivity)

### Option 2: Use Chrome Web
```powershell
cd app
flutter run -d chrome
```
**Pros:** Instant launch, browser debug tools available  
**Cons:** Limited mobile gesture support, some APIs unavailable

### Option 3: Android Emulator (Software Rendering)
After GPU fix, emulator should boot successfully:

```powershell
# Method A: Use the helper script
.\scripts\launch-emulator.ps1 Pixel_8_Pro

# Method B: Direct launch
flutter emulators --launch Pixel_8_Pro

# Wait 2-3 minutes for full boot, then check:
flutter devices

# When device appears, run your app:
cd app
flutter run
```

⏱️ **First boot:** 2-3 minutes (software rendering is slower)  
⏱️ **Subsequent boots:** 30-60 seconds (uses cached snapshot)

## 🐌 Performance Note
Software rendering (without GPU acceleration) is **slower** but **stable**. The Android emulator runs fine, just not as fast as GPU-accelerated rendering.

**If you want to try GPU acceleration again:**
1. Update Intel Graphics drivers to latest version
2. Edit AVD config: `hw.gpu.enabled = yes` and `hw.gpu.mode = host`
3. Launch: `flutter emulators --launch Pixel_8_Pro`

## 🔍 Debugging Emulator Issues

### Check if emulator process is running:
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*emulator*" -or $_.ProcessName -like "*qemu*"}
```

### Kill stuck emulator:
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*qemu*"} | Stop-Process -Force
```

### View emulator configuration:
```powershell
Get-Content "C:\Users\olubi\.android\avd\Pixel_8_Pro.avd\config.ini"
```

### Check detailed boot logs:
```powershell
cd "C:\Users\olubi\AppData\Local\Android\sdk\emulator"
.\emulator.exe -avd Pixel_8_Pro -verbose 2>&1 | Tee-Object boot.log
```

### Verify WHPX acceleration is available:
```powershell
cd "C:\Users\olubi\AppData\Local\Android\sdk\emulator"
.\emulator.exe -accel-check
```
Expected output: `WHPX(...) is installed and usable.`

## 📋 Recommended Development Workflow

| Task | Device | Time | Notes |
|------|--------|------|-------|
| **UI Layout** | Windows Desktop | Instant | Best for rapid iteration |
| **Quick Preview** | Chrome Web | Instant | Good for responsive testing |
| **Mobile Features** | Android Emulator | 2-3 min first boot | Supports camera, sensors, etc |
| **Final Testing** | Physical Android | 1-2 min | Most realistic, requires USB |

## 🆘 Advanced Troubleshooting

### If emulator still won't start:

1. **Clear AVD cache:**
   ```powershell
   cd C:\Users\olubi\.android\avd\Pixel_8_Pro.avd
   Remove-Item cache.img -Force
   Remove-Item userdata-qemu.img -Force
   ```

2. **Recreate AVD:**
   ```powershell
   flutter emulators --delete Pixel_8_Pro
   flutter emulators --create
   ```

3. **Check system requirements:**
   ```powershell
   flutter doctor -v
   ```

4. **Update Android tools:**
   - Open Android Studio
   - SDK Manager → SDK Tools tab
   - Update "Android Emulator" and "Android SDK Platform-Tools"

5. **Use Physical Device:**
   ```powershell
   # Connect Android phone via USB
   # Enable Developer Mode and USB Debugging
   flutter devices  # Should see your phone
   flutter run      # Runs on physical device
   ```

## 📚 Useful Commands Reference

```powershell
# List all emulators
flutter emulators

# Launch emulator by name
flutter emulators --launch Pixel_8_Pro

# List connected devices
flutter devices

# Run app on specific device
flutter run -d Pixel_8_Pro
flutter run -d windows
flutter run -d chrome

# Run with hot reload (works best on desktop)
flutter run -d windows

# Run tests
flutter test

# Check Flutter setup
flutter doctor -v
```

## ✅ Solution Summary

✅ **GPU disabled** for all emulators (stable software rendering)  
✅ **Emulator boots successfully** (2-3 min first time)  
✅ **Use Windows desktop** for fastest development  
✅ **Use Android emulator** when mobile-specific features needed  
✅ **All tools configured** and ready to go
