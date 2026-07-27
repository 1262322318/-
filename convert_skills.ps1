# Script to properly convert skill files with new front-matter

$frontMatterRC = @"
---
name: requirement-converter
version: 1.0.0
description: "需求转换。将原始需求输入（粘贴文本、CSV内容、口头描述、会议纪要等）转换为标准化的.md文件，只做格式标准化和信息提取，不做业务判定。"
inclusion: manual
metadata:
  requires:
    bins: []
---
"@

$frontMatterIM = @"
---
name: interaction-metrics
version: 1.0.0
description: "交互度量记录。记录每次需求处理过程的交互度量数据，区分用户侧/框架侧问题，识别瓶颈阶段，生成归因分析和改进Backlog。"
inclusion: manual
metadata:
  requires:
    bins: []
---
"@

# Process requirement-converter
$srcRC = Get-Content "C:\Users\12623\Downloads\KrioCase2\KrioCase2\KrioCase2\.kiro\skills\requirement-converter.md" -Raw -Encoding UTF8
$linesRC = $srcRC -split "`r?`n"
# Skip first 3 lines (old front-matter: ---, inclusion: manual, ---)
# Body starts at index 3 (line 4)
$bodyRC = $linesRC[3..($linesRC.Count-1)] -join "`n"
$fullRC = $frontMatterRC + "`n`n" + $bodyRC
[System.IO.File]::WriteAllText("D:\KiroCase\KrioCase2\.kiro\skills\requirement-converter\SKILL.md", $fullRC, [System.Text.UTF8Encoding]::new($false))
$rcCount = ($fullRC -split "`n").Count
Write-Host "requirement-converter SKILL.md written: $rcCount lines"

# Process interaction-metrics
$srcIM = Get-Content "C:\Users\12623\Downloads\KrioCase2\KrioCase2\KrioCase2\.kiro\skills\interaction-metrics.md" -Raw -Encoding UTF8
$linesIM = $srcIM -split "`r?`n"
# Skip first 3 lines (old front-matter: ---, inclusion: manual, ---)
$bodyIM = $linesIM[3..($linesIM.Count-1)] -join "`n"
$fullIM = $frontMatterIM + "`n`n" + $bodyIM
[System.IO.File]::WriteAllText("D:\KiroCase\KrioCase2\.kiro\skills\interaction-metrics\SKILL.md", $fullIM, [System.Text.UTF8Encoding]::new($false))
$imCount = ($fullIM -split "`n").Count
Write-Host "interaction-metrics SKILL.md written: $imCount lines"

# Verification
Write-Host ""
Write-Host "=== Verification ==="
Write-Host "Source RC lines: $($linesRC.Count)"
Write-Host "Source RC body lines (from line 4): $(($linesRC.Count - 3))"
Write-Host "New RC total lines: $rcCount"
Write-Host "Expected RC lines: $(9 + 1 + ($linesRC.Count - 3)) (9 front-matter + 1 blank + body)"
Write-Host ""
Write-Host "Source IM lines: $($linesIM.Count)"
Write-Host "Source IM body lines (from line 4): $(($linesIM.Count - 3))"
Write-Host "New IM total lines: $imCount"
Write-Host "Expected IM lines: $(9 + 1 + ($linesIM.Count - 3)) (9 front-matter + 1 blank + body)"
