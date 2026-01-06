# Tasks: E2E Runtime Testing

**Input**: Design documents from `/specs/001-e2e-runtime-testing/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: No explicit test-first approach requested. Tests are implicit in the E2E testing framework itself.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)

## Path Conventions

Based on plan.md structure:
- Test runner: `lib/mobile_runtimes/e2e/`
- Mix task: `lib/mix/tasks/e2e_test.ex`
- Android test app: `test/e2e/apps/android/`
- iOS test app: `test/e2e/apps/ios/`
- CI workflow: `.github/workflows/`

---

## Phase 1: Setup (Shared Infrastructure) ✅

**Purpose**: Create directory structure and base configuration for E2E testing

- [x] T001 Create E2E test directory structure: `test/e2e/{apps,runner,suites,fixtures}/`
- [x] T002 [P] Create Android test app directories: `test/e2e/apps/android/app/src/main/{cpp,java}/`
- [x] T003 [P] Create iOS test app directories: `test/e2e/apps/ios/BeamTest/`
- [x] T004 [P] Create expected test fixtures in `test/e2e/fixtures/expected_hashes.json`

---

## Phase 2: Foundational (Blocking Prerequisites) ✅

**Purpose**: Core E2E infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Implement Architecture enum module in `lib/mobile_runtimes/e2e/architecture.ex`
- [x] T006 [P] Implement TestCase struct in `lib/mobile_runtimes/e2e/test_case.ex`
- [x] T007 [P] Implement TestSuite struct in `lib/mobile_runtimes/e2e/test_suite.ex`
- [x] T008 [P] Implement TestReport struct in `lib/mobile_runtimes/e2e/test_report.ex`
- [x] T009 Implement JUnit XML generator in `lib/mobile_runtimes/e2e/junit_xml.ex`
- [x] T010 Implement retry helper with exponential backoff in `lib/mobile_runtimes/e2e/retry.ex`
- [x] T011 Create mix task skeleton in `lib/mix/tasks/e2e_test.ex` (argument parsing, help text)

**Checkpoint**: Foundation ready - test app and runner implementation can now begin

---

## Phase 3: User Story 1 - Validate BEAM Runtime Boots Successfully (Priority: P1) 🎯 MVP ✅

**Goal**: Verify that liberlang.a/xcframework boots BEAM VM on emulators/simulators

**Independent Test**: Run `mix e2e.test --arch android-x86_64` and verify "VM started" status within 30 seconds

### Android Test App (Boot Validation)

- [x] T012 [P] [US1] Create Android Gradle project root build.gradle in `test/e2e/apps/android/build.gradle`
- [x] T013 [P] [US1] Create Android settings.gradle in `test/e2e/apps/android/settings.gradle`
- [x] T014 [P] [US1] Create app module build.gradle.kts in `test/e2e/apps/android/app/build.gradle.kts`
- [x] T015 [P] [US1] Create CMakeLists.txt for native code in `test/e2e/apps/android/app/src/main/cpp/CMakeLists.txt`
- [x] T016 [US1] Create AndroidManifest.xml in `test/e2e/apps/android/app/src/main/AndroidManifest.xml`
- [x] T017 [US1] Implement beam-test.cpp with BEAM init in `test/e2e/apps/android/app/src/main/cpp/beam-test.cpp`
- [x] T018 [US1] Create MainActivity.kt calling native in `test/e2e/apps/android/app/src/main/java/io/beamtest/MainActivity.kt`

### iOS Test App (Boot Validation)

- [x] T019 [P] [US1] Create Xcode project structure in `test/e2e/apps/ios/BeamTest.xcodeproj/project.pbxproj`
- [x] T020 [P] [US1] Create main.swift entry point in `test/e2e/apps/ios/BeamTest/main.swift`
- [x] T021 [US1] Create AppDelegate.swift in `test/e2e/apps/ios/BeamTest/AppDelegate.swift`
- [x] T022 [US1] Implement beam-test.c with BEAM init in `test/e2e/apps/ios/BeamTest/beam-test.c`
- [x] T023 [US1] Create BeamTestRunner.swift wrapper in `test/e2e/apps/ios/BeamTest/BeamTestRunner.swift`

### Test Runner (Boot Tests)

- [x] T024 [US1] Implement boot test case logic in `test/e2e/suites/boot_test.exs` (embedded in runner)
- [x] T025 [US1] Implement Emulator.start/1 for Android in `lib/mobile_runtimes/e2e/emulator.ex`
- [x] T026 [US1] Implement Emulator.start/1 for iOS simulators in `lib/mobile_runtimes/e2e/emulator.ex`
- [x] T027 [US1] Implement Emulator.install/2 and run_app/2 in `lib/mobile_runtimes/e2e/emulator.ex`
- [x] T028 [US1] Implement Runner.run/2 for single architecture in `lib/mobile_runtimes/e2e/runner.ex`
- [x] T029 [US1] Wire up mix e2e.test --arch option in `lib/mix/tasks/e2e_test.ex`

**Checkpoint**: `mix e2e.test --arch android-x86_64` boots BEAM and reports success/failure

---

## Phase 4: User Story 2 - Verify Elixir Code Execution (Priority: P1) ✅

**Goal**: Validate Elixir arithmetic, string ops, and concurrency work within embedded runtime

**Independent Test**: After BEAM boots, evaluate `1 + 1` and verify result is `2`

### Native Test Extensions

- [x] T030 [P] [US2] Add Elixir eval test to beam-test.cpp in `test/e2e/apps/android/app/src/main/cpp/beam-test.cpp`
- [x] T031 [P] [US2] Add Elixir eval test to beam-test.c in `test/e2e/apps/ios/BeamTest/beam-test.c`

### Test Runner (Execution Tests)

- [x] T032 [US2] Implement execution test cases in `test/e2e/suites/execution_test.exs`
- [x] T033 [US2] Add result parsing for Elixir output in `lib/mobile_runtimes/e2e/runner.ex`

**Checkpoint**: `mix e2e.test --arch android-x86_64` validates BEAM boot + Elixir execution

---

## Phase 5: User Story 3 - Test Native NIF Integration (Priority: P2) ✅

**Goal**: Verify crypto and exqlite NIFs function correctly on mobile

**Independent Test**: Compute SHA256 hash and verify against known value

### Native Test Extensions

- [x] T034 [P] [US3] Add crypto NIF test to beam-test.cpp in `test/e2e/apps/android/app/src/main/cpp/beam-test.cpp`
- [x] T035 [P] [US3] Add crypto NIF test to beam-test.c in `test/e2e/apps/ios/BeamTest/beam-test.c`
- [x] T036 [P] [US3] Add exqlite NIF test to beam-test.cpp in `test/e2e/apps/android/app/src/main/cpp/beam-test.cpp`
- [x] T037 [P] [US3] Add exqlite NIF test to beam-test.c in `test/e2e/apps/ios/BeamTest/beam-test.c`

### Test Runner (NIF Tests)

- [x] T038 [US3] Implement NIF test cases in `test/e2e/suites/nif_test.exs`
- [x] T039 [US3] Add expected hash values to `test/e2e/fixtures/expected_hashes.json`

**Checkpoint**: All 3 test categories (boot, execution, NIF) work on one architecture

---

## Phase 6: User Story 4 - Run Tests Across All Target Architectures (Priority: P2) ✅

**Goal**: Execute test suite on all 6 supported architectures

**Independent Test**: `mix e2e.test --all` runs on android-{arm,arm64,x86_64} and ios-{arm64,arm64-sim,x86_64-sim}

### Multi-Architecture Support

- [x] T040 [US4] Add architecture-specific build configs for Android arm in `test/e2e/apps/android/app/build.gradle.kts`
- [x] T041 [P] [US4] Add architecture-specific build configs for Android arm64 in `test/e2e/apps/android/app/build.gradle.kts`
- [x] T042 [P] [US4] Add iOS simulator configurations to Xcode project in `test/e2e/apps/ios/BeamTest.xcodeproj/project.pbxproj`
- [x] T043 [US4] Implement --all flag to iterate architectures in `lib/mix/tasks/e2e_test.ex`
- [x] T044 [US4] Add architecture detection for liberlang linking in `lib/mobile_runtimes/e2e/builder.ex`
- [x] T045 [US4] Implement parallel suite execution in `lib/mobile_runtimes/e2e/runner.ex`
- [x] T046 [US4] Aggregate results from multiple architectures in `lib/mobile_runtimes/e2e/test_report.ex`

**Checkpoint**: `mix e2e.test --all` runs on all architectures and produces combined JUnit XML

---

## Phase 7: User Story 5 - Integrate with CI/CD Pipeline (Priority: P3) ✅

**Goal**: Automate E2E tests in GitHub Actions to block releases on failure

**Independent Test**: Push a PR and verify E2E tests run on at least Android x86_64 and iOS arm64-simulator

### GitHub Actions Workflow

- [x] T047 [P] [US5] Create E2E test workflow file in `.github/workflows/e2e-test.yml`
- [x] T048 [US5] Add Android emulator job using reactivecircus/android-emulator-runner in `.github/workflows/e2e-test.yml`
- [x] T049 [US5] Add iOS simulator job with xcodebuild in `.github/workflows/e2e-test.yml`
- [x] T050 [US5] Configure JUnit XML upload as artifact in `.github/workflows/e2e-test.yml`
- [x] T051 [US5] Add test result visualization (GitHub Actions native) in `.github/workflows/e2e-test.yml`

### Release Integration

- [x] T052 [US5] Update create-release.yml to depend on E2E tests passing in `.github/workflows/create-release.yml`
- [x] T053 [US5] Add status check requirement for E2E tests (branch protection config)

**Checkpoint**: PRs trigger E2E tests; releases blocked on failure

---

## Phase 8: Polish & Cross-Cutting Concerns ✅

**Purpose**: Documentation, error handling, and optimization

- [x] T054 [P] Add edge case error handling (OUT_OF_MEMORY, ARCHITECTURE_MISMATCH) in `lib/mobile_runtimes/e2e/retry.ex`
- [x] T055 [P] Add timeout handling (5 min default) in `lib/mobile_runtimes/e2e/runner.ex`
- [x] T056 [P] Improve error messages for emulator failures in `lib/mobile_runtimes/e2e/retry.ex`
- [x] T057 [P] Add verbose logging option (--verbose flag) in `lib/mix/tasks/e2e_test.ex`
- [x] T058 Update README.md with E2E testing section
- [x] T059 Validate quickstart.md scenarios work end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ─────────────────────────────────────────────────┐
                                                                │
Phase 2: Foundational ──────────────────────────────────────────┤
         (Architecture, TestCase, TestSuite, JUnitXML)          │
                                                                │
         ┌──────────────────────────────────────────────────────┘
         │
         ▼
Phase 3: US1 - BEAM Boot (P1) ──► Phase 4: US2 - Elixir Execution (P1)
                                                    │
                                                    ▼
                                  Phase 5: US3 - NIF Integration (P2)
                                                    │
                                                    ▼
                                  Phase 6: US4 - Multi-Architecture (P2)
                                                    │
                                                    ▼
                                  Phase 7: US5 - CI/CD Integration (P3)
                                                    │
                                                    ▼
                                  Phase 8: Polish
```

