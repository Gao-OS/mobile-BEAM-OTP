# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mobile-BEAM packages the Erlang/Elixir BEAM Virtual Machine into platform-specific binaries for mobile phones. It creates static libraries (`liberlang.a`) that can be embedded in Android and iOS applications.

**Supported platforms:**
- Android: arm (armeabi-v7a), arm64 (arm64-v8a), x86_64 (API level 26+)
- iOS: arm64 (devices), aarch64-apple-iossimulator (M1), x86_64-apple-iossimulator (Intel)

## Build Commands

```bash
# Install dependencies (mise manages Erlang/Elixir versions via .tool-versions)
mise install
mix deps.get

# Build Android runtimes (requires Docker and ANDROID_NDK_HOME)
mix package.android.runtime

# Build iOS runtimes (requires Xcode)
mix package.ios.runtime

# Build with custom NIFs
mix package.android.runtime "https://github.com/elixir-desktop/exqlite"

# Build with default NIFs (esqlite, exqlite, libsecp256k1)
mix package.android.runtime with_diode_nifs

# Generate environment variables for NIF building
mix package.android.runtime env arm64

# Format code
mix format
```

**Build outputs:**
- Android: `_build/{arch-name}/liberlang.a` and `_build/android-runtime.zip`
- iOS: `_build/liberlang.xcframework`

## Architecture

### Core Modules (`lib/`)

- `mobile_runtimes.ex` - Base utilities: command execution, OTP management, archive repackaging
- `mobile_runtimes/android.ex` - Android architecture definitions, NDK toolchain setup
- `mobile_runtimes/ios.ex` - iOS architecture definitions

### Mix Tasks (`lib/mix/tasks/`)

- `package_android_runtime.ex` - Builds Android BEAM runtimes for all architectures
- `package_android_nif.ex` - Compiles Android NIFs
- `package_ios_runtime.ex` - Builds iOS runtimes and creates xcframework
- `package_ios_nif.ex` - Compiles iOS NIFs

### Build Infrastructure

- `stubs/bin/` - Wrapper scripts for ar, ranlib, ld, libtool (handles archive repackaging for static linking)
- `scripts/` - OpenSSL and Elixir installation scripts
- `patch/` - OTP and OpenSSL patches for mobile compilation
- `xcomp/` - OTP cross-compilation configuration templates (EEx)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OTP_TAG` | Erlang OTP version | OTP-{version from .tool-versions} |
| `OTP_SOURCE` | OTP repository URL | https://github.com/erlang/otp |
| `ANDROID_NDK_HOME` | Android NDK path | Auto-detected from ~/Library/Android/sdk/ndk |
| `SKIP_CLEAN_BUILD` | Reuse existing artifacts | unset |
| `MAKEFLAGS` | Make parallelization | -j10 -O |

## Build Process

1. Clone OTP source from GitHub
2. Build OpenSSL for target platform/architecture
3. Configure OTP with cross-compilation settings (xcomp/*.conf)
4. Compile BEAM runtime with static NIFs (asn1rt_nif, crypto)
5. Optionally build additional NIFs from external repositories
6. Repackage all static libraries into single `liberlang.a`

## Key Patterns

- **Two-pass OTP build**: First pass generates headers/libs, second pass includes custom NIFs
- **Static library aggregation**: Archives are extracted and reassembled using custom libtool wrapper
- **Docker-based Android**: Android builds use Docker for reproducible cross-compilation
- **Native iOS**: iOS builds use native Xcode/macOS tools
