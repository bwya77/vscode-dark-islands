# Islands Dark Windows uninstaller

param()

$ErrorActionPreference = "Stop"

function ConvertTo-FileUrl {
    param([string]$Path)
    $resolved = [System.IO.Path]::GetFullPath($Path)
    return ([System.Uri]$resolved).AbsoluteUri
}

Write-Host "Islands Dark uninstaller" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$package = Get-Content (Join-Path $scriptDir "package.json") -Raw | ConvertFrom-Json
$extensionDirName = "$($package.publisher).$($package.name)-$($package.version)"
$extensionDir = Join-Path $env:USERPROFILE ".vscode\extensions\$extensionDirName"
$cssUrl = ConvertTo-FileUrl (Join-Path $scriptDir "custom-css\islands-dark.css")

if (Test-Path $extensionDir) {
    Remove-Item -Recurse -Force $extensionDir
    Write-Host "Removed native Islands Dark color theme from $extensionDir." -ForegroundColor Green
} else {
    Write-Host "Native Islands Dark color theme folder was not found at $extensionDir." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Finish manually:" -ForegroundColor Yellow
Write-Host "1. Run Command Palette > Disable Custom CSS and JS to restore VS Code's patched workbench file."
Write-Host "2. Remove this URL from vscode_custom_css.imports in settings.json:"
Write-Host "   $cssUrl"
Write-Host "3. Change to another color theme if VS Code is still using Islands Dark."
