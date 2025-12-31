# Quickstart: OTP 27 Mobile BEAM Release

**Date**: 2025-12-30
**Feature**: Build and Release Guide

## Prerequisites

### All Platforms
- [mise](https://mise.jdx.dev/) for version management
- Git

### Android Builds
- Android NDK (auto-detected from `~/Library/Android/sdk/ndk` on macOS or `~/Android/Sdk/ndk` on Linux)
- Or set `ANDROID_NDK_HOME` environment variable

### iOS Builds
- macOS with Xcode installed
- Xcode Command Line Tools (`xcode-select --install`)

---

## Local Development

### Setup

```bash
# Clone the repository
git clone https://github.com/Gao-OS/mobile-BEAM-OTP.git
cd mobile-BEAM-OTP

# Switch to OTP 27 branch
git checkout OTP-27

# Install Erlang/Elixir versions
mise install

# Get dependencies
mix deps.get
```

### Build Android Runtime

```bash
# Build all Android architectures (armeabi-v7a, arm64-v8a, x86_64)
mix package.android.runtime

# Output: _build/android-runtime.zip
```

### Build iOS Runtime

```bash
# Requires macOS with Xcode
mix package.ios.runtime

# Output: _build/liberlang.xcframework
```

### Build with Custom NIFs

```bash
# With exqlite (default)
mix package.android.runtime

# With specific NIF
mix package.android.runtime "https://github.com/elixir-desktop/exqlite"

# With Diode NIFs (esqlite, libsecp256k1)
mix package.android.runtime with_diode_nifs
```

---

## Creating a Release

### Via GitHub Actions (Recommended)

1. Go to [Actions → Create Release](../../actions/workflows/create-release.yml)
2. Click "Run workflow"
3. Select `OTP-27` branch
4. Click "Run workflow"

The workflow will:
- Build Android runtimes (3 architectures)
- Build iOS runtimes (3 architectures)
- Create GitHub release with tag `OTP-27.3.4.6`
- Upload `android-otp-27.3.4.6.tar.gz` and `ios-otp-27.3.4.6.tar.gz`

### Manual Release

```bash
# Build both platforms
mix package.android.runtime
mix package.ios.runtime

# Package for distribution
cd _build
unzip android-runtime.zip
tar -czvf android-otp-27.3.4.6.tar.gz armeabi-v7a/ arm64-v8a/ x86_64/
tar -czvf ios-otp-27.3.4.6.tar.gz liberlang.xcframework/
```

---

## Verification

### Check Build Output

```bash
# Android - verify archive contents
unzip -l _build/android-runtime.zip

# Expected output:
#   armeabi-v7a/liberlang.a
#   arm64-v8a/liberlang.a
#   x86_64/liberlang.a

# iOS - verify xcframework structure
ls _build/liberlang.xcframework/

# Expected directories:
#   ios-arm64/
#   ios-arm64_x86_64-simulator/
```

### Verify Static Library Contents

```bash
# Android (check arm64)
ar -t _build/aarch64-unknown-linux-android/liberlang.a | grep -E 'beam|crypto|asn1'

# iOS (check device)
ar -t _build/liberlang.xcframework/ios-arm64/liberlang.a | grep -E 'beam|crypto|asn1'
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OTP_TAG` | `OTP-27.3.4.6` | OTP version to build |
| `OTP_SOURCE` | `https://github.com/erlang/otp` | OTP git repository |
| `ANDROID_NDK_HOME` | Auto-detected | Android NDK path |
| `SKIP_CLEAN_BUILD` | unset | Reuse existing build artifacts |
| `PARALLEL` | unset | Build architectures in parallel |
| `MAKEFLAGS` | `-j10 -O` | Make parallelization |

---

## Troubleshooting

### Patch Application Fails

If patches fail to apply, the OTP source may have changed:

```bash
# Check patch status
cd _build/otp
git status

# Try applying manually
git apply --check ../../patch/otp-space.patch
```

### Android NDK Not Found

```bash
# Set explicitly
export ANDROID_NDK_HOME=/path/to/ndk

# Or install via Android Studio SDK Manager
```

### iOS Build Fails - Missing Command Line Tools

```bash
xcode-select --install
sudo xcodebuild -license accept
```

### Build Artifacts Already Exist

```bash
# Clean all build artifacts
rm -rf _build

# Or skip clean build (development only)
SKIP_CLEAN_BUILD=1 mix package.android.runtime
```

---

## Next Steps

After a successful build:

1. **Test Integration**: Link `liberlang.a` in a sample Android/iOS project
2. **Verify BEAM Startup**: Initialize the VM and run a simple Elixir module
3. **Create Release**: Trigger GitHub Actions workflow for official release
