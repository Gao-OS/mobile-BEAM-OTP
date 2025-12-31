# Research: OTP 28 Release

**Feature**: OTP 28 Release
**Date**: 2025-12-31

## Research Questions

### 1. OTP 28 Version Selection

**Question**: What is the latest stable OTP 28 release?

**Decision**: OTP-28.3

**Rationale**:
- Published 2025-12-10 (most recent)
- Stable release (not RC or pre-release)
- Available releases: OTP-28.3, OTP-28.2, OTP-28.1.1, OTP-28.1, OTP-28.0.4

**Alternatives Considered**:
- OTP-28.2: Previous stable, superseded by 28.3
- OTP-28.0.x: Initial releases, prefer latest patch level

### 2. Elixir Compatibility

**Question**: What Elixir version is compatible with OTP 28?

**Decision**: Elixir 1.19.4-otp-28

**Rationale**:
- Elixir 1.19.4 is the latest stable release
- mise supports OTP-specific variants via `-otp-28` suffix
- Same pattern used successfully for OTP 27 (1.19.4-otp-27)

**Alternatives Considered**:
- Elixir 1.18.x: Older, prefer latest compatible version
- Elixir 1.19.3: Previous patch, prefer latest

### 3. Patch Compatibility

**Question**: Do existing patches apply to OTP 28?

**Decision**: Only `otp-zlib-ios.patch` is needed

**Rationale**:
- `otp-space.patch` - Already upstream in OTP 27+, not needed
- `otp-zlib-ios.patch` - Still required for iOS zlib compatibility
- No new patches expected (OTP 28 follows same patterns)

**Alternatives Considered**:
- Create new patches: Not needed unless build fails

### 4. Code Changes Required

**Question**: What code changes are needed for OTP 28?

**Decision**: No code changes required - only configuration updates

**Rationale**:
- Update `.tool-versions` to OTP 28.3 and Elixir 1.19.4-otp-28
- Build infrastructure is OTP-version agnostic
- Cross-compilation configs use EEx templates
- Existing architecture definitions work across OTP versions

**Alternatives Considered**:
- Modify xcomp templates: Only if OTP 28 requires new config options
- Update build tasks: Only if OTP 28 changes build output structure

### 5. CI/CD Compatibility

**Question**: Does the existing GitHub Actions workflow work with OTP 28?

**Decision**: No changes needed to workflow

**Rationale**:
- Workflow reads versions from `.tool-versions`
- Creates tag from OTP version automatically
- Parallel Android/iOS builds are version-agnostic

**Alternatives Considered**:
- Update workflow file: Only if new build steps needed

## Summary

This is a straightforward version bump release. The implementation requires:

1. Update `.tool-versions`:
   - `erlang 28.3` (from 27.3.4.6)
   - `elixir 1.19.4-otp-28` (from 1.19.4-otp-27)

2. Verify patches apply cleanly to OTP 28 source

3. Run local builds to confirm compatibility

4. Trigger CI workflow to create release

No code changes to build infrastructure are anticipated.
