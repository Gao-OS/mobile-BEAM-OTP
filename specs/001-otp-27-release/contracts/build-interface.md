# Build Interface Contract

**Date**: 2025-12-30
**Feature**: OTP 27 Build System Interface

## Overview

This document defines the interface contract for the mobile-BEAM build system. As a build tooling project, the "contract" represents the Mix task interfaces and their expected inputs/outputs.

---

## Mix Task Interfaces

### `mix package.android.runtime`

Build Android static libraries for all architectures.

**Arguments**:
| Argument | Type | Description |
|----------|------|-------------|
| (none) | - | Build with default NIF (exqlite) |
| `"<url>"` | String | Build with NIF from git URL |
| `with_diode_nifs` | Atom | Build with Diode NIFs (esqlite, libsecp256k1) |
| `env <arch>` | String | Generate NIF environment for specified arch |

**Environment Variables**:
| Variable | Required | Default |
|----------|----------|---------|
| `ANDROID_NDK_HOME` | No | Auto-detected |
| `OTP_TAG` | No | `OTP-27.3.4.6` |
| `SKIP_CLEAN_BUILD` | No | unset |

**Outputs**:
| Artifact | Path | Format |
|----------|------|--------|
| Runtime archive | `_build/android-runtime.zip` | ZIP |
| Per-arch library | `_build/{arch}/liberlang.a` | Static lib |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Build failure |

---

### `mix package.ios.runtime`

Build iOS xcframework for all architectures.

**Arguments**:
| Argument | Type | Description |
|----------|------|-------------|
| (none) | - | Build with default NIF (exqlite) |
| `"<url>"` | String | Build with NIF from git URL |
| `with_diode_nifs` | Atom | Build with Diode NIFs |

**Environment Variables**:
| Variable | Required | Default |
|----------|----------|---------|
| `OTP_TAG` | No | `OTP-27.3.4.6` |
| `SKIP_CLEAN_BUILD` | No | unset |

**Requirements**:
- macOS with Xcode installed
- Xcode Command Line Tools

**Outputs**:
| Artifact | Path | Format |
|----------|------|--------|
| xcframework | `_build/liberlang.xcframework/` | xcframework |
| Per-arch library | `_build/{arch}/liberlang.a` | Static lib |

---

### `mix package.android.nif`

Compile a NIF for Android.

**Arguments**:
| Argument | Type | Description |
|----------|------|-------------|
| `<arch>` | String | Target architecture (arm, arm64, x86_64) |
| `<url>` | String | NIF git repository URL |

---

### `mix package.ios.nif`

Compile a NIF for iOS.

**Arguments**:
| Argument | Type | Description |
|----------|------|-------------|
| `<arch>` | String | Target architecture |
| `<url>` | String | NIF git repository URL |

---

## Architecture Identifiers

### Android

| ID | Full Name | NDK Target |
|----|-----------|------------|
| `arm` | `arm-unknown-linux-androideabi` | `armeabi-v7a` |
| `arm64` | `aarch64-unknown-linux-android` | `arm64-v8a` |
| `x86_64` | `x86_64-pc-linux-android` | `x86_64` |

### iOS

| ID | Full Name | Xcode SDK |
|----|-----------|-----------|
| `arm64` | `aarch64-apple-ios` | `iphoneos` |
| `arm64-simulator` | `aarch64-apple-iossimulator` | `iphonesimulator` |
| `x86_64-simulator` | `x86_64-apple-iossimulator` | `iphonesimulator` |

---

## GitHub Actions Workflow

### Workflow: `create-release.yml`

**Trigger**: `workflow_dispatch` (manual)

**Jobs**:

1. **prepare**: Read versions, create git tag
2. **build-android**: Build Android runtimes (parallel)
3. **build-ios**: Build iOS runtimes (parallel)
4. **release**: Create GitHub release with artifacts

**Outputs**:
| Artifact | Name Pattern |
|----------|--------------|
| Android archive | `android-otp-{version}.tar.gz` |
| iOS archive | `ios-otp-{version}.tar.gz` |

**Release Tag**: `OTP-{version}` (e.g., `OTP-27.3.4.6`)
