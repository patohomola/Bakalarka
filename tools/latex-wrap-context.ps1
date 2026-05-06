param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [int]$MaxWidth = 80
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$formatter = Join-Path $scriptDir "latex-wrap.ps1"

if (-not (Test-Path -LiteralPath $formatter)) {
    Write-Error "Formatter script not found: $formatter"
    exit 1
}

if (-not (Test-Path -LiteralPath $Target)) {
    Write-Error "Target path does not exist: $Target"
    exit 1
}

$resolvedTarget = (Resolve-Path -LiteralPath $Target).Path
$item = Get-Item -LiteralPath $resolvedTarget

Write-Host "LaTeX wrap formatter"
Write-Host "Target: $resolvedTarget"
Write-Host "Max width: $MaxWidth"
Write-Host ""

if ($item.PSIsContainer) {
    & $formatter -Root $resolvedTarget -Include "*.tex" -Recurse -MaxWidth $MaxWidth -InPlace
}
else {
    $parent = Split-Path -Parent $resolvedTarget
    $name = Split-Path -Leaf $resolvedTarget
    & $formatter -Root $parent -Include $name -MaxWidth $MaxWidth -InPlace
}

Write-Host ""
Write-Host "Done."
