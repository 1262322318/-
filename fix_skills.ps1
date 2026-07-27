# Fix skill files - read source as raw bytes, replace front-matter bytes, write result

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# === requirement-converter ===
$srcPath = "C:\Users\12623\Downloads\KrioCase2\KrioCase2\KrioCase2\.kiro\skills\requirement-converter.md"
$dstPath = "D:\KiroCase\KrioCase2\.kiro\skills\requirement-converter\SKILL.md"

# Read source as UTF-8
$srcBytes = [System.IO.File]::ReadAllBytes($srcPath)
$srcText = $utf8NoBom.GetString($srcBytes)

# Find end of old front-matter (the second "---" line)
$lines = $srcText -split "`r?`n"
$fmEnd = -1
$fmCount = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '---') {
        $fmCount++
        if ($fmCount -eq 2) { $fmEnd = $i; break }
    }
}

# Body = everything after front-matter
$bodyLines = $lines[($fmEnd + 1)..($lines.Count - 1)]
$body = $bodyLines -join "`n"

# Read new front-matter from a separate file
$fmPath = "D:\KiroCase\KrioCase2\.kiro\skills\requirement-converter\frontmatter.txt"
$fmText = $utf8NoBom.GetString([System.IO.File]::ReadAllBytes($fmPath))

# Combine
$result = $fmText + "`n" + $body

# Write
$dir = [System.IO.Path]::GetDirectoryName($dstPath)
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($dstPath, $result, $utf8NoBom)

$resultLines = ($result -split "`n").Count
Write-Host "RC: Written $resultLines lines to $dstPath"

# === interaction-metrics ===
$srcPath2 = "C:\Users\12623\Downloads\KrioCase2\KrioCase2\KrioCase2\.kiro\skills\interaction-metrics.md"
$dstPath2 = "D:\KiroCase\KrioCase2\.kiro\skills\interaction-metrics\SKILL.md"

$srcBytes2 = [System.IO.File]::ReadAllBytes($srcPath2)
$srcText2 = $utf8NoBom.GetString($srcBytes2)

$lines2 = $srcText2 -split "`r?`n"
$fmEnd2 = -1
$fmCount2 = 0
for ($i = 0; $i -lt $lines2.Count; $i++) {
    if ($lines2[$i].Trim() -eq '---') {
        $fmCount2++
        if ($fmCount2 -eq 2) { $fmEnd2 = $i; break }
    }
}

$bodyLines2 = $lines2[($fmEnd2 + 1)..($lines2.Count - 1)]
$body2 = $bodyLines2 -join "`n"

$fmPath2 = "D:\KiroCase\KrioCase2\.kiro\skills\interaction-metrics\frontmatter.txt"
$fmText2 = $utf8NoBom.GetString([System.IO.File]::ReadAllBytes($fmPath2))

$result2 = $fmText2 + "`n" + $body2

$dir2 = [System.IO.Path]::GetDirectoryName($dstPath2)
if (-not (Test-Path $dir2)) { New-Item -ItemType Directory -Path $dir2 -Force | Out-Null }
[System.IO.File]::WriteAllText($dstPath2, $result2, $utf8NoBom)

$resultLines2 = ($result2 -split "`n").Count
Write-Host "IM: Written $resultLines2 lines to $dstPath2"
