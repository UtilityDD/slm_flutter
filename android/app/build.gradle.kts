import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: used only when android/key.properties exists (never committed; see
// tool/build_release.sh for the one-time keytool command). Without it, release builds fall
// back to the debug key so `flutter build apk --release` never breaks on a dev machine.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// Opt-in: -Pslm.compressNativeLibs=true stores .so files compressed in the APK. The APK
// (sideload/WhatsApp download) gets ~10 MB smaller, but Android then extracts the libs at
// install time, so the app uses MORE storage on the phone. Default (false) keeps the modern
// uncompressed, page-aligned libs: smaller installed footprint, mmap'd straight from the APK.
// Play Store (AAB) compresses for download either way.
val compressNativeLibs =
    (project.findProperty("slm.compressNativeLibs") as String?)?.toBoolean() ?: false

android {
    namespace = "com.smartlineman.app.slm_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.smartlineman.app.slm_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    androidResources {
        // The UI is Flutter (Bangla/English). Drop the ~80 other translations that AndroidX and
        // Play-services libraries bundle into resources.arsc; their few native strings fall back
        // to English.
        localeFilters += listOf("en", "bn")
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseKey) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            // R8 code shrinking + resource shrinking. The Flutter Gradle plugin already turns these
            // on by default; they are stated here so the release config is explicit and survives a
            // change of plugin default. Plugin keep rules live in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = compressNativeLibs
        }
        resources {
            // Build metadata that nothing reads at runtime (Kotlin module maps, AndroidX
            // version stamps, coroutines debug-probe agent).
            excludes +=
                listOf(
                    "META-INF/*.kotlin_module",
                    "META-INF/*.version",
                    "DebugProbesKt.bin",
                )
        }
    }

    dependenciesInfo {
        // Encrypted dependency report: only Google Play reads it, so keep it in the AAB only.
        includeInApk = false
        includeInBundle = true
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
