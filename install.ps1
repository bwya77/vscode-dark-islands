# Islands Dark Theme Installer for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Installer for Windows" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Function to find VS Code command in common locations
function Find-VSCode {
    param([string]$Command, [string]$DisplayName)

    $cmdPath = Get-Command $Command -ErrorAction SilentlyContinue
    if ($cmdPath) { return $true }

    # Try common installation locations
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft $DisplayName\bin\$Command.cmd",
        "$env:ProgramFiles\Microsoft $DisplayName\bin\$Command.cmd",
        "${env:ProgramFiles(x86)}\Microsoft $DisplayName\bin\$Command.cmd"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            return $true
        }
    }
    return $false
}

# Detect VS Code or VS Code Insiders
$codeCmd = ""
$vscodeDir = ""

if (Find-VSCode "code" "VS Code") {
    $codeCmd = "code"
    $vscodeDir = "vscode"
} elseif (Find-VSCode "code-insiders" "VS Code Insiders") {
    $codeCmd = "code-insiders"
    $vscodeDir = "vscode-insiders"
}

# Exit if neither found
if (-not $codeCmd) {
    Write-Host "Error: VS Code CLI not found!" -ForegroundColor Red
    Write-Host "Please install VS Code or VS Code Insiders and make sure the CLI command is in your PATH."
    Write-Host "You can do this by:"
    Write-Host "  1. Open VS Code or VS Code Insiders"
    Write-Host "  2. Press Ctrl+Shift+P"
    Write-Host "  3. Type 'Shell Command: Install code command in PATH'"
    exit 1
}

Write-Host "$codeCmd CLI found" -ForegroundColor Green

# Set paths based on detected version
$extDirBase = "$env:USERPROFILE\.$vscodeDir"
$settingsDirBase = if ($vscodeDir -eq "vscode") { "$env:APPDATA\Code" } else { "$env:APPDATA\Code - Insiders" }

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "Step 1: Installing Islands Dark theme extension..."

# Install by copying to VS Code extensions directory
$extDir = "$extDirBase\extensions\bwya77.islands-dark-1.0.0"
if (Test-Path $extDir) {
    Remove-Item -Recurse -Force $extDir
}
New-Item -ItemType Directory -Path $extDir -Force | Out-Null
Copy-Item "$scriptDir\package.json" "$extDir\" -Force
Copy-Item "$scriptDir\themes" "$extDir\themes" -Recurse -Force

