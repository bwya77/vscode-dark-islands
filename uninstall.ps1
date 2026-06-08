# Islands Dark Theme Uninstaller for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Uninstaller for Windows" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Restore old settings
Write-Host "Step 1: Restoring VS Code settings..."
$settingsDir = "$env:APPDATA\Code\User"
$settingsFile = Join-Path $settingsDir "settings.json"

# Look for timestamped backups first, then the legacy backup name
$backupDir = Split-Path $settingsFile
$backups = @()
if (Test-Path $backupDir) {
    $backups = Get-ChildItem "$backupDir\settings.json.pre-islands-dark*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
}

if ($backups.Count -gt 0) {
    $latestBackup = $backups[0].FullName
    Copy-Item $latestBackup $settingsFile -Force
    Write-Host "Settings restored from backup" -ForegroundColor Green
    Write-Host "   Backup file: $latestBackup"
} else {
    Write-Host "No backup found" -ForegroundColor Yellow
    Write-Host "   You may need to manually update your VS Code settings."
}

# Step 2: Disable Custom UI Style
Write-Host ""
Write-Host "Step 2: Disabling Custom UI Style..."
Write-Host "   Please disable Custom UI Style manually:" -ForegroundColor Yellow
Write-Host "   1. Open Command Palette (Ctrl+Shift+P)"
Write-Host "   2. Run 'Custom UI Style: Disable'"
Write-Host "   3. VS Code will reload"

# Step 3: Remove theme extension
Write-Host ""
Write-Host "Step 3: Removing Islands Dark theme extension..."
$extDir = "$env:USERPROFILE\.vscode\extensions\bwya77.islands-dark-1.0.0"
if (Test-Path $extDir) {
    Remove-Item -Recurse -Force $extDir
    Write-Host "Theme extension removed" -ForegroundColor Green
} else {
    Write-Host "Extension directory not found (may already be removed)" -ForegroundColor Yellow
}

# Step 4: Uninstall extension via VS Code CLI
Write-Host ""
Write-Host "Step 4: Uninstalling extension from VS Code..."

# Check if VS Code CLI is available
$codePath = Get-Command "code" -ErrorAction SilentlyContinue
if (-not $codePath) {
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            break
        }
    }
}

try {
    $null = code --uninstall-extension bwya77.islands-dark --force 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Extension uninstalled via VS Code CLI" -ForegroundColor Green
    } else {
        Write-Host "Extension not installed via marketplace (or already removed)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Could not uninstall extension via VS Code CLI" -ForegroundColor Yellow
}

# Step 5: Change theme
Write-Host ""
Write-Host "Step 5: Change your color theme..."
Write-Host "   1. Open Command Palette (Ctrl+Shift+P)"
Write-Host "   2. Search for 'Preferences: Color Theme'"
Write-Host "   3. Select your preferred theme"

Write-Host ""
Write-Host "Islands Dark has been uninstalled!" -ForegroundColor Green
Write-Host ""
Write-Host "   Reload VS Code to complete the process."
Write-Host ""

Start-Sleep -Seconds 3
