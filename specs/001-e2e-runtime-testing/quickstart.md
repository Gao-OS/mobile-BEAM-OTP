# Quickstart: E2E Runtime Testing

**Feature**: 001-e2e-runtime-testing
**Date**: 2026-01-06

---

## Prerequisites

### For Android Testing

```bash
# Android SDK with NDK
export ANDROID_HOME=~/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/26.1.10909125

# Verify emulator available
$ANDROID_HOME/emulator/emulator -list-avds

# If no AVDs exist, create one
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  -n e2e_test \
  -k "system-images;android-29;default;x86_64" \
  -d pixel_6
```

### For iOS Testing

```bash
# Xcode (install from App Store)
xcode-select --install

# Verify simulators available
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot "iPhone 15"
```

### Project Setup

```bash
# Clone mobile-BEAM-OTP
git clone https://github.com/Gao-OS/mobile-BEAM-OTP.git
cd mobile-BEAM-OTP

# Checkout E2E testing branch
git checkout 001-e2e-runtime-testing

# Install dependencies
mise install
mix deps.get
```

---

## Running Tests Locally

### Quick Test (Single Architecture)

```bash
# Android x86_64 emulator (fastest for local testing)
mix e2e.test --arch android-x86_64

# iOS arm64 simulator (for M1/M2 Macs)
mix e2e.test --arch ios-arm64-simulator
```

### Full Test Suite

```bash
# All architectures
mix e2e.test --all

# Custom output location
mix e2e.test --all --output test-results.xml
```

### Debug Mode

```bash
# Verbose output
mix e2e.test --arch android-x86_64 --verbose

# Keep emulator running after tests
mix e2e.test --arch ios-arm64-simulator --keep-alive

# Skip rebuild (use cached test apps)
mix e2e.test --arch android-arm64-v8a --skip-build
```

---

## Understanding Test Results

### Console Output

```
Running E2E tests for: android-x86_64
  [boot] VM initialization... ✓ (2.3s)
  [execution] Arithmetic operations... ✓ (0.1s)
  [nif] Crypto SHA256... ✓ (0.1s)

Suite: android-x86_64 PASSED (3/3 tests, 2.5s)

JUnit XML report: _build/test-results/junit.xml
```

### JUnit XML Report

```xml
<testsuites name="E2E Runtime Tests" tests="3" failures="0" time="2.5">
  <testsuite name="android-x86_64" tests="3" failures="0">
    <testcase classname="boot" name="vm_initialization" time="2.3"/>
    <testcase classname="execution" name="arithmetic_operations" time="0.1"/>
    <testcase classname="nif" name="crypto_sha256" time="0.1"/>
  </testsuite>
</testsuites>
```

---

## CI Integration

### GitHub Actions

The E2E tests run automatically in CI. View results:

1. Go to **Actions** tab in GitHub
2. Select the workflow run
3. Check **e2e-test-results** artifact for JUnit XML
4. View test results in **Summary** tab (native visualization)

### Local CI Simulation

```bash
# Simulate CI environment
act -j e2e-test
```

---

## Troubleshooting

### Emulator Won't Start

```bash
# Android: Check hardware acceleration
$ANDROID_HOME/emulator/emulator -accel-check

# iOS: Reset simulators
xcrun simctl shutdown all
xcrun simctl erase all
```

### Tests Timeout

```bash
# Increase timeout (default: 5 minutes)
mix e2e.test --arch android-x86_64 --timeout 600000
```

### BEAM Fails to Initialize

```bash
# Check liberlang.a was built correctly
file _build/android-arm64-v8a/liberlang.a

# Rebuild runtime
mix package.android.runtime
```

### Infrastructure Retries Exhausted

```bash
# Increase retries (default: 3)
mix e2e.test --arch ios-arm64-simulator --retries 5
```

---

## Architecture Quick Reference

| Architecture | Platform | Best For |
|--------------|----------|----------|
| `android-x86_64` | Android emulator | Fast local testing |
| `android-arm64-v8a` | Android device/M1 emu | Production validation |
| `android-armeabi-v7a` | Android device | Legacy device testing |
| `ios-arm64-simulator` | iOS simulator (M1/M2) | Fast local testing |
| `ios-x86_64-simulator` | iOS simulator (Intel) | Intel Mac testing |
| `ios-arm64` | iOS device | Production validation |

---

## Next Steps

1. Run `mix e2e.test --arch android-x86_64` to verify setup
2. Check `_build/test-results/junit.xml` for results
3. Push changes to trigger CI E2E tests
4. Review failed tests in GitHub Actions artifacts
