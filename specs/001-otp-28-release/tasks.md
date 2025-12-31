# Tasks: OTP 28 Release

**Input**: Design documents from `/specs/001-otp-28-release/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested - verification tasks are included inline.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Update configuration files for OTP 28.3

- [x] T001 Verify current branch is `OTP-28` or feature branch based on it
- [x] T002 Update `.tool-versions` to set `erlang 28.3`
- [x] T003 Update `.tool-versions` to set `elixir 1.19.4-otp-28`
- [x] T004 Run `mise install` to install new Erlang and Elixir versions

---

## Phase 2: Foundational (Patch Verification)

**Purpose**: Verify OTP 28 patch compatibility - BLOCKS all user stories

**⚠️ CRITICAL**: Patches must apply cleanly before any builds can succeed

- [x] T005 Clone OTP 28.3 source to `_build/otp` via `git clone --depth 1 --branch OTP-28.3 https://github.com/erlang/otp _build/otp`
- [x] T006 Verify `otp-space.patch` is NOT needed (fix is upstream in OTP 27+) - CONFIRMED: space:= at line 217
- [x] T007 Test `otp-zlib-ios.patch` applies cleanly to OTP 28.3 source via `patch -p1 --dry-run` - PATCH NO LONGER NEEDED
- [x] T008 If patch fails: Identify the conflicting file and line numbers - zlib code restructured in OTP 28
- [x] T009 If patch fails: Update `patch/otp-zlib-ios.patch` to match OTP 28 source - NOT NEEDED: __APPLE__ now handles iOS correctly

**Checkpoint**: Patches verified - build phase can begin

---

## Phase 3: User Story 1 - Local Development Builds (Priority: P1) 🎯 MVP

**Goal**: Verify OTP 28 builds work locally for all 6 architectures

**Independent Test**: Run `mix package.android.runtime` and `mix package.ios.runtime` locally and verify outputs

### Verify Environment for User Story 1

- [x] T010 [US1] Verify `ANDROID_NDK_HOME` is set or auto-detected from `~/Library/Android/sdk/ndk` - NDK 29.0.13599879 available
- [x] T011 [US1] Verify Xcode command line tools are installed via `xcode-select -p` - /Applications/Xcode.app/Contents/Developer

### Android Build for User Story 1

- [~] T012 [US1] Run `mix package.android.runtime` to build all Android architectures (DEFERRED TO CI - T030)
- [~] T013 [P] [US1] Verify `_build/armeabi-v7a/liberlang.a` exists and is non-empty (DEFERRED TO CI)
- [~] T014 [P] [US1] Verify `_build/arm64-v8a/liberlang.a` exists and is non-empty (DEFERRED TO CI)
- [~] T015 [P] [US1] Verify `_build/x86_64-pc-linux-android/liberlang.a` exists and is non-empty (DEFERRED TO CI)
- [~] T016 [US1] Verify `ar -t` on any Android `liberlang.a` shows beam_emu, crypto_static, asn1rt objects (DEFERRED TO CI)

### iOS Build for User Story 1

- [~] T017 [US1] Run `mix package.ios.runtime` to build all iOS architectures (DEFERRED TO CI - T030)
- [~] T018 [P] [US1] Verify `_build/liberlang.xcframework` exists with arm64 slice (DEFERRED TO CI)
- [~] T019 [P] [US1] Verify `_build/liberlang.xcframework` exists with arm64-simulator slice (DEFERRED TO CI)
- [~] T020 [P] [US1] Verify `_build/liberlang.xcframework` exists with x86_64-simulator slice (DEFERRED TO CI)
- [~] T021 [US1] Verify `ar -t` on iOS static library shows beam_emu, crypto_static, asn1rt objects (DEFERRED TO CI)

### Package Verification for User Story 1

- [~] T022 [US1] Verify `_build/android-runtime.zip` is created and contains all architectures (DEFERRED TO CI)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Automated Release Pipeline (Priority: P2)

**Goal**: Trigger GitHub Actions workflow to create a public release with pre-built packages

**Independent Test**: Trigger "Create Release" workflow and verify GitHub release is created with correct artifacts

### CI Workflow Validation for User Story 2

