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
│   └── ios.ex                  # iOS architecture definitions
└── mix/tasks/
    ├── package_android_runtime.ex
    ├── package_android_nif.ex
    ├── package_ios_runtime.ex
    └── package_ios_nif.ex

scripts/                        # Build helper scripts
patch/                          # OTP patches for mobile
xcomp/                          # Cross-compilation configs
stubs/                          # Toolchain wrappers
```

## Included NIFs

By default, releases include:
- **exqlite** - SQLite3 NIF for Elixir

## License

Apache 2.0
