<!--
SYNC IMPACT REPORT
==================
Version change: N/A (initial) → 1.0.0
Added sections:
  - Core Principles (5 principles)
  - Build Infrastructure section
  - Platform Support section
  - Governance section
Modified principles: N/A (initial constitution)
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (no changes needed - generic)
  - .specify/templates/spec-template.md ✅ (no changes needed - generic)
  - .specify/templates/tasks-template.md ✅ (no changes needed - generic)
Follow-up TODOs: None
-->

# mobile-BEAM Constitution

## Core Principles

### I. OTP Version Branch Strategy

All development MUST follow the OTP version branch naming convention:
- Branch `OTP-26` targets Erlang/OTP 26.x releases
- Branch `OTP-27` targets Erlang/OTP 27.x releases
- The `OTP_TAG` environment variable MUST match the branch's target OTP version
- Version upgrades MUST be made on the appropriate branch first before merging

**Rationale**: Multiple OTP major versions require parallel maintenance. Branch naming
provides clear traceability between code and OTP compatibility.

### II. Cross-Platform Parity

Every feature and NIF MUST be buildable for both Android and iOS:
- Android: arm (armeabi-v7a), arm64 (arm64-v8a), x86_64 architectures
- iOS: arm64 (devices), aarch64-apple-iossimulator, x86_64-apple-iossimulator
- Platform-specific code MUST be isolated in `runtimes/android.ex` or `runtimes/ios.ex`
- Build outputs MUST produce valid static libraries (`liberlang.a` / `liberlang.xcframework`)

**Rationale**: Mobile applications targeting both platforms require consistent BEAM runtime
behavior across all supported architectures.

### III. Reproducible Builds

All builds MUST be reproducible given the same inputs:
- Android builds MUST use Docker-based cross-compilation via dockercross images
- iOS builds MUST use native Xcode/macOS toolchain
- OTP source MUST be cloned from a pinned `OTP_TAG` (e.g., `OTP-26.2.5.16`)
- OpenSSL and other dependencies MUST use version-pinned builds
- `SKIP_CLEAN_BUILD` is only for development iteration, never for releases

**Rationale**: Mobile app stores and enterprise deployments require bit-for-bit reproducible
artifacts for security auditing and compliance.

### IV. Static Linking Only

The BEAM runtime MUST be packaged as a single static library:
- All NIFs (asn1rt_nif, crypto, custom NIFs) MUST be statically linked
- Archive repackaging via `stubs/bin/` wrappers MUST aggregate all `.a` files
- Dynamic linking is NOT supported on mobile platforms
- Two-pass OTP build: first pass generates headers/libs, second includes custom NIFs

**Rationale**: iOS and Android prohibit dynamic library loading for security. A single
`liberlang.a` simplifies integration into mobile app build systems.

### V. Minimal Patch Footprint

Patches to OTP and dependencies MUST be minimal and documented:
- All patches MUST reside in `patch/` directory with descriptive names
- Patches MUST include comments explaining why they are necessary
- Upstream contributions SHOULD be attempted for non-mobile-specific fixes
- Cross-compilation configs in `xcomp/` MUST use EEx templates for maintainability

**Rationale**: Minimizing divergence from upstream OTP reduces maintenance burden when
upgrading to new OTP versions.

## Build Infrastructure

Build tooling MUST adhere to these constraints:
- Mix tasks in `lib/mix/tasks/` MUST handle all build orchestration
- Environment variables (`OTP_TAG`, `ANDROID_NDK_HOME`, etc.) MUST have sensible defaults
- Build outputs MUST go to `_build/` directory exclusively
- NIFs from external repositories MUST be specifiable via URL or preset (e.g., `with_diode_nifs`)

## Platform Support

Minimum platform requirements:
- Android: API level 26+ (Android 8.0 Oreo, ~95% device coverage)
- iOS: arm64 devices, M1 and Intel simulators
- Build host: macOS with Xcode (iOS), Docker (Android)

## Governance

This constitution governs all contributions to mobile-BEAM:
- Amendments require documentation in this file with version bump
- All PRs MUST verify compliance with these principles
- Breaking changes to build process require MAJOR version bump to constitution
- Use CLAUDE.md for runtime development guidance and quick reference

**Version**: 1.0.0 | **Ratified**: 2025-12-25 | **Last Amended**: 2025-12-25
