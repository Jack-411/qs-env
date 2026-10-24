# qs — lightweight python environment helper (PowerShell function)
# Windows port of the qs shell function from qs-env (macOS/Linux).
# Installed to $HOME\.qs\qs.ps1 and sourced from the PowerShell $PROFILE.
# All internals use the qs__ prefix so nothing collides with your own commands.

function qs__IsUvProject([string]$Path) {
    (Test-Path (Join-Path $Path "pyproject.toml")) -and
    (Test-Path (Join-Path $Path ".venv\Scripts\python.exe"))
}

function qs__GetPythonVersion([string]$Path) {
    $py = Join-Path $Path ".venv\Scripts\python.exe"
    if (Test-Path $py) {
        try { return ((& $py --version 2>$null) -split '\s+')[1] } catch { }
    }
    $py = Join-Path $Path "bin\python"   # POSIX-style venv on mounted drives (rare)
    if (Test-Path $py) {
        try { return ((& $py --version 2>$null) -split '\s+')[1] } catch { }
    }
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        Push-Location $Path
        try {
            $out = (& uv run python --version 2>$null)
            if ($LASTEXITCODE -eq 0 -and $out) { return (($out -split '\s+')[1]) }
        } catch { } finally { Pop-Location }
    }
    return "unknown"
}

