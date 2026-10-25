# qs-env: add the uv_project prompt segment to an existing Oh My Posh config.
#
# Oh My Posh has no built-in segment showing the uv project qs-env entered
# (its `python` segment reflects VIRTUAL_ENV only). qs-env exports
# UV_PROJECT_NAME / UV_PROJECT_PYTHON when you `qs <uv-project>`; this script
# injects the matching yellow text segment into YOUR current OMP theme,
# right after the `python` segment when present (else appended to the first
# prompt block). Your prompt is otherwise untouched, and a timestamped
# backup is written next to the config.
#
# Usage:
#   .\add-uv-segment.ps1 -ConfigPath D:\Documents\Theme\custom.omp.json
#   .\add-uv-segment.ps1            # uses ~\.qs\Theme\custom.omp.json
param(
    [string]$ConfigPath = (Join-Path $HOME ".qs\Theme\custom.omp.json")
)
$ErrorActionPreference = "Stop"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Theme file not found: $ConfigPath"
    Write-Error "Run the installer first (it ships ~/.qs/Theme/custom.omp.json), or pass -ConfigPath your.omp.json"
    exit 1
}

$json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$marker = 'UV_PROJECT_NAME'   # matches both $env: and $(env:) spellings

$uvSegment = [pscustomobject]@{
    type       = "text"
    style      = "powerline"
    background = "#FFDF00"
    foreground = "#44536E"
    template   = "{{ if .Env.UV_PROJECT_NAME }}  {{ .Env.UV_PROJECT_NAME }} ({{ .Env.UV_PROJECT_PYTHON }}) {{ end }}"
}

# Already there? (idempotent)
foreach ($block in @($json.blocks)) {
    foreach ($seg in @($block.segments)) {
        if ($seg.template -and $seg.template -like "*$marker*") {
            Write-Host "uv_project segment already present in $ConfigPath - nothing to do."
            exit 0
        }
    }
}

$done = $false
foreach ($block in @($json.blocks)) {
    if ($block.type -ne "prompt" -or -not $block.segments) { continue }
    $segs = @($block.segments)
    $pyIdx = -1
    for ($i = 0; $i -lt $segs.Count; $i++) {
        if ($segs[$i].type -eq "python") { $pyIdx = $i; break }
    }
    if ($pyIdx -ge 0 -and ($pyIdx + 1) -le ($segs.Count - 1)) {
        $block.segments = @($segs[0..$pyIdx]) + $uvSegment + @($segs[($pyIdx + 1)..($segs.Count - 1)])
    } else {
        $block.segments = $segs + $uvSegment
    }
    $done = $true
    break   # first prompt block only (left prompt)
}

if (-not $done) {
    Write-Error "No prompt block found in $ConfigPath - add the segment manually (see Theme/custom.omp.json in the repo)."
    exit 1
}

$backup = "$ConfigPath.qs-backup.$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item $ConfigPath $backup
$json | ConvertTo-Json -Depth 100 | Set-Content $ConfigPath -Encoding UTF8
Write-Host "Added uv_project segment to $ConfigPath"
Write-Host "  backup: $backup"
Write-Host "Reload your prompt (new terminal, or re-run your oh-my-posh init) and 'qs <uvproject>' to see it."
