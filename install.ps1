# Islands Dark Theme Installer for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Installer for Windows" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if VS Code is installed
$codePath = Get-Command "code" -ErrorAction SilentlyContinue
if (-not $codePath) {
    # Try to find code in common locations
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )

    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            $found = $true
            break
        }
    }

    if (-not $found) {
        Write-Host "Error: VS Code CLI (code) not found!" -ForegroundColor Red
        Write-Host "Please install VS Code and make sure 'code' command is in your PATH."
        Write-Host "You can do this by:"
        Write-Host "  1. Open VS Code"
        Write-Host "  2. Press Ctrl+Shift+P"
        Write-Host "  3. Type 'Shell Command: Install code command in PATH'"
        exit 1
    }
}

Write-Host "VS Code CLI found" -ForegroundColor Green

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "Step 1: Installing Islands Dark theme extension..."

# Install by copying to VS Code extensions directory
$extDir = "$env:USERPROFILE\.vscode\extensions\bwya77.islands-dark-1.0.0"
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

# Register extension in extensions.json so VS Code discovers it
$extJsonPath = "$env:USERPROFILE\.vscode\extensions\extensions.json"
try {
    $extensions = @()
    if (Test-Path $extJsonPath) {
        $extensions = Get-Content $extJsonPath -Raw | ConvertFrom-Json
    }

    # Remove any existing Islands Dark entry
    $extensions = @($extensions | Where-Object {
        $_.identifier.id -ne 'bwya77.islands-dark' -and
        $_.identifier.id -ne 'your-publisher-name.islands-dark'
    })

    # Add new entry
    $newEntry = [PSCustomObject]@{
        identifier = [PSCustomObject]@{ id = 'bwya77.islands-dark' }
        version = '1.0.0'
        location = [PSCustomObject]@{
            '$mid' = 1
            path = "$env:USERPROFILE\.vscode\extensions\bwya77.islands-dark-1.0.0"
            scheme = 'file'
        }
        relativeLocation = 'bwya77.islands-dark-1.0.0'
    }
    $extensions += $newEntry

    $extensions | ConvertTo-Json -Depth 10 -Compress | Set-Content $extJsonPath
    Write-Host "Extension registered" -ForegroundColor Green
} catch {
    Write-Host "Could not register extension automatically" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Installing Custom UI Style extension..."
try {
    $output = code --install-extension subframe7536.custom-ui-style --force 2>&1
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
$settingsDir = "$env:APPDATA\Code\User"
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

$settingsFile = Join-Path $settingsDir "settings.json"

# Backup existing settings if they exist
if (Test-Path $settingsFile) {
    $backupFile = "$settingsFile.pre-islands-dark"
    Copy-Item $settingsFile $backupFile -Force
    Write-Host "Existing settings.json backed up to:" -ForegroundColor Yellow
    Write-Host "   $backupFile"
    Write-Host "   You can restore your old settings from this file if needed."
}

# Copy Islands Dark settings
Copy-Item "$scriptDir\settings.json" $settingsFile -Force
Write-Host "Islands Dark settings applied" -ForegroundColor Green

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
    code --reload-window 2>$null
} catch {
    code $scriptDir 2>$null
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

Start-Sleep -Seconds 3
