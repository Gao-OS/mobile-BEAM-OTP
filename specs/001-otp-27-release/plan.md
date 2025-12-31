# Implementation Plan: OTP 27 Mobile BEAM Release

**Branch**: `001-otp-27-release` | **Date**: 2025-12-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-otp-27-release/spec.md`

## Summary

Build and release the OTP 27 version of mobile-BEAM, creating static libraries (`liberlang.a` and `liberlang.xcframework`) for Android (armeabi-v7a, arm64-v8a, x86_64) and iOS (arm64, arm64-simulator, x86_64-simulator). The codebase is already configured for OTP 27.3.4.6 via `.tool-versions`, requiring validation of patch compatibility and CI workflow execution.

## Technical Context

**Language/Version**: Elixir 1.19.4-otp-27, Erlang/OTP 27.3.4.6
**Primary Dependencies**: Mix (build tool), Android NDK, Xcode, OpenSSL (static), EEx (templates)
**Storage**: N/A (build tooling only)
**Testing**: Manual build verification, CI workflow validation
**Target Platform**: Android (API 26+), iOS (12.0+), Build host: macOS (iOS), Ubuntu/Docker (Android)
**Project Type**: Single (build tooling project)
**Performance Goals**: Build completes within GitHub Actions job limits (~6 hours max per job)
**Constraints**: Static linking only, OTP patches must apply cleanly, reproducible builds
**Scale/Scope**: 6 target architectures (3 Android + 3 iOS)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. OTP Version Branch Strategy | PASS | Building on `OTP-27` branch, `.tool-versions` specifies erlang 27.3.4.6 |
| II. Cross-Platform Parity | PASS | Spec requires all 6 architectures (3 Android + 3 iOS) |
| III. Reproducible Builds | PASS | Using pinned OTP_TAG=OTP-27.3.4.6, CI uses version caching |
| IV. Static Linking Only | PASS | Build produces single `liberlang.a` with static NIFs |
| V. Minimal Patch Footprint | PASS | Using existing patches from `patch/` directory |

**Gate Status**: PASS - All constitution principles satisfied.

## Project Structure

### Documentation (this feature)

```text
specs/001-otp-27-release/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (build artifacts model)
├── quickstart.md        # Phase 1 output (build guide)
├── contracts/           # Phase 1 output (N/A for build tooling)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── mobile_runtimes.ex              # Core utilities, OTP management
└── mobile_runtimes/
    ├── android.ex                  # Android architecture definitions
    └── ios.ex                      # iOS architecture definitions

lib/mix/tasks/
├── package_android_runtime.ex      # Android build orchestration
├── package_android_nif.ex          # Android NIF compilation
├── package_ios_runtime.ex          # iOS build orchestration
└── package_ios_nif.ex              # iOS NIF compilation

patch/
├── otp-space.patch                 # Makefile space fix
└── otp-zlib-ios.patch              # zlib iOS compatibility

xcomp/                              # Cross-compilation EEx templates

.github/workflows/
└── create-release.yml              # CI release workflow

_build/                             # Build outputs (generated)
├── android-runtime.zip             # Android artifacts
└── liberlang.xcframework/          # iOS artifacts
```

**Structure Decision**: Existing structure is appropriate. No new directories needed. Build outputs go to `_build/` per constitution.

## Constitution Check (Post-Design)

*Re-evaluated after Phase 1 design completion.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. OTP Version Branch Strategy | PASS | Design confirms OTP-27 branch with OTP-27.3.4.6 tag |
| II. Cross-Platform Parity | PASS | data-model.md documents all 6 architectures |
| III. Reproducible Builds | PASS | quickstart.md documents pinned versions, CI caching |
| IV. Static Linking Only | PASS | contracts/build-interface.md confirms static lib outputs |
| V. Minimal Patch Footprint | PASS | research.md confirms existing patches are sufficient |

**Post-Design Gate Status**: PASS - All constitution principles remain satisfied.

## Complexity Tracking

> No constitution violations. This is a straightforward build/release using established patterns from OTP 26.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

## Phase 1 Artifacts Generated

- `research.md` - Technical research and decisions
- `data-model.md` - Build artifacts model
- `quickstart.md` - Build and release guide
- `contracts/build-interface.md` - Mix task interface documentation

## Next Steps

Run `/speckit.tasks` to generate the implementation task list.
