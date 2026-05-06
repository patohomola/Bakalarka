Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $scriptDir "latex-wrap-context.ps1"

if (-not (Test-Path -LiteralPath $launcher)) {
    Write-Error "Launcher script not found: $launcher"
    exit 1
}

$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File `"$launcher`" -Target `"%1`""
$cmdBackground = "powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File `"$launcher`" -Target `"%V`""

$entries = @(
    "HKCU:\Software\Classes\*\shell\LatexWrap80",
    "HKCU:\Software\Classes\Directory\shell\LatexWrap80",
    "HKCU:\Software\Classes\Directory\Background\shell\LatexWrap80"
)

foreach ($entry in $entries) {
    New-Item -Path $entry -Force | Out-Null
    New-ItemProperty -Path $entry -Name "MUIVerb" -Value "Format LaTeX to 80 cols" -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $entry -Name "Icon" -Value "imageres.dll,-5302" -PropertyType String -Force | Out-Null

    $cmdPath = Join-Path $entry "command"
    New-Item -Path $cmdPath -Force | Out-Null

    if ($entry -like "*Background*") {
        Set-ItemProperty -Path $cmdPath -Name "(default)" -Value $cmdBackground
    }
    else {
        Set-ItemProperty -Path $cmdPath -Name "(default)" -Value $cmd
    }
}

Write-Host "Context menu installed for file, folder, and folder background."
Write-Host "You may need to restart Explorer to see it immediately."
