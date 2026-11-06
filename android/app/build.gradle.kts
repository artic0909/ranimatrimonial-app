import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rani.matrimonial"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.rani.matrimonial"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties.getProperty("keyAlias")
            val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
            val storeFileVal = keystoreProperties.getProperty("storeFile")
            val storePasswordVal = keystoreProperties.getProperty("storePassword")

            if (storeFileVal != null) {
                val sFile = file(storeFileVal)
                val rootSFile = rootProject.file(storeFileVal)
                val appSFile = rootProject.file("app/$storeFileVal")
                if (sFile.exists()) {
                    storeFile = sFile
                    keyAlias = keyAliasVal
                    keyPassword = keyPasswordVal
                    storePassword = storePasswordVal
                } else if (rootSFile.exists()) {
                    storeFile = rootSFile
                    keyAlias = keyAliasVal
                    keyPassword = keyPasswordVal
                    storePassword = storePasswordVal
                } else if (appSFile.exists()) {
                    storeFile = appSFile
                    keyAlias = keyAliasVal
                    keyPassword = keyPasswordVal
                    storePassword = storePasswordVal
                }
            } else if (file("upload-keystore.jks").exists()) {
                storeFile = file("upload-keystore.jks")
                keyAlias = keyAliasVal ?: "upload"
                keyPassword = keyPasswordVal ?: "12345678"
                storePassword = storePasswordVal ?: "12345678"
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.findByName("release")
            if (releaseSigning != null && releaseSigning.storeFile != null && releaseSigning.storeFile!!.exists()) {
                signingConfig = releaseSigning
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("androidx.appcompat:appcompat:1.7.0")
}
