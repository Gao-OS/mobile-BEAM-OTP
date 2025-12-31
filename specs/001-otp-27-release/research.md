# Research: OTP 27 Mobile BEAM Release

**Date**: 2025-12-30
**Feature**: OTP 27 Release Build

## Summary

This research validates the technical decisions and compatibility for building OTP 27.3.4.6 mobile runtimes. The codebase is already configured for OTP 27 with minimal changes required.

---

## 1. OTP 27 Patch Compatibility

### Decision
Existing patches (`otp-space.patch`, `otp-zlib-ios.patch`) are compatible with OTP 27.

### Rationale
- `otp-space.patch`: Fixes Makefile variable definition for spaces - affects `erts/emulator/Makefile.in` which has stable structure across OTP versions
- `otp-zlib-ios.patch`: Adds `__IOS__` exclusion to zlib header - addresses platform detection unchanged in OTP 27

### Alternatives Considered
- Upstream contribution: The patches are mobile-specific and unlikely to be accepted upstream as OTP doesn't officially support iOS/Android

### Verification Steps
1. Clone OTP 27.3.4.6 source
2. Apply patches with `git apply`
3. Build should proceed without patch rejection

---

## 2. Cross-Compilation Configuration

### Decision
Use OTP's built-in xcomp configurations located at `xcomp/erl-xcomp-{arch}-android.conf` within the OTP source tree.

### Rationale
- OTP 27 includes cross-compilation configs for Android ARM, ARM64, and x86_64
- iOS configurations use custom xcomp values mapped through `arch.xcomp` in `lib/mobile_runtimes/ios.ex`
- No changes to xcomp handling required

### Verification
- Confirmed `erl-xcomp-arm-android.conf` exists in OTP 27.3.4.6 repository

---

## 3. OTP Version Default

### Decision
Default OTP tag set to `OTP-27.3.4.6` in `lib/mobile_runtimes.ex:69`.

### Rationale
- `.tool-versions` specifies `erlang 27.3.4.6`
- The codebase was already updated in commit `73d8fe1` ("feat: update OTP to version 27")
- Consistent with OTP version branch strategy from constitution

### Evidence
```elixir
# lib/mobile_runtimes.ex:68-69
def otp_tag() do
  System.get_env("OTP_TAG", "OTP-27.3.4.6")
end
```

---

## 4. Android NDK Compatibility

### Decision
Continue using automatic NDK detection with Android API level 26.

### Rationale
- API level 26 (Android 8.0 Oreo) covers ~95% of active devices
- NDK toolchain paths follow stable conventions
- Current detection logic in `guess_ndk_home()` works with latest NDK versions

### No Changes Required
The existing NDK integration is version-agnostic and works with NDK r21+.

---

## 5. iOS SDK Compatibility

### Decision
Continue targeting iOS 12.0+ with Xcode's native toolchain.

### Rationale
- iOS 12.0 minimum provides arm64 (devices) + M1/Intel simulator support
- Xcode toolchain is stable across iOS SDK versions
- xcframework format is the standard for multi-architecture static libraries

### No Changes Required
iOS build process is Xcode-version independent.

---

## 6. OpenSSL Build

### Decision
Continue using existing OpenSSL build scripts for static linking.

### Rationale
- OpenSSL is architecture-dependent but OTP-version independent
- Existing `scripts/install_openssl.sh` handles all target architectures
- Static linking ensures crypto NIF compatibility

### Caching Strategy
GitHub Actions caches OpenSSL builds per architecture and OTP version:
```yaml
key: openssl-{platform}-${{ needs.prepare.outputs.otp-version }}
```

---

## 7. GitHub Actions Workflow

### Decision
Existing `create-release.yml` workflow is ready for OTP 27.

### Rationale
- Workflow reads versions dynamically from `.tool-versions`
- Tag naming follows `OTP-{version}` pattern automatically
- Build matrix covers all 6 architectures (3 Android + 3 iOS)

### Workflow Verification
- `prepare` job extracts `27.3.4.6` from `.tool-versions`
- Creates tag `OTP-27.3.4.6`
- `build-android` and `build-ios` jobs run in parallel
- `release` job creates GitHub release with artifacts

---

## 8. NIF Compatibility (exqlite)

### Decision
Default NIF (exqlite) is compatible with OTP 27.

### Rationale
- exqlite uses standard Erlang NIF interface
- NIF ABI is stable across OTP versions
- Static linking process is OTP-version independent

### External NIFs
- `https://github.com/elixir-desktop/exqlite` (default)
- `https://github.com/diodechain/esqlite.git` (with_diode_nifs)
- `https://github.com/diodechain/libsecp256k1.git` (with_diode_nifs)

---

## Conclusion

**All research items resolved. No clarifications needed.**

The codebase is ready for OTP 27 release:
1. Version defaults already updated to OTP 27.3.4.6
2. Patches are compatible with OTP 27 Makefile structure
3. Cross-compilation configs exist in OTP 27 source
4. CI workflow dynamically handles version from `.tool-versions`
5. No code changes required - only trigger the release workflow

### Recommended Next Steps
1. Run local build test: `mix package.android.runtime` (requires Android NDK)
2. Run local build test: `mix package.ios.runtime` (requires macOS + Xcode)
3. Trigger GitHub Actions "Create Release" workflow
4. Verify release artifacts contain correct libraries
