#!/usr/bin/env bash
# qs-env installer (macOS)
#
# One-liner install (recommended — no Gatekeeper issues, no chmod):
#   curl -fsSL https://raw.githubusercontent.com/Jack-411/qs-env/main/install.sh | bash
#
# From a clone:
#   bash install.sh
#
# Options: --p10k | --no-p10k   (default: auto — installs the p10k segment
#          only if your .zshrc already references p10k)
#          env QS_ENV_P10K=auto|yes|no for the curl one-liner form.
set -euo pipefail

QS_ENV_RAW_URL="${QS_ENV_RAW_URL:-https://raw.githubusercontent.com/Jack-411/qs-env/main}"
P10K_MODE="${QS_ENV_P10K:-auto}"

for arg in "$@"; do
    case "$arg" in
        --p10k)    P10K_MODE=yes ;;
        --no-p10k) P10K_MODE=no ;;
        -h|--help)
            echo "usage: install.sh [--p10k|--no-p10k]"
            exit 0 ;;
        *) echo "unknown option: $arg (see --help)"; exit 2 ;;
    esac
done

if [[ "$(uname -s)" != Darwin && "${QS_ENV_UNSAFE:-0}" != 1 ]]; then
    echo "qs-env targets macOS (found: $(uname -s))."
    exit 1
fi

INSTALL_DIR="$HOME/.qs"
ZSHRC="$HOME/.zshrc"
MARK_BEGIN="# >>> qs-env >>>"
MARK_END="# <<< qs-env <<<"
QS_LINE='[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs'
P10K_LINE='[[ -f ~/.qs/.p10k-custom.zsh ]] && source ~/.qs/.p10k-custom.zsh'

# --- locate sources: local checkout if present, otherwise download ----------
if [[ -n "${BASH_SOURCE[0]:-}" && -f "$(dirname "${BASH_SOURCE[0]}")/code/qs" ]]; then
    SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/code" && pwd)"
else
    SRC_DIR=""
fi

fetch() {  # fetch <repo-relative-path> <dest>
    if [[ -n "$SRC_DIR" && -f "$SRC_DIR/$(basename "$1")" ]]; then
        cp "$SRC_DIR/$(basename "$1")" "$2"
    else
        curl -fsSL "$QS_ENV_RAW_URL/$1" -o "$2"
    fi
}

[[ -f "$ZSHRC" ]] || : > "$ZSHRC"

# --- decide p10k integration -------------------------------------------------
if [[ "$P10K_MODE" == auto ]]; then
    if grep -qi 'p10k' "$ZSHRC" 2>/dev/null; then
        P10K_MODE=yes
    else
        P10K_MODE=no
    fi
fi

# --- stage files (fail BEFORE touching .zshrc on any download error) --------
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

fetch code/qs          "$STAGE/.qs"
fetch code/qs-version  "$STAGE/.qs-version"
if [[ "$P10K_MODE" == yes ]]; then
    fetch code/p10k-custom "$STAGE/.p10k-custom.zsh"
fi

mkdir -p "$INSTALL_DIR"
cp "$STAGE/.qs" "$INSTALL_DIR/.qs"
cp "$STAGE/.qs-version" "$INSTALL_DIR/.qs-version"
if [[ "$P10K_MODE" == yes ]]; then
    cp "$STAGE/.p10k-custom.zsh" "$INSTALL_DIR/.p10k-custom.zsh"
fi

# --- rewrite .zshrc ----------------------------------------------------------
# Backup once per run.
cp "$ZSHRC" "$ZSHRC.qs-backup.$(date +%Y%m%d-%H%M%S)"

# Build the managed block.
if [[ "$P10K_MODE" == yes ]]; then
    BLOCK="$(printf '%s\n%s\n%s\n%s' "$MARK_BEGIN" "$P10K_LINE" "$QS_LINE" "$MARK_END")"
else
    BLOCK="$(printf '%s\n%s\n%s' "$MARK_BEGIN" "$QS_LINE" "$MARK_END")"
fi

TMP="$STAGE/zshrc"

# Pass 1 — strip any previous managed block AND old (pre-marker) exact lines.
awk -v b="$MARK_BEGIN" -v e="$MARK_END" -v ql="$QS_LINE" -v pl="$P10K_LINE" '
    index($0, b) == 1 { inskip = 1; next }
    inskip == 1 { if (index($0, e) == 1) inskip = 0; next }
    $0 == ql { next }
    $0 == pl { next }
    { print }
' "$ZSHRC" > "$TMP"

# Pass 2 — insert the block after the last p10k-related line; append if none.
LAST_P10K="$(grep -in 'p10k' "$TMP" | tail -n 1 | cut -d: -f1 || true)"

OUT="$STAGE/zshrc.new"
if [[ -n "$LAST_P10K" ]]; then
    awk -v ln="$LAST_P10K" -v block="$BLOCK" '
        { print }
        NR == ln { print block }
    ' "$TMP" > "$OUT"
else
    cat "$TMP" > "$OUT"
    printf '%s\n' "$BLOCK" >> "$OUT"
fi

# Write back through the original inode (keeps perms/ACLs exactly).
cat "$OUT" > "$ZSHRC"

echo ""
echo "===================================================="
echo " qs-env installed."
if [[ "$P10K_MODE" == yes ]]; then
    echo "   .qs + p10k segment installed"
else
    echo "   .qs installed (no p10k integration)"
fi
echo "   managed block added to ~/.zshrc"
echo "   backup: $(basename "$ZSHRC").qs-backup.*"
echo "===================================================="
echo ""
echo "Open a new terminal (or run: source ~/.zshrc), then try:  qs help"
