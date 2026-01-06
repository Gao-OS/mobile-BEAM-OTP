# Research: E2E Runtime Testing

**Feature**: 001-e2e-runtime-testing
**Date**: 2026-01-06

---

## 1. Android Emulator CI Testing

### Decision: Use `reactivecircus/android-emulator-runner@v2`

**Rationale**: This is the de facto standard GitHub Action for Android emulator testing, maintained actively and used by major Android projects. It handles emulator lifecycle, hardware acceleration, and provides consistent API across all GitHub Actions runner types.

**Alternatives Considered**:
- Manual emulator setup via `emulator` CLI: More complex, requires explicit AVD management, hardware acceleration setup is error-prone
- Firebase Test Lab: Cloud-based, adds external dependency and costs, better for production testing than CI validation
- Local Docker-based emulator: Not well-supported on GitHub Actions, hardware acceleration issues

### Configuration Recommendations

```yaml
- name: Run Android E2E Tests
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 29                    # API 29 (Android 10) - good balance of features and stability
    target: default                  # Use 'google_apis' if Play Services needed
    arch: x86_64                     # x86_64 for GitHub Actions (better performance than arm64)
    profile: pixel_6                 # Device profile for consistent screen size
    emulator-options: -no-snapshot-save -no-window -gpu swiftshader_indirect
    disable-animations: true
    script: ./test/e2e/run-android-tests.sh
```

### Architecture Support in CI

| Architecture | CI Support | Notes |
|--------------|------------|-------|
| x86_64 | ✅ Best | Hardware acceleration on Linux runners |
| arm64-v8a | ⚠️ Limited | Requires macOS runner with Apple Silicon |
| armeabi-v7a | ❌ Slow | Software emulation only, not recommended for CI |

**Recommendation**: Run x86_64 tests in CI, use arm64 on macOS-14 runners if needed. Physical arm devices for comprehensive arm testing.

### Test Results Collection

```yaml
- name: Upload Android Test Results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: android-test-results
    path: |
      test/e2e/apps/android/app/build/outputs/androidTest-results/
      test/e2e/apps/android/app/build/reports/
```

---

## 2. iOS Simulator CI Testing

### Decision: Use `xcodebuild test` with `xcrun simctl`

**Rationale**: Native Xcode tooling provides the most reliable iOS simulator testing. GitHub Actions macos-14 and macos-15 runners include pre-installed simulators and Xcode versions.

**Alternatives Considered**:
- Third-party CI services (CircleCI, Bitrise): Adds external dependency, GitHub Actions sufficient
- `fastlane scan`: Good abstraction but adds Ruby dependency, overkill for our minimal test needs

### Configuration Recommendations

```yaml
jobs:
  ios-e2e-test:
    runs-on: macos-14  # Apple Silicon for arm64 simulator
    steps:
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app

      - name: List Available Simulators
        run: xcrun simctl list devices available

      - name: Boot Simulator
        run: |
          DEVICE_ID=$(xcrun simctl create "E2E-iPhone" "iPhone 15" iOS17.5)
          xcrun simctl boot "$DEVICE_ID"
          echo "DEVICE_ID=$DEVICE_ID" >> $GITHUB_ENV

      - name: Run Tests
        run: |
          xcodebuild test \
            -project test/e2e/apps/ios/BeamTest.xcodeproj \
            -scheme BeamTest \
            -destination "platform=iOS Simulator,id=$DEVICE_ID" \
            -resultBundlePath TestResults.xcresult

      - name: Convert to JUnit XML
        run: |
          xcrun xcresulttool get --path TestResults.xcresult --format json > results.json
          # Convert to JUnit XML using custom script or xcparse tool
```

### Runner Architecture

| Runner | Architecture | Simulators Available |
|--------|--------------|---------------------|
| macos-14 | arm64 (M1) | arm64-simulator |
| macos-13 | x86_64 (Intel) | x86_64-simulator |
| macos-15 | arm64 (M3) | arm64-simulator |

**Recommendation**: Use macos-14 for arm64 simulator tests (matches modern iPhones), use macos-13 for x86_64 simulator tests if needed.

### JUnit XML from Xcode

Xcode doesn't natively produce JUnit XML. Options:
1. **xcparse** (`brew install xcparse`): Converts .xcresult to JUnit XML
2. **trainer** gem (`gem install trainer`): Ruby-based converter
3. **Custom conversion**: Parse xcresult JSON and generate JUnit XML

**Recommendation**: Use `xcparse` or custom Elixir script to convert xcresult to JUnit XML.

---

## 3. Minimal BEAM Test App Patterns

### Decision: Create minimal native wrappers inspired by elixir-desktop

**Rationale**: The elixir-desktop apps (ios-example-app, android-example-app) demonstrate working BEAM initialization patterns. We'll extract the minimal code needed for testing without the full Bridge/WebView complexity.

**Alternatives Considered**:
- Fork elixir-desktop apps: Too much complexity (Phoenix, LiveView, Bridge protocol)
- Pure C executable: Harder to run on iOS/Android without app wrapper

### Android Minimal Test App Structure

```text
test/e2e/apps/android/
├── app/
│   ├── src/main/
│   │   ├── AndroidManifest.xml
│   │   ├── cpp/
│   │   │   ├── CMakeLists.txt
│   │   │   └── beam-test.cpp      # BEAM init + test execution
│   │   └── java/io/beamtest/
│   │       └── MainActivity.kt     # Minimal activity that calls native
│   └── build.gradle.kts
├── build.gradle.kts
└── settings.gradle.kts
```

