<#
.SYNOPSIS
  Compile-checks the companion scaffolds. Nothing here is deployed.

.DESCRIPTION
  Compiles companions/common, then each variant directory on top of it, into
  build/companions-check/<variant>/ -- never into build/papyrus (the shipping
  output) and never into Data/Scripts (Vortex-deployed).

  Each variant is compiled SEPARATELY, with common on its import path, because
  two variants are two answers to the same question and may define the same
  script names.

  ASCII only (Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI).

  Run it with pwsh (PowerShell 7). On 2026-09-23 the same files compiled clean
  under pwsh 7, while Windows PowerShell 5.1 (started from Git Bash) died with a
  NativeCommandError quoting "filename does not match script name" for
  Track.psc. Not diagnosed -- only observed, once, on each host.
#>
[CmdletBinding()]
param(
    [string] $Base       = 'D:\F4CustomMods\PapyrusBase\Source\Base',
    [string] $Compiler   = 'D:\GOGGames\Fallout 4 GOTY\Papyrus Compiler\PapyrusCompiler.exe',
    [string] $RapportSrc = 'C:\Users\DuduPhudu\Documents\Projects\fo4-rapport\papyrus'
)

$ErrorActionPreference = 'Stop'
$here   = Split-Path -Parent $PSScriptRoot
$root   = Split-Path -Parent $here
$common = Join-Path $here 'common'
$out    = Join-Path $root 'build\companions-check'

if (-not (Test-Path $Compiler)) { throw "No Papyrus compiler at $Compiler." }

$failed = 0
$targets = @(@{ Name = 'common'; Dir = $common })
Get-ChildItem -Path $here -Directory | Where-Object { $_.Name -like 'variant-*' } | ForEach-Object {
    $targets += @{ Name = $_.Name; Dir = $_.FullName }
}

foreach ($t in $targets) {
    $dest = Join-Path $out $t.Name
    New-Item -ItemType Directory -Force $dest | Out-Null
    $imports = @($Base, $common, $t.Dir, $RapportSrc) -join ';'
    $log = & $Compiler $t.Dir -import="$imports" -output="$dest" -flags='Institute_Papyrus_Flags.flg' -all 2>&1
    $bad = $log | Select-String -Pattern '(error|failed)' -CaseSensitive:$false |
        Where-Object { $_.Line -notmatch '0 failed' }
    if ($LASTEXITCODE -ne 0 -or $bad) {
        $failed += 1
        Write-Host ("FAIL  {0}" -f $t.Name)
        $log | ForEach-Object { Write-Host ("      {0}" -f $_) }
    } else {
        $n = (Get-ChildItem -Path $dest -Recurse -Filter *.pex).Count
        Write-Host ("ok    {0}  ({1} pex)" -f $t.Name, $n)
    }
}
if ($failed -gt 0) { exit 1 }
