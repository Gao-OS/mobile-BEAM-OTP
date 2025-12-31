# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mobile-BEAM packages the Erlang/Elixir BEAM Virtual Machine into platform-specific binaries for mobile phones. It creates static libraries (`liberlang.a`) that can be embedded in Android and iOS applications.

**Supported platforms:**
- Android (API level 26+): armeabi-v7a (arm), arm64-v8a (arm64), x86_64
- iOS (12.0+): arm64 (devices), arm64-simulator (M1/M2), x86_64-simulator (Intel)

## Build Commands

```bash
# Install dependencies (mise manages Erlang/Elixir versions via .tool-versions)
mise install
mix deps.get

# Build Android runtimes (requires ANDROID_NDK_HOME)
mix package.android.runtime

# Build iOS runtimes (requires Xcode)
mix package.ios.runtime

# Build with custom NIFs
mix package.android.runtime "https://github.com/elixir-desktop/exqlite"

# Build with Diode NIFs (esqlite, libsecp256k1)
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
- `patch/` - OTP patches for mobile compilation (no patches needed for OTP 28+; all fixes are upstream)
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

1. Clone/checkout OTP source from GitHub (or use actions/checkout in CI)
2. Apply mobile patches (`patch/otp-*.patch`)
3. Build OpenSSL for target platform/architecture
4. Configure OTP with cross-compilation settings (xcomp/*.conf)
5. Compile BEAM runtime with static NIFs (asn1rt_nif, crypto)
6. Optionally build additional NIFs from external repositories
7. Repackage all static libraries into single `liberlang.a`

## Key Patterns

- **Two-pass OTP build**: First pass generates headers/libs, second pass includes custom NIFs
- **Static library aggregation**: Archives are extracted and reassembled using custom libtool wrapper
- **Patch tracking**: `.mobile_patched` marker file prevents re-applying patches
- **Native builds**: Both Android and iOS use native toolchains (NDK/Xcode)

## Branch Strategy

Each OTP major version has its own mainline branch:
- `OTP-27` - Erlang/OTP 27.x (current)
- `OTP-26` - Erlang/OTP 26.x (legacy)

## CI/CD

GitHub Actions workflow (`create-release.yml`):
- Uses `actions/checkout` to clone OTP source (faster than git clone)
- Caches OpenSSL builds between runs
- Builds Android and iOS in parallel
- Creates release with detailed build info after both complete

## Active Technologies
- Elixir 1.19.4-otp-28, Erlang/OTP 28.3 + Mix (build tool), Android NDK, Xcode, OpenSSL (static), EEx (templates) (001-otp-28-release)
- N/A (build tooling only) (001-otp-28-release)

## Recent Changes
- 001-otp-28-release: Added Elixir 1.19.4-otp-28, Erlang/OTP 28.3 + Mix (build tool), Android NDK, Xcode, OpenSSL (static), EEx (templates)
