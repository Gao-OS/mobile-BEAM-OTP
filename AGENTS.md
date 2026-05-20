# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project Summary

mobile-BEAM-OTP packages the Erlang/Elixir BEAM Virtual Machine into static libraries (`liberlang.a`) for embedding in Android and iOS applications. The build system cross-compiles OTP, OpenSSL, and native NIFs for each target architecture, then aggregates everything into platform-specific static archives.

**Versions** (from `.tool-versions`): Erlang 28.3, Elixir 1.19.4-otp-28

## Repository Structure

```
lib/
  mobile_runtimes.ex              # Core: cmd(), OTP cloning/patching, archive repackaging
  mobile_runtimes/
    android.ex                    # Android arch definitions, NDK toolchain, NIF build env
    ios.ex                        # iOS arch definitions
    e2e/                          # E2E testing framework
      architecture.ex             # Architecture atom mapping and parsing
      builder.ex                  # Builds test APKs (Gradle) and iOS apps (xcodebuild)
      emulator.ex                 # Manages Android emulators and iOS simulators
      junit_xml.ex                # JUnit XML report generation
      retry.ex                    # Exponential backoff retry for infra failures
      runner.ex                   # Orchestrates E2E test execution across architectures
      test_case.ex                # Individual test case struct
      test_report.ex              # Aggregated report across all suites
      test_suite.ex               # Per-architecture test suite

lib/mix/tasks/
  package_android_runtime.ex      # mix package.android.runtime
  package_android_nif.ex          # mix package.android.nif
  package_ios_runtime.ex          # mix package.ios.runtime
  package_ios_nif.ex              # mix package.ios.nif
  e2e_build.ex                    # mix e2e.build
  e2e_run.ex                      # mix e2e.run
  e2e_test.ex                     # mix e2e.test

stubs/bin/                        # Wrapper scripts for ar, ld, libtool, ranlib
scripts/                          # OpenSSL install, Elixir install, NIF build scripts
patch/                            # OTP patches for mobile compilation
packages/                         # Flutter plugin packages (beam_vm, beam_vm_android, etc.)
test/e2e/                         # E2E test fixtures and test apps (Android/iOS)
```

## Key Build Commands

```bash
# Setup
mise install                     # Install Erlang/Elixir via .tool-versions
mix deps.get                     # Install Elixir deps (jason)

# Android (requires ANDROID_NDK_HOME)
mix package.android.runtime      # All architectures, default NIF (exqlite)
mix package.android.runtime "https://github.com/user/nif-repo"
mix package.android.runtime with_diode_nifs
mix package.android.runtime env arm64  # Dump NIF build env to nif_env.sh

# iOS (requires Xcode)
mix package.ios.runtime          # All architectures, default NIF
mix package.ios.runtime with_diode_nifs

# E2E Testing
mix e2e.test --all               # Build + test all architectures
mix e2e.build --arch android-x86_64
mix e2e.run --arch android-x86_64

# Formatting
mix format
```

## Build Outputs

| Target | Output |
|--------|--------|
| Android arm | `_build/arm-unknown-linux-androideabi/liberlang.a` |
| Android arm64 | `_build/aarch64-unknown-linux-android/liberlang.a` |
| Android x86_64 | `_build/x86_64-pc-linux-android/liberlang.a` |
| Android ZIP | `_build/android-runtime.zip` |
| iOS | `_build/liberlang.xcframework` |

## Architecture Definitions

### Android (`MobileRuntimes.Android.architectures/0`)

Three targets, all API 26+:
- **arm** — `arm-unknown-linux-androideabi`, armeabi-v7a, `--disable-year2038`
- **arm64** — `aarch64-unknown-linux-android`, arm64-v8a
- **x86_64** — `x86_64-pc-linux-android`, x86_64

### iOS (`MobileRuntimes.Ios.architectures/0`)

Three targets, all iOS 12.0+:
- **ios-arm64** — `aarch64-apple-ios`, iphoneos SDK
- **iossimulator-x86_64** — `x86_64-apple-iossimulator`, iphonesimulator SDK
- **iossimulator-arm64** — `aarch64-apple-iossimulator`, iphonesimulator SDK

## Core Build Flow

1. **Clone OTP** — `MobileRuntimes.ensure_otp/0` clones to `_build/otp` and applies patches from `patch/`
2. **Build OpenSSL** — `scripts/install_openssl.sh` per architecture
3. **First-pass OTP build** — `./otp_build setup` with built-in static NIFs (asn1rt_nif, crypto)
4. **Build extra NIFs** — Clone and compile with cross-compilation env from first pass
5. **Second-pass OTP build** — `./otp_build configure` including all NIF paths
6. **Repackage** — Collect all `.a` files into single `liberlang.a` via `repackage_archive/4`
7. **Package** — ZIP (Android) or xcframework (iOS)

