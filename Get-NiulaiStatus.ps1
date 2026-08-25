[CmdletBinding()]
param(
    [string]$CodexHome,

    [string]$StartupFolder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    $CodexHome = if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $env:CODEX_HOME
    } else {
        Join-Path $env:USERPROFILE '.codex'
    }
}
if ([string]::IsNullOrWhiteSpace($StartupFolder)) {
    $StartupFolder = [Environment]::GetFolderPath('Startup')
}

$petPath = [IO.Path]::GetFullPath((Join-Path $CodexHome 'pets\niulai-film-pet')).TrimEnd('\')
$startupShortcutPath = Join-Path ([IO.Path]::GetFullPath($StartupFolder)) '牛来.lnk'

function Get-VerifiedProcess {
    param(
        [string]$PidPath,
        [string]$ScriptPath
    )

    if (-not (Test-Path -LiteralPath $PidPath -PathType Leaf)) {
        return $null
    }
    $processIdText = (Get-Content -LiteralPath $PidPath -Raw -Encoding UTF8).Trim()
    if ($processIdText -notmatch '^\d+$') {
        return $null
    }
    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $processIdText" -ErrorAction SilentlyContinue
    if ($null -eq $process -or $null -eq $process.CommandLine -or
        $process.CommandLine.IndexOf($ScriptPath, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        return $null
    }
    return $process
}

$manifestPath = Join-Path $petPath 'pet.json'
$spritePath = Join-Path $petPath 'spritesheet.webp'
$versionPath = Join-Path $petPath 'package-version.json'
$layoutStatePath = Join-Path $petPath 'niulai-talk-layout-state.json'
$bridgeScript = Join-Path $petPath 'CodexPetInputBridge.ps1'
$overlayScript = Join-Path $petPath 'NiulaiOverlay.ps1'
$bridge = Get-VerifiedProcess -PidPath (Join-Path $petPath 'codex-pet-input-bridge.pid') -ScriptPath $bridgeScript
$speech = Get-VerifiedProcess -PidPath (Join-Path $petPath 'niulai-talk-overlay.pid') -ScriptPath $overlayScript

$manifestValid = $false
$spriteVersionNumber = $null
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $spriteVersionNumber = $manifest.spriteVersionNumber
        $manifestValid = $manifest.id -eq 'niulai-film-pet' -and
            $manifest.spriteVersionNumber -eq 2 -and
            $manifest.spritesheetPath -eq 'spritesheet.webp'
    } catch {}
}

$probe = $null
if (Test-Path -LiteralPath $bridgeScript -PathType Leaf) {
    try {
        $probeShellCandidates = @()
        if (-not [string]::IsNullOrWhiteSpace($env:SystemRoot)) {
            $probeShellCandidates += Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        }
        $probeShellCandidates += Join-Path $PSHOME 'powershell.exe'
        $probeShellCandidates += Join-Path $PSHOME 'pwsh.exe'
        $probeShell = $probeShellCandidates |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($probeShell)) {
            throw 'No compatible PowerShell executable was found for the isolated overlay probe.'
        }
        $probeOutput = & $probeShell -NoProfile -ExecutionPolicy Bypass -File $bridgeScript -ProbeOnly
        $probe = $probeOutput | ConvertFrom-Json
    } catch {
        $probe = [pscustomobject]@{ overlayFound = $false; error = $_.Exception.Message }
    }
}

$runtimeHealthy = $null -ne $bridge -and $null -ne $speech
$packageVersion = $null
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
    try { $packageVersion = (Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8 | ConvertFrom-Json).version } catch {}
}
$bubbleLayout = $null
if (Test-Path -LiteralPath $layoutStatePath -PathType Leaf) {
    try { $bubbleLayout = Get-Content -LiteralPath $layoutStatePath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
}
[pscustomobject]@{
    installed = Test-Path -LiteralPath $petPath -PathType Container
    petPath = $petPath
    packageVersion = $packageVersion
    manifestValid = $manifestValid
    spriteVersionNumber = $spriteVersionNumber
    spriteExists = Test-Path -LiteralPath $spritePath -PathType Leaf
    inputBridgeRunning = $null -ne $bridge
    inputBridgeProcessId = if ($null -ne $bridge) { [int]$bridge.ProcessId } else { $null }
    speechOverlayRunning = $null -ne $speech
    speechOverlayProcessId = if ($null -ne $speech) { [int]$speech.ProcessId } else { $null }
    runtimeHealthy = $runtimeHealthy
    startupRegistered = Test-Path -LiteralPath $startupShortcutPath -PathType Leaf
    startupShortcut = $startupShortcutPath
    bubbleLayout = $bubbleLayout
    overlayProbe = $probe
} | ConvertTo-Json -Depth 5 -Compress
