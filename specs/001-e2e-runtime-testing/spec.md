# Feature Specification: E2E Runtime Testing

**Feature Branch**: `001-e2e-runtime-testing`
**Created**: 2026-01-06
**Status**: Draft
**Input**: User description: "Create a way to do E2E testing to test the runtime in real devices or emulators for both Android and iOS"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Validate BEAM Runtime Boots Successfully (Priority: P1)

As a mobile-BEAM-OTP maintainer, I want to verify that the compiled BEAM runtime boots successfully on real devices and emulators so that I can ensure each release produces a functional runtime.

**Why this priority**: This is the fundamental validation - if the BEAM VM doesn't start, nothing else works. Every release must pass this test before deployment.

**Independent Test**: Can be fully tested by building a minimal test app that attempts to boot BEAM and reports success/failure. Delivers confidence that the liberlang.a artifact is functional.

**Acceptance Scenarios**:

1. **Given** a freshly built liberlang.a for Android arm64, **When** the test app launches on an Android arm64 emulator, **Then** the BEAM runtime initializes within 30 seconds and reports "VM started" status
2. **Given** a freshly built liberlang.xcframework for iOS, **When** the test app launches on an iOS simulator, **Then** the BEAM runtime initializes within 30 seconds and reports "VM started" status
3. **Given** a test app running on a physical Android device, **When** BEAM initialization completes, **Then** the app displays confirmation that all core subsystems (scheduler, IO, memory) are operational

---

### User Story 2 - Verify Elixir Code Execution (Priority: P1)

As a mobile-BEAM-OTP maintainer, I want to verify that Elixir code executes correctly within the embedded runtime so that I can ensure the complete runtime stack works end-to-end.

**Why this priority**: A booting VM that cannot execute Elixir code is useless. This validates the full stack from VM to application layer.

**Independent Test**: Can be tested by running a simple Elixir module that performs calculations and returns results. Delivers validation of the complete runtime execution path.

**Acceptance Scenarios**:

1. **Given** BEAM runtime has started, **When** Elixir code `1 + 1` is evaluated, **Then** the result `2` is returned correctly
2. **Given** BEAM runtime has started, **When** an Elixir module performs string manipulation, **Then** the correct output is produced
3. **Given** BEAM runtime has started, **When** concurrent Elixir processes are spawned, **Then** they execute in parallel and complete without deadlock

---

### User Story 3 - Test Native NIF Integration (Priority: P2)

As a mobile-BEAM-OTP maintainer, I want to verify that bundled NIFs (crypto, SQLite) function correctly so that applications depending on these NIFs will work on mobile.

**Why this priority**: NIFs are essential for real applications. Crypto is needed for TLS/security, SQLite for data persistence. Failures here would break most practical uses.

**Independent Test**: Can be tested by calling NIF functions (e.g., crypto hash, SQLite query) and validating results. Delivers confidence in NIF linkage and ABI compatibility.

**Acceptance Scenarios**:

1. **Given** BEAM runtime with crypto NIF loaded, **When** a SHA256 hash is computed, **Then** the output matches the expected hash value
2. **Given** BEAM runtime with exqlite NIF loaded, **When** a SQLite database is created and queried, **Then** data is correctly stored and retrieved
3. **Given** BEAM runtime on iOS arm64, **When** multiple NIFs are called sequentially, **Then** no memory corruption or crashes occur

---

### User Story 4 - Run Tests Across All Target Architectures (Priority: P2)

As a mobile-BEAM-OTP maintainer, I want to run the same test suite across all supported architectures (Android arm64/arm/x86_64, iOS arm64/arm64-sim/x86_64-sim) so that I can ensure consistent behavior across platforms.

**Why this priority**: Architecture-specific bugs are common in cross-compilation. Testing all targets prevents "works on my machine" issues.

**Independent Test**: Can be tested by triggering the test suite for each architecture and comparing pass/fail results. Delivers cross-platform validation matrix.

**Acceptance Scenarios**:

1. **Given** the E2E test suite, **When** run against Android arm64-v8a emulator, **Then** all tests pass
2. **Given** the E2E test suite, **When** run against iOS arm64 simulator (Apple Silicon), **Then** all tests pass
3. **Given** the E2E test suite, **When** run against iOS x86_64 simulator (Intel), **Then** all tests pass
4. **Given** test results from all architectures, **When** compared, **Then** no architecture-specific failures exist

---

### User Story 5 - Integrate with CI/CD Pipeline (Priority: P3)

As a mobile-BEAM-OTP maintainer, I want E2E tests to run automatically in GitHub Actions after each build so that regressions are caught before release.

**Why this priority**: Automation ensures tests are always run. Manual testing is error-prone and often skipped under time pressure.

