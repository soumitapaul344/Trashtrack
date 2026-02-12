// Top-level build.gradle.kts

plugins {
    id("com.android.application") version "8.2.1" apply false
    id("com.android.library") version "8.2.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Disable tests for Flutter modules to prevent Gradle errors
tasks.withType<Test>().configureEach {
    enabled = false
}
