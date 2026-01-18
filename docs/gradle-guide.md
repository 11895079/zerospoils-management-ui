# Build System & Gradle Guide

> **Who is this for?** Developers building ZeroSpoils for Android or encountering build issues.
>
> **Time to read:** ~5 minutes
>
> **What you'll learn:** What Gradle is, why it matters, and how it fits into Flutter

---

## What is Gradle?

**Gradle** is a **build system** that compiles your code into a working app. Think of it like a recipe that tells the compiler how to turn your Dart code into an Android app.

**Simple flow:**
```
Your Dart/Flutter code
          ↓
   Gradle (build system)
          ↓
   Android app (.apk or .aab)
```

Gradle handles:
- ✅ Downloading dependencies (libraries your app uses)
- ✅ Compiling Kotlin/Java code (Android native code)
- ✅ Packaging everything into an app
- ✅ Running tests
- ✅ Creating release builds

---

## Where is Gradle in ZeroSpoils?

All Gradle files are in `app/android/`:

```
app/android/
├── settings.gradle.kts          # Project-level settings
├── gradle.properties             # Gradle configuration
├── gradle/
│   └── wrapper/
│       └── gradle-wrapper.properties  # Gradle version config
└── app/
    └── build.gradle.kts         # App-level build config
```

**Key file: `app/android/app/build.gradle.kts`**

This tells Gradle how to build the app:
```kotlin
plugins {
    id("dev.flutter.flutter-gradle-plugin")  // ← Flutter plugin
}

android {
    compileSdk = 34  // Target Android version
    
    defaultConfig {
        minSdk = 21   // Minimum Android version
        targetSdk = 34
    }
}
```

---

## When Does Gradle Run?

Gradle automatically runs when you:

1. **`flutter run`** - Builds and runs app on emulator/device
2. **`flutter build apk`** - Creates an APK (Android app file)
3. **`flutter build aab`** - Creates an AAB (for Google Play Store)

You don't call Gradle directly; Flutter handles it!

---

## Common Gradle Error Scenarios

### ❌ "Build Gradle files are out of date"

**Cause:** Gradle version mismatch or corrupted cache  
**Fix:**
```bash
cd app
flutter clean
flutter pub get
flutter run
```

### ❌ "Gradle task build failed"

**Cause:** Dependency issues or compilation errors  
**Fix:**
```bash
cd app/android
./gradlew --stop  # Stop Gradle daemon
cd ..
flutter clean
flutter pub get
```

### ❌ "No matching variant"

**Cause:** Version conflict in dependencies  
**Fix:** Update `pubspec.yaml` with compatible versions, then:
```bash
flutter pub upgrade
flutter clean
flutter run
```

### ❌ "Java compilation failed"

**Cause:** Java/Kotlin code has errors  
**Fix:**
1. Check the error message carefully
2. Update dependencies:
   ```bash
   cd app
   flutter pub get
   ```
3. Try again

---

## Gradle vs. CocoaPods (iOS)

| Platform | Build System | Where | Purpose |
|----------|--------------|-------|---------|
| **Android** | Gradle | `app/android/` | Compiles Java/Kotlin to APK |
| **iOS** | CocoaPods | `app/ios/` | Manages iOS dependencies |

For this project, we focus on Android Gradle. CocoaPods is handled separately for iOS builds.

---

## Gradle Configuration (What You Might Change)

The most common Gradle settings you might adjust:

```kotlin
// app/android/app/build.gradle.kts

android {
    // Minimum Android version your app supports
    minSdk = 21
    
    // Target Android version (for features/compatibility)
    compileSdk = 34
    targetSdk = 34
    
    defaultConfig {
        applicationId = "com.example.zerospoils"  // App package name
        versionCode = 1
        versionName = "1.0.0"
    }
}

dependencies {
    // Additional Android dependencies go here
    // (Most are added via pubspec.yaml)
}
```

**You typically DON'T need to change Gradle files** unless:
- Adding native Android libraries
- Updating Android SDK versions
- Fixing build compatibility issues

---

## The Gradle Wrapper

The `gradle/wrapper/` directory contains:

```
gradle-wrapper.jar           # Gradle executable
gradle-wrapper.properties    # Gradle version (currently 8.14)
```

**Why a wrapper?**
- Everyone on the team uses the **same Gradle version**
- No manual installation needed
- Ensures consistent builds

The wrapper is in `.gitignore`, but the properties file is tracked in Git.

---

## Building Without Flutter CLI

If you need direct Gradle commands (rare):

```bash
cd app/android

# Build debug APK
./gradlew assemble

# Build release APK
./gradlew assembleRelease

# Run tests
./gradlew test

# Clean build cache
./gradlew clean
```

**But in most cases, just use:**
```bash
flutter run
flutter build apk
```

---

## Performance Tips

### Gradle Caching Issue
If builds are slow, Gradle's cache might need clearing:

```bash
cd app
flutter clean
flutter pub get
flutter run
```

### Increase Gradle Memory
If you see "heap space" errors, edit `app/android/gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G
```

This gives Gradle more RAM to work with.

---

## Quick Glossary

| Term | Meaning |
|------|---------|
| **APK** | Android Package - installable app file |
| **AAB** | Android App Bundle - optimized for Play Store |
| **SDK** | Software Development Kit (Android tools) |
| **minSdk** | Oldest Android version that can run your app |
| **targetSdk** | Newest Android version you've tested against |
| **compileSdk** | Android SDK version used to compile code |
| **Plugin** | Extension that adds functionality (Flutter plugin) |
| **Dependency** | External library your app uses |

---

## Next Steps

1. **Don't worry about Gradle details** until you encounter an issue
2. **Always try `flutter clean` first** when builds fail
3. **For build errors:** Google the exact error message
4. **For deep issues:** Check `app/android/app/build.gradle.kts`
5. **Reference:** [Gradle Official Docs](https://gradle.org)

---

## See Also

- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design
- [flutter-basics.md](flutter-basics.md) - Flutter fundamentals
- [Build pipelines issue](../planning/milestones/M1/030-set-up-build-pipelines-android-ios-on-tags.md) - CI/CD setup (M1/030)