# Expand ~ and make relative paths absolute so the stored default works
# from any directory.
function qs__ResolvePath([string]$Path) {
    if ($Path -eq "~") { return $HOME }
    if ($Path.StartsWith("~/") -or $Path.StartsWith("~\")) {
        $Path = Join-Path $HOME $Path.Substring(2)
    }
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path (Get-Location).Path $Path
    }
    try { $Path = [System.IO.Path]::GetFullPath($Path) } catch { }
    return $Path.TrimEnd('\', '/')
}

function qs__RootDirs {
    $pwd_now = (Get-Location).Path
    $dirs = @(Get-ChildItem $HOME -Directory -ErrorAction SilentlyContinue)
    if ($pwd_now.TrimEnd('\','/') -ne $HOME.TrimEnd('\','/')) {
        $dirs += @(Get-ChildItem $pwd_now -Directory -ErrorAction SilentlyContinue)
    }
    return $dirs
}

function qs__DeactivateQuiet {
    if (Get-Command deactivate -ErrorAction SilentlyContinue) {
        deactivate 2>$null
    }
}

function qs__ActivateVenv([string]$Venv) {
    $activate = Join-Path $Venv "Scripts\Activate.ps1"
    if (-not (Test-Path $activate)) {
        $activate = Join-Path $Venv "bin\Activate.ps1"
    }
    qs__DeactivateQuiet
    . $activate
    $env:VIRTUAL_ENV_NAME = Split-Path $Venv -Leaf
    Remove-Item Env:UV_PROJECT_ACTIVE, Env:UV_PROJECT_NAME, Env:UV_PROJECT_PYTHON, Env:UV_PROJECT_PATH -ErrorAction SilentlyContinue
    Write-Output "Activated venv '$env:VIRTUAL_ENV_NAME' (Python $(qs__GetPythonVersion $Venv))"
}

function qs__ActivateUvProject([string]$Project) {
    if (-not (Test-Path $Project)) { Write-Output "Not found: $Project"; return }
    $abs = (Resolve-Path $Project).Path
    $pyv = qs__GetPythonVersion $abs
    Set-Location $abs
    $env:UV_PROJECT_ACTIVE = "1"
    $env:UV_PROJECT_NAME = Split-Path $abs -Leaf
    $env:UV_PROJECT_PYTHON = $pyv
    $env:UV_PROJECT_PATH = $abs
    qs__DeactivateQuiet
    Write-Output "Entered uv project '$env:UV_PROJECT_NAME' (Python $pyv)"
}

function qs__ExitUvProject {
    Remove-Item Env:UV_PROJECT_ACTIVE, Env:UV_PROJECT_NAME, Env:UV_PROJECT_PYTHON, Env:UV_PROJECT_PATH -ErrorAction SilentlyContinue
    Set-Location $HOME
    Write-Output "Exited uv project"
}

function qs__ExitVenv {
    qs__DeactivateQuiet
    Write-Output "Deactivated venv"
}

function qs__Doctor {
    Write-Host "`e[34mRunning qs doctor...`e[0m" -ForegroundColor Blue
    Write-Output ""

    if (Test-Path "$HOME\.qs") {
        Write-Host "`e[32m✓ ~/.qs directory exists`e[0m" -ForegroundColor Green
    } else {
        Write-Host "`e[31m✗ ~/.qs directory missing`e[0m" -ForegroundColor Red
    }

    if (Test-Path "$HOME\.qs\qs.ps1") {
        Write-Host "`e[32m✓ ~/.qs/qs.ps1 found`e[0m" -ForegroundColor Green
    } else {
        Write-Host "`e[31m✗ ~/.qs/qs.ps1 missing`e[0m" -ForegroundColor Red
    }

    if (Test-Path "$HOME\.qs\.qs-version") {
        $dver = (Get-Content "$HOME\.qs\.qs-version" -Raw).Trim()
        Write-Host "`e[32m✓ Version file found: $dver`e[0m" -ForegroundColor Green
    } else {
        Write-Host "`e[31m✗ Version file missing`e[0m" -ForegroundColor Red
    }

    if ((Test-Path $PROFILE) -and (Select-String -SimpleMatch -Quiet -Pattern "qs.ps1" -Path $PROFILE)) {
        Write-Host "`e[32m✓ PowerShell profile contains qs source line`e[0m" -ForegroundColor Green
    } else {
        Write-Host "`e[31m✗ PowerShell profile does not contain qs source line`e[0m" -ForegroundColor Red
    }

    $py3 = Get-Command python -ErrorAction SilentlyContinue
    if ($py3) {
        Write-Host "`e[32m✓ python available: $(python --version 2>&1)`e[0m" -ForegroundColor Green
    } else {
        Write-Host "`e[31m✗ python not found`e[0m" -ForegroundColor Red
    }

    if (Get-Command uv -ErrorAction SilentlyContinue) {
        $uvv = (uv --version 2>$null | Select-Object -First 1)
        Write-Host "`e[32m✓ uv available: $uvv`e[0m" -ForegroundColor Green
    } else {
        Write-Host "`e[33m⚠ uv not found (optional)`e[0m" -ForegroundColor Yellow
    }

    if ($env:VIRTUAL_ENV) {
        Write-Host "`e[32m✓ Active environment detected:`e[0m $env:VIRTUAL_ENV" -ForegroundColor Green

        if (Test-Path (Join-Path $env:VIRTUAL_ENV "pyvenv.cfg")) {
            Write-Host "`e[34m  → Classical venv detected`e[0m" -ForegroundColor Blue

            if (Test-Path (Join-Path $env:VIRTUAL_ENV "Scripts\Activate.ps1")) {
                Write-Host "`e[32m    ✓ activate script present`e[0m" -ForegroundColor Green
            } else {
                Write-Host "`e[31m    ✗ activate script missing`e[0m" -ForegroundColor Red
            }

            if (Test-Path (Join-Path $env:VIRTUAL_ENV "Scripts\python.exe")) {
                Write-Host "`e[32m    ✓ python binary present`e[0m" -ForegroundColor Green
            } else {
                Write-Host "`e[31m    ✗ python binary missing`e[0m" -ForegroundColor Red
            }

            if (Get-Command uv -ErrorAction SilentlyContinue) {
                $site = & (Join-Path $env:VIRTUAL_ENV "Scripts\python.exe") -c "import site; print(site.getsitepackages()[0])" 2>$null
                if ($site -and (Test-Path $site)) {
                    if (-not (Get-ChildItem $site -ErrorAction SilentlyContinue)) {
                        Write-Host "`e[33m    ⚠ site-packages empty — environment may not be synced`e[0m" -ForegroundColor Yellow
                        Write-Host "`e[33m      → Run: uv sync`e[0m" -ForegroundColor Yellow
                    } else {
                        Write-Host "`e[32m    ✓ site-packages populated`e[0m" -ForegroundColor Green
                    }
                }
            }
        }

        if ($env:UV_PROJECT_PATH -and (Test-Path (Join-Path $env:UV_PROJECT_PATH ".python-version"))) {
            $pinned = (Get-Content (Join-Path $env:UV_PROJECT_PATH ".python-version") -Raw).Trim()
            $actual = qs__GetPythonVersion $env:UV_PROJECT_PATH
            if ($pinned -and $actual -and $actual -ne "unknown" -and
                -not ($actual.StartsWith($pinned) -or $pinned.StartsWith($actual))) {
                Write-Host "`e[33m    ⚠ uv project python mismatch`e[0m" -ForegroundColor Yellow
                Write-Host "`e[33m      pinned: $pinned  actual: $actual`e[0m" -ForegroundColor Yellow
                Write-Host "`e[33m      → Run: uv sync`e[0m" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "`e[33mℹ No active environment`e[0m" -ForegroundColor Yellow
    }

    Write-Output ""
    Write-Host "`e[34mqs doctor completed.`e[0m" -ForegroundColor Blue
}

function qs {
    $ConfigFile = Join-Path $HOME ".qs_default"

    $DefaultPath = ""
    if (Test-Path $ConfigFile) { $DefaultPath = (Get-Content $ConfigFile -Raw).Trim() }
    if (-not $DefaultPath) { $DefaultPath = Join-Path $HOME "uv-global" }

    $argv = @($args)

    if ($argv.Count -ge 1 -and ($argv[0] -in "--version", "-v")) {
        $vf = Join-Path $HOME ".qs\.qs-version"
        $vtxt = if (Test-Path $vf) { (Get-Content $vf -Raw).Trim() } else { "" }
        if ($vtxt) {
            Write-Output "qs $vtxt"
        } else {
            Write-Output "qs version: unknown (version file missing)"
        }
        return
    }

    if ($argv.Count -ge 1 -and ($argv[0] -in "help", "-help", "--help", "-h")) {
        Write-Output @'
qs                         # toggle uv/venv or enter default
qs default                 # show current default path
qs --set default <path>    # set/change default path
qs list                    # list all venv and uv projects
qs doctor                  # diagnose qs installation and environments
qs <name>                  # activate venv or enter uv project
'@
        return
    }

    if ($argv.Count -ge 1 -and $argv[0] -eq "doctor") {
        qs__Doctor
        return
    }

    if ($argv.Count -ge 1 -and $argv[0] -eq "default") {
        if (qs__IsUvProject $DefaultPath) {
            $pyv = qs__GetPythonVersion $DefaultPath
            Write-Output "Default path: $DefaultPath  (uv project, Python $pyv)"
        } elseif (Test-Path (Join-Path $DefaultPath "Scripts\Activate.ps1")) {
            $pyv = qs__GetPythonVersion $DefaultPath
            Write-Output "Default path: $DefaultPath  (venv, Python $pyv)"
        } else {
            Write-Output "Default path: $DefaultPath  (not a venv or uv project)"
        }
        return
    }

    if ($argv.Count -ge 2 -and $argv[0] -eq "--set" -and $argv[1] -eq "default") {
        if ($argv.Count -lt 3) {
            Write-Output "Usage: qs --set default <path>"
            return
        }
        $resolved = qs__ResolvePath $argv[2]
        Set-Content -Path $ConfigFile -Value $resolved -NoNewline
        if (qs__IsUvProject $resolved) {
            $pyv = qs__GetPythonVersion $resolved
            Write-Output "Default path set to: $resolved  (uv project, Python $pyv)"
        } elseif (Test-Path (Join-Path $resolved "Scripts\Activate.ps1")) {
            $pyv = qs__GetPythonVersion $resolved
            Write-Output "Default path set to: $resolved  (venv, Python $pyv)"
        } else {
            Write-Output "Default path set to: $resolved  (not a venv or uv project)"
        }
        return
    }

    if ($argv.Count -ge 1 -and $argv[0] -eq "list") {
        Write-Output "venv environments:"
        foreach ($d in qs__RootDirs) {
            if (Test-Path (Join-Path $d.FullName "Scripts\Activate.ps1")) {
                Write-Output "  $($d.Name)  (Python $(qs__GetPythonVersion $d.FullName))"
            }
        }
        Write-Output ""
        Write-Output "uv projects:"
        foreach ($d in qs__RootDirs) {
            if (qs__IsUvProject $d.FullName) {
                Write-Output "  $($d.Name)  (Python $(qs__GetPythonVersion $d.FullName))"
            }
        }
        return
    }

    if ($argv.Count -eq 0) {
        if ($env:UV_PROJECT_ACTIVE) { qs__ExitUvProject; return }
        if ($env:VIRTUAL_ENV) { qs__ExitVenv; return }
        if (qs__IsUvProject $DefaultPath) { qs__ActivateUvProject $DefaultPath; return }
        if (Test-Path (Join-Path $DefaultPath "Scripts\Activate.ps1")) { qs__ActivateVenv $DefaultPath; return }
        Write-Output "Default path '$DefaultPath' is not a venv or uv project"
        return
    }

    $needle = $argv[0]
    $target = $null
    foreach ($d in qs__RootDirs) {
        if ($d.Name -like "*$needle*") { $target = $d.FullName; break }
    }

    if (-not $target) {
        Write-Output "No venv or uv project matching '$needle'"
        return
    }

    if (qs__IsUvProject $target) {
        qs__ActivateUvProject $target
    } elseif (Test-Path (Join-Path $target "Scripts\Activate.ps1")) {
        qs__ActivateVenv $target
    } else {
        Write-Output "'$target' is not a venv or uv project"
    }
}
