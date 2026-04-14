# Islands Dark Windows installer

param(
    [switch]$SkipFonts
)

$ErrorActionPreference = "Stop"

function ConvertTo-FileUrl {
    param([string]$Path)
    $resolved = (Resolve-Path $Path).Path
    return ([System.Uri]$resolved).AbsoluteUri
}

function Strip-Jsonc {
    param([string]$Text)

    $builder = New-Object System.Text.StringBuilder
    $inString = $false
    $escaped = $false
    $lineComment = $false
    $blockComment = $false

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]
        $next = if ($i + 1 -lt $Text.Length) { $Text[$i + 1] } else { [char]0 }

        if ($lineComment) {
            if ($ch -eq "`n") {
                $lineComment = $false
                [void]$builder.Append($ch)
            }
            continue
        }

        if ($blockComment) {
            if ($ch -eq '*' -and $next -eq '/') {
                $blockComment = $false
                $i++
            }
            continue
        }

        if ($inString) {
            [void]$builder.Append($ch)
            if ($escaped) {
                $escaped = $false
            } elseif ($ch -eq '\') {
                $escaped = $true
            } elseif ($ch -eq '"') {
                $inString = $false
            }
            continue
        }

        if ($ch -eq '"') {
            $inString = $true
            [void]$builder.Append($ch)
            continue
        }

        if ($ch -eq '/' -and $next -eq '/') {
            $lineComment = $true
            $i++
            continue
        }

        if ($ch -eq '/' -and $next -eq '*') {
            $blockComment = $true
            $i++
            continue
        }

        [void]$builder.Append($ch)
    }

    return ($builder.ToString() -replace ',\s*([}\]])', '$1')
}

function Read-SettingsObject {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return [ordered]@{} }
    $raw = Get-Content $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return [ordered]@{} }
    $parsed = (Strip-Jsonc $raw) | ConvertFrom-Json
    $result = [ordered]@{}
    $parsed.PSObject.Properties | ForEach-Object { $result[$_.Name] = $_.Value }
    return $result
}

function Write-SettingsObject {
    param([string]$Path, [hashtable]$Settings)
    $json = [PSCustomObject]$Settings | ConvertTo-Json -Depth 100
    Set-Content -Path $Path -Value $json -Encoding UTF8
}

function Copy-ExtensionItem {
    param([string]$Name, [string]$Destination)
    $source = Join-Path $scriptDir $Name
    if (Test-Path $source) {
        Copy-Item $source $Destination -Recurse -Force
    }
}

Write-Host "Islands Dark installer" -ForegroundColor Cyan
Write-Host "This installs the theme, Custom CSS and JS Loader, fonts, and a CSS import setting." -ForegroundColor Cyan
Write-Host "It merges settings instead of replacing your settings.json." -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$package = Get-Content (Join-Path $scriptDir "package.json") -Raw | ConvertFrom-Json
$extensionDirName = "$($package.publisher).$($package.name)-$($package.version)"
$extensionDir = Join-Path $env:USERPROFILE ".vscode\extensions\$extensionDirName"

$codePath = Get-Command "code" -ErrorAction SilentlyContinue
if (-not $codePath) {
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )
    foreach ($candidate in $possiblePaths) {
        if (Test-Path $candidate) {
            $codePath = Get-Item $candidate
            break
        }
    }
}
if (-not $codePath) {
    throw "VS Code CLI 'code' was not found. Install VS Code or add the code command to PATH."
}

Write-Host "Installing Islands Dark theme extension to $extensionDir..."
if (Test-Path $extensionDir) {
    Remove-Item -Recurse -Force $extensionDir
}
New-Item -ItemType Directory -Path $extensionDir -Force | Out-Null
Copy-ExtensionItem "package.json" $extensionDir
Copy-ExtensionItem "README.md" $extensionDir
Copy-ExtensionItem "themes" $extensionDir
Copy-ExtensionItem "custom-css" $extensionDir
Copy-ExtensionItem "assets" $extensionDir
Copy-ExtensionItem "fonts" $extensionDir
Copy-ExtensionItem "icon.png" $extensionDir

Write-Host "Installing Custom CSS and JS Loader..."
& $codePath.Source --install-extension be5invis.vscode-custom-css --force | Out-Host

if (-not $SkipFonts) {
    Write-Host "Installing bundled Bear Sans UI fonts..."
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
    Get-ChildItem (Join-Path $scriptDir "fonts\*.otf") -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName $fontDir -Force -ErrorAction SilentlyContinue
    }
}

$cssPath = Join-Path $extensionDir "custom-css\islands-dark.css"
$settingsDir = Join-Path $env:APPDATA "Code\User"
New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
$settingsFile = Join-Path $settingsDir "settings.json"
if (Test-Path $settingsFile) {
    $backup = "$settingsFile.pre-islands-dark"
    Copy-Item $settingsFile $backup -Force
    Write-Host "Backed up settings to $backup" -ForegroundColor Yellow
}

$settings = Read-SettingsObject $settingsFile
$cssUrl = ConvertTo-FileUrl $cssPath
$imports = @()
if ($settings.Contains('vscode_custom_css.imports') -and $settings['vscode_custom_css.imports']) {
    $imports = @($settings['vscode_custom_css.imports'])
}
if ($imports -notcontains $cssUrl) {
    $imports += $cssUrl
}
$settings['vscode_custom_css.imports'] = $imports
$settings['vscode_custom_css.statusbar'] = $true
$settings['workbench.colorTheme'] = 'Islands Dark'
Write-SettingsObject $settingsFile $settings

Write-Host ""
Write-Host "Installed. Final step:" -ForegroundColor Green
Write-Host "1. Restart VS Code as Administrator if your install directory requires it."
Write-Host "2. Run Command Palette > Enable Custom CSS and JS, or Reload Custom CSS and JS."
Write-Host "3. Reload VS Code."
Write-Host ""
Write-Host "CSS import added: $cssUrl"