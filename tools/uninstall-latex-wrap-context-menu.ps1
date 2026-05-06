Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$entries = @(
    "HKCU:\Software\Classes\*\shell\LatexWrap80",
    "HKCU:\Software\Classes\Directory\shell\LatexWrap80",
    "HKCU:\Software\Classes\Directory\Background\shell\LatexWrap80"
)

foreach ($entry in $entries) {
    if (Test-Path -LiteralPath $entry) {
        Remove-Item -LiteralPath $entry -Recurse -Force
        Write-Host "Removed: $entry"
    }
}

Write-Host "Context menu uninstalled."
