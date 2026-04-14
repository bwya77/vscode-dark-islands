# Islands Dark Bootstrap Installer for Windows
# One-liner: irm https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.ps1 | iex

param()

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/bwya77/vscode-dark-islands.git"
$Branch = "main"
$InstallDir = Join-Path $env:TEMP "islands-dark-temp"

Write-Host "Downloading Islands Dark..." -ForegroundColor Cyan
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}

git clone $RepoUrl $InstallDir --quiet --branch $Branch

Write-Host "Running installer..." -ForegroundColor Cyan
& (Join-Path $InstallDir "install.ps1")

Write-Host "Temporary files kept at: $InstallDir" -ForegroundColor Yellow
