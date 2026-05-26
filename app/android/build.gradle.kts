plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Ensure every Android library compiles against API 35+.
// firebase_app_distribution_android uses Material3 resources that reference
// android:attr/lStar (API 31+); a compileSdk floor of 35 guarantees AAPT2
// can resolve those attributes regardless of what each plugin declares.
//
// Uses androidComponents.finalizeDsl — the AGP variant API that fires after
// the subproject's android{} block has run but before AGP reads compileSdk to
// create variants.  This is the only window where the value can still be
// changed without a "It is too late to set compileSdk" error.
//
//   afterEvaluate            → too late: AGP has already read compileSdk
//   plugins.withId (direct)  → too early: android{} overwrites our value
//   finalizeDsl              → correct: after android{}, before variant setup
//
// compileSdk is Int? in AGP 8.x (nullable until set); ?: 0 makes maxOf
// compile on both nullable and non-nullable AGP versions.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl { lib ->
                lib.compileSdk = maxOf(lib.compileSdk ?: 0, 35)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
