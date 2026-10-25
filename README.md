# 📦 qs-env

A lightweight python environment helper for macOS and Windows that installs:

- A hidden shell function file: `~/.qs/.qs`
- An optional Powerlevel10k custom segment: `~/.qs/.p10k-custom.zsh`
- A **managed block** in your `~/.zshrc` (placed after your last p10k‑related line, or at the end)

The goal is a clean, reproducible, folder‑based environment setup that installs and uninstalls in one step, from any Mac.

---

## 🚀 One‑click install (recommended)

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/Jack-411/qs-env/main/install.sh | bash
```

Options:

```bash
# force on/off the p10k segment (default: auto — only if your .zshrc uses p10k)
curl -fsSL .../install.sh | QS_ENV_P10K=yes bash
curl -fsSL .../install.sh | QS_ENV_P10K=no  bash
```

### 🧹 Uninstall (one line)

```bash
curl -fsSL https://raw.githubusercontent.com/Jack-411/qs-env/main/uninstall.sh | bash
```

Removes `~/.qs/` and **only** the exact lines qs-env added to your `.zshrc` — never anything that merely contains "qs". A backup is saved as `~/.zshrc.bak.qs-uninstall`.

---

## 🖱 Double‑click install (Finder)

The `macOS/` folder also contains `install.command` / `uninstall.command` for double‑clicking.

> **About the macOS security prompt.** Files downloaded in a browser carry a *quarantine* flag, and macOS blocks unsigned scripts from launching with a plain double‑click — that's Gatekeeper, and no `.command` file can dodge it without a paid Apple Developer signature. The one‑time workaround: **right‑click → Open → Open**. (Installing via the `curl` one‑liner above never hits this at all, which is why it's the recommended path. `git clone` downloads also never set the quarantine flag.)

---

## 🪟 Windows (PowerShell)

Same `qs` features as macOS/Linux — toggle/enter projects, `qs <name>`, `qs list`, `qs default`, `qs --set default <path>`, `qs doctor`, `qs help` — implemented as a PowerShell function (`windows/qs.ps1`).

From PowerShell:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Jack-411/qs-env/main/windows/install.ps1)))

# optionally also install the bundled Oh My Posh theme (needs the oh-my-posh CLI):
& ([scriptblock]::Create((irm .../windows/install.ps1))) -WithTheme
```

Uninstall:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Jack-411/qs-env/main/windows/uninstall.ps1)))
```

Installs to `~\.qs\` and manages a `# >>> qs-env >>> … # <<< qs-env <<<` block in your PowerShell `$PROFILE` — rewritten in place, never duplicated, timestamped backup before every change, and uninstall removes exactly the block (never anything that merely contains "qs").

**Prompt policy (same philosophy as the p10k segment on macOS): qs-env never takes over your prompt.** With `-WithTheme`, the theme file (your Oh My Posh config + a yellow `uv_project` segment that shows only when qs is *inside* a uv project — venvs already have the built-in `python` segment) is installed to `~\.qs\Theme\custom.omp.json`. If your profile already initialises Oh My Posh, qs-env detects it, changes nothing, and just tells you where the theme file is; an init line is added only when you have none.

### Project search

Search order for `qs <name>`:
1. `$HOME` and the current directory (one level — instant, like the shell version)
2. Deep-scan cache (`~\.qs\.qs-index.json`, refreshed automatically)
3. Extra roots you added: `qs --add root D:\projects` (depth-limited recursive search; `qs roots`, `qs --remove root`, `qs list` includes them, `qs list --all` scans every fixed drive)
4. Last resort: every fixed drive, depth-limited with system folders excluded — so projects on `D:`, `E:` … are found even when someone keeps them outside your home. `qs rehash` clears the cache.

Windows notes: venvs are detected via `Scripts\Activate.ps1` (the old `D:\` hardcoded search is gone — see Project search above); `uv` is optional but recommended.

---

## 🧩 What gets added to .zshrc

```bash
# >>> qs-env >>>
[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs
[[ -f ~/.qs/.p10k-custom.zsh ]] && source ~/.qs/.p10k-custom.zsh
# <<< qs-env <<<
```

The block between the markers is *owned by qs-env*: reinstalling rewrites it in place (never duplicates), uninstalling removes exactly it. A timestamped backup of your `.zshrc` is taken before every install.

---

## 🧑‍💻 Usage

After installation, the `qs` function is available in every new terminal session.

qs currently supports:

- Classical Python `venv`
- `uv` projects

### 1. Enter a uv project or activate a venv

```bash
qs <name>
```

If `qs` is run without a name, it goes to the default project; change it with:

```bash
qs --set default <path>     # ~ and relative paths are expanded and stored absolute
```

### 2. See all names

```bash
qs list
```

### 3. Full usage detail

```bash
qs help
```

### 4. Check the qs environment

```bash
qs doctor
```

---

## 🛠 Folder Structure

After installation:
```bash
~/.qs/
    .qs
    .qs-version
    .p10k-custom.zsh   (optional)
```

---

## 💡 Notes

- The installer writes only inside `~/.qs/` and the managed block in `~/.zshrc`.
- Idempotent — running it multiple times re-writes the managed block, never duplicates lines.
- Works on stock macOS `/bin/bash` (3.2) — no Homebrew prerequisites.

---

## 🧭 Troubleshooting

### `qs: command not found`

Open a new terminal, or `source ~/.zshrc`. Then `qs doctor` will tell you exactly what's wrong.

### The managed block is missing from .zshrc

Re-run the installer, or add the two lines above manually.

### The custom p10k segment does not show up

`source ~/.zshrc` or restart the terminal; check `qs doctor`.

---

## 📄 License
MIT License — feel free to modify and adapt.
