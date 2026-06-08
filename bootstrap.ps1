# Islands Dark Theme Bootstrap Installer for Windows
# One-liner: irm https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.ps1 | iex

param()

$ErrorActionPreference = "Stop"

echo '🏝️  Islands Dark Theme Bootstrap Installer'
echo "=========================================="
echo ""

$RepoUrl = "https://github.com/bwya77/vscode-dark-islands.git"
$Branch = "main"
$TempRoot = if ([string]::IsNullOrWhiteSpace($env:TEMP)) { [System.IO.Path]::GetTempPath() } else { $env:TEMP }
$InstallDir = Join-Path $TempRoot ("islands-dark-temp-{0}" -f ([guid]::NewGuid().ToString("N")))

echo '📥 Step 1: Downloading Islands Dark...'
echo "   Repository: $RepoUrl"

# Remove old temp directory if exists
if (Test-Path -LiteralPath $InstallDir) {
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Clone repository
try {
    git clone $RepoUrl $InstallDir --quiet --branch $Branch
    if ($LASTEXITCODE -ne 0) {
        throw "git clone exited with code $LASTEXITCODE"
    }
} catch {
    echo '❌ Failed to download Islands Dark'
    echo "   Make sure Git is installed: https://git-scm.com/download/win"
    echo "   $($_.Exception.Message)"
    return
}

echo '✓ Downloaded successfully'
echo ""

echo '🚀 Step 2: Running installer...'
echo ""

# Run installer
$InstallerPath = Join-Path $InstallDir "install.ps1"
$PowerShellPath = (Get-Command "powershell.exe" -ErrorAction SilentlyContinue).Source
if (-not $PowerShellPath) {
    $PowerShellPath = (Get-Process -Id $PID).Path
}

try {
    & $PowerShellPath -NoProfile -ExecutionPolicy Bypass -File $InstallerPath
    if ($LASTEXITCODE -ne 0) {
        throw "Installer exited with code $LASTEXITCODE"
    }
} catch {
    echo "❌ Installation failed"
    echo $_.Exception.Message
    return
}

# Cleanup
echo ""
echo '🧹 Step 3: Cleaning up...'
$remove = Read-Host "   Remove temporary files? (y/n)"
if ($remove -eq 'y' -or $remove -eq 'Y') {
    try {
        Remove-Item -LiteralPath $InstallDir -Recurse -Force
        echo '✓ Temporary files removed'
    } catch {
        echo "   Could not remove temporary files:"
        echo "   $($_.Exception.Message)"
        echo "   Files kept at: $InstallDir"
    }
} else {
    echo "   Files kept at: $InstallDir"
}

echo ""
echo '🎉 Done! Enjoy your Islands Dark theme!'
