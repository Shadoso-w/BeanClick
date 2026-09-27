import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 发布签名从 android/key.properties 读取，该文件不进仓库。
// 没有它时回落到 debug 签名，保证新克隆的仓库与 CI 仍能构建。
// 生成密钥与配置文件的方法见 docs/DEVELOPMENT.md「发布签名」。
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.beanclick.beanclick"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.beanclick.beanclick"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // 版本号来自 pubspec.yaml。split APK 时 Flutter 会自动叠加 1000 * ABI 值。
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                // 注意：key.properties 里的 storeFile 是相对 android/ 的路径，
                // 所以必须用 rootProject.file()。直接用 file() 会相对 android/app/ 解析，
                // 报 "Keystore file ... not found for signing config 'release'"。
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // 未配置发布密钥：用 debug 签名，只够本地装机测试，**不能分发**。
                signingConfigs.getByName("debug")
            }
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
