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
    namespace = "com.example.e_commerce"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // تفعيل الـ Desugaring عشان Java 8 ومكتبة النوتيفيكيشن
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.e_commerce"
        minSdk = flutter.minSdkVersion // يفضل تخليه 21 عشان يدعم معظم الأجهزة مع النوتيفيكيشن
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // تفعيل الـ MultiDex لو المشروع كبر
        multiDexEnabled = true
    }

    buildTypes {
        release {
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

flutter {
    source = "../.."
}

dependencies {
    // المكتبة المسؤولة عن حل مشكلة الـ Desugaring اللي ظهرتلك
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
