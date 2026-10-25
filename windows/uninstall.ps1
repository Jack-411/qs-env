# qs-env Windows uninstaller
# One-liner:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Jack-411/qs-env/main/windows/uninstall.ps1)))
#
# Removes ONLY the managed block (between the >>> qs-env <<< markers) from
# the PowerShell $PROFILE — never anything that merely contains "qs" — and
# deletes ~/.qs/. A backup is saved as $PROFILE.bak.qs-uninstall.

$PROFILE_PATH = $PROFILE
if (Test-Path $PROFILE_PATH) {
    $backup = "$PROFILE_PATH.bak.qs-uninstall"
    Copy-Item $PROFILE_PATH $backup -Force

    $content = Get-Content $PROFILE_PATH -Raw
    $pattern = "(?s)# >>> qs-env >>>.*?# <<< qs-env <<<\r?\n?"
    if ($content -match "# >>> qs-env >>>") {
        $newContent = [regex]::Replace($content, $pattern, "")
        Set-Content -Path $PROFILE_PATH -Value $newContent -NoNewline
        Write-Host "qs-env: managed block removed from profile (backup: $backup)."
    } else {
        Write-Host "qs-env: no managed block found in profile; left untouched."
    }
}

if (Test-Path "$HOME\.qs") {
    Remove-Item "$HOME\.qs" -Recurse -Force
    Write-Host "qs-env: ~/.qs deleted."
}

Write-Host "qs-env uninstalled. Open a new PowerShell window to see the change."
