# Quickstart: OTP 28 Release

**Feature**: OTP 28 Release
**Date**: 2025-12-31

## Prerequisites

- macOS (for iOS builds)
- [mise](https://mise.jdx.dev/) installed
- Xcode with command-line tools
- Android NDK (auto-detected from `~/Library/Android/sdk/ndk`)

## Setup

```bash
# Switch to OTP-28 branch
git checkout OTP-28

# Install Erlang 28.3 and Elixir 1.19.4-otp-28
mise install

# Get dependencies
mix deps.get
```

## Update Versions

Edit `.tool-versions`:
```
erlang 28.3
elixir 1.19.4-otp-28
```

## Build Locally

### Android

```bash
mix package.android.runtime
```

Output: `_build/android-runtime.zip`

### iOS

```bash
mix package.ios.runtime
```

Output: `_build/liberlang.xcframework`

## Verify Builds

```bash
# Check Android libraries contain expected symbols
ar -t _build/arm64-v8a/liberlang.a | grep -E "(beam_emu|crypto|asn1)"

# Check iOS framework structure
ls _build/liberlang.xcframework/
```

## Create Release

### Via GitHub Actions (Recommended)

```bash
# Push changes to OTP-28 branch
git add .tool-versions
git commit -m "feat: update OTP to version 28.3"
git push origin OTP-28

# Trigger workflow
gh workflow run "Create Release" --ref OTP-28

# Monitor progress
gh run list --workflow="Create Release" --limit 1
```

### Verify Release

```bash
# Check release was created
gh release view OTP-28.3
```

## Common Issues

### Patch fails to apply

If `otp-zlib-ios.patch` fails, check if the fix is already upstream in OTP 28:

```bash
# Clone OTP source
git clone --depth 1 --branch OTP-28.3 https://github.com/erlang/otp _build/otp

# Try to apply patch
cd _build/otp && patch -p1 --dry-run < ../../patch/otp-zlib-ios.patch
```

### mise install fails

Ensure mise is up to date:

```bash
mise self-update
mise install
```
