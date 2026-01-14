# beam_vm

Flutter plugin for embedding and running the Erlang/Elixir BEAM virtual machine on Android and iOS.

## Features

- Initialize the BEAM VM from an Elixir release
- Call Erlang/Elixir functions from Dart
- Send messages to named Elixir processes
- Receive messages from Elixir in Dart

## Requirements

### Android
- `liberlang.a` for each architecture (armeabi-v7a, arm64-v8a, x86_64)
- Download from [mobile-BEAM-OTP releases](https://github.com/Gao-OS/mobile-BEAM-OTP/releases)

### iOS
- `liberlang.xcframework`
- Download from [mobile-BEAM-OTP releases](https://github.com/Gao-OS/mobile-BEAM-OTP/releases)

## Installation

### 1. Add dependency

```yaml
dependencies:
  beam_vm:
    git:
      url: https://github.com/Gao-OS/mobile-BEAM-OTP
      path: dart_plugin
```

### 2. Download BEAM runtime

```bash
gh release download OTP-28.3 --repo Gao-OS/mobile-BEAM-OTP
tar -xzf android-otp-28.3.tar.gz
tar -xzf ios-otp-28.3.tar.gz
```

### 3. Android Setup

Place `liberlang.a` files in your app:

```
android/app/src/main/jniLibs/
├── armeabi-v7a/liberlang.a
├── arm64-v8a/liberlang.a
└── x86_64/liberlang.a
```

### 4. iOS Setup

1. Drag `liberlang.xcframework` into your Xcode project
2. Ensure it's linked in Build Phases → Link Binary With Libraries

## Usage

### Initialize BEAM

```dart
import 'package:beam_vm/beam_vm.dart';

final beamVm = BeamVm();

// Path to your Elixir release (extracted from assets)
final erlangPath = '/path/to/erlang';

try {
  await beamVm.initialize(erlangPath);
  print('BEAM VM initialized!');
} on BeamVmException catch (e) {
  print('Failed to initialize: $e');
}
```

### Check Status

```dart
if (beamVm.isInitialized) {
  print('BEAM is running');
}

// Listen to status changes
beamVm.statusStream.listen((status) {
  print('Status: $status');
});
```

### Call Elixir Functions

```dart
// Call Elixir.MyApp.Math.add(1, 2)
final result = await beamVm.call(
  'Elixir.MyApp.Math',
  'add',
  [1, 2],
);
print('Result: $result'); // 3
```

### Send Messages

```dart
// Send to a named process
await beamVm.send('MyApp.Worker', {'type': 'ping'});
```

### Receive Messages

```dart
final subscription = beamVm.onMessage('events', (message) {
  print('Received: $message');
});

// Later: cancel subscription
subscription.cancel();
```

### Shutdown

```dart
await beamVm.shutdown();
```

## Preparing Your Elixir Release

Configure your `mix.exs` for mobile:

```elixir
def project do
  [
    releases: [
      my_app: [
        include_erts: false,
        include_executables_for: [],
        steps: [:assemble]
      ]
    ]
  ]
end
```

Build the release:

```bash
MIX_ENV=prod mix release --path _build/erlang_release
```

Bundle `_build/erlang_release/` in your app's assets.

## Architecture

```
┌─────────────────┐
│   Dart Code     │
│   (beam_vm)     │
└────────┬────────┘
         │ MethodChannel
┌────────┴────────┐
│  Platform Code  │
│ (Kotlin/Swift)  │
└────────┬────────┘
         │ JNI / C Bridge
┌────────┴────────┐
│  liberlang.a    │
│  (BEAM VM)      │
└─────────────────┘
```

## Limitations

- BEAM VM cannot be cleanly stopped without terminating the process
- Function calls require ei library integration (not yet implemented)
- Only one VM instance per app

## License

Apache 2.0
