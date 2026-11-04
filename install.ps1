param(
    [string]$Target = "."
)

$ErrorActionPreference = "Stop"

$Target = (Resolve-Path $Target).Path
$SourceMod = Join-Path $Target "addons\sourcemod"
if (-not (Test-Path $SourceMod)) {
    Write-Host "Usage: .\install.ps1 -Target C:\path\to\csgo"
    exit 1
}

$Package = Split-Path -Parent $MyInvocation.MyCommand.Path
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Backup = Join-Path $SourceMod "plugins\disabled\threi-backup-$Stamp"
foreach ($sub in @("plugins", "gamedata", "translations", "cfg")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Backup $sub) | Out-Null
}

Write-Host "[ThRei] target: $Target"
Write-Host "[ThRei] backup: $Backup"

# Back up all current GOKZ files before replacing the whole stack.
$sourceModDirs = @{
    "plugins" = "plugins"
    "gamedata" = "gamedata"
    "translations" = "translations"
}
foreach ($name in $sourceModDirs.Keys) {
    $src = Join-Path $SourceMod $sourceModDirs[$name]
    if (Test-Path $src) {
        Get-ChildItem $src -File | Copy-Item -Destination (Join-Path $Backup $name) -Force
    }
}
$targetGokzCfg = Join-Path $Target "cfg\sourcemod\gokz"
if (Test-Path $targetGokzCfg) {
    Copy-Item $targetGokzCfg (Join-Path $Backup "cfg") -Recurse -Force
}

# Old plugins have different filenames, so extraction cannot remove them.
foreach ($file in @("GlobalAPI-Core.smx", "GlobalAPI-Jumpstats.smx")) {
    $path = Join-Path $SourceMod "plugins\$file"
    if (Test-Path $path) {
        Move-Item $path (Join-Path $Backup "plugins") -Force
        Write-Host "[ThRei] disabled old plugin: $file"
    }
}

# GOKZ uploads directly now. Keeping the uploader loaded would duplicate runs.
$uploader = Join-Path $SourceMod "plugins\threi-kz-uploader.smx"
if (Test-Path $uploader) {
    Move-Item $uploader (Join-Path $Backup "plugins") -Force
    Write-Host "[ThRei] disabled uploader: threi-kz-uploader.smx (use it only for manual backfill)"
}

Copy-Item (Join-Path $Package "addons\*") (Join-Path $Target "addons") -Recurse -Force

# Full package also contains GOKZ game assets and default configs.
foreach ($dir in @("materials", "models", "sound", "maps")) {
    $src = Join-Path $Package $dir
    if (Test-Path $src) {
        $dst = Join-Path $Target $dir
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Copy-Item (Join-Path $src "*") $dst -Recurse -Force
    }
}

$pkgGokzCfg = Join-Path $Package "cfg\sourcemod\gokz"
if (Test-Path $pkgGokzCfg) {
    New-Item -ItemType Directory -Force -Path $targetGokzCfg | Out-Null
    Copy-Item (Join-Path $pkgGokzCfg "*") $targetGokzCfg -Recurse -Force
}

$convarsExample = Join-Path $Package "cfg\sourcemod\globalapi-convars.cfg.example"
$convarsTarget = Join-Path $Target "cfg\sourcemod\globalapi-convars.cfg"
if ((Test-Path $convarsExample) -and -not (Test-Path $convarsTarget)) {
    Copy-Item $convarsExample $convarsTarget -Force
}

$keyFile = Join-Path $Target "cfg\sourcemod\globalapi-key.cfg"
if (-not (Test-Path $keyFile)) {
    $keyDir = Split-Path -Parent $keyFile
    New-Item -ItemType Directory -Force -Path $keyDir | Out-Null
    Copy-Item (Join-Path $Package "cfg\sourcemod\globalapi-key.cfg.example") $keyFile -Force
    Write-Host "[ThRei] created $keyFile"
}

Write-Host ""
Write-Host "[ThRei] installed."
Write-Host "[ThRei] edit $keyFile and put your ThRei server key on the first line."
Write-Host "[ThRei] then change map or restart the server, and run !gc in game."
