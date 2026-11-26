pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localProps = file("local.properties")
        require(localProps.exists()) { "local.properties नहीं मिली — पहले `flutter pub get` चलाएँ" }
        localProps.inputStream().use { properties.load(it) }
        val path = properties.getProperty("flutter.sdk")
        require(path != null) { "local.properties में flutter.sdk सेट नहीं है" }
        path
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.2" apply false
    id("org.jetbrains.kotlin.android") version "2.4.21" apply false
}

include(":app")
