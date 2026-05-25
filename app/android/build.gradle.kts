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
// Sequencing:
//   plugins.withId fires when "com.android.library" is applied — i.e. during
//   the subproject's plugins{} block, BEFORE android{} runs.  If we configure
//   compileSdk directly in that callback the subproject's own android{} block
//   overwrites it afterwards.
//
//   Wrapping in afterEvaluate (registered while the project is still being
//   evaluated) defers the override until after android{} has run, so our floor
//   wins.  This avoids the "project already evaluated" error that plain
//   subprojects { afterEvaluate{} } triggers when evaluationDependsOn(":app")
//   causes a subproject to be evaluated before the root afterEvaluate hook is
//   registered.
//
// compileSdk is Int? in AGP 8.x (nullable until set); ?: 0 makes maxOf work
// on both nullable and non-nullable AGP versions.
subprojects {
    plugins.withId("com.android.library") {
        afterEvaluate {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = maxOf(compileSdk ?: 0, 35)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
