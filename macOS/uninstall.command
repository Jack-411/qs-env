#!/bin/bash
# Double-click uninstaller (kept for Finder users — see README for the
# curl one-liner).
cd "$(dirname "$0")/.." || exit 1

if xattr -p com.apple.quarantine "$(pwd)/macOS/$(basename "$0")" >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "$(pwd)" 2>/dev/null || true
fi

exec /bin/bash uninstall.sh "$@"
