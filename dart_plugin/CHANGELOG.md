# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0

First stable release of the beam_vm Flutter plugin.

### Features

* Initialize the BEAM VM from an Elixir release path
* Check VM initialization status (`isInitialized`)
* Monitor VM lifecycle via `statusStream`
* Call Erlang/Elixir functions from Dart (`call`)
* Send messages to named Elixir processes (`send`)
* Receive messages from Elixir via streams (`onMessage`)
* Graceful shutdown support (`shutdown`)
* Get OTP version (`getOtpVersion`)

### Platform Support

* **Android**: JNI bridge with native C++ implementation
  * Supported architectures: armeabi-v7a, arm64-v8a, x86_64
  * Requires `liberlang.a` in app's jniLibs
  * Minimum SDK: 26

* **iOS**: C bridging header with Swift plugin
  * Supported architectures: arm64, arm64-simulator, x86_64-simulator
  * Requires `liberlang.xcframework` linked in Xcode
  * Minimum iOS: 12.0

### Known Limitations

* BEAM VM cannot be cleanly restarted without terminating the app process
* Single VM instance per app

## 0.1.0

Initial development release.

* Core plugin structure
* Platform interface design
* Basic Dart API
