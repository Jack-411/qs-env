#!/bin/bash
# Double-click installer (kept for Finder users — see README for the
# curl one-liner, which avoids Gatekeeper entirely).
cd "$(dirname "$0")/.." || exit 1

# Once Gatekeeper has approved this launch, clear the quarantine flag from
# the rest of the folder so the uninstaller never trips it again.
if xattr -p com.apple.quarantine "$(pwd)/macOS/$(basename "$0")" >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "$(pwd)" 2>/dev/null || true
fi

exec /bin/bash macOS/install.sh "$@"
