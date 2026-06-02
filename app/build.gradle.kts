import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

val localProps = Properties().apply {
    rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

/**
 * ビルド設定値の解決順:
 *   1. local.properties（ローカル開発）
 *   2. 環境変数（CI / GitHub Actions の Secrets）
 * どちらにも無ければ空文字。release ビルドでの必須値の空チェックは下で行う。
 */
fun resolveProp(key: String): String =
    localProps.getProperty(key)?.takeIf { it.isNotBlank() }
        ?: System.getenv(key)?.takeIf { it.isNotBlank() }
        ?: ""

val supabaseUrl = resolveProp("SUPABASE_URL")
val supabaseAnonKey = resolveProp("SUPABASE_ANON_KEY")
val supabaseGoogleWebClientId = resolveProp("SUPABASE_GOOGLE_WEB_CLIENT_ID")

android {
    namespace = "com.example.aleartmycontroller"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.aleartmycontroller"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        buildConfigField("String", "SUPABASE_URL", "\"$supabaseUrl\"")
        buildConfigField("String", "SUPABASE_ANON_KEY", "\"$supabaseAnonKey\"")
        buildConfigField("String", "SUPABASE_GOOGLE_WEB_CLIENT_ID", "\"$supabaseGoogleWebClientId\"")
    }

    val keystoreFile = resolveProp("RELEASE_KEYSTORE_PATH")
    signingConfigs {
        // keystore 情報（local.properties か CI Secrets）が揃っている場合のみ release 署名を構成する。
        // 揃っていなければ署名なし（=インストール不可な APK）になるため、配布時は必ず設定すること。
        if (keystoreFile.isNotBlank()) {
            create("release") {
                storeFile = file(keystoreFile)
                storePassword = resolveProp("RELEASE_KEYSTORE_PASSWORD")
                keyAlias = resolveProp("RELEASE_KEY_ALIAS")
                keyPassword = resolveProp("RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // keystore Secrets があれば release 署名、なければ debug 署名で代用（ローカル動作確認用）。
            signingConfig = if (keystoreFile.isNotBlank()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // fail-fast: 認証情報が無いまま空の release APK を配布してしまう事故を防ぐ。
            // （local.properties も環境変数も無い CI ビルドで起動直後にクラッシュするのを構造的に防止）
            if (supabaseUrl.isBlank() || supabaseAnonKey.isBlank()) {
                throw GradleException(
                    "SUPABASE_URL / SUPABASE_ANON_KEY が未設定です。" +
                        "local.properties か環境変数（CI Secrets）で指定してください。"
                )
            }
        }
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1,DEPENDENCIES,LICENSE,NOTICE}"
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.play.services.auth)
    implementation(libs.google.api.client)
    implementation(libs.google.api.services.calendar)
    implementation(libs.androidx.work.runtime.ktx)
    implementation(libs.hilt.work)
    ksp(libs.hilt.work.compiler)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.navigation.compose)

    // Room
    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)

    // Retrofit / OkHttp
    implementation(libs.retrofit.core)
    implementation(libs.retrofit.converter.gson)
    implementation(libs.okhttp.logging)

    // Coroutines
    implementation(libs.kotlinx.coroutines.android)

    // Coil
    implementation(libs.coil.compose)

    // DataStore
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.security.crypto)

    // Accompanist Permissions
    implementation(libs.accompanist.permissions)

    // Vico charts
    implementation(libs.vico.compose.m3)

    // Supabase
    implementation(platform(libs.supabase.bom))
    implementation(libs.supabase.auth)
    implementation(libs.supabase.postgrest)
    implementation(libs.supabase.storage)
    implementation(libs.ktor.android)

    // Hilt
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(libs.androidx.room.testing)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
    // SLF4J バックエンド（Supabase/Ktor が使用）。release ビルドにも必要なので全 variant に含める。
    implementation(libs.logback.android)
}
