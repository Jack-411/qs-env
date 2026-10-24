# qs-env Windows installer
# One-liner:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Jack-411/qs-env/main/windows/install.ps1)))
#
# Optional theme (requires the `oh-my-posh` CLI on PATH):
#   & ([scriptblock]::Create((irm .../install.ps1))) -WithTheme
#
# Writes ONLY inside $HOME\.qs and the managed block in the PowerShell
# $PROFILE. Idempotent: the block is rewritten in place, never duplicated.
# A timestamped backup of the profile is taken before every change.

param([switch]$WithTheme)
$ErrorActionPreference = "Stop"

# Resolve repo files: works from a clone, or self-fetches for the one-liner.
$RepoFiles = $PSScriptRoot
if (-not $RepoFiles -or -not (Test-Path (Join-Path $RepoFiles "qs.ps1"))) {
    $RepoFiles = Join-Path $env:TEMP "qs-env-bootstrap"
    Remove-Item $RepoFiles -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $RepoFiles | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $RepoFiles "Theme") | Out-Null
    $base = "https://raw.githubusercontent.com/Jack-411/qs-env/main/windows"
    Invoke-WebRequest -UseBasicParsing "$base/qs.ps1" -OutFile (Join-Path $RepoFiles "qs.ps1")
    Invoke-WebRequest -UseBasicParsing "$base/Theme/custom.omp.json" -OutFile (Join-Path $RepoFiles "Theme\custom.omp.json")
}

$QsHome = Join-Path $HOME ".qs"
New-Item -ItemType Directory -Force -Path $QsHome | Out-Null
Copy-Item (Join-Path $RepoFiles "qs.ps1") (Join-Path $QsHome "qs.ps1") -Force

# Version: prefer local clone's code/qs-version, else fetch it.
$Version = $null
foreach ($vf in @((Join-Path (Split-Path $RepoFiles -Parent) "code/qs-version"))) {
    if (Test-Path $vf) { $Version = (Get-Content $vf -Raw).Trim(); break }
}
if (-not $Version) {
    try { $Version = (Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/Jack-411/qs-env/main/code/qs-version").Content.Trim() } catch { }
}
if (-not $Version) { $Version = "unknown" }
Set-Content -Path (Join-Path $QsHome ".qs-version") -Value $Version -NoNewline

if ($WithTheme) {
    New-Item -ItemType Directory -Force -Path (Join-Path $QsHome "Theme") | Out-Null
    Copy-Item (Join-Path $RepoFiles "Theme\custom.omp.json") (Join-Path $QsHome "Theme\custom.omp.json") -Force
}

# --- managed $PROFILE block -------------------------------------------
if (-not $PROFILE) {
    $userDocs = [Environment]::GetFolderPath("MyDocuments")
    $PROFILE_PATH = Join-Path $userDocs "PowerShell\Microsoft.PowerShell_profile.ps1"
} else {
    $PROFILE_PATH = $PROFILE
}
$profileDir = Split-Path $PROFILE_PATH -Parent
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
if (-not (Test-Path $PROFILE_PATH)) { New-Item -ItemType File -Force -Path $PROFILE_PATH | Out-Null }

$backup = "$PROFILE_PATH.bak.qs-$(Get-Date -Format yyyyMMddHHmmss)"
Copy-Item $PROFILE_PATH $backup

$blockLines = @(
    "# >>> qs-env >>>",
    'if (Test-Path "$HOME\.qs\qs.ps1") { . "$HOME\.qs\qs.ps1" }'
)
if ($WithTheme) {
    $blockLines += 'if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { oh-my-posh init pwsh --config "$HOME\.qs\Theme\custom.omp.json" | Invoke-Expression }'
}
$blockLines += "# <<< qs-env <<<"
$block = $blockLines -join "`n"

$content = Get-Content $PROFILE_PATH -Raw -ErrorAction SilentlyContinue
if ($content -and $content.Contains("# >>> qs-env >>>")) {
    $pattern = "(?s)# >>> qs-env >>>.*?# <<< qs-env <<<"
    $content = [regex]::Replace($content, $pattern, { param($m) $block })
    Set-Content -Path $PROFILE_PATH -Value $content -NoNewline
    Write-Host "qs-env: managed profile block updated in place."
} else {
    Add-Content -Path $PROFILE_PATH -Value "`n$block"
    Write-Host "qs-env: managed profile block appended to profile."
}

Write-Host ""
Write-Host "qs-env installed (version $Version)." -ForegroundColor Green
Write-Host "  ~/.qs/qs.ps1      helper function"
if ($WithTheme) { Write-Host "  ~/.qs/Theme/      Oh My Posh theme (loaded from profile block)" }
Write-Host "  profile backup:   $backup"
Write-Host ""
Write-Host "Open a new PowerShell window, then try:  qs doctor"
