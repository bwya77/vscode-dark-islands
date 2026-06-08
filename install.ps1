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

# Track which fonts already existed (for clean uninstall)
$fontPreExistence = @{}
$fontFiles = Get-ChildItem "$scriptDir\fonts\*.otf" -ErrorAction SilentlyContinue
foreach ($f in $fontFiles) {
    $destPath = Join-Path $fontDir $f.Name
    $fontPreExistence[$f.Name] = @{
        wasPresentBeforeInstall = (Test-Path $destPath)
        installedPath = $destPath
    }
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

# Strip JSONC features (comments, trailing commas) so ConvertFrom-Json can parse.
# Uses a character-by-character approach to avoid stripping // inside quoted strings.
function Strip-Jsonc {
    param([string]$Text)
    $result = [System.Text.StringBuilder]::new($Text.Length)
    $inString = $false
    $escaped = $false
    $i = 0
    while ($i -lt $Text.Length) {
        $c = $Text[$i]
        if ($escaped) {
            [void]$result.Append($c)
            $escaped = $false
            $i++
            continue
        }
        if ($c -eq '\' -and $inString) {
            [void]$result.Append($c)
            $escaped = $true
            $i++
            continue
        }
        if ($c -eq '"') {
            $inString = -not $inString
            [void]$result.Append($c)
            $i++
            continue
        }
        if (-not $inString) {
            # Single-line comment: skip to end of line
            if ($c -eq '/' -and ($i + 1) -lt $Text.Length -and $Text[$i + 1] -eq '/') {
                while ($i -lt $Text.Length -and $Text[$i] -ne "`n") { $i++ }
                continue
            }
            # Multi-line comment: skip to closing */
            if ($c -eq '/' -and ($i + 1) -lt $Text.Length -and $Text[$i + 1] -eq '*') {
                $i += 2
                while ($i -lt $Text.Length) {
                    if ($Text[$i] -eq '*' -and ($i + 1) -lt $Text.Length -and $Text[$i + 1] -eq '/') {
                        $i += 2
                        break
                    }
                    $i++
                }
                continue
            }
        }
        [void]$result.Append($c)
        $i++
    }
    $resultStr = $result.ToString()
    # Remove trailing commas before } or ]
    $resultStr = $resultStr -replace ',\s*([}\]])', '$1'
    return $resultStr
}

# Our own settings.json is valid JSON - parse directly
$newSettings = Get-Content "$scriptDir\settings.json" -Raw | ConvertFrom-Json

# If the user has existing settings, merge instead of overwrite.
# Islands Dark theme keys win so updated fixes are applied correctly.
# Non-theme user settings are preserved.
if (Test-Path $settingsFile) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = "$settingsFile.pre-islands-dark.$timestamp"
    Copy-Item $settingsFile $backupFile -Force
    Write-Host "Existing settings.json backed up to:" -ForegroundColor Yellow
    Write-Host "   $backupFile"
    Write-Host "   You can restore your old settings from this file if needed."

    try {
        $existingRaw = Get-Content $settingsFile -Raw
        # Try direct parse first; fall back to JSONC stripping for user files with comments
        try {
            $existingSettings = $existingRaw | ConvertFrom-Json
        } catch {
            $existingSettings = (Strip-Jsonc $existingRaw) | ConvertFrom-Json
        }

        # Start with user's existing settings, then overlay Islands Dark theme settings.
        # Theme keys win so fixes/updates are applied correctly.
        $mergedSettings = [ordered]@{}

        # First, copy all existing user settings
        $existingSettings.PSObject.Properties | ForEach-Object {
            $mergedSettings[$_.Name] = $_.Value
        }

        # Then overlay Islands Dark settings (theme keys win)
        $newSettings.PSObject.Properties | ForEach-Object {
            $mergedSettings[$_.Name] = $_.Value
        }

        # Deep merge custom-ui-style.stylesheet so user's extra CSS rules survive
        # but Islands Dark's selectors always get the latest fixes
        $stylesheetKey = 'custom-ui-style.stylesheet'
        if ($existingSettings.$stylesheetKey -and $newSettings.$stylesheetKey) {
            $mergedStylesheet = [ordered]@{}
            # Start with user's custom CSS selectors
            $existingSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
                $mergedStylesheet[$_.Name] = $_.Value
            }
            # Overlay Islands Dark selectors (theme wins for its own selectors)
            $newSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
                $mergedStylesheet[$_.Name] = $_.Value
            }
            $mergedSettings[$stylesheetKey] = [PSCustomObject]$mergedStylesheet
        }

        [PSCustomObject]$mergedSettings | ConvertTo-Json -Depth 100 | Set-Content $settingsFile
        Write-Host "Settings merged (your non-theme settings preserved, theme settings updated)" -ForegroundColor Green
    } catch {
        Write-Host "Could not parse existing settings.json - leaving it untouched" -ForegroundColor Yellow
        Write-Host "   Your backup is at: $backupFile" -ForegroundColor DarkGray
        Write-Host "   To apply Islands Dark settings, manually merge from: $scriptDir\settings.json" -ForegroundColor DarkGray
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
} else {
    Copy-Item "$scriptDir\settings.json" $settingsFile -Force
    Write-Host "Islands Dark settings applied" -ForegroundColor Green
}