**Independent Test**: Can be tested by pushing a change and verifying the CI workflow triggers E2E tests. Delivers automated quality gates.

**Acceptance Scenarios**:

1. **Given** a pull request is opened, **When** the CI workflow runs, **Then** E2E tests execute on at least one Android and one iOS target
2. **Given** E2E tests fail, **When** the CI workflow completes, **Then** the PR is blocked from merging and failure details are visible
3. **Given** a release is created, **When** the release workflow runs, **Then** E2E tests pass on all supported architectures before artifacts are published

---

### Edge Cases

- **Insufficient memory**: When BEAM VM fails due to insufficient device memory, test fails with clear "OUT_OF_MEMORY" error after retry attempts exhausted
- **Architecture mismatch**: System detects and rejects mismatched binaries (e.g., arm binary on x86 emulator) with "ARCHITECTURE_MISMATCH" error before test execution
- **Test app crash**: Crashes during initialization are captured and reported; retry mechanism attempts up to 3 restarts before marking test as failed
- **Test timeouts**: Tests exceeding configured timeout (default 5 min) are terminated and marked failed with "TIMEOUT" status
- **Emulator/simulator launch failure**: System retries emulator launch up to 3 times with exponential backoff before failing the test run
- **Device connectivity issues**: Intermittent disconnections trigger test retry (up to 3 attempts); persistent failures result in "DEVICE_DISCONNECTED" error

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide test applications that embed liberlang.a (Android) and liberlang.xcframework (iOS) to validate runtime functionality
- **FR-002**: System MUST verify BEAM VM initialization completes successfully and report clear pass/fail status
- **FR-003**: System MUST execute Elixir code within the embedded runtime and validate correct output
- **FR-004**: System MUST test bundled NIFs (at minimum: crypto for security operations)
- **FR-005**: System MUST support running tests on emulators/simulators for CI/CD environments
- **FR-006**: System MUST support running tests on physical devices for comprehensive validation
- **FR-007**: System MUST produce test reports in JUnit XML format indicating which tests passed/failed on which architectures (enables native GitHub Actions visualization)
- **FR-008**: System MUST integrate with GitHub Actions workflow for automated testing
- **FR-009**: System MUST timeout and fail gracefully if tests exceed reasonable duration (configurable, default 5 minutes per test suite)
- **FR-010**: System MUST support testing all architectures defined in mobile-BEAM-OTP (Android: armeabi-v7a, arm64-v8a, x86_64; iOS: arm64, arm64-simulator, x86_64-simulator)
- **FR-011**: System MUST retry failed infrastructure operations (emulator launch, device connection) up to 3 times with exponential backoff before marking tests as failed

### Key Entities

- **Test App**: A minimal standalone mobile application embedding liberlang.a/xcframework, capable of booting BEAM, running test assertions, and reporting results via stdout/exit codes
- **Test Suite**: A collection of test cases covering VM boot, Elixir execution, and NIF functionality
- **Test Report**: JUnit XML file containing pass/fail status, execution time, and failure details for each test case on each architecture
- **Test Runner**: Orchestrator that launches test apps on devices/emulators and collects results

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Test suite executes all test cases within 10 minutes per architecture on CI infrastructure
- **SC-002**: Test reports clearly indicate pass/fail status for each of the 3 validation areas (VM boot, Elixir execution, NIF functionality)
- **SC-003**: CI pipeline blocks releases when any E2E test fails
- **SC-004**: 100% of supported architectures have E2E test coverage
- **SC-005**: Test infrastructure setup can be completed by a new contributor within 1 hour using provided documentation
- **SC-006**: False positive rate (tests failing due to infrastructure issues, not runtime bugs) is below 5%

## Clarifications

### Session 2026-01-06

- Q: When infrastructure fails (emulator won't start, device disconnects), should tests retry, fail immediately, or skip? → A: Retry with limit (up to 3 retries before failing)
- Q: What format should test reports use for CI integration and debugging? → A: JUnit XML (industry-standard, native CI visualization)
- Q: Should test apps be minimal standalone implementations or based on elixir-desktop example apps? → A: Minimal standalone (lightweight, fewer dependencies, focused on runtime validation)

## Assumptions

- GitHub Actions macOS runners have access to iOS simulators and can run Xcode
- GitHub Actions runners (or self-hosted runners) can run Android emulators
- Test apps will be minimal standalone implementations (not forks of elixir-desktop apps) to reduce dependencies and maintenance burden
- The elixir-desktop example apps serve as architectural reference only (for understanding BEAM initialization patterns)
- Physical device testing is optional for CI but supported for local development
- Test apps will communicate results via simple mechanisms (stdout, exit codes, file output) rather than complex Bridge protocols
