#!/bin/bash
# Install pinned quality tools only in this checkout's ignored cache.
set -euo pipefail
cd "$(dirname "$0")/.."
test "$(uname -s)" = Darwin || { echo 'Quality tools require macOS.' >&2; exit 1; }
mkdir -p .build/tools
install_tool() {
    local tool=$1 version=$2 url=$3 expected_hash=$4
    local destination="$PWD/.build/tools/$tool-$version"
    if [[ -x "$destination/$tool" ]] && [[ "$("$destination/$tool" --version)" = "$version" ]]; then
        return
    fi
    local staging
    staging=$(mktemp -d "$PWD/.build/tools/install.XXXXXX")
    trap 'rm -rf "$staging"' RETURN
    curl --fail --location --silent --show-error "$url" -o "$staging/tool.zip"
    test "$(shasum -a 256 "$staging/tool.zip" | cut -d ' ' -f 1)" = "$expected_hash"
    unzip -q "$staging/tool.zip" -d "$staging/unpacked"
    test "$("$staging/unpacked/$tool" --version)" = "$version"
    mkdir -p "$destination"
    cp "$staging/unpacked/$tool" "$destination/$tool"
    chmod +x "$destination/$tool"
}
install_tool swiftformat 0.59.1 \
    https://github.com/nicklockwood/SwiftFormat/releases/download/0.59.1/swiftformat.zip \
    8b6289b608a44e73cd3851c3589dbd7c553f32cc805aa54b3a496ce2b90febe7
install_tool swiftlint 0.65.0 \
    https://github.com/realm/SwiftLint/releases/download/0.65.0/portable_swiftlint.zip \
    d6cb0aa7a2f5f1ef306fc9e37bcb54dc9a26facc8f7784ac0c3dd3eccf5c6ba6
