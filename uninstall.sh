#!/usr/bin/env bash
# qs-env uninstaller (macOS)
#
# One-liner:  curl -fsSL https://raw.githubusercontent.com/Jack-411/qs-env/main/uninstall.sh | bash
# From clone:  bash uninstall.sh
#
# Removes ~/.qs and ONLY the lines qs-env itself added to ~/.zshrc
# (the managed marker block, plus known pre-marker install lines matched
# exactly). Never removes lines that merely contain "qs".
set -euo pipefail

if [[ "$(uname -s)" != Darwin && "${QS_ENV_UNSAFE:-0}" != 1 ]]; then
    echo "qs-env targets macOS (found: $(uname -s))."
    exit 1
fi

ZSHRC="$HOME/.zshrc"
MARK_BEGIN="# >>> qs-env >>>"
MARK_END="# <<< qs-env <<<"

echo "Removing qs-env files…"
rm -rf "$HOME/.qs"         && echo "  deleted ~/.qs/"
rm -f  "$HOME/.qs"                       # legacy single-file install
rm -f  "$HOME/.qs_default"               # legacy config
rm -f  "$HOME/.p10k-custom.zsh"          # legacy p10k file

if [[ ! -f "$ZSHRC" ]]; then
    echo "No ~/.zshrc — nothing to clean."
    echo "Uninstallation complete."
    exit 0
fi

cp "$ZSHRC" "$ZSHRC.bak.qs-uninstall"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Known lines written by current and older installers (exact match only).
awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    index($0, b) == 1 { inskip = 1; next }
    inskip == 1 { if (index($0, e) == 1) inskip = 0; next }
    $0 == "[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs" { next }
    $0 == "[[ -f ~/.qs/.p10k-custom.zsh ]] && source ~/.qs/.p10k-custom.zsh" { next }
    $0 == "[[ -f ~/.p10k-custom.zsh ]] && source ~/.p10k-custom.zsh" { next }
    { print }
' "$ZSHRC" > "$TMP"

cat "$TMP" > "$ZSHRC"

# --- remove the uv_project element from ~/.p10k.zsh --------------------------
# Only exact element lines (optional indent, optional trailing comma) that
# sit INSIDE the POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=( ... ) block — never a
# comment, colour setting, or anything else that merely mentions uv_project.
P10KCFG="$HOME/.p10k.zsh"
if [[ -f "$P10KCFG" ]]; then
    P_START="$(grep -n 'POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(' "$P10KCFG" | head -n 1 | cut -d: -f1 || true)"
    if [[ -n "$P_START" ]]; then
        P_END="$(awk -v s="$P_START" 'NR > s && /^[[:space:]]*\)/ { print NR; exit }' "$P10KCFG")"
        if [[ -n "$P_END" ]] && grep -qE '^[[:space:]]*uv_project([[:space:]]+#.*)?[[:space:]]*$' "$P10KCFG"; then
            cp "$P10KCFG" "$P10KCFG.bak.qs-uninstall"
            PTMP="$(mktemp)"
            awk -v s="$P_START" -v e="$P_END" '
                NR > s && NR < e && /^[[:space:]]*uv_project([[:space:]]+#.*)?[[:space:]]*$/ { next }
                { print }
            ' "$P10KCFG" > "$PTMP"
            cat "$PTMP" > "$P10KCFG"
            rm -f "$PTMP"
            echo "  removed uv_project from ~/.p10k.zsh (backup: .p10k.zsh.bak.qs-uninstall)"
            echo "  note: uv_project colour settings (if any) left untouched — harmless."
        fi
    fi
fi

echo "Uninstallation complete."
echo "Backup of your .zshrc saved as ~/.zshrc.bak.qs-uninstall"
echo "Restart your shell to apply changes."
