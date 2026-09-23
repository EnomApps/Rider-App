// Imported explicitly: inside the Kotlin DSL `java` resolves to the Gradle
// java extension, which shadows the `java.util` package.
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase Cloud Messaging reads its project keys from google-services.json,
// which is not in version control. The plugin fails the build outright when
// the file is missing, so it is applied only when the file is there: a fresh
// checkout still builds, and push simply stays dark until the file is dropped
// in. See docs/PUSH-SETUP.md.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "Nexmile Rider: android/app/google-services.json is missing — building " +
            "without Firebase. Offer notifications will not arrive.",
    )
}

android {
    namespace = "com.nexmile.rider"
    compileSdk = flutter.compileSdkVersion
    // Pinned rather than flutter.ndkVersion: shared_preferences_android and
    // flutter_native_splash both require 27.x, and NDK releases are backward
    // compatible.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // flutter_local_notifications schedules against java.time, which is
        // API 26. Desugaring back-fills it for the older half of the install
        // base rather than raising minSdk.
        isCoreLibraryDesugaringEnabled = true
    }

    // Kotlin 2.3 removed the string-valued `kotlinOptions.jvmTarget`; the
    // typed compilerOptions DSL is the replacement.
    kotlin {
        compilerOptions {
            jvmTarget = JvmTarget.JVM_11
        }
    }

    defaultConfig {
        applicationId = "com.nexmile.rider"
        // 23 is the floor for adaptive-icon tooling and covers >99% of active
        // Android devices in India.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Release signing is read from android/key.properties when present so
        // the keystore never lands in version control. See README.
        create("release") {
            val keystoreProperties = Properties()
            val keystoreFile = rootProject.file("key.properties")
            if (keystoreFile.exists()) {
                keystoreProperties.load(keystoreFile.inputStream())
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug keys until android/key.properties exists,
            // so `flutter build apk --release` works out of the box.
            signingConfig = if (rootProject.file("key.properties").exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
