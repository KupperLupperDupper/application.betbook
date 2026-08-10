import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Release signing configuration.
//
// Credentials are resolved from two sources, in order of priority:
//   1. android/key.properties  (local developer machines; git-ignored)
//   2. environment variables    (CI, e.g. GitHub Actions)
//
// This lets the same build work locally and in CI without any code changes.
// A key.properties file looks like:
//
//   storeFile=/absolute/path/to/upload-keystore.jks
//   storePassword=********
//   keyAlias=upload
//   keyPassword=********
//
// The matching environment variables are:
//   KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
// ---------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// Resolve a single signing value: prefer key.properties, then fall back to env.
fun signingValue(propKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propKey) ?: System.getenv(envKey)

val resolvedStoreFile: String? = signingValue("storeFile", "KEYSTORE_PATH")
// Treat an empty env value (CI without keystore secrets) as "no signing" so the
// release build falls back to debug keys instead of failing.
val hasReleaseSigning: Boolean = !resolvedStoreFile.isNullOrBlank()

android {
    namespace = "io.github.kupperlupperdupper.betbook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time on older APIs).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.kupperlupperdupper.betbook"
        // minSdk raised to 23 for biometric (BiometricPrompt) support.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // versionCode / versionName are derived from pubspec.yaml `version:`
        // (e.g. 1.0.0+1 -> versionName "1.0.0", versionCode 1), exactly as the
        // default Flutter template does.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // App name shown under the icon; overridden for debug below.
        manifestPlaceholders["appLabel"] = "BetBook"
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(resolvedStoreFile!!)
                storePassword = signingValue("storePassword", "KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Use the real upload keystore when credentials are available
            // (CI or a configured local machine). Otherwise fall back to the
            // debug keys so `flutter run --release` still works out of the box.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        debug {
            // Install debug builds as a SEPARATE app alongside the release app,
            // with their own data — so on-device testing never touches the
            // installed release build.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = "BetBook (debug)"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
