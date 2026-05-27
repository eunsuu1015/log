import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// local.properties에서 AdMob ID 등을 읽는다 (이 파일은 .gitignore에 포함됨)
val localProps = Properties().also { props ->
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { props.load(it) }
}

// key.properties에서 서명 키 정보를 읽는다 (android/key.properties)
val keystoreProperties = Properties().also { props ->
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { props.load(it) }
}

android {
    namespace = "com.tistory.es1015.poopoolog"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildFeatures {
        compose = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            storeFile = if (storeFilePath != null) file(storeFilePath) else null
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.tistory.es1015.poopoolog"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // admob.app.id가 없으면 Google 테스트 App ID로 폴백
        manifestPlaceholders["admobAppId"] =
            localProps["admob.app.id"] ?: "ca-app-pub-3940256099942544~3347511713"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
//            signingConfig = signingConfigs.getByName("debug")

            // 💡 3. 오타 교정 (signingCOnfig -> signingConfig) 및 올바른 release 지정
            signingConfig = signingConfigs.getByName("release")

            // 💡 4. 코틀린 DSL 문법에 맞게 부호 개정 (= 추가)
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

configurations.all {
    resolutionStrategy.eachDependency {
        // home_widget이 "glance-appwidget:1.+"로 선언해 alpha(1.3.0-alpha01)가 선택됨.
        // alpha는 compileSdk 37 + AGP 9.1.0+를 요구하므로 1.0.0 stable로 고정.
        if (requested.group == "androidx.glance") {
            useVersion("1.0.0")
            because("glance 1.3.0-alpha01+ requires compileSdk 37 / AGP 9.1+")
        }
        // home_widget의 "work-runtime-ktx:2.+"가 2.11.x(minSdk 23)를 선택하므로 고정.
        if (requested.group == "androidx.work") {
            useVersion("2.9.1")
            because("work 2.10+ requires minSdk 23; pinned to 2.9.1 for minSdk 21 support")
        }
    }
}

dependencies {
    implementation("androidx.glance:glance-appwidget:1.0.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("io.mockk:mockk:1.13.8")
}

flutter {
    source = "../.."
}
