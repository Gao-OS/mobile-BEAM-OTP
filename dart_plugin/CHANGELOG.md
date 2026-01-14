## 0.1.0

Initial release of the beam_vm Flutter plugin.

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

* **iOS**: C bridging header with Swift plugin
  * Supported architectures: arm64, arm64-simulator, x86_64-simulator
  * Requires `liberlang.xcframework` linked in Xcode

### Known Limitations

* Function calls (`call`) and messaging (`send`) require ei library integration (placeholder implementations)
* BEAM VM cannot be cleanly restarted without terminating the app process
* Single VM instance per app
