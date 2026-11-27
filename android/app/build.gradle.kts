plugins {
    id("com.android.application")
    // Flutter Gradle Plugin, Android प्लगइन के बाद ही लगना चाहिए।
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.bsmfoundation.bsm_mandir"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.bsmfoundation.bsm_mandir"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // रिलीज़ के लिए अपनी कीस्टोर सेट करें (README देखें)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
