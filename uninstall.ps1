# Islands Dark Theme Uninstaller for Windows

param()

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Uninstaller for Windows" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Locate VS Code CLI
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
            $codePath = $true
            break
        }
    }
}

if ($codePath) {
    Write-Host "VS Code CLI found" -ForegroundColor Green
} else {
    Write-Host "VS Code CLI not found - will skip CLI operations" -ForegroundColor Yellow
}
Write-Host ""

# Load pre-install state if available
$settingsDir = "$env:APPDATA\Code\User"
$settingsFile = Join-Path $settingsDir "settings.json"
$stateFile = Join-Path $settingsDir ".islands-dark-state.json"
$state = $null

if (Test-Path $stateFile) {
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        Write-Host "Found pre-install state file" -ForegroundColor Green
    } catch {
        Write-Host "Could not read state file" -ForegroundColor Yellow
    }
}

# Step 1: Restore VS Code settings
Write-Host "Step 1: Restoring VS Code settings..."

$restored = $false

# Try to restore from the exact backup recorded in state file
if ($state -and $state.settingsBackupPath -and (Test-Path $state.settingsBackupPath)) {
    Copy-Item $state.settingsBackupPath $settingsFile -Force
    Write-Host "Settings restored from original backup" -ForegroundColor Green
    Write-Host "   Source: $($state.settingsBackupPath)" -ForegroundColor DarkGray
    $restored = $true
}

# Fall back to latest timestamped backup
if (-not $restored -and (Test-Path $settingsDir)) {
    $backups = Get-ChildItem "$settingsDir\settings.json.pre-islands-dark*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($backups.Count -gt 0) {
        Copy-Item $backups[0].FullName $settingsFile -Force
        Write-Host "Settings restored from backup" -ForegroundColor Green
        Write-Host "   Source: $($backups[0].FullName)" -ForegroundColor DarkGray
        $restored = $true
    }
}

# If no backup exists, surgically remove Islands Dark keys from settings
if (-not $restored -and (Test-Path $settingsFile)) {
    Write-Host "No backup found - surgically removing Islands Dark settings..." -ForegroundColor Yellow
    try {
        $raw = Get-Content $settingsFile -Raw
        try { $settings = $raw | ConvertFrom-Json }
        catch { $settings = $null }

        if ($settings) {
            # Keys that Islands Dark adds
            $islandsKeys = @(
                '// Islands Dark Settings v0.0.3',
                '// Islands Dark Settings v0.0.2',
                'custom-ui-style.stylesheet',
                'custom-ui-style.font',
                'chat.viewSessions.orientation'
            )

            $cleaned = [ordered]@{}
            $settings.PSObject.Properties | ForEach-Object {
                if ($_.Name -notin $islandsKeys) {
                    $cleaned[$_.Name] = $_.Value
                }
            }

            # Restore previous theme if we have state
            if ($state) {
                if ($state.previousColorTheme) {
                    $cleaned['workbench.colorTheme'] = $state.previousColorTheme
                }
                if ($state.previousIconTheme) {
                    $cleaned['workbench.iconTheme'] = $state.previousIconTheme
                }
            } else {
                # Reset to VS Code defaults
                $cleaned['workbench.colorTheme'] = 'Default Dark+'
                $cleaned.Remove('workbench.iconTheme')
            }

            [PSCustomObject]$cleaned | ConvertTo-Json -Depth 100 | Set-Content $settingsFile
            Write-Host "Islands Dark settings removed, previous theme restored" -ForegroundColor Green
        }
    } catch {
        Write-Host "Could not modify settings.json - please update manually" -ForegroundColor Yellow
    }
} elseif (-not $restored) {
    Write-Host "No settings.json found" -ForegroundColor Yellow
}

# Step 2: Remove Islands Dark theme extension
Write-Host ""
Write-Host "Step 2: Removing Islands Dark theme extension..."
$extDir = "$env:USERPROFILE\.vscode\extensions\bwya77.islands-dark-1.0.0"
if (Test-Path $extDir) {
    Remove-Item -Recurse -Force $extDir
    Write-Host "Theme extension directory removed" -ForegroundColor Green
} else {
    Write-Host "Extension directory not found (may already be removed)" -ForegroundColor Yellow
}

if ($codePath) {
    try {
        $null = code --uninstall-extension bwya77.islands-dark --force 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Extension uninstalled via VS Code CLI" -ForegroundColor Green
        }
    } catch {}
}

# Step 3: Handle Custom UI Style extension
Write-Host ""
Write-Host "Step 3: Handling Custom UI Style extension..."

if ($state -and $state.customUiStyleWasInstalled -eq $true) {
    # Custom UI Style was already installed before Islands Dark - leave it but disable CSS
    Write-Host "Custom UI Style was installed before Islands Dark - leaving it installed" -ForegroundColor Green
    Write-Host "   The Islands Dark CSS rules have been removed from your settings." -ForegroundColor DarkGray
} else {
    # We installed it, so uninstall it
    if ($codePath) {
        try {
            $null = code --uninstall-extension subframe7536.custom-ui-style --force 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Custom UI Style extension uninstalled" -ForegroundColor Green
            } else {
                Write-Host "Custom UI Style may already be removed" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Could not uninstall Custom UI Style automatically" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Please uninstall Custom UI Style manually from VS Code Extensions" -ForegroundColor Yellow
    }
}

# Step 4: Remove fonts that we installed
Write-Host ""
Write-Host "Step 4: Removing installed fonts..."

if ($state -and $state.fonts) {
    $removedCount = 0
    $state.fonts.PSObject.Properties | ForEach-Object {
        $fontInfo = $_.Value
        if ($fontInfo.wasPresentBeforeInstall -eq $false -and $fontInfo.installedPath -and (Test-Path $fontInfo.installedPath)) {
            Remove-Item $fontInfo.installedPath -Force -ErrorAction SilentlyContinue
            $removedCount++
        }
    }
    if ($removedCount -gt 0) {
        Write-Host "$removedCount font(s) removed" -ForegroundColor Green
    } else {
        Write-Host "No fonts to remove (all were pre-existing)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "No font state found - skipping font removal" -ForegroundColor Yellow
    Write-Host "   You can manually remove Bear Sans UI fonts from: $env:LOCALAPPDATA\Microsoft\Windows\Fonts" -ForegroundColor DarkGray
}

# Step 5: Clean up state and backup files
Write-Host ""
Write-Host "Step 5: Cleaning up..."

if (Test-Path $stateFile) {
    Remove-Item $stateFile -Force
    Write-Host "State file removed" -ForegroundColor DarkGray
}

# Clean up backup files
if (Test-Path $settingsDir) {
    $backupFiles = Get-ChildItem "$settingsDir\settings.json.pre-islands-dark*" -ErrorAction SilentlyContinue
    if ($backupFiles.Count -gt 0) {
        $backupFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "$($backupFiles.Count) backup file(s) removed" -ForegroundColor DarkGray
    }
}

# Step 6: Reload VS Code
Write-Host ""
Write-Host "Step 6: Reloading VS Code..."

if ($codePath) {
    Write-Host "   Closing VS Code..." -ForegroundColor Cyan
    Stop-Process -Name "Code" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "   Relaunching VS Code..." -ForegroundColor Cyan
    Start-Process "code" -ErrorAction SilentlyContinue
} else {
    Write-Host "   Please restart VS Code manually to complete the uninstall." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Islands Dark has been uninstalled!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: If you see CSS artifacts, open Command Palette (Ctrl+Shift+P)" -ForegroundColor Yellow
Write-Host "and run 'Custom UI Style: Disable' to clean up injected styles." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 3
