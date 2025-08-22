plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.budget_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8 // Or your current Java version
        targetCompatibility = JavaVersion.VERSION_1_8 // Or your current Java version
        isCoreLibraryDesugaringEnabled = true //
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.budget_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
dependencies {
    // Kotlin standard library
    implementation(kotlin("stdlib")) // Or implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8") or specific version

    // Example Firebase BoM and other dependencies
    // implementation(platform("com.google.firebase:firebase-bom:32.3.1"))
    // implementation("com.google.firebase:firebase-analytics-ktx")

    // --- This is the crucial line you need to add or ensure is present ---
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Or latest version

    // ... any other implementation, api, debugImplementation dependencies
}

flutter {
    source = "../.."
}
