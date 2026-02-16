# Islands Dark Theme Installer for Windows
# Run with -CheckUpdate to only check for updates without installing
# Run with -Force to reinstall even if on latest version

param(
    [switch]$CheckUpdate,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Version information
$SCRIPT_VERSION = "1.0.0"
$EXTENSION_ID = "bwya77.islands-dark"

Write-Host "Islands Dark Theme Installer for Windows" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Read the version from package.json in the repo
$repoPackageJsonPath = Join-Path $scriptDir "package.json"
$REPO_VERSION = $SCRIPT_VERSION
if (Test-Path $repoPackageJsonPath) {
    try {
        $repoPackageJson = Get-Content $repoPackageJsonPath -Raw | ConvertFrom-Json
        $REPO_VERSION = $repoPackageJson.version
    } catch {
        Write-Host "Warning: Could not read version from package.json" -ForegroundColor Yellow
    }
}

# Function to check current installed version
function Get-InstalledVersion {
    $extDir = "$env:USERPROFILE\.vscode\extensions\${EXTENSION_ID}-${REPO_VERSION}"
    $genericExtDir = "$env:USERPROFILE\.vscode\extensions\${EXTENSION_ID}-*"
    
    # Check for exact version match first
    if (Test-Path $extDir) {
        $packagePath = Join-Path $extDir "package.json"
        if (Test-Path $packagePath) {
            try {
                $installedPackage = Get-Content $packagePath -Raw | ConvertFrom-Json
                return $installedPackage.version
            } catch {
                return $null
            }
        }
    }
    
    # Check for any version of the extension
    $foundDirs = Get-ChildItem -Path $genericExtDir -Directory -ErrorAction SilentlyContinue
    if ($foundDirs) {
        # Get the most recently modified extension directory
        $latestDir = $foundDirs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $packagePath = Join-Path $latestDir.FullName "package.json"
        if (Test-Path $packagePath) {
            try {
                $installedPackage = Get-Content $packagePath -Raw | ConvertFrom-Json
                return $installedPackage.version
            } catch {
                return $null
            }
        }
    }
    
    return $null
}

# Check current version
$installedVersion = Get-InstalledVersion

# Display version information
Write-Host "Repository version: $REPO_VERSION" -ForegroundColor Cyan
if ($installedVersion) {
    Write-Host "Installed version:  $installedVersion" -ForegroundColor Cyan
} else {
    Write-Host "Installed version:  Not installed" -ForegroundColor Yellow
}
Write-Host ""

# Check update mode - just display status and exit
if ($CheckUpdate) {
    if (-not $installedVersion) {
        Write-Host "Islands Dark is not installed." -ForegroundColor Yellow
        Write-Host "Run without -CheckUpdate to install." -ForegroundColor Gray
        exit 0
    }
    
    if ($installedVersion -eq $REPO_VERSION) {
        Write-Host "You have the latest version ($REPO_VERSION) installed!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Update available: $installedVersion -> $REPO_VERSION" -ForegroundColor Yellow
        Write-Host "Run without -CheckUpdate to update." -ForegroundColor Gray
        exit 0
    }
}

# Check if we should proceed with installation
if ($installedVersion -eq $REPO_VERSION -and -not $Force) {
    Write-Host "Islands Dark version $REPO_VERSION is already installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  • Run with -Force to reinstall anyway" -ForegroundColor Gray
    Write-Host "  • Run with -CheckUpdate to just check for updates" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Do you want to reinstall anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Check if VS Code: is installed
$codePath = Get-Command "code" -ErrorAction SilentlyContinue
if (-not $codePath) {
    # Try to find code in common locations
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code:\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code:\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code:\bin\code.cmd"
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
        Write-Host "Error: VS Code: CLI (code) not found!" -ForegroundColor Red
        Write-Host "Please install VS Code: and make sure 'code' command is in your PATH."
        Write-Host "You can do this by:"
        Write-Host "  1. Open VS Code:"
        Write-Host "  2. Press Ctrl+Shift+P"
        Write-Host "  3. Type 'Shell Command: Install code command in PATH'"
        exit 1
    }
}

Write-Host "VS Code: CLI found" -ForegroundColor Green

Write-Host ""
Write-Host "Step 1: Installing Islands Dark theme extension..."

# Install by copying to VS Code: extensions directory
$extDir = "$env:USERPROFILE\.vscode\extensions\${EXTENSION_ID}-${REPO_VERSION}"

# Remove old versions of the extension
$oldExtDirs = Get-ChildItem -Path "$env:USERPROFILE\.vscode\extensions\${EXTENSION_ID}-*" -Directory -ErrorAction SilentlyContinue
foreach ($oldDir in $oldExtDirs) {
    if ($oldDir.Name -ne "${EXTENSION_ID}-${REPO_VERSION}") {
        Write-Host "  Removing old version: $($oldDir.Name)" -ForegroundColor DarkGray
        Remove-Item -Recurse -Force $oldDir.FullName -ErrorAction SilentlyContinue
    }
}

# Install new version
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

try {
    $fonts = Get-ChildItem "$scriptDir\fonts\*.otf" -ErrorAction SilentlyContinue
    if ($fonts) {
        foreach ($font in $fonts) {
            try {
                Copy-Item $font.FullName $fontDir -Force -ErrorAction SilentlyContinue
            } catch {
                # Silently continue if copy fails
            }
        }
        Write-Host "Fonts installed" -ForegroundColor Green
        Write-Host "   Note: You may need to restart applications to use the new fonts" -ForegroundColor DarkGray
    } else {
        Write-Host "No font files found in $scriptDir\fonts\" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Could not install fonts automatically" -ForegroundColor Yellow
    Write-Host "   Please manually install the fonts from the 'fonts/' folder"
    Write-Host "   Select all .otf files and right-click > Install"
}

Write-Host ""
Write-Host "Step 4: Applying VS Code: settings..."
$settingsDir = "$env:APPDATA\Code:\User"
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

$settingsFile = Join-Path $settingsDir "settings.json"

# Function to strip JSONC features (comments and trailing commas) for JSON parsing
function Strip-Jsonc {
    param([string]$Text)
    # Remove single-line comments
    $Text = $Text -replace '//.*$', ''
    # Remove multi-line comments
    $Text = $Text -replace '/\*[\s\S]*?\*/', ''
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
        Write-Host "   Please manually merge settings.json from this repo into your VS Code: settings"
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
    Write-Host "   - After VS Code: reloads, you may see a 'corrupt installation' warning"
    Write-Host "   - This is expected - click the gear icon and select 'Don't Show Again'"
    Write-Host ""
    Read-Host "Press Enter to continue and reload VS Code:"
}

Write-Host "   Applying CSS customizations..."

Write-Host ""
Write-Host "Islands Dark theme has been installed!" -ForegroundColor Green
Write-Host "   VS Code: will now reload to apply the custom UI style."
Write-Host ""

# Reload VS Code:
Write-Host "   Reloading VS Code:..." -ForegroundColor Cyan
try {
    code --reload-window 2>$null
} catch {
    code $scriptDir 2>$null
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

Start-Sleep -Seconds 3
