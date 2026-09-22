<#
.SYNOPSIS
  Compiles Overture's Papyrus scripts.

.DESCRIPTION
  Compiles papyrus/ into build/papyrus/ against the reconstructed base sources,
  plus F4MCP's MCP\Bridge.psc and MCP\Core.psc, which are the addon contract.

  Those imports are IMPORT PATHS, never source paths. Compiled as sources they
  would emit .pex files shadowing another mod's scripts, and the loser of that
  collision is whichever one Vortex deploys last.

  NEVER compile into Data/Scripts. That directory is Vortex-deployed.

  ASCII only. Windows PowerShell 5.1 reads a BOM-less UTF-8 script as ANSI, and
  one non-ASCII character in a string turns this into a parse error that still
  exits 0.

  The decompiled base sources have NO default argument values, so every argument
  must be passed explicitly.
#>
[CmdletBinding()]
param(
    [string] $Base     = 'D:\F4CustomMods\PapyrusBase\Source\Base',
    [string] $Compiler = 'D:\GOGGames\Fallout 4 GOTY\Papyrus Compiler\PapyrusCompiler.exe',
    [string] $McpSrc   = 'C:\Users\DuduPhudu\Documents\Projects\fo4-mcp\papyrus',
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$sources = Join-Path $root 'papyrus'
$out     = Join-Path $root 'build\papyrus'

if (-not (Test-Path $Compiler)) {
    throw "No Papyrus compiler at $Compiler."
}
if (-not (Test-Path (Join-Path $Base 'Institute_Papyrus_Flags.flg'))) {
    throw "No Institute_Papyrus_Flags.flg in $Base."
}
if (-not (Test-Path (Join-Path $McpSrc 'MCP\Bridge.psc'))) {
    throw "No MCP\Bridge.psc under $McpSrc. Clone fo4-mcp beside this repo, or pass -McpSrc."
}

New-Item -ItemType Directory -Force $out | Out-Null

# $sources is on the IMPORT path as well as being the input directory. A
# namespaced script (Overture:Approach) compiled without it fails with
# "unable to locate script Overture:Approach" -- the namespace is resolved from
# the imports, not from the file's path. fo4-rapport carries the same comment.
$imports = @($Base, $sources, $McpSrc) -join ';'
$files = Get-ChildItem -Path $sources -Recurse -Filter *.psc
Write-Host ("Compiling {0} script(s) against {1}" -f $files.Count, $imports)

& $Compiler $sources `
    -import="$imports" `
    -output="$out" `
    -flags='Institute_Papyrus_Flags.flg' `
    -all `
    -optimize

if ($LASTEXITCODE -ne 0) {
    throw "Papyrus compile failed with exit code $LASTEXITCODE."
}

$pex = Get-ChildItem -Path $out -Recurse -Filter *.pex
Write-Host ("`n{0} .pex in {1}" -f $pex.Count, $out)
