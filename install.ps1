# Islands Dark minimal Windows installer

param()

$ErrorActionPreference = "Stop"

function ConvertTo-FileUrl {
    param([string]$Path)
    $resolved = (Resolve-Path $Path).Path
    return ([System.Uri]$resolved).AbsoluteUri
}

function Find-CodeCommand {
    $codePath = Get-Command "code" -ErrorAction SilentlyContinue
    if ($codePath) { return $codePath.Source }

    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )
    foreach ($candidate in $possiblePaths) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

Write-Host "Islands Dark minimal installer" -ForegroundColor Cyan
Write-Host "This installs only the native color theme helper and prints the manual CSS setup." -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$package = Get-Content (Join-Path $scriptDir "package.json") -Raw | ConvertFrom-Json
$extensionDirName = "$($package.publisher).$($package.name)-$($package.version)"
$extensionDir = Join-Path $env:USERPROFILE ".vscode\extensions\$extensionDirName"
$cssUrl = ConvertTo-FileUrl (Join-Path $scriptDir "custom-css\islands-dark.css")

Write-Host "Installing native Islands Dark color theme to $extensionDir..."
if (Test-Path $extensionDir) {
    Remove-Item -Recurse -Force $extensionDir
}
New-Item -ItemType Directory -Path $extensionDir -Force | Out-Null
Copy-Item (Join-Path $scriptDir "package.json") $extensionDir -Force
Copy-Item (Join-Path $scriptDir "themes") $extensionDir -Recurse -Force

$codeCommand = Find-CodeCommand
if ($codeCommand) {
    Write-Host "Installing Custom CSS and JS Loader..."
    & $codeCommand --install-extension be5invis.vscode-custom-css --force | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Could not install Custom CSS and JS Loader automatically. Install it manually from VS Code Extensions." -ForegroundColor Yellow
    }
} else {
    Write-Host "VS Code CLI 'code' was not found. Install Custom CSS and JS Loader manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Theme helper installed. Finish manually:" -ForegroundColor Green
Write-Host "1. Install the .otf files from ./fonts if you want the exact typography."
Write-Host "2. Add this to VS Code settings.json:"
Write-Host ""
Write-Host '   "workbench.colorTheme": "Islands Dark",'
Write-Host '   "vscode_custom_css.statusbar": true,'
Write-Host '   "vscode_custom_css.imports": ['
Write-Host "     `"$cssUrl`""
Write-Host '   ]'
Write-Host ""
Write-Host "3. Run Command Palette > Enable Custom CSS and JS, or Reload Custom CSS and JS."
Write-Host "4. Reload VS Code."
Write-Host ""
Write-Host "This script did not edit settings.json or install fonts."
