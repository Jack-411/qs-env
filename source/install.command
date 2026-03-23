#!/bin/bash
cd "$(dirname "$0")"
set -e

INSTALL_DIR="$HOME/.qs"
QS_DEST="$INSTALL_DIR/.qs"
P10K_DEST="$INSTALL_DIR/.p10k-custom.zsh"
ZSHRC="$HOME/.zshrc"

mkdir -p "$INSTALL_DIR"
cp "qs" "$QS_DEST"
cp "qs-version" "$INSTALL_DIR/.qs-version"

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
    echo "ERROR: Could not find any p10k lines in ~/.zshrc"
    exit 1
fi

echo "Install p10k-custom integration? (y/N)"
read -r INSTALL_P10K

if [[ "$INSTALL_P10K" =~ ^[Yy]$ ]]; then
    cp "p10k-custom" "$P10K_DEST"
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
echo " They should appear immediately after the LAST p10k-related line."
echo "===================================================="
echo ""
echo "Restart your terminal to apply changes."