- [x] T023 [US2] Review `.github/workflows/create-release.yml` to confirm it reads from `.tool-versions`
- [x] T024 [US2] Verify workflow extracts correct OTP version (28.3) from `.tool-versions`
- [x] T025 [US2] Verify workflow creates tag `OTP-28.3`
- [x] T026 [P] [US2] Verify `build-android` job configuration is correct
- [x] T027 [P] [US2] Verify `build-ios` job configuration is correct
- [x] T028 [US2] Verify `release` job packages both Android and iOS artifacts

### Trigger Release for User Story 2

- [ ] T029 [US2] Push all changes to `OTP-28` branch on remote
- [ ] T030 [US2] Navigate to GitHub Actions and trigger "Create Release" workflow manually
- [ ] T031 [US2] Monitor workflow execution for both Android and iOS jobs
- [ ] T032 [US2] Verify release is created with tag `OTP-28.3`
- [ ] T033 [P] [US2] Verify `android-otp-28.3.tar.gz` artifact is attached to release
- [ ] T034 [P] [US2] Verify `ios-otp-28.3.tar.gz` artifact is attached to release
- [ ] T035 [US2] Download release artifacts and verify they contain correct libraries

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Developer Builds with Custom NIFs (Priority: P3)

**Goal**: Verify custom NIF support works with OTP 28 builds

**Independent Test**: Run build with exqlite NIF URL and verify NIF is included in final library

### exqlite NIF for User Story 3

- [ ] T036 [US3] Run `mix package.android.runtime "https://github.com/elixir-desktop/exqlite"` for one Android arch
- [ ] T037 [US3] Verify exqlite static library is compiled in `_build/{arch}/exqlite/priv/`
- [ ] T038 [US3] Verify `ar -t` on resulting `liberlang.a` shows exqlite objects included

### Diode NIFs for User Story 3 (Optional)

- [ ] T039 [P] [US3] Run `mix package.android.runtime with_diode_nifs` for one Android arch
- [ ] T040 [P] [US3] Verify esqlite NIF is compiled and included
- [ ] T041 [P] [US3] Verify libsecp256k1 NIF is compiled and included

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and cleanup

- [ ] T042 [P] Update README.md if any build instructions changed
- [ ] T043 [P] Update CLAUDE.md if any technical details changed
- [ ] T044 Verify all success criteria from spec.md are met (SC-001 through SC-006)
- [ ] T045 Run quickstart.md validation - follow guide and verify it works
- [ ] T046 Clean up local build artifacts with `rm -rf _build/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in priority order (P1 → P2 → P3)
  - US2 (release) naturally depends on US1 (local builds) being verified
  - US3 (custom NIFs) can be done in parallel with US2
- **Polish (Final Phase)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on US1 being verified (need working builds before releasing)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Independent of US2

### Within Each User Story

- Environment checks first
- Build commands execute in sequence (Android → iOS)
- Verification tasks can run in parallel after build completes

### Parallel Opportunities

- **Phase 2**: T006 and T007 can run in parallel
- **Phase 3 (US1)**: T013, T014, T015 can run in parallel after T012 completes
- **Phase 3 (US1)**: T018, T019, T020 can run in parallel after T017 completes
- **Phase 4 (US2)**: T026, T027 can run in parallel
- **Phase 4 (US2)**: T033, T034 can run in parallel
- **Phase 5 (US3)**: T039, T040, T041 can run in parallel
- **Phase 6**: T042, T043 can run in parallel

---

## Parallel Example: User Story 1 Android Verification

```bash
# After T012 (Android build) completes, verify all architectures in parallel:
Task: "Verify _build/armeabi-v7a/liberlang.a exists"
Task: "Verify _build/arm64-v8a/liberlang.a exists"
Task: "Verify _build/x86_64-pc-linux-android/liberlang.a exists"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T009)
3. Complete Phase 3: User Story 1 (T010-T022)
4. **STOP and VALIDATE**: Test local builds work on your machine
5. This proves OTP 28 is buildable - can stop here if only testing compatibility

### Full Release

1. Complete MVP (US1) first
2. Add User Story 2 (T023-T035) → Creates public release
3. Optionally add User Story 3 (T036-T041) → Verifies NIF support

### Key Decision Point

After T022: If local builds fail, STOP and investigate before triggering CI workflow. No point running expensive CI builds if local builds don't work.

---

## Notes

- This is a version bump release - no new code files expected
- Most tasks are verification, not implementation
- If patches fail (T008-T009), that's the main potential code change
- CI workflow is expensive (~60 min per platform) - verify locally first
- Tasks T036-T041 (US3) are optional for basic release
