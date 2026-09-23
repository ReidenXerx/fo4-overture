<#
.SYNOPSIS
  Stage Overture into Vortex for a dev test.

.DESCRIPTION
  Builds nothing. Copies the already-built plugin and scripts into a Vortex mod
  folder, then stops and tells you what it cannot do for you.

  IT CANNOT ENABLE THE PLUGIN. Overture.esp is a NEW file, and Vortex only picks
  a new file up when someone presses Deploy; until then the staging folder has it
  and the game does not. Worse, Vortex can write a new plugin into plugins.txt
  DISABLED, which produces Fallout 4's "content no longer present" box on the
  next load of any save made while it was enabled. That happened on this machine
  today with another mod's esp, so this script refuses to pretend otherwise.

  The game must be closed. Vortex may stay open.
#>
[CmdletBinding()]
param(
    [string] $Staging = 'D:\Vortex\fallout4\mods\Overture-dev'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if (Get-Process -Name 'Fallout4' -ErrorAction SilentlyContinue) {
    throw 'Fallout4 is running. Close it first - a deploy over a running game is how you get a half-updated plugin.'
}

$esp = Join-Path $root 'build\Overture.esp'
$pex = Join-Path $root 'build\papyrus'
if (-not (Test-Path $esp)) { throw "No $esp. Run tools/make_overture_esp.py first." }
if (-not (Test-Path $pex)) { throw "No $pex. Run scripts/build-papyrus.ps1 first." }

New-Item -ItemType Directory -Force (Join-Path $Staging 'Scripts\Overture') | Out-Null
Copy-Item $esp (Join-Path $Staging 'Overture.esp') -Force
Copy-Item (Join-Path $pex 'Overture\*.pex') (Join-Path $Staging 'Scripts\Overture') -Force

# The MCM page (tools/make_mcm.py). A new file the first time: Vortex's Deploy puts it in Data.
$mcm = Join-Path $root 'data\MCM'
if (Test-Path $mcm) {
    New-Item -ItemType Directory -Force (Join-Path $Staging 'MCM') | Out-Null
    Copy-Item (Join-Path $mcm '*') (Join-Path $Staging 'MCM') -Recurse -Force
}

# The voice (scripts/stage-voice.py): <VoiceType>\<INFO id>_1.fuz, lip sync packed in.
# Vortex deploys by HARDLINK, so a changed file is rewritten IN PLACE - the game's
# copy is the same file and sees the new bytes. Deleting and re-copying would leave
# Data holding the old audio until the next Deploy. A NEW file still needs Deploy.
# Files the build no longer names are removed: audio for a line that is gone.
$voiceSrc = Join-Path $root 'build\voice\Sound\Voice\Overture.esp'
$voiceDst = Join-Path $Staging 'Sound\Voice\Overture.esp'
$voiceNew = 0; $voiceUpdated = 0; $voiceRemoved = 0
if (Test-Path $voiceSrc) {
    $wanted = @{}
    Get-ChildItem -Recurse -File $voiceSrc | ForEach-Object {
        $dst = Join-Path $voiceDst $_.FullName.Substring($voiceSrc.Length + 1)
        $wanted[$dst.ToLowerInvariant()] = $true
        if (-not (Test-Path $dst)) {
            New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
            Copy-Item $_.FullName $dst
            $voiceNew++
        } elseif ((Get-FileHash $dst).Hash -ne (Get-FileHash $_.FullName).Hash) {
            [IO.File]::WriteAllBytes($dst, [IO.File]::ReadAllBytes($_.FullName))
            $voiceUpdated++
        }
    }
    if (Test-Path $voiceDst) {
        Get-ChildItem -Recurse -File $voiceDst |
            Where-Object { -not $wanted.ContainsKey($_.FullName.ToLowerInvariant()) } |
            ForEach-Object { Remove-Item $_.FullName; $voiceRemoved++ }
    }
} else {
    Write-Host 'No build\voice - run scripts/stage-voice.py. Every line will be subtitle-only.'
}

Get-ChildItem -Recurse -File $Staging |
    Where-Object { -not $_.FullName.StartsWith($voiceDst, [StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object { '  {0}  {1} bytes  {2:HH:mm:ss}' -f $_.FullName, $_.Length, $_.LastWriteTime }
'  voice: {0} new, {1} updated in place, {2} removed  ({3})' -f $voiceNew, $voiceUpdated, $voiceRemoved, $voiceDst

Write-Host ''
Write-Host 'Staged. THREE THINGS THIS SCRIPT CANNOT DO:'
Write-Host '  1. Enable the mod in Vortex (it is new - it will not be listed until you refresh).'
Write-Host '  2. Press Deploy, which is what puts Overture.esp where the game can see it.'
Write-Host '     Also needed for every NEW voice file above; updated ones are live already.'
Write-Host '  3. Tick Overture.esp in the plugins list. Vortex may add it DISABLED.'
Write-Host ''
Write-Host 'Requires XDI.esm and Fallout4.esm. Load order: after Rapport.esp is fine.'
