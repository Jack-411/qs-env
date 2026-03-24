#!/bin/bash

cd "$(dirname "$0")"
set -e

ZSHRC="$HOME/.zshrc"

echo "Removing installed qs files…"

if [[ -d "$HOME/.qs" ]]; then
    rm -rf "$HOME/.qs"
    echo "Deleted ~/.qs/"
fi

if [[ -f "$HOME/.qs" ]]; then
    rm -f "$HOME/.qs"
    echo "Deleted legacy ~/.qs"
fi

if [[ -f "$HOME/.qs_default" ]]; then
    rm -f "$HOME/.qs_default"
    echo "Deleted legacy ~/.qs_default"
fi

if [[ -f "$HOME/.p10k-custom.zsh" ]]; then
    rm -f "$HOME/.p10k-custom.zsh"
    echo "Deleted legacy ~/.p10k-custom.zsh"
fi

echo "Cleaning .zshrc…"

if [[ ! -f "$ZSHRC" ]]; then
    echo "No ~/.zshrc found — nothing to clean."
    echo "Uninstallation complete."
    exit 0
fi

cp "$ZSHRC" "$ZSHRC.bak.qs-uninstall"

sed -i '' '/qs\/qs/d' "$ZSHRC"
sed -i '' '/qs\/p10k-custom\.zsh/d' "$ZSHRC"
sed -i '' '/\.qs\/qs/d' "$ZSHRC"
sed -i '' '/\.qs\/p10k-custom\.zsh/d' "$ZSHRC"
sed -i '' '/\.p10k-custom\.zsh/d' "$ZSHRC"
sed -i '' '/source ~\/\.qs/d' "$ZSHRC"
sed -i '' '/source ~\/\.p10k-custom\.zsh/d' "$ZSHRC"
sed -i '' '/qs/d' "$ZSHRC"

echo "Uninstallation complete."
echo "A backup of your .zshrc was saved as .zshrc.bak.qs-uninstall"
echo "Restart your shell to apply changes."