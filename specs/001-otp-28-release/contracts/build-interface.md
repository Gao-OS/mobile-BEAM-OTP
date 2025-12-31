# Build Interface Contract: OTP 28 Release

**Feature**: OTP 28 Release
**Date**: 2025-12-31

## Overview

This project uses Mix tasks as the primary interface. No REST/GraphQL APIs are involved.

## Mix Task Contracts

### mix package.android.runtime

Builds BEAM runtime for all Android architectures.

**Input**:
- Optional: NIF URL (string) - External NIF repository to include
- Optional: `with_diode_nifs` - Preset for Diode NIFs
- Optional: `env {arch}` - Generate environment variables only

**Output**:
- `_build/{arch-name}/liberlang.a` for each architecture
- `_build/android-runtime.zip` containing all architectures

**Exit Codes**:
- 0: Success
- 1: Build failure (compilation error, missing dependencies)

### mix package.ios.runtime

Builds BEAM runtime for all iOS architectures.

**Input**:
- Optional: NIF URL (string) - External NIF repository to include

**Output**:
- `_build/liberlang.xcframework` containing all slices

**Exit Codes**:
- 0: Success
- 1: Build failure

## Environment Variables

| Variable | Type | Required | Default |
|----------|------|----------|---------|
| OTP_TAG | string | No | `OTP-{version from .tool-versions}` |
| OTP_SOURCE | string | No | `https://github.com/erlang/otp` |
| ANDROID_NDK_HOME | path | Yes (Android) | Auto-detected |
| SKIP_CLEAN_BUILD | boolean | No | unset |
| MAKEFLAGS | string | No | `-j10 -O` |

## GitHub Actions Workflow Contract

### Workflow: create-release.yml

**Trigger**: Manual dispatch (workflow_dispatch)

**Inputs**: None (reads from `.tool-versions`)

**Outputs**:
- GitHub Release with tag `OTP-{version}`
- Attached artifacts:
  - `android-otp-{version}.tar.gz`
  - `ios-otp-{version}.tar.gz`

**Jobs**:
1. `prepare` - Read versions, create git tag
2. `build-android` - Build Android runtimes (ubuntu-latest)
3. `build-ios` - Build iOS runtimes (macos-latest)
4. `release` - Create GitHub release with artifacts
