# Third-Party Notices

This Flutter plugin requires the BEAM runtime binaries (`liberlang.a` / `liberlang.xcframework`), which are built from the [mobile-BEAM-OTP](https://github.com/Gao-OS/mobile-BEAM-OTP) project and distributed separately via GitHub Releases.

The BEAM runtime binaries include code from the following open-source projects:

---

## Erlang/OTP

- **Project**: Erlang/OTP
- **Version**: 28.x (see release notes for exact version)
- **Source**: https://github.com/erlang/otp
- **License**: Apache License 2.0
- **Form**: Compiled into static library (`liberlang.a`)

Erlang/OTP is the core runtime that provides the BEAM virtual machine, standard library, and NIFs (Native Implemented Functions).

### Apache License 2.0

```
Copyright Ericsson AB and contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## OpenSSL

- **Project**: OpenSSL
- **Version**: 3.x (bundled for crypto NIF support)
- **Source**: https://github.com/openssl/openssl
- **License**: Apache License 2.0
- **Form**: Compiled into static library (linked into `liberlang.a`)

OpenSSL provides cryptographic functions used by OTP's `crypto` application.

### Apache License 2.0

```
Copyright 2016-2024 The OpenSSL Project Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## System Libraries

The following system libraries are dynamically linked at runtime:

| Library | Purpose | License |
|---------|---------|---------|
| zlib | Compression | zlib License |
| libm | Math functions | Platform SDK |
| libdl | Dynamic loading | Platform SDK |
| libc++ | C++ runtime (Android) | Apache 2.0 / MIT |

---

## Build Reproducibility

The BEAM runtime binaries are built using:

1. **Android**: NDK toolchain with CMake
2. **iOS**: Xcode toolchain

Build process:
1. Clone Erlang/OTP source at specified tag
2. Apply mobile-specific patches (see `patch/` directory)
3. Cross-compile OpenSSL for target architecture
4. Cross-compile OTP with `--xcomp-conf` for target platform
5. Bundle all static libraries into single `liberlang.a`

For full build instructions and source access, see:
https://github.com/Gao-OS/mobile-BEAM-OTP

---

## License Compliance

When distributing apps using this plugin:

1. Include this THIRD_PARTY_NOTICES.md or equivalent attribution
2. The Apache 2.0 license requires preservation of copyright notices
3. No patent claims are made by this plugin's authors regarding OTP or OpenSSL

For questions about licensing, please open an issue at:
https://github.com/Gao-OS/mobile-BEAM-OTP/issues