### Important Patterns

- **Two-pass OTP build**: Headers/libs from pass 1 are needed to compile extra NIFs, then pass 2 links everything
- **Stub tools**: `stubs/bin/{ar,ld,libtool,ranlib}-stub.sh` wrap real NDK/Xcode tools to handle archive repackaging. Generated per-arch into `_build/{arch}/stubs/`
- **Patch marker**: `_build/otp/.mobile_patched` prevents re-applying patches
- **Incremental builds**: If `liberlang.a` exists, the build is skipped. Use `SKIP_CLEAN_BUILD=1` to reuse existing OTP builds
- **Parallel builds**: Set `PARALLEL=1` to build all architectures concurrently (spawn_monitor)

## E2E Testing Framework

The E2E framework validates BEAM runtime functionality on actual mobile emulators/simulators.

### Flow
1. `Builder` compiles test apps (Gradle for Android, xcodebuild for iOS)
2. `Emulator` starts platform-specific emulators (AVD for Android, simctl for iOS)
3. Test app runs on emulator, outputs JSON wrapped in `E2E_TEST_RESULTS_START/END` markers
4. `Runner` parses results into `TestCase`/`TestSuite` structs
5. `TestReport` aggregates and `JUnitXML` writes CI-compatible reports

### Architecture Atoms
- `:android_armeabi_v7a`, `:android_arm64_v8a`, `:android_x86_64`
- `:ios_arm64`, `:ios_arm64_simulator`, `:ios_x86_64_simulator`

### Retry Behavior
- Infrastructure errors (emulator crash, boot timeout) trigger retries with exponential backoff
- Test assertion failures do **not** retry
- Max 3 retries by default

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `OTP_TAG` | Erlang OTP version | `OTP-28.3` |
| `OTP_SOURCE` | OTP git URL | `https://github.com/erlang/otp` |
| `ANDROID_NDK_HOME` | NDK path | Auto-detected from SDK dir |
| `SKIP_CLEAN_BUILD` | Skip `git clean -xdf` on OTP | unset |
| `PARALLEL` | Build all archs concurrently | unset |
| `MAKEFLAGS` | Make parallelization | `-j10 -O` |

## Coding Conventions

- **Language**: Elixir (Mix project, `:mobile_runtimes` app)
- **Dependencies**: Only `jason` for JSON parsing
- **Module naming**: `MobileRuntimes.*` for core, `Mix.Tasks.Package.*` for build tasks, `Mix.Tasks.E2e.*` for E2E
- **Command execution**: All shell commands go through `MobileRuntimes.cmd/2` which logs and streams output
- **Cross-compilation env**: Built up as keyword lists, passed to `System.cmd/3` as env
- **File organization**: Each module in its own file; E2E sub-system in `lib/mobile_runtimes/e2e/`

## Common Modification Patterns

### Adding a new Android architecture
1. Add entry to `MobileRuntimes.Android.architectures/0`
2. Create cross-compilation config template
3. The build system will pick it up automatically

### Adding a new iOS architecture
1. Add entry to `MobileRuntimes.Ios.architectures/0`
2. Create cross-compilation config template
3. Lipo merging in `buildall/2` handles multi-arch xcframework creation

### Adding a new default NIF
1. Add URL to `MobileRuntimes.default_nifs/0` or pass as argument to mix tasks
2. NIF must produce a static `.a` file in its `priv/` directory
3. `scripts/build_nif.sh` detects build system (mix, make, or rebar3)

### Adding E2E test cases
1. Test cases are defined in the native test apps (`test/e2e/apps/`)
2. Results are parsed from JSON output via `TestCase.from_json/1`
3. Categories: `:boot`, `:execution`, `:nif`

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `create-release.yml` — Builds Android + iOS, creates GitHub release
- `e2e-test.yml` — Runs E2E tests on emulators/simulators
- `flutter-plugin-integration.yml` — Tests Flutter plugin integration
- `packages-ci.yml` — CI for packages/ directory

## Branch Strategy

Each OTP major version has its own branch: `OTP-28` (current), `OTP-27`, `OTP-26`

## Gotchas

- The `arm` Android target requires `--disable-year2038` (32-bit limitation)
- iOS DED_LD requires using `$CC` as linker instead of `$LD` (OTP 28 OSSF hardening)
- Stub scripts replace `%TOOL%` placeholder with real tool path at build time
- Android NIF builds install Elixir into `_build/{arch}/elixir/` with a custom PATH
- iOS simulator architectures are merged with `lipo` before creating xcframework
- E2E tests require pre-built `liberlang.a` / `liberlang.xcframework` artifacts
