pluginManagement {
    val flutterSdkPath = System.getenv("FLUTTER_ROOT") ?: throw Exception("Flutter SDK not found")


    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
id("org.jetbrains.kotlin.android") version "2.0.0" apply false
}

include(":app")



