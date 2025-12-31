# Feature Specification: OTP 27 Mobile BEAM Release

**Feature Branch**: `001-otp-27-release`
**Created**: 2025-12-30
**Status**: Draft
**Input**: User description: "we should build the otp 27 release now, please try to make the otp 27 version of the mobile beam otp"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mobile App Developer Integrates OTP 27 Runtime (Priority: P1)

A mobile application developer wants to embed the Erlang/Elixir BEAM VM (OTP 27) into their Android or iOS application to run Elixir code on mobile devices.

**Why this priority**: This is the core functionality of the project - without a working OTP 27 runtime package, developers cannot build mobile apps with the latest Erlang/OTP features and improvements.

**Independent Test**: Can be fully tested by running the build commands for both Android and iOS platforms and verifying the output artifacts are produced correctly.

**Acceptance Scenarios**:

1. **Given** the developer has set up the build environment with required dependencies (mise, Xcode, Android NDK), **When** they run `mix package.android.runtime`, **Then** the build produces `_build/android-runtime.zip` containing `liberlang.a` for all three Android architectures (armeabi-v7a, arm64-v8a, x86_64).

2. **Given** the developer has Xcode installed, **When** they run `mix package.ios.runtime`, **Then** the build produces `_build/liberlang.xcframework` containing libraries for arm64, arm64-simulator, and x86_64-simulator.

3. **Given** the developer has a mobile app project, **When** they link the OTP 27 `liberlang.a` or `liberlang.xcframework`, **Then** they can initialize and run the BEAM VM within their app.

---

### User Story 2 - Release Pipeline Creates Distributable Packages (Priority: P2)

The project maintainer wants to create GitHub releases with pre-built OTP 27 runtime packages so developers don't need to build from source.

**Why this priority**: Pre-built packages significantly reduce onboarding time for developers and ensure consistent, tested builds.

**Independent Test**: Can be tested by triggering the GitHub Actions workflow and verifying the release artifacts are created with correct naming and content.

**Acceptance Scenarios**:

1. **Given** the OTP 27 branch is ready, **When** the maintainer triggers the "Create Release" GitHub Action, **Then** the workflow builds both Android and iOS runtimes and creates a release with `android-otp-27.x.x.x.tar.gz` and `ios-otp-27.x.x.x.tar.gz`.

2. **Given** the release is created, **When** a developer downloads the release artifacts, **Then** the archives contain the correct static libraries and can be used directly in mobile projects.

---

### User Story 3 - Developer Builds with Custom NIFs (Priority: P3)

A developer wants to include additional Native Implemented Functions (NIFs) like exqlite or custom NIFs in their OTP 27 runtime build.

**Why this priority**: Many real-world applications require database access or custom native code, making NIF support essential for practical use.

**Independent Test**: Can be tested by running the build with a NIF repository URL and verifying the NIF code is compiled and included in the final static library.

**Acceptance Scenarios**:

1. **Given** the OTP 27 runtime builds successfully, **When** the developer runs `mix package.android.runtime "https://github.com/elixir-desktop/exqlite"`, **Then** the exqlite NIF is compiled and statically linked into `liberlang.a`.

2. **Given** Diode NIFs are requested, **When** the developer runs `mix package.android.runtime with_diode_nifs`, **Then** esqlite and libsecp256k1 NIFs are included in the build.

---

### Edge Cases

- What happens when OTP patches fail to apply cleanly to OTP 27?
  - Build should fail with clear error message indicating which patch failed
  - Patches may need updating for OTP 27 API changes

- What happens when OpenSSL build fails for a specific architecture?
  - Build should fail early with clear error, not continue with incomplete build

- How does the system handle missing Android NDK or Xcode?
  - Clear error message should indicate which dependency is missing and how to install it

- What happens if OTP 27 introduces breaking changes in the build system?
  - Cross-compilation configuration files (xcomp/*.conf) may need updates
  - Build should fail with meaningful error rather than producing corrupt binaries

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST build static library `liberlang.a` for Android architectures: armeabi-v7a, arm64-v8a, and x86_64
- **FR-002**: System MUST build `liberlang.xcframework` for iOS containing arm64, arm64-simulator, and x86_64-simulator slices
- **FR-003**: System MUST use OTP source from version 27.x.x as specified in `.tool-versions`
- **FR-004**: System MUST apply mobile platform patches from the `patch/` directory to OTP source
- **FR-005**: System MUST build OpenSSL as a static dependency for cryptographic NIFs
- **FR-006**: System MUST statically link core NIFs (asn1rt_nif, crypto) into the runtime library
- **FR-007**: System MUST support building additional NIFs from external repositories (exqlite, Diode NIFs)
- **FR-008**: System MUST produce packaged archives suitable for distribution (zip, tar.gz)
- **FR-009**: GitHub Actions workflow MUST build Android and iOS runtimes and create release artifacts
- **FR-010**: Build process MUST verify produced artifacts contain expected libraries before packaging

### Key Entities

- **OTP Source**: Erlang/OTP 27 source code cloned from GitHub repository
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
- **SC-005**: GitHub release includes both Android and iOS archives with correct version in filename (OTP-27.x.x)
- **SC-006**: Developers can complete setup and first build following documentation without errors

## Assumptions

- The existing OTP patches (`otp-space.patch`, `otp-zlib-ios.patch`) will apply cleanly to OTP 27 or can be trivially updated
- OTP 27 cross-compilation configuration is compatible with existing xcomp templates
- OpenSSL build scripts work with OTP 27 requirements
- The GitHub Actions CI environment has sufficient resources for cross-compilation
- Android NDK and Xcode versions in CI are compatible with OTP 27 build requirements
