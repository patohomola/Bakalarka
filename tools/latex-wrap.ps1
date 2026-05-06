param(
    [Parameter(Position = 0)]
    [string]$Root = ".",

    [int]$MaxWidth = 80,

    [switch]$InPlace,

    [switch]$Recurse,

    [string]$Include = "*.tex"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsSkippableLine {
    param([string]$Line)

    $trim = $Line.Trim()
    if ($trim -eq "") { return $true }

    if ($trim -match "^%") { return $true }
    if ($trim -match "^\\") { return $true }

    # Keep lines with likely comment content unchanged.
    if ($Line -match "(^|[^\\])%") { return $true }

    return $false
}

function Split-WrapText {
    param(
        [string]$Text,
        [int]$Width,
        [string]$Indent
    )

    $words = ($Text -replace "\s+", " ").Trim().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($words.Count -eq 0) { return @() }

    $lines = New-Object System.Collections.Generic.List[string]
    $current = ""

    foreach ($word in $words) {
        if ($current.Length -eq 0) {
            $current = $word
            continue
        }

        $candidate = "$current $word"
        if (($Indent.Length + $candidate.Length) -le $Width) {
            $current = $candidate
        }
        else {
            $lines.Add("$Indent$current")
            $current = $word
        }
    }

    if ($current.Length -gt 0) {
        $lines.Add("$Indent$current")
    }

    return $lines
}

function Flush-Paragraph {
    param(
        [System.Collections.Generic.List[string]]$Buffer,
        [System.Collections.Generic.List[string]]$Out,
        [int]$Width
    )

    if ($Buffer.Count -eq 0) { return }

    $firstLine = $Buffer[0]
    $indentMatch = [regex]::Match($firstLine, "^\s*")
    $indent = $indentMatch.Value

    $joined = ($Buffer -join " ")
    $wrapped = Split-WrapText -Text $joined -Width $Width -Indent $indent

    foreach ($line in $wrapped) {
        $Out.Add($line)
    }

    $Buffer.Clear()
}

function Format-LatexContent {
    param(
        [string[]]$Lines,
        [int]$Width
    )

    $out = New-Object System.Collections.Generic.List[string]
    $paragraph = New-Object System.Collections.Generic.List[string]

    $envStack = New-Object System.Collections.Generic.Stack[string]
    $doNotWrapEnvs = @(
        "verbatim", "lstlisting", "minted", "equation", "equation*", "align", "align*",
        "gather", "gather*", "multline", "multline*", "tikzpicture", "tabular", "table",
        "figure", "algorithm", "comment"
    )

    foreach ($line in $Lines) {
        $trim = $line.Trim()

        if ($trim -match "^\\begin\{([^\}]+)\}") {
            Flush-Paragraph -Buffer $paragraph -Out $out -Width $Width
            $envName = $matches[1]
            $envStack.Push($envName)
            $out.Add($line)
            continue
        }

        if ($trim -match "^\\end\{([^\}]+)\}") {
            Flush-Paragraph -Buffer $paragraph -Out $out -Width $Width
            $envName = $matches[1]
            if ($envStack.Count -gt 0 -and $envStack.Peek() -eq $envName) {
                [void]$envStack.Pop()
            }
            $out.Add($line)
            continue
        }

        $insideNoWrap = $false
        if ($envStack.Count -gt 0) {
            $active = $envStack.Peek()
            if ($doNotWrapEnvs -contains $active) {
                $insideNoWrap = $true
            }
        }

        if ($insideNoWrap) {
            Flush-Paragraph -Buffer $paragraph -Out $out -Width $Width
            $out.Add($line)
            continue
        }

        if (Test-IsSkippableLine -Line $line) {
            Flush-Paragraph -Buffer $paragraph -Out $out -Width $Width
            $out.Add($line)
            continue
        }

        $paragraph.Add($line.Trim())
    }

    Flush-Paragraph -Buffer $paragraph -Out $out -Width $Width

    return $out
}

$searchOpt = if ($Recurse) { "AllDirectories" } else { "TopDirectoryOnly" }
$rootPath = (Resolve-Path -Path $Root).Path
$files = [System.IO.Directory]::GetFiles($rootPath, $Include, $searchOpt)

if ($files.Count -eq 0) {
    Write-Host "No files matched '$Include' in '$rootPath'."
    exit 0
}

$changedFiles = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $original = [System.IO.File]::ReadAllLines($file)
    $formatted = Format-LatexContent -Lines $original -Width $MaxWidth

    if ($formatted.Count -ne $original.Count -or (($formatted -join "`n") -ne ($original -join "`n"))) {
        $changedFiles.Add($file)

        if ($InPlace) {
            [System.IO.File]::WriteAllLines($file, $formatted)
        }
    }
}

if ($changedFiles.Count -eq 0) {
    Write-Host "No formatting changes needed."
    exit 0
}

if ($InPlace) {
    Write-Host "Formatted $($changedFiles.Count) file(s):"
}
else {
    Write-Host "Would format $($changedFiles.Count) file(s) (dry run):"
}

$changedFiles | ForEach-Object { Write-Host " - $_" }
