# Data Model: OTP 28 Release

**Feature**: OTP 28 Release
**Date**: 2025-12-31

## Overview

This feature involves configuration files and build artifacts, not traditional data entities. The "data model" represents the structure of configuration and output files.

## Configuration Entities

### .tool-versions

Version specification file read by mise.

| Field | Type | Description |
|-------|------|-------------|
| erlang | string | OTP version (e.g., "28.3") |
| elixir | string | Elixir version with OTP suffix (e.g., "1.19.4-otp-28") |

**State Transitions**: Static file, no state changes

### lib/mobile_runtimes.ex - otp_tag()

Function that determines the OTP source tag.

| Return | Type | Description |
|--------|------|-------------|
| otp_tag | string | Git tag for OTP source (e.g., "OTP-28.3") |

**Derivation**: Read from `.tool-versions` erlang field, prefixed with "OTP-"

## Build Artifacts

### liberlang.a (Android)

Static library for each Android architecture.

| Field | Type | Description |
|-------|------|-------------|
| architecture | enum | armeabi-v7a, arm64-v8a, x86_64 |
| path | string | `_build/{arch-name}/liberlang.a` |
| contents | binary | BEAM VM + NIFs (beam_emu, crypto_static, asn1rt_nif) |

### liberlang.xcframework (iOS)

Universal framework containing all iOS slices.

| Field | Type | Description |
|-------|------|-------------|
| slices | list | arm64, arm64-simulator, x86_64-simulator |
| path | string | `_build/liberlang.xcframework` |
| contents | binary | BEAM VM + NIFs for each slice |

### Release Artifacts

| Artifact | Format | Contents |
|----------|--------|----------|
| android-otp-28.3.tar.gz | tar.gz | liberlang.a for all Android architectures |
| ios-otp-28.3.tar.gz | tar.gz | liberlang.xcframework |

## Relationships

```
.tool-versions
    └──> otp_tag() function
         └──> OTP Source (git clone)
              └──> liberlang.a (Android) x3
              └──> liberlang.xcframework (iOS)
                   └──> Release Artifacts
```

## Validation Rules

1. `.tool-versions` erlang field MUST be a valid OTP version (e.g., "28.3")
2. `.tool-versions` elixir field MUST include `-otp-{major}` suffix matching erlang major version
3. `liberlang.a` MUST contain beam_emu, crypto_static, and asn1rt_nif symbols
4. `liberlang.xcframework` MUST contain all three iOS slices