# Save pre-install state for clean uninstall (only on first install)
$stateFile = Join-Path $settingsDir ".islands-dark-state.json"
if (-not (Test-Path $stateFile)) {
    $state = [ordered]@{
        previousColorTheme = "Default Dark+"
        previousIconTheme  = ""
        customUiStyleWasInstalled = $false
        settingsBackupPath = ""
        fonts = @{}
        installedAt = (Get-Date -Format "o")
    }

    # Read previous theme from the backup (pre-merge settings)
    if ($backupFile -and (Test-Path $backupFile)) {
        try {
            $backupRaw = Get-Content $backupFile -Raw
            try { $backupSettings = $backupRaw | ConvertFrom-Json }
            catch { $backupSettings = (Strip-Jsonc $backupRaw) | ConvertFrom-Json }

            if ($backupSettings.'workbench.colorTheme') {
                $state.previousColorTheme = $backupSettings.'workbench.colorTheme'
            }
            if ($backupSettings.'workbench.iconTheme') {
                $state.previousIconTheme = $backupSettings.'workbench.iconTheme'
            }
        } catch {}
        $state.settingsBackupPath = $backupFile
    }

    # Check if Custom UI Style was already installed
    $cuiExtDirs = Get-ChildItem "$env:USERPROFILE\.vscode\extensions\subframe7536.custom-ui-style-*" -Directory -ErrorAction SilentlyContinue
    if ($cuiExtDirs) {
        $state.customUiStyleWasInstalled = $true
    }

    # Track which fonts were installed (use pre-install check from Step 3)
    $fontState = [ordered]@{}
    foreach ($key in $fontPreExistence.Keys) {
        $fontState[$key] = [ordered]@{
            wasPresentBeforeInstall = $fontPreExistence[$key].wasPresentBeforeInstall
            installedPath = $fontPreExistence[$key].installedPath
        }
    }
    $state.fonts = [PSCustomObject]$fontState

    [PSCustomObject]$state | ConvertTo-Json -Depth 10 | Set-Content $stateFile
    Write-Host "Pre-install state saved for clean uninstall" -ForegroundColor DarkGray
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
Write-Host ""

# Quit VS Code and relaunch so Custom UI Style fully initializes and patches CSS
Write-Host "   Closing VS Code..." -ForegroundColor Cyan
Stop-Process -Name "Code" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host "   Relaunching VS Code..." -ForegroundColor Cyan
Start-Process "code" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "If the CSS customizations are not applied, open the Command Palette" -ForegroundColor Yellow
Write-Host "(Ctrl+Shift+P) and run: Custom UI Style: Reload" -ForegroundColor Yellow

Start-Sleep -Seconds 3
