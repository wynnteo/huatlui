plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// No key.properties and no passwords in source control.
// Reuse the existing release keystore from MyLui / ByeLui.
val releaseKeyFile = System.getenv("HUATLUI_STORE_FILE")
    ?: "${System.getProperty("user.home")}/my-release-key.jks"
val releaseKeyAlias = System.getenv("HUATLUI_KEY_ALIAS") ?: "my-key-alias"
val releaseKeyPassword = System.getenv("HUATLUI_KEY_PASSWORD")
    ?: System.getenv("BYELUI_KEY_PASSWORD")
val releaseStorePassword = System.getenv("HUATLUI_STORE_PASSWORD")
    ?: System.getenv("BYELUI_STORE_PASSWORD")
val releaseAdMobId = System.getenv("HUATLUI_ADMOB_APP_ID")
val buildingRelease = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true) ||
        it.contains("bundle", ignoreCase = true)
}
if (buildingRelease) {
    require(!releaseKeyPassword.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        file(releaseKeyFile).isFile) {
        "Release signing not configured. Set HUATLUI_STORE_FILE (optional), " +
            "HUATLUI_KEY_PASSWORD and HUATLUI_STORE_PASSWORD."
    }
    require(releaseAdMobId != null &&
        Regex("""ca-app-pub-\d{16}~\d{10}""").matches(releaseAdMobId)) {
        "Set HUATLUI_ADMOB_APP_ID to HuatLui's own AdMob app ID before building release."
    }
}

android {
    namespace = "com.cloudfullstack.huatlui"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseKeyAlias
            if (releaseKeyPassword != null) keyPassword = releaseKeyPassword
            storeFile = file(releaseKeyFile)
            if (releaseStorePassword != null) storePassword = releaseStorePassword
        }
    }

    defaultConfig {
        applicationId = "com.cloudfullstack.huatlui"
        // Requested parity with MyLui. This excludes Android 15 and below.
        minSdk = 36
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Official test AdMob app ID in debug builds only.
        manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders["admobAppId"] = releaseAdMobId ?: ""
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
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
