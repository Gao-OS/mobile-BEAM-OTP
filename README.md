# mobile-BEAM

Packages the Erlang/Elixir BEAM Virtual Machine into static libraries for mobile platforms.

## Supported Platforms

**Android** (API level 26+):
- arm (armeabi-v7a)
- arm64 (arm64-v8a)
- x86_64 (emulator)

**iOS**:
- arm64 (devices)
- arm64 (M1/M2 simulator)
- x86_64 (Intel simulator)

## Prerequisites

- [mise](https://mise.jdx.dev/) for Erlang/Elixir version management (reads `.tool-versions`)
- Docker (for Android builds)
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

Output: `_build/{arch}/liberlang.a` for each architecture

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

## Releases

Releases are created via GitHub Actions. Trigger the "Create Release" workflow manually:

1. Go to Actions → Create Release → Run workflow
2. The workflow reads OTP/Elixir versions from `.tool-versions`
3. Creates tag `otp-{version}` and release page
4. Builds and publishes:
   - `android-otp-{version}.tar.gz`
   - `ios-otp-{version}.tar.gz`

## Version Management

OTP and Elixir versions are managed in `.tool-versions`:

```
erlang 26.2.5.16
elixir 1.16.3
```

Update these versions and run the release workflow to create a new release.

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
│   └── ios.ex                  # iOS architecture definitions
└── mix/tasks/
    ├── package_android_runtime.ex
    ├── package_android_nif.ex
    ├── package_ios_runtime.ex
    └── package_ios_nif.ex

scripts/                        # Build helper scripts
patch/                          # OTP and OpenSSL patches
xcomp/                          # Cross-compilation configs
stubs/                          # Toolchain wrappers
```

## License

Apache 2.0
