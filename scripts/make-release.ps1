<#
.SYNOPSIS
  Builds the distributable archive: a Data-rooted zip a mod manager can install.

.DESCRIPTION
  deploy-dev.ps1 stages the same files into Vortex for testing. This makes the
  thing a stranger downloads, from the same build folders, so the two cannot drift.

  What it refuses, and why:
    - a VERSION that is not a plain x.y.z, or one already built (-Force rebuilds it
      on purpose);
    - uncommitted changes to anything that ships: a zip must be a commit, or nobody
      can say what is in it;
    - a script whose .pex is older than its .psc, and a plugin older than the tools
      that generate it: a stale build ships last week's behaviour under this
      week's number.

  THE VOICE SHIPS LOOSE, never packed into a BA2. Rapport lends a borrowed voice
  to a line whose own voice type has no file (O-43), and it decides that by
  looking for the LOOSE file under Sound\Voice\Overture.esp. Packed into an
  archive, every line would look missing and borrow, or go silent.

  ASCII only, deliberately: Windows PowerShell 5.1 reads a BOM-less UTF-8 script
  as ANSI, and one em dash turns it into a parse error that still exits 0.
#>
[CmdletBinding()]
param(
    [switch] $Force,
    [string] $OutDir = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $OutDir) { $OutDir = Join-Path $root 'build\release' }

$version = (Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') { throw "VERSION must hold a plain x.y.z, not '$version'" }
$zip = Join-Path $OutDir "Overture-$version.zip"
if ((Test-Path $zip) -and -not $Force) {
    throw "Overture-$version.zip already exists. Bump VERSION, or pass -Force to rebuild this exact version on purpose."
}

# ---- the source must be a commit -------------------------------------------------
Push-Location $root
try {
    $dirty = @(git status --porcelain -- papyrus tools voice data VERSION 2>$null)
} finally {
    Pop-Location
}
if ($dirty.Count -gt 0) {
    throw ("Uncommitted changes to shipped sources - commit them first:`n  " + ($dirty -join "`n  "))
}

# ---- the build must be current ---------------------------------------------------
$esp = Join-Path $root 'build\Overture.esp'
if (-not (Test-Path $esp)) { throw "No build\Overture.esp. Run tools/make_overture_esp.py." }
$newestTool = Get-ChildItem (Join-Path $root 'tools') -Filter *.py | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($newestTool -and (Get-Item $esp).LastWriteTime -lt $newestTool.LastWriteTime) {
    throw "build\Overture.esp is older than tools\$($newestTool.Name). Run tools/make_overture_esp.py."
}

$psc = Join-Path $root 'papyrus\Overture'
$pex = Join-Path $root 'build\papyrus\Overture'
$stale = @()
Get-ChildItem $psc -Recurse -Filter *.psc | ForEach-Object {
    $compiled = Join-Path $pex ($_.FullName.Substring($psc.Length + 1) -replace '\.psc$', '.pex')
    if (-not (Test-Path $compiled)) { $stale += "missing  $compiled" }
    elseif ((Get-Item $compiled).LastWriteTime -lt $_.LastWriteTime) { $stale += "stale    $compiled" }
}
if ($stale.Count -gt 0) {
    throw ("Run scripts/build-papyrus.ps1 - these do not match their source:`n  " + ($stale -join "`n  "))
}

$voice = Join-Path $root 'build\voice\Sound\Voice\Overture.esp'
if (-not (Test-Path $voice)) { throw "No build\voice. Run scripts/stage-voice.py - without it every line is subtitle-only." }

# ---- assemble ---------------------------------------------------------------------
$stage = Join-Path $OutDir "Overture-$version"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item $esp $stage -Force

# Every compiled script, namespace folders included (Overture:Companions:*,
# Overture:Fragments:AskPerk): a folder copied by name is the next namespace missing.
Get-ChildItem $pex -Recurse -Filter *.pex | ForEach-Object {
    $dst = Join-Path (Join-Path $stage 'Scripts\Overture') $_.FullName.Substring($pex.Length + 1)
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    Copy-Item $_.FullName $dst -Force
}

$mcm = Join-Path $root 'data\MCM'
if (-not (Test-Path $mcm)) { throw "No data\MCM. Run tools/make_mcm.py." }
Copy-Item $mcm $stage -Recurse -Force

$voiceOut = Join-Path $stage 'Sound\Voice\Overture.esp'
New-Item -ItemType Directory -Force $voiceOut | Out-Null
Copy-Item (Join-Path $voice '*') $voiceOut -Recurse -Force

foreach ($doc in 'LICENSE', 'README.md', 'CHANGELOG.md') {
    $p = Join-Path $root $doc
    if (Test-Path $p) { Copy-Item $p $stage -Force }
}

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal

# ---- report -------------------------------------------------------------------------
$files = @(Get-ChildItem $stage -Recurse -File)
$voiceFiles = @($files | Where-Object { $_.FullName.StartsWith($voiceOut, [StringComparison]::OrdinalIgnoreCase) })
Write-Host "Overture $version"
Write-Host ''
Write-Host 'Contents (voice summarised):'
$files | Where-Object { -not $_.FullName.StartsWith($voiceOut, [StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object { $_.FullName.Substring($stage.Length + 1) } | Sort-Object | ForEach-Object { Write-Host "    $_" }
Get-ChildItem $voiceOut -Directory | Sort-Object Name | ForEach-Object {
    Write-Host ("    Sound\Voice\Overture.esp\{0}\  {1} file(s)" -f $_.Name, @(Get-ChildItem $_.FullName -File).Count)
}
$item = Get-Item $zip
Write-Host ''
Write-Host ("  {0}" -f $item.FullName)
Write-Host ("  {0:N0} bytes, {1} file(s), {2} of them voice" -f $item.Length, $files.Count, $voiceFiles.Count)
Write-Host ''
Write-Host 'Requires Rapport 0.2.1 or newer (API 201), XDI.esm and AAF. Against an older Rapport it runs without narration, names or lovers, and says so.'
