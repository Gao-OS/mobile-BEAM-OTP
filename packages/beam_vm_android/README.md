# beam_vm_android

The Android implementation of [`beam_vm`](https://pub.dev/packages/beam_vm).

## Usage

This package is [endorsed](https://flutter.dev/to/federated-plugins), which means you can simply use `beam_vm` normally. This package will be automatically included in your app when you do, so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package directly, you should add it to your `pubspec.yaml` as usual.

## Bundled Binaries

This package bundles pre-compiled `liberlang.a` static libraries for:

- `armeabi-v7a` (32-bit ARM)
- `arm64-v8a` (64-bit ARM)
- `x86_64` (Intel/AMD 64-bit emulators)

The binaries are approximately 41 MB total and are downloaded from [mobile-BEAM-OTP releases](https://github.com/Gao-OS/mobile-BEAM-OTP/releases).

## Requirements

- Android API level 26+ (Android 8.0 Oreo)
- NDK for native code compilation
