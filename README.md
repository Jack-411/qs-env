# 📦 qs-env

A lightweight Python environment helper — one `qs` command to jump into and out of **venv**s and **uv** projects, with a prompt indicator for the active uv project.

- 🍎 **macOS / 🐧 Linux** — zsh function + optional **Powerlevel10k** segment (`macOS/`, `code/`)
- 🪟 **Windows** — PowerShell function + optional **Oh My Posh** segment (`windows/`)

Installs and uninstalls in one step on every platform. Both installers own only a *managed block* in your shell config — rewritten in place, never duplicated, removed exactly on uninstall.

---

## 🚀 Install

### macOS / Linux (zsh)

```bash
curl -fsSL https://raw.githubusercontent.com/Jack-411/qs-env/main/macOS/install.sh | bash
```

Options:

```bash
# force on/off the p10k segment (default: auto — only if your .zshrc uses p10k)
curl -fsSL .../macos/install.sh | QS_ENV_P10K=yes bash
curl -fsSL .../macos/install.sh | QS_ENV_P10K=no  bash
```

Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/Jack-411/qs-env/main/macOS/uninstall.sh | bash
```

Installs `~/.qs/.qs` (+ optional `~/.qs/.p10k-custom.zsh`) and a managed block in `~/.zshrc`, placed after your last p10k-related line:

```bash
# >>> qs-env >>>
[[ -f ~/.qs/.qs ]] && source ~/.qs/.qs
[[ -f ~/.qs/.p10k-custom.zsh ]] && source ~/.qs/.p10k-custom.zsh
# <<< qs-env <<<
```

The p10k segment is the *only* prompt change, and only when p10k is detected — your prompt theme is never otherwise touched. Uninstall removes `~/.qs/` and exactly the managed lines (backup: `~/.zshrc.bak.qs-uninstall`).

> 🖱 **Double-click (Finder):** `macOS/install.command` / `uninstall.command` work too. Because browsers quarantine unsigned downloads, the first run needs **right-click → Open → Open** (Gatekeeper — no unsigned `.command` can skip this). The `curl` one-liner never triggers it, and `git clone` downloads are never quarantined.

### Windows (PowerShell 5.1 / 7)

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Jack-411/qs-env/main/windows/install.ps1)))

# optionally also place the bundled Oh My Posh theme:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Jack-411/qs-env/main/windows/install.ps1))) -WithTheme
```

Uninstall:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Jack-411/qs-env/main/windows/uninstall.ps1)))
```

Installs to `~\.qs\` and manages a `# >>> qs-env >>> … # <<< qs-env <<<` block in your PowerShell `$PROFILE` (timestamped backup before every change; uninstall removes exactly the block).

---

## 🎨 Prompt integration

qs-env **never takes over your prompt** on any platform — it never removes or replaces an existing theme. Its only prompt contribution is a small yellow segment that appears **only when `qs` has entered a uv project** (venv activation is already shown by p10k's `virtualenv` / Oh My Posh's `python` segment).

| Platform | Prompt system | What qs-env adds |
|---|---|---|
| macOS / Linux | Powerlevel10k | `uv_project` custom segment (`~/.qs/.p10k-custom.zsh`), registered in `~/.p10k.zsh` only when p10k is detected |
| Windows | Oh My Posh (or anything you like) | Nothing automatically. With `-WithTheme`, the theme file `~\.qs\Theme\custom.omp.json` (a full OMP theme incl. the uv segment) is placed for you. To add just the segment to **your own** OMP config: `.\add-uv-segment.ps1 -ConfigPath your.omp.json` (inserts after the `python` segment, timestamped backup, idempotent) |

Why a custom segment? Neither p10k nor Oh My Posh has a built-in "uv project entered via helper" indicator — OMP's `python` segment only reflects `VIRTUAL_ENV`. `qs <uv-project>` exports `UV_PROJECT_NAME` / `UV_PROJECT_PYTHON`, and the segment renders them.

---

## 🧑‍💻 Usage

Both implementations support:

```
qs <name>                  # activate venv / enter uv project (fuzzy match)
qs                         # toggle out (or enter the default project)
qs list                    # list projects
qs default                 # show default target
qs --set default <path>    # set default (~ and relative paths expanded)
qs doctor                  # diagnose installation
qs help                    # full usage
```

### Project search (Windows)

Search order for `qs <name>`:
1. `$HOME` and the current directory (one level — instant)
2. Deep-scan cache (`~\.qs\.qs-index.json`)
3. Extra roots you added: `qs --add root D:\projects` (`qs roots`, `qs --remove root <path>`)
4. Last resort: **every fixed drive** (depth-limited, system folders excluded, results cached) — projects on `D:`/`E:` are found even when kept outside your home

`qs list` includes extra-root finds (full paths shown); `qs list --all` also scans every drive. `qs rehash` clears the cache (e.g. after adding a new disk). venvs are detected via `Scripts\Activate.ps1`; `uv` is optional but recommended.

*(macOS/Linux searches `$HOME` + current directory, like the classic shell version.)*

---

## 🛠 Repo structure

```
code/                    macOS/Linux shell function + p10k segment sources
macOS/                   installer, uninstaller, double-click .command wrappers
windows/                 PowerShell qs function, install/uninstall,
                         add-uv-segment.ps1, Theme/custom.omp.json
```

Installed layout — macOS/Linux: `~/.qs/{.qs,.qs-version,.p10k-custom.zsh}` · Windows: `~\.qs\{qs.ps1,.qs-version,Theme\,\.qs-index.json}`

---

## 💡 Notes

- Installers write only into `~/.qs` and the managed config block; idempotent on every platform.
- macOS script runs on stock `/bin/bash` 3.2 — no Homebrew prerequisites.
- Windows: works in Windows PowerShell 5.1 and pwsh 7+.

## 🧭 Troubleshooting

- **`qs: command not found`** — open a new terminal (Windows: new PowerShell window), or `source ~/.zshrc`; then `qs doctor`.
- **uv segment not showing** — you must `qs` into a *uv project* (venv shows via the normal python/virtualenv segment); `qs doctor` lists what's loaded.
- **Windows drive not scanned** — check the `scanning drives: …` line; if a disk is missing there, PowerShell itself can't see the mount. `qs rehash` after adding drives.

## 📄 License
MIT License — feel free to modify and adapt.
