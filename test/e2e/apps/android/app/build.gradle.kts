plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "io.beamtest"
    compileSdk = 34

    defaultConfig {
        applicationId = "io.beamtest"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        ndk {
            // Default to x86_64 for emulator testing
            // CI will override this for other architectures
            abiFilters += listOf("x86_64")
        }

        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17"
                arguments += listOf(
                    "-DANDROID_STL=c++_shared",
                    "-DANDROID_TOOLCHAIN=clang"
                )
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
        }
        debug {
            isDebuggable = true
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    // Architecture-specific configurations for CI
    flavorDimensions += "arch"
    productFlavors {
        create("x86_64") {
            dimension = "arch"
            ndk {
                abiFilters.clear()
                abiFilters += "x86_64"
            }
        }
        create("arm64") {
            dimension = "arch"
            ndk {
                abiFilters.clear()
                abiFilters += "arm64-v8a"
            }
        }
        create("arm") {
            dimension = "arch"
            ndk {
                abiFilters.clear()
                abiFilters += "armeabi-v7a"
            }
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
