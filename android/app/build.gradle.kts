import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "au.com.duxtonpubs.pubsfinancial"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Load signing values from android/local.properties
    val localProps = Properties().apply {
        val f = rootProject.file("local.properties")
        if (f.exists()) {
            f.inputStream().use { load(it) }
        }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = localProps.getProperty("storeFile")
                ?: throw GradleException("Missing storeFile in android/local.properties")
            val storePass = localProps.getProperty("storePassword")
                ?: throw GradleException("Missing storePassword in android/local.properties")
            val keyAliasVal = localProps.getProperty("keyAlias")
                ?: throw GradleException("Missing keyAlias in android/local.properties")
            val keyPass = localProps.getProperty("keyPassword")
                ?: throw GradleException("Missing keyPassword in android/local.properties")

            storeFile = file(storeFilePath)
            storePassword = storePass
            keyAlias = keyAliasVal
            keyPassword = keyPass

            if (!storeFile!!.exists()) {
                throw GradleException("Keystore not found: ${storeFile!!.absolutePath}")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "au.com.duxtonpubs.pubsfinancial"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
