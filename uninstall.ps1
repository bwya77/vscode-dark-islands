# Islands Dark Windows uninstaller

param()

$ErrorActionPreference = "Stop"

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

function ConvertTo-FileUrl {
    param([string]$Path)
    $resolved = [System.IO.Path]::GetFullPath($Path)
    return ([System.Uri]$resolved).AbsoluteUri
}

Write-Host "Islands Dark uninstaller" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$package = Get-Content (Join-Path $scriptDir "package.json") -Raw | ConvertFrom-Json
$extensionDirName = "$($package.publisher).$($package.name)-$($package.version)"
$extensionDir = Join-Path $env:USERPROFILE ".vscode\extensions\$extensionDirName"
$cssUrls = @(
    (ConvertTo-FileUrl (Join-Path $extensionDir "custom-css\islands-dark.css")),
    (ConvertTo-FileUrl (Join-Path $scriptDir "custom-css\islands-dark.css"))
) | Select-Object -Unique
$settingsFile = Join-Path $env:APPDATA "Code\User\settings.json"

if (Test-Path $settingsFile) {
    Copy-Item $settingsFile "$settingsFile.pre-islands-dark-uninstall" -Force
    $raw = Get-Content $settingsFile -Raw
    $settings = if ([string]::IsNullOrWhiteSpace($raw)) { [ordered]@{} } else { (Strip-Jsonc $raw) | ConvertFrom-Json }
    $map = [ordered]@{}
    $settings.PSObject.Properties | ForEach-Object { $map[$_.Name] = $_.Value }
    if ($map.Contains('vscode_custom_css.imports')) {
        $map['vscode_custom_css.imports'] = @($map['vscode_custom_css.imports'] | Where-Object { $cssUrls -notcontains $_ })
    }
    [PSCustomObject]$map | ConvertTo-Json -Depth 100 | Set-Content $settingsFile -Encoding UTF8
    Write-Host "Removed Islands Dark CSS import from settings.json." -ForegroundColor Green
}

Write-Host ""
Write-Host "Run Command Palette > Disable Custom CSS and JS to restore VS Code's patched workbench file." -ForegroundColor Yellow
Write-Host "Then uninstall the Islands Dark extension normally if desired."
