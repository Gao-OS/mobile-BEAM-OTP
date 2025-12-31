# Feature Specification: OTP 28 Release

**Feature Branch**: `001-otp-28-release`
**Created**: 2025-12-31
**Status**: Draft
**Input**: User description: "switch to branch OTP-28, now we should update otp to 28, use latest otp-28"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Local Development Builds (Priority: P1)

As a mobile developer, I want to build the BEAM runtime locally with OTP 28 so that I can develop and test mobile applications using the latest Erlang/Elixir features.

**Why this priority**: Local builds are the foundation - developers need working builds before any release pipeline matters. This validates that OTP 28 compiles correctly for all mobile platforms.

**Independent Test**: Run `mix package.android.runtime` and `mix package.ios.runtime` locally and verify the builds complete successfully with valid `liberlang.a` outputs.

**Acceptance Scenarios**:

1. **Given** a developer has cloned the repository and run `mise install`, **When** they execute `mix package.android.runtime`, **Then** the build completes with `liberlang.a` for all three Android architectures (armeabi-v7a, arm64-v8a, x86_64).

2. **Given** a developer is on macOS with Xcode installed, **When** they execute `mix package.ios.runtime`, **Then** the build completes with `liberlang.xcframework` containing all three iOS slices (arm64, arm64-simulator, x86_64-simulator).

3. **Given** a completed build, **When** the developer inspects the resulting static libraries, **Then** they contain expected symbols (beam_emu, crypto_static, asn1rt_nif).

---

### User Story 2 - Automated Release Pipeline (Priority: P2)

As a project maintainer, I want to trigger a GitHub Actions workflow that builds and releases OTP 28 mobile runtimes so that end users can download pre-built packages.

**Why this priority**: Depends on User Story 1 (builds must work locally first). Release automation enables distribution to end users.

**Independent Test**: Trigger the "Create Release" GitHub Actions workflow and verify it creates a release with Android and iOS artifacts attached.

**Acceptance Scenarios**:

1. **Given** the OTP-28 branch has `.tool-versions` pointing to OTP 28.3, **When** the "Create Release" workflow is triggered, **Then** it creates a GitHub release tagged `OTP-28.3`.

2. **Given** the workflow runs successfully, **When** the release is created, **Then** it contains `android-otp-28.3.tar.gz` and `ios-otp-28.3.tar.gz` artifacts.

3. **Given** a user downloads the release artifacts, **When** they extract the archives, **Then** they find valid static libraries for all supported architectures.

---

### User Story 3 - Developer Builds with Custom NIFs (Priority: P3)

As a developer building custom mobile applications, I want to include additional NIFs (like exqlite) in my OTP 28 builds so that I can extend the runtime with native functionality.

**Why this priority**: Advanced feature building on P1/P2. Custom NIFs are optional enhancements.

**Independent Test**: Run build with exqlite NIF URL and verify the NIF objects are included in the final `liberlang.a`.

**Acceptance Scenarios**:

1. **Given** the base OTP 28 runtime builds successfully, **When** a developer runs `mix package.android.runtime "https://github.com/elixir-desktop/exqlite"`, **Then** the resulting `liberlang.a` includes exqlite NIF objects.

2. **Given** the NIF build infrastructure, **When** building with `with_diode_nifs` option, **Then** esqlite and libsecp256k1 NIFs are compiled and included.

---

### Edge Cases

- What happens when OTP 28 patches fail to apply? The build should fail with a clear error message indicating which patch failed and why.
- How does the system handle missing Android NDK? The build should detect missing NDK and provide instructions for installation.
- What if Xcode version is incompatible with OTP 28? The build should verify Xcode compatibility before starting iOS builds.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST build static library `liberlang.a` for Android architectures: armeabi-v7a, arm64-v8a, and x86_64
- **FR-002**: System MUST build `liberlang.xcframework` for iOS containing arm64, arm64-simulator, and x86_64-simulator slices
- **FR-003**: System MUST use OTP source from version 28.x.x as specified in `.tool-versions`
- **FR-004**: System MUST apply mobile platform patches from the `patch/` directory to OTP 28 source
- **FR-005**: System MUST build OpenSSL as a static dependency for cryptographic NIFs
- **FR-006**: System MUST statically link core NIFs (asn1rt_nif, crypto) into the runtime library
- **FR-007**: System MUST support building additional NIFs from external repositories (exqlite, Diode NIFs)
- **FR-008**: System MUST produce packaged archives suitable for distribution (zip, tar.gz)
- **FR-009**: GitHub Actions workflow MUST build Android and iOS runtimes and create release artifacts
- **FR-010**: Build process MUST verify produced artifacts contain expected libraries before packaging

### Key Entities

- **OTP Source**: Erlang/OTP 28 source code cloned from GitHub repository
- **Static Library**: Platform-specific compiled library (`liberlang.a` or xcframework) containing BEAM VM and NIFs
- **Cross-compilation Config**: Architecture-specific build configuration for mobile targets (xcomp templates)
- **Patch Files**: Source modifications required for mobile platform compatibility
- **Release Artifact**: Compressed archive containing built libraries ready for distribution

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All six target architectures (3 Android + 3 iOS) build successfully without errors
- **SC-002**: Build completes within CI time limits (reasonable for cross-compilation workload)
- **SC-003**: Produced `liberlang.a` files contain all expected object files (BEAM VM core, crypto, asn1rt)
- **SC-004**: Mobile applications can successfully link against and initialize the BEAM VM from produced libraries
- **SC-005**: GitHub release includes both Android and iOS archives with correct version in filename (OTP-28.3)
- **SC-006**: Developers can complete setup and first build following documentation without errors

## Assumptions

- The existing OTP patches (`otp-zlib-ios.patch`) will apply cleanly to OTP 28 or can be trivially updated
- The `otp-space.patch` is already upstream in OTP 28 (as confirmed in OTP 27)
- OTP 28 cross-compilation configuration is compatible with existing xcomp templates
- OpenSSL build scripts work with OTP 28 requirements
- The GitHub Actions CI environment has sufficient resources for cross-compilation
- Android NDK and Xcode versions in CI are compatible with OTP 28 build requirements
- Elixir 1.19.4 is compatible with OTP 28 (using `elixir 1.19.4-otp-28` in mise)
