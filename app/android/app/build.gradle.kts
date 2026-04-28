import org.gradle.api.GradleException
import java.util.Properties

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
val keystoreProperties = Properties()
val requiredKeystoreKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val allowDebugSigningForRelease = providers
    .gradleProperty("ALLOW_DEBUG_SIGNING_FOR_RELEASE")
    .orNull
    ?.toBooleanStrictOrNull() == true
val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { input ->
        keystoreProperties.load(input)
    }

    val missingKeys = requiredKeystoreKeys.filter { key ->
        keystoreProperties.getProperty(key).isNullOrBlank()
    }

    if (missingKeys.isNotEmpty()) {
        throw GradleException(
            "key.properties is missing required entries: ${missingKeys.joinToString(", ")}. " +
                "Required keys: ${requiredKeystoreKeys.joinToString(", ")}."
        )
    }
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
        // firebase_app_distribution_android exposes staging/production flavors.
        // Prefer staging so Android builds include the in-app Tester SDK.
        // Keep production as fallback for compatibility.
        missingDimensionStrategy("default", "staging", "production")
    }

    // Configure release signing only when key.properties is present and complete.
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else if (allowDebugSigningForRelease) {
                logger.warn(
                    "Building release with DEBUG signing because key.properties is missing and " +
                        "ALLOW_DEBUG_SIGNING_FOR_RELEASE=true. Do not distribute this APK."
                )
                signingConfigs.getByName("debug")
            } else if (isReleaseTaskRequested) {
                throw GradleException(
                    "Missing app/android/key.properties for release signing. " +
                        "Configure a release keystore, or set -PALLOW_DEBUG_SIGNING_FOR_RELEASE=true " +
                        "for local-only testing."
                )
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

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
    exclude(group = "com.google.firebase", module = "firebase-iid")
}

dependencies {
    // Keep Firebase Android SDK versions aligned when adding direct Firebase deps.
    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-common-ktx:20.4.0")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}

flutter {
    source = "../.."
}
