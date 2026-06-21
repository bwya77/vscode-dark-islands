# Islands Dark Theme Uninstaller for Windows

param(
    [ValidateSet("auto", "vscode", "vscodium")]
    [string]$Editor = "auto"
)

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Uninstaller for Windows" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Pick editor target
if ($env:ISLANDS_DARK_EDITOR -and $Editor -eq "auto") {
    $Editor = $env:ISLANDS_DARK_EDITOR
}
$Editor = $Editor.ToLowerInvariant()
if ($Editor -eq "codium") {
    $Editor = "vscodium"
} elseif ($Editor -eq "code") {
    $Editor = "vscode"
}

if ($Editor -eq "auto") {
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        $Editor = "vscode"
    } elseif (Get-Command "codium" -ErrorAction SilentlyContinue) {
        $Editor = "vscodium"
    } else {
        $Editor = "vscode"
    }
}

if ($Editor -eq "vscodium") {
    $editorName = "VSCodium"
    $cliName = "codium"
    $extRoot = "$env:USERPROFILE\.vscode-oss\extensions"
    $settingsDir = "$env:APPDATA\VSCodium\User"
    $processName = "VSCodium"
    $editorDirs = @(
        "$env:LOCALAPPDATA\Programs\VSCodium",
        "$env:ProgramFiles\VSCodium",
        "${env:ProgramFiles(x86)}\VSCodium"
    )
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\VSCodium\bin\codium.cmd",
        "$env:ProgramFiles\VSCodium\bin\codium.cmd",
        "${env:ProgramFiles(x86)}\VSCodium\bin\codium.cmd"
    )
} else {
    $editorName = "VS Code"
    $cliName = "code"
    $extRoot = "$env:USERPROFILE\.vscode\extensions"
    $settingsDir = "$env:APPDATA\Code\User"
    $processName = "Code"
    $editorDirs = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code",
        "$env:ProgramFiles\Microsoft VS Code",
        "${env:ProgramFiles(x86)}\Microsoft VS Code"
    )
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    )
}

# Locate editor CLI
$codePath = Get-Command $cliName -ErrorAction SilentlyContinue
if (-not $codePath) {
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            $codePath = $true
            break
        }
    }
}

if ($codePath) {
    Write-Host "$editorName CLI found" -ForegroundColor Green
} else {
    Write-Host "$editorName CLI not found - will skip CLI operations" -ForegroundColor Yellow
}
Write-Host ""

# Load pre-install state if available
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

# Step 1: Restore editor settings
Write-Host "Step 1: Restoring $editorName settings..."

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
                # Reset to editor defaults
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
$extDir = Join-Path $extRoot "bwya77.islands-dark-1.0.0"
if (Test-Path $extDir) {
    Remove-Item -Recurse -Force $extDir
    Write-Host "Theme extension directory removed" -ForegroundColor Green
} else {
    Write-Host "Extension directory not found (may already be removed)" -ForegroundColor Yellow
}

if ($codePath) {
    try {
        $null = & $cliName --uninstall-extension bwya77.islands-dark --force 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Extension uninstalled via $editorName CLI" -ForegroundColor Green
        }
    } catch {}
}

# Step 3: Handle Custom UI Style extension
Write-Host ""
Write-Host "Step 2b: Clearing extensions.json..."

# Remove extensions.json so the editor rebuilds it from the extensions
# actually on disk. Restoring the pre-install backup would lose any
# extensions the user installed after Islands Dark.
$extJson = Join-Path $extRoot "extensions.json"
if (Test-Path $extJson) {
    Remove-Item $extJson -Force
    Write-Host "extensions.json removed ($editorName will rebuild it on next launch)" -ForegroundColor Green
} else {
    Write-Host "extensions.json not present (already clean)" -ForegroundColor DarkGray
}

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
            $null = & $cliName --uninstall-extension subframe7536.custom-ui-style --force 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Custom UI Style extension uninstalled" -ForegroundColor Green
            } else {
                Write-Host "Custom UI Style may already be removed" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Could not uninstall Custom UI Style automatically" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Please uninstall Custom UI Style manually from $editorName Extensions" -ForegroundColor Yellow
    }
}

# Step 3b: Restore editor workbench files patched by Custom UI Style
Write-Host ""
Write-Host "Step 3b: Removing Custom UI Style CSS patches..."

$cuiRestoredCount = 0
foreach ($vscodeBase in $editorDirs) {
    if (-not (Test-Path $vscodeBase)) { continue }

    # Custom UI Style saves originals as *.custom-ui-style.{ext}
    # Find all backup files and restore them
    $backupFiles = Get-ChildItem $vscodeBase -Recurse -Filter "*.custom-ui-style.*" -ErrorAction SilentlyContinue
    foreach ($backup in $backupFiles) {
        # Derive the original filename: workbench.custom-ui-style.html -> workbench.html
        # workbench.desktop.main.custom-ui-style.css -> workbench.desktop.main.css
        $originalName = $backup.Name -replace '\.custom-ui-style\.', '.'
        $originalPath = Join-Path $backup.DirectoryName $originalName
        if (Test-Path $originalPath) {
            try {
                Copy-Item $backup.FullName $originalPath -Force
                Remove-Item $backup.FullName -Force
                $cuiRestoredCount++
            } catch {
                Write-Host "   Could not restore: $originalName" -ForegroundColor Yellow
            }
        }
    }
    break
}

if ($cuiRestoredCount -gt 0) {
    Write-Host "$cuiRestoredCount $editorName file(s) restored to original state" -ForegroundColor Green
} else {
    Write-Host "No Custom UI Style patches found (already clean)" -ForegroundColor DarkGray
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
        Write-Host "$($backupFiles.Count) settings backup file(s) removed" -ForegroundColor DarkGray
    }
}

# Clean up extensions.json backup files
if (Test-Path $extRoot) {
    $extJsonBackups = Get-ChildItem "$extRoot\extensions.json.pre-islands-dark*" -ErrorAction SilentlyContinue
    if ($extJsonBackups.Count -gt 0) {
        $extJsonBackups | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "$($extJsonBackups.Count) extensions.json backup file(s) removed" -ForegroundColor DarkGray
    }
}

# Step 6: Reload editor
Write-Host ""
Write-Host "Step 6: Reloading $editorName..."

if ($codePath) {
    Write-Host "   Closing $editorName..." -ForegroundColor Cyan
    Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "   Relaunching $editorName..." -ForegroundColor Cyan
    Start-Process $cliName -ErrorAction SilentlyContinue
} else {
    Write-Host "   Please restart $editorName manually to complete the uninstall." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Islands Dark has been uninstalled!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: If you see CSS artifacts, open Command Palette (Ctrl+Shift+P)" -ForegroundColor Yellow
Write-Host "and run 'Custom UI Style: Disable' to clean up injected styles." -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 3