if (Test-Path "$extDir\themes") {
    Write-Host "Theme extension installed to $extDir" -ForegroundColor Green
} else {
    Write-Host "Failed to install theme extension" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Installing Custom UI Style extension..."
try {
    $output = & $codeCmd --install-extension subframe7536.custom-ui-style --force 2>&1
    Write-Host "Custom UI Style extension installed" -ForegroundColor Green
} catch {
    Write-Host "Could not install Custom UI Style extension automatically" -ForegroundColor Yellow
    Write-Host "   Please install it manually from the Extensions marketplace"
}

Write-Host ""
Write-Host "Step 3: Installing Bear Sans UI fonts..."
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

# Try user fonts first
if (-not (Test-Path $fontDir)) {
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
}

try {
    $fonts = Get-ChildItem "$scriptDir\fonts\*.otf"
    foreach ($font in $fonts) {
        try {
            Copy-Item $font.FullName $fontDir -Force -ErrorAction SilentlyContinue
        } catch {
            # Silently continue if copy fails
        }
    }

    Write-Host "Fonts installed" -ForegroundColor Green
    Write-Host "   Note: You may need to restart applications to use the new fonts" -ForegroundColor DarkGray
} catch {
    Write-Host "Could not install fonts automatically" -ForegroundColor Yellow
    Write-Host "   Please manually install the fonts from the 'fonts/' folder"
    Write-Host "   Select all .otf files and right-click > Install"
}

Write-Host ""
Write-Host "Step 4: Applying VS Code settings..."
$settingsDir = "$settingsDirBase\User"
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

$settingsFile = Join-Path $settingsDir "settings.json"

# Function to strip JSONC features (comments and trailing commas) for JSON parsing
function Strip-Jsonc {
    param([string]$Text)
    # Remove multi-line comments first
    $Text = $Text -replace '/\*[\s\S]*?\*/', ''
    # Remove single-line comments (only those not inside strings)
    $Text = $Text -replace '(?m)^\s*//.*$', ''  # Comments at start of line
    $Text = $Text -replace '(?m)([^:"''])//.*$', '$1'  # Comments after non-string content
    # Remove trailing commas before } or ]
    $Text = $Text -replace ',\s*([}\]])', '$1'
    return $Text
}

$newSettingsRaw = Get-Content "$scriptDir\settings.json" -Raw
$newSettings = (Strip-Jsonc $newSettingsRaw) | ConvertFrom-Json

if (Test-Path $settingsFile) {
    Write-Host "Existing settings.json found" -ForegroundColor Yellow
    Write-Host "   Backing up to settings.json.backup"
    Copy-Item $settingsFile "$settingsFile.backup" -Force

    try {
        $existingRaw = Get-Content $settingsFile -Raw
        $existingSettings = (Strip-Jsonc $existingRaw) | ConvertFrom-Json

        # Merge settings - Islands Dark settings take precedence
        $mergedSettings = @{}
        $existingSettings.PSObject.Properties | ForEach-Object {
            $mergedSettings[$_.Name] = $_.Value
        }
        $newSettings.PSObject.Properties | ForEach-Object {
            $mergedSettings[$_.Name] = $_.Value
        }

        # Deep merge custom-ui-style.stylesheet
        $stylesheetKey = 'custom-ui-style.stylesheet'
        if ($existingSettings.$stylesheetKey -and $newSettings.$stylesheetKey) {
            $mergedStylesheet = @{}
            $existingSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
                $mergedStylesheet[$_.Name] = $_.Value
            }
            $newSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
                $mergedStylesheet[$_.Name] = $_.Value
            }
            $mergedSettings[$stylesheetKey] = [PSCustomObject]$mergedStylesheet
        }

        [PSCustomObject]$mergedSettings | ConvertTo-Json -Depth 100 | Set-Content $settingsFile
        Write-Host "Settings merged successfully" -ForegroundColor Green
    } catch {
        Write-Host "Could not merge settings automatically" -ForegroundColor Yellow
        Write-Host "   Please manually merge settings.json from this repo into your VS Code settings"
        Write-Host "   Your original settings have been backed up to settings.json.backup"
    }
} else {
    Copy-Item "$scriptDir\settings.json" $settingsFile
    Write-Host "Settings applied" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 5: Enabling Custom UI Style..."

# Check if this is the first run
$firstRunFile = Join-Path $scriptDir ".islands_dark_first_run"
if (-not (Test-Path $firstRunFile)) {
    New-Item -ItemType File -Path $firstRunFile | Out-Null
    Write-Host ""
    Write-Host "Important Notes:" -ForegroundColor Yellow
    Write-Host "   - IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    Write-Host "   - After VS Code reloads, you may see a 'corrupt installation' warning"
    Write-Host "   - This is expected - click the gear icon and select 'Don't Show Again'"
    Write-Host ""
    Read-Host "Press Enter to continue and reload VS Code"
}

Write-Host "   Applying CSS customizations..."

Write-Host ""
Write-Host "Islands Dark theme has been installed!" -ForegroundColor Green
Write-Host "   VS Code will now reload to apply the custom UI style."
Write-Host ""

# Reload VS Code
Write-Host "   Reloading VS Code..." -ForegroundColor Cyan
try {
    & $codeCmd --reload-window 2>$null
} catch {
    & $codeCmd $scriptDir 2>$null
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

Start-Sleep -Seconds 3
