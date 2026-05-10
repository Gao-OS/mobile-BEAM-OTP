---
description: Guide for using the beam_vm Flutter plugin to embed and run the Erlang/Elixir BEAM VM on Android and iOS. Use this skill when users ask about integrating BEAM/Erlang/Elixir into Flutter apps, running Elixir on mobile, or using the beam_vm plugin.
---

# beam_vm Flutter Plugin

This skill covers how to use the `beam_vm` Flutter plugin to embed the Erlang/Elixir BEAM virtual machine in Android and iOS applications.

## Overview

The `beam_vm` plugin allows Flutter apps to:
- Initialize and run the BEAM VM from an Elixir release
- Call Erlang/Elixir functions from Dart
- Send messages to named Elixir processes
- Receive messages from Elixir in Dart streams

## Installation

### 1. Add the plugin dependency

```yaml
# pubspec.yaml
dependencies:
  beam_vm:
    git:
      url: https://github.com/Gao-OS/mobile-BEAM-OTP
      path: packages/beam_vm
```

### 2. Download BEAM runtime libraries

```bash
# Download from mobile-BEAM-OTP releases
gh release download OTP-28.5 --repo Gao-OS/mobile-BEAM-OTP
tar -xzf android-otp-28.5.tar.gz
tar -xzf ios-otp-28.5.tar.gz
```

### 3. Android Setup

Place `liberlang.a` files in your app's jniLibs directory:

```
android/app/src/main/jniLibs/
├── armeabi-v7a/liberlang.a
├── arm64-v8a/liberlang.a
└── x86_64/liberlang.a
```

Add to `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86_64'
        }
    }
}
```

### 4. iOS Setup

1. Drag `liberlang.xcframework` into your Xcode project
2. In Build Phases → Link Binary With Libraries, ensure it's linked
3. Add required system libraries: `libz.tbd`, `libc++.tbd`

## Preparing Your Elixir Release

Configure `mix.exs` for mobile deployment:

```elixir
def project do
  [
    app: :my_app,
    version: "1.0.0",
    elixir: "~> 1.15",
    releases: [
      my_app: [
        include_erts: false,           # Use embedded BEAM
        include_executables_for: [],   # No CLI executables
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

Bundle `_build/erlang_release/` in your Flutter app's assets.

## Usage

### Import the plugin

```dart
import 'package:beam_vm/beam_vm.dart';
```

### Initialize the BEAM VM

```dart
final beamVm = BeamVm();

// Extract release from assets to a writable directory first
final erlangPath = '/path/to/extracted/erlang_release';

try {
  await beamVm.initialize(erlangPath);
  print('BEAM VM initialized successfully');
} on BeamVmException catch (e) {
  print('Initialization failed: ${e.message}');
}
```

### Monitor VM Status

```dart
// Check current status
if (beamVm.isInitialized) {
  print('VM is running');
}

// Listen to status changes
beamVm.statusStream.listen((status) {
  switch (status) {
    case BeamVmStatus.uninitialized:
      print('VM not started');
    case BeamVmStatus.initializing:
      print('VM starting...');
    case BeamVmStatus.running:
      print('VM running');
    case BeamVmStatus.error:
      print('VM error');
    case BeamVmStatus.shuttingDown:
      print('VM shutting down');
  }
});
```

### Call Elixir Functions

```dart
// Call Elixir.MyApp.Math.add(1, 2)
try {
  final result = await beamVm.call(
    'Elixir.MyApp.Math',  // Module name
    'add',                 // Function name
    [1, 2],               // Arguments as List
  );
  print('Result: $result');  // Output: 3
} on BeamVmException catch (e) {
  print('Call failed: ${e.message}');
}

// Call with complex arguments
final user = await beamVm.call(
  'Elixir.MyApp.Users',
  'create',
  [{'name': 'Alice', 'email': 'alice@example.com'}],
);
```

### Send Messages to Processes

```dart
// Send to a named GenServer
await beamVm.send('MyApp.Worker', {'type': 'ping', 'data': 123});

