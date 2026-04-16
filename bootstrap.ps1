# Islands Dark Bootstrap Installer for Windows
# One-liner: irm https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.ps1 | iex

param()

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/bwya77/vscode-dark-islands.git"
$Branch = "main"
$InstallDir = Join-Path $env:USERPROFILE "vscode-dark-islands"

if (Test-Path (Join-Path $InstallDir ".git")) {
    Write-Host "Updating Islands Dark at $InstallDir..." -ForegroundColor Cyan
    git -C $InstallDir pull --ff-only
} elseif (Test-Path $InstallDir) {
    throw "Install directory already exists but is not a git checkout: $InstallDir"
} else {
    Write-Host "Downloading Islands Dark to $InstallDir..." -ForegroundColor Cyan
    git clone $RepoUrl $InstallDir --quiet --branch $Branch
}

Write-Host "Running installer..." -ForegroundColor Cyan
& (Join-Path $InstallDir "install.ps1")

Write-Host "Keep this folder in place. The CSS import points to it: $InstallDir" -ForegroundColor Yellow