**Key Native Code (beam-test.cpp)**:
```cpp
#include <jni.h>
#include <android/log.h>
extern "C" {
  #include "erl_nif.h"
}

extern "C" JNIEXPORT jint JNICALL
Java_io_beamtest_MainActivity_runBeamTests(JNIEnv *env, jobject thiz, jstring erlRootPath) {
    // 1. Initialize ERTS
    // 2. Start BEAM with minimal boot
    // 3. Evaluate test expressions
    // 4. Return pass/fail count
}
```

### iOS Minimal Test App Structure

```text
test/e2e/apps/ios/
├── BeamTest/
│   ├── AppDelegate.swift
│   ├── main.swift
│   ├── BeamTestRunner.swift       # Swift wrapper for tests
│   └── beam-test.c                # C code for BEAM init
├── BeamTest.xcodeproj/
└── BeamTestTests/                 # XCTest wrapper
    └── BeamE2ETests.swift
```

**Key Native Code (beam-test.c)**:
```c
#include "erl_nif.h"

int run_beam_tests(const char* erl_root) {
    // 1. Set up ERL_FLAGS environment
    // 2. Initialize ERTS
    // 3. Start BEAM scheduler
    // 4. Evaluate test expressions via erl_eval
    // 5. Return results
}
```

### BEAM Initialization Pattern (from elixir-desktop)

Based on `native-lib.cpp` from ios-example-app:

```cpp
void start_erlang(const char* root_dir) {
    setenv("BINDIR", bin_dir, 1);
    setenv("EMU", "beam", 1);
    setenv("ROOTDIR", root_dir, 1);

    char* args[] = {
        "beam",
        "--",
        "-sbwt", "none",                    // No scheduler binding
        "-MIscs", "10",                     // 10MB literal super carrier
        "-config", config_path,
        "-boot", boot_path,
        "-noshell",
        NULL
    };

    erl_start(sizeof(args)/sizeof(args[0]) - 1, args);
}
```

---

## 4. JUnit XML Generation

### Decision: Custom Elixir module for JUnit XML generation

**Rationale**: Simple format, no external dependencies, integrates well with our Elixir-based test runner.

**Alternatives Considered**:
- ExUnit formatters: Would require running ExUnit in embedded BEAM (complex)
- junit-formatter hex package: Designed for ExUnit, not custom test output
- External tools (xcparse, etc.): Platform-specific, adds dependencies

### JUnit XML Format

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="E2E Runtime Tests" tests="9" failures="0" errors="0" time="45.2">
  <testsuite name="android-arm64" tests="3" failures="0" errors="0" time="15.1">
    <testcase classname="BeamBoot" name="vm_starts_within_30_seconds" time="2.3"/>
    <testcase classname="ElixirExecution" name="arithmetic_works" time="0.1"/>
    <testcase classname="NifIntegration" name="crypto_sha256" time="0.5"/>
  </testsuite>
  <testsuite name="ios-arm64-simulator" tests="3" failures="0" errors="0" time="14.8">
    <!-- ... -->
  </testsuite>
</testsuites>
```

### Elixir Module

```elixir
defmodule MobileRuntimes.E2E.JUnitXML do
  def generate(results) do
    # results = [%{arch: "android-arm64", tests: [...], time: 15.1}]
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <testsuites name="E2E Runtime Tests" ...>
      #{Enum.map(results, &testsuite_xml/1) |> Enum.join("\n")}
    </testsuites>
    """
  end
end
```

---

## 5. Test Runner Architecture

### Decision: Mix task orchestrating per-architecture test execution

**Rationale**: Consistent with mobile-BEAM-OTP build patterns, leverages existing Elixir infrastructure.

### Architecture

```
mix e2e.test [--arch android-arm64] [--arch ios-arm64-simulator] [--all]
     │
     ├── Build test app for architecture (if not cached)
     │   └── Android: gradle assembleDebug
     │   └── iOS: xcodebuild build
     │
     ├── Launch emulator/simulator
     │   └── Android: adb emu start / emulator -avd
     │   └── iOS: xcrun simctl boot
     │
     ├── Install & run test app
     │   └── Android: adb install && adb shell am start
     │   └── iOS: xcrun simctl install && xcrun simctl launch
     │
     ├── Collect results (stdout, exit code, logs)
     │
     ├── Retry on infrastructure failure (up to 3x)
     │
     └── Generate JUnit XML report
```

### Retry Logic

```elixir
defp run_with_retry(fun, retries \\ 3, backoff \\ 1000) do
  case fun.() do
    {:ok, result} -> {:ok, result}
    {:error, :infrastructure, _} when retries > 0 ->
      Process.sleep(backoff)
      run_with_retry(fun, retries - 1, backoff * 2)
    {:error, reason, details} -> {:error, reason, details}
  end
end
```

---

## Summary of Decisions

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Android CI | reactivecircus/android-emulator-runner@v2 | De facto standard, handles lifecycle |
| Android arch in CI | x86_64 primarily | Hardware acceleration on Linux runners |
| iOS CI | xcodebuild + xcrun simctl | Native tooling, pre-installed on runners |
| iOS runner | macos-14 (M1) | arm64 simulator matches modern devices |
| Test app approach | Minimal native wrappers | Focused on runtime validation |
| JUnit XML | Custom Elixir module | No external dependencies |
| Test orchestration | Mix task | Consistent with project patterns |
| Retry mechanism | 3 retries, exponential backoff | Reduces false positives per SC-006 |
