#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

VERSION=$(grep '^elixir' "$REPO_ROOT/.tool-versions" | awk '{print $2}')

mkdir "$1"
cd "$1"
wget "https://github.com/elixir-lang/elixir/archive/v${VERSION}.zip"
unzip "v${VERSION}.zip"
cd "elixir-${VERSION}"
make
mv * ..
