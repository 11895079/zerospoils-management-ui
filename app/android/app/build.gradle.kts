plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase integration for cloud telemetry and remote config
    id("com.google.gms.google-services")
}
// Load keystore properties from key.properties file (if it exists)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}


android {
    namespace = "com.zerospoils.zerospoils"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.zerospoils.zerospoils"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Configure release signing if key.properties exists
        signingConfigs {
            if (keystorePropertiesFile.exists()) {
                create("release") {
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    storeFile = file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                }
            }
        }

    }

    buildTypes {
        release {
            // Use release signing config if available, otherwise fall back to debug
            // This allows:
            // - Proper release signing when key.properties is configured
            // - Debug signing for developers without keystore (for testing)
            // See docs/ANDROID_SIGNING_GUIDE.md for setup instructions
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Enable Dart obfuscation via Flutter. Use with:
            // flutter build apk --release --obfuscate --split-debug-info=./debug-info/
            // Note: Obfuscation flag is passed via Flutter CLI, not here.
            // This is documented for the build team as a release pipeline step.
        }
    }

    // Enable R8/ProGuard minification for release builds
    buildFeatures {
        resValues = true
    }

    packagingOptions {
        exclude("META-INF/proguard/androidx-*.pro")
        exclude("META-INF/DEPENDENCIES")
    }
}

configurations.all {
    exclude(group = "com.google.android.play", module = "core-common")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}

flutter {
    source = "../.."
}
