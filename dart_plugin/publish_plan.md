# Plan: Publish beam_vm Flutter Plugin to pub.dev

## Summary

The `beam_vm` plugin is well-architected but needs metadata fixes before pub.dev publication. The main issues are: missing SDK upper bound, outdated CHANGELOG, and large example binaries that need exclusion.

## Critical Fixes (Blocking Publication)

### 1. Fix SDK Version Constraint
**File:** `pubspec.yaml`
- Current: `sdk: ">=3.0.0"`
- Required: `sdk: ">=3.0.0 <4.0.0"`
- Reason: pub.dev requires upper bound to protect against future breaking changes

### 2. Update CHANGELOG.md
**File:** `CHANGELOG.md`
- Current: Only documents version 0.1.0
- Required: Add entry for version 1.0.0
- Content: Document the full feature set for initial stable release

### 3. Create .pubignore
**File:** `.pubignore` (new file)
- Exclude example binaries (73 MB total):
  - `example/android/app/src/main/jniLibs/`
  - `example/ios/liberlang.xcframework/`
- This reduces published package from ~26 MB to ~3 MB

## Recommended Improvements

### 4. Update Installation Docs
**File:** `README.md`
- Add pub.dev installation method alongside git method
- Update example references

### 5. Add pub.dev Metadata (Optional)
**File:** `pubspec.yaml`
- Add `topics:` field for discoverability: `[flutter, plugin, erlang, elixir, beam-vm]`

## Files to Modify

| File | Action | Priority |
|------|--------|----------|
| `pubspec.yaml` | Fix SDK constraint, add topics | Critical |
| `CHANGELOG.md` | Add 1.0.0 entry | Critical |
| `.pubignore` | Create new file | Critical |
| `README.md` | Update installation section | Recommended |

## Verification

1. Run `flutter pub publish --dry-run` to verify all checks pass
2. Check published package size is reasonable (~3 MB without binaries)
3. Verify all pub.dev metadata renders correctly

## Publication Command

After fixes:
```bash
cd dart_plugin
flutter pub publish
```
