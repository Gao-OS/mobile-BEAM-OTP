# Implementation Plan: E2E Runtime Testing

**Branch**: `001-e2e-runtime-testing` | **Date**: 2026-01-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-e2e-runtime-testing/spec.md`

## Summary

Create an E2E testing infrastructure to validate that the BEAM runtime (liberlang.a/xcframework) functions correctly on mobile devices and emulators. The system will include minimal standalone test apps for Android and iOS, a test runner that orchestrates execution across all supported architectures, and GitHub Actions integration for automated CI testing. Test results will be reported in JUnit XML format for native CI visualization.

## Technical Context

**Language/Version**:
- Test Runner: Elixir (same as mobile-BEAM-OTP project)
- Android Test App: Kotlin/Java + C++ (JNI)
- iOS Test App: Swift + C (native-lib)

**Primary Dependencies**:
- Android: Android NDK, CMake, Gradle
- iOS: Xcode, xcframework linking
- CI: GitHub Actions, reactivecircus/android-emulator-runner (NEEDS RESEARCH)
- Test Reporting: JUnit XML generation

**Storage**: N/A (test artifacts are ephemeral)

**Testing**:
- Android: Android instrumentation tests or native executable with ADB
- iOS: XCTest or native executable via xcrun simctl

**Target Platform**:
- Android: API 26+ (armeabi-v7a, arm64-v8a, x86_64 emulators)
- iOS: arm64 devices, arm64-simulator (M1/M2), x86_64-simulator (Intel)

**Project Type**: Mobile test infrastructure (test apps + runner)

**Performance Goals**:
- Test suite execution < 10 minutes per architecture
- BEAM boot validation < 30 seconds

**Constraints**:
- Retry up to 3 times on infrastructure failures
- 5-minute timeout per test suite
- <5% false positive rate

**Scale/Scope**: 6 architectures, 3 test categories (boot, execution, NIF)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. OTP Version Branch Strategy | ✅ PASS | E2E tests will run against the branch's OTP version |
| II. Cross-Platform Parity | ✅ PASS | Testing both Android (3 archs) and iOS (3 archs) |
| III. Reproducible Builds | ✅ PASS | Test apps will be built from source in CI |
| IV. Static Linking Only | ✅ PASS | Test apps link liberlang.a statically |
| V. Minimal Patch Footprint | ✅ PASS | No OTP patches required for testing |

**Build Infrastructure Compliance**:
- ✅ Mix tasks will orchestrate test execution
- ✅ Test outputs go to `_build/test-results/`
- ✅ Environment variables have sensible defaults

**Platform Support Compliance**:
- ✅ Android API 26+ (matches constitution)
- ✅ iOS arm64 devices + M1/Intel simulators

## Project Structure

### Documentation (this feature)

```text
specs/001-e2e-runtime-testing/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (test contracts/interfaces)
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
test/
├── e2e/
│   ├── apps/
│   │   ├── android/                    # Android test app project
│   │   │   ├── app/
│   │   │   │   ├── src/main/
│   │   │   │   │   ├── cpp/            # JNI/native code
│   │   │   │   │   │   └── native-test.cpp
│   │   │   │   │   └── java/           # Kotlin/Java wrapper
│   │   │   │   └── build.gradle
│   │   │   ├── CMakeLists.txt
│   │   │   └── build.gradle
│   │   └── ios/                        # iOS test app project
│   │       ├── BeamTest/
│   │       │   ├── main.swift
│   │       │   ├── BeamTestRunner.swift
│   │       │   └── native-test.c
│   │       └── BeamTest.xcodeproj/
│   ├── runner/                         # Test orchestration
│   │   └── test_runner.ex
│   ├── suites/                         # Elixir test modules
│   │   ├── boot_test.exs
│   │   ├── execution_test.exs
│   │   └── nif_test.exs
│   └── fixtures/                       # Test data/expected results
│       └── expected_hashes.json
├── lib/mix/tasks/
│   └── e2e_test.ex                     # mix e2e.test task
└── .github/workflows/
    └── e2e-test.yml                    # CI workflow (or update create-release.yml)
```

**Structure Decision**: Mobile test infrastructure pattern - separate test apps for each platform with shared test suite definitions. Test runner orchestrates via Mix tasks, consistent with existing mobile-BEAM-OTP build patterns.

## Complexity Tracking

No constitution violations requiring justification.

## Research Topics (Phase 0)

The following areas require research before detailed design:

1. **Android Emulator CI** - How to run Android emulator tests in GitHub Actions
2. **iOS Simulator CI** - How to run iOS simulator tests in GitHub Actions
3. **Minimal BEAM Test App** - Patterns for embedding and testing BEAM runtime
4. **JUnit XML Generation** - How to produce JUnit XML from custom test runner

---

*Phase 0 research and Phase 1 design artifacts follow in separate files.*
