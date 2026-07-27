---
name: update-readmes
version: 1.0.0
description: "更新所有README。扫描项目中所有包含README.md的目录，根据目录当前实际内容重新生成/更新README.md，确保文档索引与实际文件保持同步。"
inclusion: manual
metadata:
  requires:
    bins: []
---

# 更新所有README技能

## 触发词
用户说以下任意一种时激活本技能：
- "更新README"、"更新所有readme"、"刷新文档索引"
- "同步README"、"更新目录说明"

## 技能说明
扫描项目中所有包含README.md的目录，根据目录当前实际内容重新生成/更新README.md，确保文档索引与实际文件保持同步。

## 覆盖范围

以下目录的README.md会被检查和更新：

| 目录 | README路径 |
|------|-----------|
| `.kiro/steering/` | `.kiro/steering/README.md` |
| `.kiro/skills/` | `.kiro/skills/README.md` |
| `.kiro/hooks/` | `.kiro/hooks/README.md` |
| `.kiro/settings/` | `.kiro/settings/README.md` |
| `.kiro/specs/` | `.kiro/specs/README.md` |
| `.kiro/data/` | `.kiro/data/README.md` |
| `requirements/` | `requirements/README.md` |
| `audit-feedback/` | `audit-feedback/README.md` |

## 执行步骤

### 1. 扫描所有目标目录
对每个目录执行 `list_directory`，获取当前文件列表。

### 2. 对比现有README
读取每个目录的README.md，检查文件清单是否与实际文件一致。

### 3. 识别差异（逐文件核对，禁止跳过）

**强制规则**：对比时必须逐文件列出，禁止批量判定"无变化"。具体做法：
1. 将目录中的实际文件列表记为集合A
2. 将README文件清单表格中列出的文件记为集合B
3. 逐一检查：A中有但B中没有的 → 标记为"新增"
4. 逐一检查：B中有但A中没有的 → 标记为"已删除"
5. 只有当A和B完全一致时才标记"无变化"

**禁止行为**：
- 禁止只看文件数量是否相同就判定"无变化"（文件数相同但内容不同也是差异）
- 禁止跳过任何目录的对比步骤
- 禁止在未逐文件核对的情况下输出"无变化"

对每个目录输出差异：
```
[目录名]（实际文件数: X，README记录数: Y）：
  + 新增文件（README中没有但目录中存在）：[文件列表]
  - 已删除文件（README中有但目录中不存在）：[文件列表]
  ~ 无变化（已逐文件核对确认）
```

### 4. 确认更新
向用户展示所有差异，询问：
```
以下目录的README需要更新：

1. .kiro/skills/ — 新增1个文件
2. .kiro/hooks/ — 新增1个文件
3. requirements/ — 无变化

是否全部更新？（全部更新 / 选择性更新 / 取消）
```

### 5. 执行更新
用户确认后，对每个有差异的README执行更新：
- 保留README的整体结构和说明文字
- 更新文件清单表格（新增行/删除行）
- 更新统计数字
- 保留用户手写的额外说明

### 6. 输出结果
```
✅ README更新完成：

- .kiro/skills/README.md — 更新（+1文件）
- .kiro/hooks/README.md — 更新（+1文件）
- .kiro/steering/README.md — 无需更新
- ...

共更新 [N] 个README文件。
```

## README生成规则

每个README必须包含以下结构：
1. **标题**：`# 目录名 + 中文说明`
2. **说明**：一段话描述目录用途
3. **文件清单**：表格形式列出所有文件及其功能
4. **使用方式**（如适用）
5. **注意事项**（如适用）

## 注意事项
- 本技能通过 `#update-readmes` 手动引用激活
- 更新前会展示差异让用户确认，不会静默覆盖
- 不会修改README中用户手写的额外内容（只更新文件清单部分）
- steering/README.md 由于结构较复杂（含依赖关系图），更新时只同步文件清单表格
