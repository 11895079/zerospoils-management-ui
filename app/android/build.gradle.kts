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
// Uses plugins.withId() instead of afterEvaluate() to avoid
// "project already evaluated" errors caused by evaluationDependsOn(":app").
//
// compileSdk is declared as Int? in AGP 8.x (nullable until the plugin sets
// it); ?: 0 provides the null-safe default so maxOf resolves to Int on both
// older (non-nullable) and newer (nullable) AGP versions.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = maxOf(compileSdk ?: 0, 35)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
