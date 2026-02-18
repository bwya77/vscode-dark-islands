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
$backupFile = "$settingsFile.pre-islands-dark"

if (Test-Path $backupFile) {
    Copy-Item $backupFile $settingsFile -Force
    Write-Host "Settings restored from backup" -ForegroundColor Green
    Write-Host "   Backup file: $backupFile"
} else {
    Write-Host "No backup found at $backupFile" -ForegroundColor Yellow
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

# Step 4: Remove extension from extensions.json
Write-Host ""
Write-Host "Step 4: Unregistering extension..."
$extJsonPath = "$env:USERPROFILE\.vscode\extensions\extensions.json"
try {
    if (Test-Path $extJsonPath) {
        $extensions = Get-Content $extJsonPath -Raw | ConvertFrom-Json
        $before = $extensions.Count
        $extensions = @($extensions | Where-Object {
            $_.identifier.id -ne 'bwya77.islands-dark' -and
            $_.identifier.id -ne 'your-publisher-name.islands-dark'
        })
        if ($extensions.Count -lt $before) {
            $extensions | ConvertTo-Json -Depth 10 -Compress | Set-Content $extJsonPath
            Write-Host "Extension unregistered" -ForegroundColor Green
        } else {
            Write-Host "Extension was not registered" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Could not update extensions.json" -ForegroundColor Yellow
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
