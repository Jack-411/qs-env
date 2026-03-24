#!/bin/bash
cd "$(dirname "$0")"
set -e

INSTALL_DIR="$HOME/.qs"
QS_SRC="../code/qs"
QS_VERSION_SRC="../code/qs-version"
P10K_SRC="../code/p10k-custom"

QS_DEST="$INSTALL_DIR/.qs"
P10K_DEST="$INSTALL_DIR/.p10k-custom.zsh"
ZSHRC="$HOME/.zshrc"

if [[ ! -f "$ZSHRC" ]]; then
    echo "# Created by qs installer" > "$ZSHRC"
    echo "Created new ~/.zshrc"
fi

mkdir -p "$INSTALL_DIR"
cp "$QS_SRC" "$QS_DEST"
cp "$QS_VERSION_SRC" "$INSTALL_DIR/.qs-version"

insert_after_line() {
    local LINE_NUM="$1"
    local TEXT="$2"

    TMPFILE=$(mktemp)
    echo "$TEXT" > "$TMPFILE"

    sed -i.bak "${LINE_NUM}r $TMPFILE" "$ZSHRC"
    rm "$TMPFILE"
}

P10K_LINE_NUM=$(grep -n "p10k" "$ZSHRC" | tail -n 1 | cut -d: -f1)

if [[ -z "$P10K_LINE_NUM" ]]; then
    BOTTOM_GUARD_LINE=$(grep -nE \
"zsh-syntax-highlighting|zsh-history-substring-search|zsh-autosuggestions|fzf/shell/key-bindings|starship init zsh|#.*end" \
"$ZSHRC" | head -n 1 | cut -d: -f1)

    if [[ -n "$BOTTOM_GUARD_LINE" ]]; then
        P10K_LINE_NUM=$((BOTTOM_GUARD_LINE - 1))
        insert_after_line "$P10K_LINE_NUM" ""
    else
        P10K_LINE_NUM=$(wc -l < "$ZSHRC")
    fi
fi

if [[ -z "$(grep -n "p10k" "$ZSHRC")" ]]; then
    INSTALL_P10K="n"
else
    echo "Install p10k-custom integration? (y/N)"
    read -r INSTALL_P10K
fi

if [[ "$INSTALL_P10K" =~ ^[Yy]$ ]]; then
    cp "$P10K_SRC" "$P10K_DEST"
    CUSTOM_LINE='[[ -f ~/.qs/.p10k-custom.zsh ]] && source ~/.qs/.p10k-custom.zsh'

    if ! grep -Fq "$CUSTOM_LINE" "$ZSHRC"; then
        insert_after_line "$P10K_LINE_NUM" "$CUSTOM_LINE"
    fi

    QS_LINE='[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs'
    CUSTOM_LINE_NUM=$(grep -n "\.p10k-custom\.zsh" "$ZSHRC" | tail -n 1 | cut -d: -f1)

    if ! grep -Fq "$QS_LINE" "$ZSHRC"; then
        insert_after_line "$CUSTOM_LINE_NUM" "$QS_LINE"
    fi

else
    QS_LINE='[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs'
    if ! grep -Fq "$QS_LINE" "$ZSHRC"; then
        insert_after_line "$P10K_LINE_NUM" "$QS_LINE"
    fi
fi

echo ""
echo "===================================================="
echo " Installation finished."
echo " Please open ~/.zshrc and verify these lines:"
echo ""
echo "   [[ -f ~/.qs/.qs ]] && source ~/.qs/.qs"
echo "   [[ -f ~/.qs/.p10k-custom.zsh ]] && source ~/.qs/.p10k-custom.zsh"
echo ""
echo " They should appear immediately after the LAST p10k-related line,"
echo " or before any end-of-file plugins if p10k is not present."
echo "===================================================="
echo ""
echo "Restart your terminal to apply changes."