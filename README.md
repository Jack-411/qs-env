# 📦 qs-env

A lightweight python environment helper for macOS that installs:

- A hidden shell function file: `~/.qs/.qs`
- An optional Powerlevel10k custom segment: `~/.qs/.p10k-custom.zsh`
- Automatic sourcing lines in your `~/.zshrc` (placed safely after the last p10k‑related line)

The goal is to provide a clean, reproducible, folder‑based environment setup that users can install or remove with a simple double‑click.

---

## 🚀 Features

- Double‑click installation using `install.command`
- Double‑click uninstallation using `uninstall.command`
- Installs everything into a dedicated folder: `~/.qs/`
- Adds sourcing lines to `.zshrc` in the correct location
- Optional Powerlevel10k integration for uv project
- Fully macOS‑compatible (Finder‑safe)
- Idempotent — running it multiple times will **not** duplicate lines

---

## 🔧 Supported Environment Types

qs-env currently supports:

- Classical Python `venv`
- `uv` projects

Other environment managers (Conda, Poetry, Rye, virtualenvwrapper, etc.) are **not supported yet**.

---

## 📥 Installation

### 1. Download or clone the repository

### 2. Make the installer executable (only needed once)

```bash
chmod +x install.command
```

### 3. Double-click `install.command` in Finder

This will:
- Create `~/.qs/`
- Install `.qs` (always)
- Ask whether to install `.p10k-custom.zsh`
- Insert sourcing lines into your `.zshrc` **after** the last p10k‑related line

### 4. Restart your terminal

---

## 🧩 What gets added to `.zshrc`

Depending on your choices, the installer adds:
```bash
[[ -f ~/.qs/.p10k-custom.zsh ]] && source ~/.qs/.p10k-custom.zsh
[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs
```

These lines are inserted immediately **after** the last line containing `p10k` in your `.zshrc`.

---

## 🧹 Uninstallation

### 1. Make the uninstaller executable (only needed once)

```bash
chmod +x uninstall.command
```

### 2. Double‑click `uninstall.command` in Finder

This will:
- Remove the entire ~/.qs/ directory
- Remove legacy files (~/.qs, ~/.qs_default, ~/.p10k-custom.zsh)
- Remove all related lines from .zshrc
- Save a backup as:
```bash
~/.zshrc.bak.qs-uninstall
```

### 3. Restart your terminal

---

## 🛠 Folder Structure

After installation:
```bash
~/.qs/
    .qs
    .p10k-custom.zsh   (optional)
```

---

## 💡 Notes

- The installer is designed specifically for macOS and uses `.command` files so users can install by double‑clicking.
- The `.zshrc` insertion logic is robust: it always finds the last p10k‑related line and inserts your lines directly after it.
- The uninstaller removes everything cleanly and safely.

---

## 🧭 Troubleshooting

### The installer didn’t add lines to `.zshrc`

Check that:
- Your `.zshrc` contains at least one line referencing p10k
- The file is writable
- You restarted your terminal
If you do **not** use p10k, manually add the line to `zshrc`:
```bash
[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs
```

### The custom p10k segment doesn’t show up

Run:
```bash
source ~/.zshrc
```
Or restart your terminal

---

## 📄 License
MIT License — feel free to modify and adapt.
