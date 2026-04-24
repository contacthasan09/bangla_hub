plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ updated
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.banglahubus.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.banglahubus.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// ✅ NEW Kotlin config (required for Kotlin 2.3+)
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

dependencies {

    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))

    // Firebase services
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    // MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
}