// Send complex data
await beamVm.send('MyApp.EventHandler', {
  'event': 'user_action',
  'payload': {'action': 'click', 'target': 'button_1'}
});
```

### Receive Messages from Elixir

```dart
// Subscribe to a message channel
final subscription = beamVm.onMessage('events', (message) {
  print('Received from Elixir: $message');

  // Handle different message types
  if (message is Map && message['type'] == 'notification') {
    showNotification(message['text']);
  }
});

// Later: cancel the subscription
subscription.cancel();
```

### Shutdown

```dart
await beamVm.shutdown();
```

**Note:** The BEAM VM cannot be cleanly restarted without terminating the app process. Plan your app lifecycle accordingly.

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:beam_vm/beam_vm.dart';

class ElixirCounter extends StatefulWidget {
  @override
  _ElixirCounterState createState() => _ElixirCounterState();
}

class _ElixirCounterState extends State<ElixirCounter> {
  final _beamVm = BeamVm();
  int _count = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeBeam();
  }

  Future<void> _initializeBeam() async {
    try {
      // Assume erlang release is extracted to this path
      await _beamVm.initialize('/data/data/com.example.app/erlang');
      setState(() => _isReady = true);

      // Subscribe to counter updates from Elixir
      _beamVm.onMessage('counter_updates', (value) {
        setState(() => _count = value as int);
      });
    } catch (e) {
      print('Failed to initialize BEAM: $e');
    }
  }

  Future<void> _increment() async {
    if (!_isReady) return;

    final result = await _beamVm.call(
      'Elixir.MyApp.Counter',
      'increment',
      [_count],
    );
    setState(() => _count = result as int);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _isReady ? _increment : null,
          child: Text(_isReady ? 'Increment' : 'Loading...'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _beamVm.shutdown();
    super.dispose();
  }
}
```

## Architecture

```
┌─────────────────────────────────┐
│         Flutter App             │
│         (Dart Code)             │
└────────────┬────────────────────┘
             │ MethodChannel
┌────────────┴────────────────────┐
│       beam_vm Plugin            │
│   (Platform Interface)          │
└────────────┬────────────────────┘
             │
     ┌───────┴───────┐
     │               │
┌────┴────┐    ┌─────┴────┐
│ Android │    │   iOS    │
│ (JNI)   │    │ (C API)  │
└────┬────┘    └─────┬────┘
     │               │
┌────┴───────────────┴────┐
│      liberlang.a        │
│      (BEAM VM)          │
└─────────────────────────┘
```

## Troubleshooting

### Android: "liberlang.a not found"

Ensure the library is in the correct jniLibs path:
```
android/app/src/main/jniLibs/{arch}/liberlang.a
```

### iOS: "Undefined symbols for architecture arm64"

1. Verify `liberlang.xcframework` is linked in Xcode
2. Add to Build Settings → Other Linker Flags: `-lz -lm -ldl`

### "BEAM VM initialization failed"

1. Check the erlangPath points to a valid Elixir release directory
2. Verify the release contains `lib/` and `releases/` directories
3. Ensure the release was built with `include_erts: false`

### "Function call returned null"

The `call()` and `send()` methods require ei library integration which is not yet fully implemented. Currently these return placeholder values.

## Limitations

1. **Single VM instance**: Only one BEAM VM can run per app process
2. **No clean shutdown**: `erl_exit()` terminates the entire process; `shutdown()` only marks the VM as stopped
3. **ei library pending**: Full function calling requires ei (Erlang Interface) library integration
4. **No hot code reload**: Unlike standard Erlang deployments, mobile apps require full restart for code updates

## Related Resources

- [mobile-BEAM-OTP Repository](https://github.com/Gao-OS/mobile-BEAM-OTP)
- [Erlang Embedded Documentation](https://www.erlang.org/doc/embedded/embedded_solaris)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
