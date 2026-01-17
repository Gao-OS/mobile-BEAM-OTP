# mobile-BEAM

Packages the Erlang/Elixir BEAM Virtual Machine into static libraries for mobile platforms.

## Supported Platforms

**Android** (API level 26+):
- armeabi-v7a (arm 32-bit)
- arm64-v8a (arm64)
- x86_64 (emulator)

**iOS** (12.0+):
- arm64 (devices)
- arm64-simulator (M1/M2 Macs)
- x86_64-simulator (Intel Macs)

## Flutter Plugin

The easiest way to use the BEAM runtime in your mobile app is via our Flutter plugin: [beam_vm](https://github.com/gsmlg-app/beam_vm).

```yaml
dependencies:
  beam_vm: ^1.0.0
```

The plugin bundles pre-built `liberlang.a` binaries for all supported architectures—no manual download or native configuration required.

For manual native integration without Flutter, see [Using Releases in Your App](#using-releases-in-your-app) below.

## Prerequisites

- [mise](https://mise.jdx.dev/) for Erlang/Elixir version management (reads `.tool-versions`)
- Xcode (for iOS builds)
- Android NDK (auto-detected from `~/Library/Android/sdk/ndk`)

## Setup

```bash
# Install Erlang and Elixir versions from .tool-versions
mise install

# Get dependencies
mix deps.get
```

## Building

### Android

```bash
mix package.android.runtime
```

Output: `_build/android-runtime.zip` containing `liberlang.a` for each architecture

### iOS

```bash
mix package.ios.runtime
```

Output: `_build/liberlang.xcframework`

### With Custom NIFs

```bash
# With specific NIF
mix package.android.runtime "https://github.com/elixir-desktop/exqlite"

# With Diode NIFs (esqlite, libsecp256k1)
mix package.android.runtime with_diode_nifs
```

## E2E Testing

End-to-end tests validate BEAM runtime functionality on actual mobile emulators/simulators.

### Running Tests

```bash
# Build test apps for specific architecture
mix e2e.build --arch android-x86_64

# Run tests
mix e2e.run --arch android-x86_64

# Combined build and run
mix e2e.test --arch android-x86_64

# Run on all architectures
mix e2e.test --all

# Output JUnit XML for CI
mix e2e.run --arch android-x86_64 --output-format junit --output results.xml
```

### Test Categories

- **Boot Tests**: VM initializes within 30 seconds
- **Execution Tests**: Arithmetic operations, string operations
- **NIF Tests**: Crypto SHA256, SQLite functionality

### CI Integration

E2E tests run automatically on PRs affecting `lib/**` or `test/e2e/**`. The release workflow optionally runs E2E tests before creating releases.

```bash
# Manual E2E test run via GitHub Actions
gh workflow run e2e-test.yml
```

## Releases

Releases are created via GitHub Actions and include:
- OTP source reference and version
- Elixir version
- Build commit SHA
- Included NIFs (exqlite by default)

### Triggering a Release

1. Go to Actions -> Create Release -> Run workflow
2. The workflow reads versions from `.tool-versions`
3. Builds Android and iOS runtimes in parallel
4. Creates release with:
   - `android-otp-{version}.tar.gz`
   - `ios-otp-{version}.tar.gz`

## Version Management

OTP and Elixir versions are managed in `.tool-versions`:

```
erlang 28.3
elixir 1.19.4-otp-28
```

Each OTP major version has its own branch (e.g., `OTP-26`, `OTP-27`, `OTP-28`).

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OTP_TAG` | Erlang OTP git tag | `OTP-{version from .tool-versions}` |
| `OTP_SOURCE` | OTP repository URL | `https://github.com/erlang/otp` |
| `ANDROID_NDK_HOME` | Android NDK path | Auto-detected |
| `SKIP_CLEAN_BUILD` | Reuse existing build artifacts | unset |

## Project Structure

```
lib/
├── mobile_runtimes.ex          # Core utilities
├── mobile_runtimes/
│   ├── android.ex              # Android architecture definitions
│   ├── ios.ex                  # iOS architecture definitions
│   └── e2e/                    # E2E test framework
│       ├── architecture.ex     # Architecture parsing
│       ├── builder.ex          # Test app builder
│       ├── emulator.ex         # Emulator/simulator control
│       ├── junit_xml.ex        # JUnit XML output
│       ├── retry.ex            # Retry with backoff
│       ├── runner.ex           # Test orchestration
│       ├── test_case.ex        # Test case struct
│       ├── test_report.ex      # Report aggregation
│       └── test_suite.ex       # Test suite struct
└── mix/tasks/
    ├── package_android_runtime.ex
    ├── package_android_nif.ex
    ├── package_ios_runtime.ex
    ├── package_ios_nif.ex
    ├── e2e_build.ex            # mix e2e.build
    ├── e2e_run.ex              # mix e2e.run
    └── e2e_test.ex             # mix e2e.test

test/e2e/apps/                  # Native test applications
├── android/                    # Android test app (Kotlin + JNI)
└── ios/                        # iOS test app (Swift + C)

scripts/                        # Build helper scripts
patch/                          # OTP patches for mobile
xcomp/                          # Cross-compilation configs
stubs/                          # Toolchain wrappers
```

## Included NIFs

By default, releases include:
- **exqlite** - SQLite3 NIF for Elixir

## Using Releases in Your App

This section explains how to embed the BEAM runtime and run Elixir code in your mobile app.

### Step 1: Download Release Artifacts

```bash
# Download from GitHub releases
gh release download OTP-28.3 --repo Gao-OS/mobile-BEAM-OTP

# Extract
tar -xzf android-otp-28.3.tar.gz  # Creates: armeabi-v7a/, arm64-v8a/, x86_64/
tar -xzf ios-otp-28.3.tar.gz      # Creates: liberlang.xcframework/
```

### Step 2: Build Your Elixir Project

Create a release of your Elixir project that can run on mobile:

```bash
# In your Elixir project
MIX_ENV=prod mix release --path _build/erlang_release

# The release directory structure:
# _build/erlang_release/
# ├── bin/
# ├── lib/           # Compiled BEAM files (.beam)
# ├── releases/
# │   └── start.boot # Boot script
# └── erts-{version}/
```

**Important**: Configure your release for embedded mode in `mix.exs`:

```elixir
def project do
  [
    releases: [
      my_app: [
        include_erts: false,  # We provide ERTS via liberlang
        include_executables_for: [],
        steps: [:assemble]
      ]
    ]
  ]
end
```

### Step 3: Android Integration

#### Project Structure

```
android/app/
├── src/main/
│   ├── cpp/
│   │   ├── CMakeLists.txt
│   │   └── native-lib.cpp
│   ├── assets/
│   │   └── erlang/          # Your Elixir release
│   │       ├── lib/
│   │       └── releases/
│   └── jniLibs/
│       ├── arm64-v8a/
│       │   └── liberlang.a
│       ├── armeabi-v7a/
│       │   └── liberlang.a
│       └── x86_64/
│           └── liberlang.a
```

#### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22.1)
project("myapp")

# Path to liberlang.a
set(LIBERLANG_DIR "${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}")

# Import liberlang
add_library(erlang STATIC IMPORTED)
set_target_properties(erlang PROPERTIES
    IMPORTED_LOCATION "${LIBERLANG_DIR}/liberlang.a"
)

# Your native library
add_library(native-lib SHARED native-lib.cpp)

# Link libraries
target_link_libraries(native-lib
    erlang
    android
    log
    z m dl
)
```

#### Native Code (native-lib.cpp)

```cpp
#include <jni.h>
#include <android/log.h>
#include <string>

extern "C" {
    int erl_start(int argc, char *argv[]);
}

static bool g_initialized = false;
static std::string g_erl_root;

extern "C" JNIEXPORT jint JNICALL
Java_com_example_myapp_MainActivity_initBeam(
    JNIEnv *env, jobject thiz, jstring erlangPath) {

    if (g_initialized) return 0;

    const char* path = env->GetStringUTFChars(erlangPath, nullptr);
    g_erl_root = path;
    env->ReleaseStringUTFChars(erlangPath, path);

    // Set environment
    std::string bindir = g_erl_root + "/bin";
    setenv("BINDIR", bindir.c_str(), 1);
    setenv("ROOTDIR", g_erl_root.c_str(), 1);
    setenv("EMU", "beam", 1);

    // Boot path
    std::string boot = g_erl_root + "/releases/start";

    const char* args[] = {
        "beam",
        "--",
        "-sbwt", "none",
        "-noshell",
        "-boot", boot.c_str(),
        nullptr
    };

    int argc = 0;
    while (args[argc]) argc++;

    int result = erl_start(argc, const_cast<char**>(args));
    if (result == 0) g_initialized = true;

    return result;
}
```

#### Kotlin/Java Code

```kotlin
class MainActivity : AppCompatActivity() {
    companion object {
        init {
            System.loadLibrary("native-lib")
        }
    }

    external fun initBeam(erlangPath: String): Int

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Extract assets to internal storage
        val erlangDir = File(filesDir, "erlang")
        extractAssets("erlang", erlangDir)

        // Initialize BEAM
        val result = initBeam(erlangDir.absolutePath)
        Log.i("BEAM", "Init result: $result")
    }

    private fun extractAssets(assetPath: String, destDir: File) {
        // Extract erlang/ assets to destDir
        // Implementation depends on your needs
    }
}
```

### Step 4: iOS Integration

#### Project Structure

```
ios/MyApp/
├── MyApp.xcodeproj
├── Frameworks/
│   └── liberlang.xcframework/
├── Resources/
│   └── erlang/              # Your Elixir release
│       ├── lib/
│       └── releases/
└── Sources/
    ├── BeamBridge.h
    ├── BeamBridge.c
    └── AppDelegate.swift
```

#### Xcode Setup

1. Drag `liberlang.xcframework` into your project
2. In Build Settings:
   - Add `-lz -lm -ldl` to "Other Linker Flags"
   - Add `$(PROJECT_DIR)/Frameworks` to "Framework Search Paths"

#### C Bridge (BeamBridge.h)

```c
#ifndef BeamBridge_h
#define BeamBridge_h

#include <stdbool.h>

int beam_init(const char* erl_root);
bool beam_is_initialized(void);

#endif
```

#### C Bridge (BeamBridge.c)

```c
#include "BeamBridge.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int erl_start(int argc, char *argv[]);

static bool g_initialized = false;

int beam_init(const char* erl_root) {
    if (g_initialized) return 0;

    // Set environment
    char bindir[1024];
    snprintf(bindir, sizeof(bindir), "%s/bin", erl_root);

    setenv("BINDIR", bindir, 1);
    setenv("ROOTDIR", erl_root, 1);
    setenv("EMU", "beam", 1);

    // Boot path
    char boot[1024];
    snprintf(boot, sizeof(boot), "%s/releases/start", erl_root);

    char* args[] = {
        "beam",
        "--",
        "-sbwt", "none",
        "-noshell",
        "-boot", boot,
        NULL
    };

    int argc = 0;
    while (args[argc]) argc++;

    int result = erl_start(argc, args);
    if (result == 0) g_initialized = true;

    return result;
}

bool beam_is_initialized(void) {
    return g_initialized;
}
```

#### Bridging Header (MyApp-Bridging-Header.h)

```c
#import "BeamBridge.h"
```

#### Swift Code

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Get erlang bundle path
        guard let erlangPath = Bundle.main.path(forResource: "erlang", ofType: nil) else {
            print("Erlang runtime not found in bundle")
            return false
        }

        // Initialize BEAM
        let result = beam_init(erlangPath)
        print("BEAM init result: \(result)")

        return result == 0
    }
}
```

### Step 5: Communicating with Elixir

For bidirectional communication between native code and Elixir, use one of these patterns:

#### Option A: Port Driver (Recommended)

Create an Elixir GenServer that communicates via stdin/stdout:

```elixir
defmodule MyApp.Bridge do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    port = Port.open({:spawn, "native_bridge"}, [:binary, :exit_status])
    {:ok, %{port: port}}
  end

  def handle_info({port, {:data, data}}, state) do
    # Handle data from native side
    {:noreply, state}
  end
end
```

#### Option B: NIF Callbacks

Register native functions that Elixir can call:

```cpp
// In your native code
static ERL_NIF_TERM call_native(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    // Handle call from Elixir
    return enif_make_atom(env, "ok");
}

static ErlNifFunc nif_funcs[] = {
    {"call_native", 1, call_native}
};

ERL_NIF_INIT(Elixir.MyApp.Native, nif_funcs, NULL, NULL, NULL, NULL)
```

### Complete Example

See the E2E test apps for working examples:
- Android: `test/e2e/apps/android/`
- iOS: `test/e2e/apps/ios/`

### Troubleshooting

**BEAM fails to start**:
- Ensure `ROOTDIR`, `BINDIR` environment variables are set correctly
- Verify boot file exists at `{erl_root}/releases/start.boot`
- Check that all `.beam` files are present in `lib/`

**Linker errors on iOS**:
- Add `-lz -lm -ldl` to Other Linker Flags
- Ensure xcframework is properly linked

**Linker errors on Android**:
- Verify `liberlang.a` path in CMakeLists.txt
- Ensure NDK version compatibility (25.x recommended)

**App crashes on startup**:
- Use `-noshell` flag to prevent BEAM from expecting terminal
- Use `-sbwt none` to disable scheduler binding (not supported on mobile)

## License

Apache 2.0
