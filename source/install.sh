#!/usr/bin/env bash

set -e

QS_SRC="qs"
P10K_CUSTOM_SRC="p10k-custom"
QS_DEST="$HOME/.qs"
P10K_CUSTOM_DEST="$HOME/.p10k-custom.zsh"
ZSHRC="$HOME/.zshrc"

echo "Installing qs…"
cp "$QS_SRC" "$QS_DEST"

echo "Do you want to install p10k-custom integration? (y/N)"
read -r INSTALL_P10K

if [[ "$INSTALL_P10K" =~ ^[Yy]$ ]]; then
    echo "Installing p10k-custom…"
    cp "$P10K_CUSTOM_SRC" "$P10K_CUSTOM_DEST"

    # Add sourcing line after p10k line
    if ! grep -q 'source ~/.p10k-custom.zsh' "$ZSHRC"; then
        echo "Adding p10k-custom sourcing to .zshrc…"

        # Insert after the p10k line if it exists
        if grep -q 'source ~/.p10k.zsh' "$ZSHRC"; then
            sed -i.bak '/source ~\/\.p10k\.zsh/a [[ -f ~/.p10k-custom.zsh ]] && source ~/.p10k-custom.zsh' "$ZSHRC"
        else
            # Otherwise append at end
            echo '[[ -f ~/.p10k-custom.zsh ]] && source ~/.p10k-custom.zsh' >> "$ZSHRC"
        fi
    fi
else
    echo "Skipping p10k-custom installation."
fi

# Add qs sourcing to .zshrc
if ! grep -q 'source ~/.qs' "$ZSHRC"; then
    echo "Adding qs sourcing to .zshrc…"
    echo '[[ -f ~/.qs ]] && source ~/.qs' >> "$ZSHRC"
fi

echo "Installation complete."
echo "Restart your shell to apply changes."