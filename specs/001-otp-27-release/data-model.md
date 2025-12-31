# Data Model: OTP 27 Mobile BEAM Release

**Date**: 2025-12-30
**Feature**: Build Artifacts Model

## Overview

This document describes the build artifacts and their relationships for the OTP 27 mobile BEAM release. As a build tooling project, the "data model" represents file artifacts rather than database entities.

---

## Build Artifacts

### 1. Source Inputs

| Artifact | Location | Description |
|----------|----------|-------------|
| OTP Source | `_build/otp/` | Erlang/OTP 27.3.4.6 source tree from GitHub |
| Patches | `patch/*.patch` | Mobile compatibility patches |
| xcomp Configs | `xcomp/erl-xcomp-*.conf` (in OTP) | Cross-compilation configurations |

### 2. Intermediate Outputs

| Artifact | Location | Description |
|----------|----------|-------------|
| OpenSSL (per arch) | `_build/{arch}/openssl/` | Static OpenSSL library for target |
| OTP Build (per arch) | `_build/{arch}/otp/` | Compiled OTP for target architecture |
| NIF Libraries | `_build/{arch}/{nif}/priv/*.a` | Compiled static NIF libraries |
| Stub Scripts | `_build/{arch}/stubs/` | Toolchain wrapper scripts |

### 3. Final Outputs

| Artifact | Location | Format | Description |
|----------|----------|--------|-------------|
| Android Runtime | `_build/android-runtime.zip` | ZIP | Contains `liberlang.a` per arch |
| iOS Runtime | `_build/liberlang.xcframework/` | xcframework | Universal framework |
| Release (Android) | `android-otp-27.3.4.6.tar.gz` | tar.gz | Distribution archive |
| Release (iOS) | `ios-otp-27.3.4.6.tar.gz` | tar.gz | Distribution archive |

---

## Architecture Mappings

### Android Architectures

| ID | Name | Android Type | OpenSSL Arch |
|----|------|--------------|--------------|
| arm | arm-unknown-linux-androideabi | armeabi-v7a | android-arm |
| arm64 | aarch64-unknown-linux-android | arm64-v8a | android-arm64 |
| x86_64 | x86_64-pc-linux-android | x86_64 | android-x86_64 |

### iOS Architectures

| ID | Name | Target Type |
|----|------|-------------|
| arm64 | aarch64-apple-ios | Device |
| arm64-simulator | aarch64-apple-iossimulator | M1/M2 Simulator |
| x86_64-simulator | x86_64-apple-iossimulator | Intel Simulator |

---

## Artifact Dependencies

```
OTP Source + Patches
       │
       ▼
   OpenSSL Build (per arch)
       │
       ▼
   OTP First Pass (headers/libs)
       │
       ▼
   NIF Compilation (exqlite, etc.)
       │
       ▼
   OTP Second Pass (with static NIFs)
       │
       ▼
   liberlang.a (per arch)
       │
       ├─────────────────┐
       ▼                 ▼
android-runtime.zip   liberlang.xcframework
       │                 │
       ▼                 ▼
 android-otp-*.tar.gz  ios-otp-*.tar.gz
```

---

## Validation Rules

### Pre-build Validation
- `.tool-versions` contains erlang version matching OTP_TAG
- Android NDK is installed and accessible
- Xcode command line tools are available (iOS)

### Post-build Validation
- `liberlang.a` exists for each target architecture
- Archive contains expected object files (beam_emu, crypto, asn1rt)
- xcframework is valid (passes `xcodebuild -create-xcframework`)

### Release Validation
- Tag format: `OTP-{major}.{minor}.{patch}.{build}`
- Archives contain correct static libraries
- Release notes include build metadata

---

## State Transitions

Build artifacts follow a linear state progression:

```
[Not Started] → [OTP Cloned] → [Patches Applied] → [OpenSSL Built]
    → [OTP First Pass] → [NIFs Built] → [OTP Second Pass]
    → [Archives Created] → [Release Published]
```

Each architecture progresses independently through this flow, enabling parallel builds.
