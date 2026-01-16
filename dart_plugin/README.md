# beam_vm

[![Pub Version](https://img.shields.io/pub/v/beam_vm)](https://pub.dev/packages/beam_vm)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Flutter plugin for embedding and running the Erlang/Elixir BEAM virtual machine on mobile devices.

## What This Plugin Does

This plugin embeds the BEAM VM (Erlang's virtual machine) into your Flutter app, allowing you to:

- Run Elixir/Erlang code natively on Android and iOS
- Call Erlang/Elixir functions from Dart
- Send/receive messages between Dart and Elixir processes
- Package Elixir releases as mobile app assets

**Use cases**: offline-capable apps with Elixir business logic, distributed systems nodes on mobile, or apps requiring Erlang's concurrency model.

## Platform Support

| Platform | Architectures | Min Version | Status |
|----------|--------------|-------------|--------|
| Android | arm64-v8a, armeabi-v7a, x86_64 | API 26 | ✅ Supported |
| iOS | arm64, arm64-simulator, x86_64-simulator | iOS 12.0 | ✅ Supported |
| macOS | - | - | ❌ Not yet |
| Linux | - | - | ❌ Not yet |
| Windows | - | - | ❌ Not yet |

## Binary Size

The BEAM runtime adds approximately:
- **Android**: ~15 MB per ABI (arm64-v8a), ~10 MB (armeabi-v7a)
- **iOS**: ~12 MB (device), ~21 MB (simulator, universal)

These are static libraries linked into your app. Android app bundles can target specific ABIs to reduce download size.

## Security Considerations

### Code Execution Model

This plugin executes **only pre-bundled Elixir/Erlang code** from your app's assets. The BEAM VM:

- ❌ Does NOT download code from the internet
- ❌ Does NOT execute arbitrary remote code
- ✅ Only runs `.beam` files bundled in your app at build time
- ✅ Follows the same security model as native code

### iOS App Store Compliance

This plugin is designed to comply with Apple's guidelines:

- Code is bundled at build time, not downloaded at runtime
- No JIT compilation (BEAM uses interpretation + HiPE/JIT disabled for iOS)
- Similar to embedded scripting engines (Lua, JavaScript Core)

### Binary Provenance

The BEAM runtime binaries are:

- Built from official [Erlang/OTP source](https://github.com/erlang/otp)
- Cross-compiled using [mobile-BEAM-OTP](https://github.com/Gao-OS/mobile-BEAM-OTP)
- Distributed via GitHub Releases with SHA256 checksums
- Built in GitHub Actions (reproducible, auditable)

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for complete license information.

## Installation

### 1. Add the dependency

```yaml
dependencies:
  beam_vm: ^1.0.0
```

### 2. Download BEAM Runtime

Download the pre-built runtime from [mobile-BEAM-OTP releases](https://github.com/Gao-OS/mobile-BEAM-OTP/releases):

```bash
# Using GitHub CLI
gh release download OTP-28.3 --repo Gao-OS/mobile-BEAM-OTP
tar -xzf android-otp-*.tar.gz
tar -xzf ios-otp-*.tar.gz
```

### 3. Android Setup

Place `liberlang.a` files in your app's jniLibs:

```
android/app/src/main/jniLibs/
├── arm64-v8a/liberlang.a
├── armeabi-v7a/liberlang.a
└── x86_64/liberlang.a
```

### 4. iOS Setup

1. Copy `liberlang.xcframework` to your iOS project directory
2. In Xcode: Add to "Frameworks, Libraries, and Embedded Content"
3. Ensure it's set to "Do Not Embed" (it's a static library)

## Usage

### Initialize BEAM VM

```dart
import 'package:beam_vm/beam_vm.dart';

final beamVm = BeamVm();

// Path to extracted Elixir release in app assets
final erlangPath = await extractReleaseToPath();

try {
  await beamVm.initialize(erlangPath);
  print('BEAM VM running OTP ${await beamVm.getOtpVersion()}');
} on BeamVmException catch (e) {
  print('Failed: $e');
}
```

### Monitor Status

```dart
// Check current status
if (beamVm.isInitialized) {
  print('VM is running');
}

// Stream status changes
beamVm.statusStream.listen((status) {
  switch (status) {
    case BeamVmStatus.uninitialized:
      print('Not started');
    case BeamVmStatus.initializing:
      print('Starting...');
    case BeamVmStatus.running:
      print('Running');
    case BeamVmStatus.error:
      print('Error occurred');
  }
});
```

### Call Elixir Functions

```dart
// Call MyApp.Math.add(1, 2)
final result = await beamVm.call(
  'Elixir.MyApp.Math',
  'add',
  [1, 2],
);
print('Result: $result'); // 3
```

### Message Passing

```dart
// Send message to named process
await beamVm.send('my_worker', {'action': 'ping'});

// Receive messages
final subscription = beamVm.onMessage('events', (message) {
  print('Received: $message');
});

// Clean up
subscription.cancel();
```

### Shutdown

```dart
await beamVm.shutdown();
```

## Preparing Your Elixir Release

Configure `mix.exs` for mobile deployment:

```elixir
def project do
  [
    releases: [
      my_app: [
        include_erts: false,  # ERTS is provided by liberlang
        include_executables_for: [],
        steps: [:assemble]
      ]
    ]
  ]
end
```

Build and bundle:

```bash
MIX_ENV=prod mix release --path _build/mobile_release
# Copy _build/mobile_release to your Flutter app's assets
```

## Architecture

```
┌─────────────────────────┐
│   Flutter/Dart App      │
│   (Your UI + Logic)     │
└───────────┬─────────────┘
            │ MethodChannel
┌───────────┴─────────────┐
│   beam_vm Plugin        │
│   (Platform Binding)    │
├─────────────────────────┤
│   Kotlin/Swift Bridge   │
│   (JNI / C Interop)     │
└───────────┬─────────────┘
            │ Native Calls
┌───────────┴─────────────┐
│   liberlang.a           │
│   (BEAM VM + OTP + SSL) │
└─────────────────────────┘
```

## Limitations

- **Single VM instance**: Only one BEAM VM per app process
- **No hot restart**: VM cannot be cleanly stopped; requires app restart
- **Static linking**: Runtime must be bundled, not dynamically loaded

## Troubleshooting

### Android: "liberlang.a not found"

Ensure files are in the correct paths:
```
android/app/src/main/jniLibs/{ABI}/liberlang.a
```

### iOS: "library 'erlang' not found"

1. Verify xcframework is added to Xcode project
2. Check Library Search Paths include the xcframework location
3. Ensure "Do Not Embed" is selected (static library)

### VM fails to initialize

- Check the Elixir release path is accessible
- Ensure release was built with `include_erts: false`
- Check device logs for detailed error messages

## License

This plugin is licensed under the [MIT License](LICENSE).

The BEAM runtime binaries include Erlang/OTP (Apache 2.0) and OpenSSL (Apache 2.0).
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for complete attribution.