### User Story Dependencies

| Story | Depends On | Can Parallelize With |
|-------|------------|---------------------|
| US1 (Boot) | Phase 2 only | - |
| US2 (Execution) | US1 (needs boot first) | - |
| US3 (NIF) | US2 (needs execution test pattern) | - |
| US4 (Multi-Arch) | US1-US3 (needs tests to run) | - |
| US5 (CI/CD) | US4 (needs multi-arch working) | - |

### Parallel Opportunities Within Phases

**Phase 2** - Run in parallel:
```
T006 (TestCase) + T007 (TestSuite) + T008 (TestReport)
```

**Phase 3 (US1)** - Run in parallel:
```
Android: T012 + T013 + T014 + T015 (Gradle/CMake setup)
iOS: T019 + T020 (Xcode + main.swift)
```

**Phase 5 (US3)** - Run in parallel:
```
T034 (Android crypto) + T035 (iOS crypto) + T036 (Android SQLite) + T037 (iOS SQLite)
```

**Phase 8** - All tasks can run in parallel:
```
T054 + T055 + T056 + T057 + T058 (all touch different files)
```

---

## Parallel Example: Phase 3 (User Story 1)

```bash
# Launch Android setup tasks in parallel (different files):
claude "Create Android Gradle project root build.gradle in test/e2e/apps/android/build.gradle"
claude "Create Android settings.gradle in test/e2e/apps/android/settings.gradle"
claude "Create app module build.gradle.kts in test/e2e/apps/android/app/build.gradle.kts"

# Launch iOS setup tasks in parallel (different files):
claude "Create Xcode project structure in test/e2e/apps/ios/BeamTest.xcodeproj/project.pbxproj"
claude "Create main.swift entry point in test/e2e/apps/ios/BeamTest/main.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T011)
3. Complete Phase 3: User Story 1 - Boot Validation (T012-T029)
4. **STOP and VALIDATE**: Run `mix e2e.test --arch android-x86_64`
5. Verify BEAM boots and reports success within 30 seconds

### Incremental Delivery

| Increment | Stories | What's Testable |
|-----------|---------|-----------------|
| MVP | US1 | BEAM boots on one arch |
| +1 | US1+US2 | BEAM boots + Elixir runs |
| +2 | US1+US2+US3 | Full test suite on one arch |
| +3 | US1-US4 | Full suite on all archs |
| Complete | US1-US5 | CI/CD integrated |

### Suggested MVP Scope

**For initial deployment, complete through Phase 3 (US1)**:
- Total tasks: 29 (T001-T029)
- Deliverable: `mix e2e.test --arch android-x86_64` validates BEAM boot
- Value: Immediate confidence that liberlang.a is functional

---

## Notes

- [P] tasks = different files, no dependencies within same phase
- [US#] label maps task to specific user story
- US1+US2 are both P1 priority but sequentially dependent (need boot before execution)
- Android and iOS test apps can be developed in parallel (different platforms)
- JUnit XML generation enables immediate GitHub Actions visualization
- Commit after each task or logical group
