#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

OTP_VERSION=$(grep '^erlang' "$REPO_ROOT/.tool-versions" | awk '{print $2}')
export OTP_TAG="OTP-${OTP_VERSION}"
export OTP_SOURCE=https://github.com/erlang/otp

mix package.ios.runtime with_diode_nifs
