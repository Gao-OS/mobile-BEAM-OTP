# Implementation Plan: OTP 28 Release

**Branch**: `001-otp-28-release` | **Date**: 2025-12-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-otp-28-release/spec.md`

## Summary

Update mobile-BEAM to support Erlang/OTP 28.3, the latest OTP 28 release. This involves updating `.tool-versions`, verifying patch compatibility, and triggering the release workflow. Based on OTP 27 experience, no code changes are expected - only configuration updates and verification.

## Technical Context

**Language/Version**: Elixir 1.19.4-otp-28, Erlang/OTP 28.3
**Primary Dependencies**: Mix (build tool), Android NDK, Xcode, OpenSSL (static), EEx (templates)
**Storage**: N/A (build tooling only)
**Testing**: Manual verification via `mix package.*.runtime` tasks, CI workflow
**Target Platform**: Android (API 26+), iOS (12.0+)
**Project Type**: Build tooling / cross-compilation infrastructure
**Performance Goals**: Build completion within CI time limits (~60 min per platform)
**Constraints**: Static linking only, reproducible builds, cross-platform parity
**Scale/Scope**: 6 target architectures (3 Android + 3 iOS)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. OTP Version Branch Strategy | ✅ PASS | Working on OTP-28 branch, targeting OTP 28.3 |
| II. Cross-Platform Parity | ✅ PASS | Building all 6 architectures (3 Android + 3 iOS) |
| III. Reproducible Builds | ✅ PASS | Pinned OTP_TAG=OTP-28.3, version-pinned dependencies |
| IV. Static Linking Only | ✅ PASS | All NIFs statically linked via two-pass build |
| V. Minimal Patch Footprint | ✅ PASS | Only otp-zlib-ios.patch needed (space patch upstream) |

**Gate Status**: PASS - All constitution principles satisfied.

## Project Structure

### Documentation (this feature)

```text
specs/001-otp-28-release/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── mobile_runtimes.ex           # Core utilities, OTP management
└── mobile_runtimes/
    ├── android.ex               # Android architecture definitions
    └── ios.ex                   # iOS architecture definitions

lib/mix/tasks/
├── package_android_runtime.ex   # Android build task
├── package_android_nif.ex       # Android NIF compilation
├── package_ios_runtime.ex       # iOS build task
└── package_ios_nif.ex           # iOS NIF compilation

patch/
└── otp-zlib-ios.patch           # iOS zlib compatibility (required)

xcomp/
└── *.conf.eex                   # Cross-compilation templates

.github/workflows/
└── create-release.yml           # CI/CD release workflow
```

**Structure Decision**: Existing structure is preserved. This is a version bump release - no new source files required.

## Complexity Tracking

> No constitution violations. No complexity justifications needed.
