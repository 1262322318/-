---
name: sql-template-extract
version: 1.0.0
description: "SQL模板提取。从指定的已有SQL脚本中自动提取可复用的模式/CTE/结构，写入sql_templates.md作为实战模板。"
inclusion: manual
metadata:
  requires:
    bins: []
---

# SQL模板提取技能

## 触发词
用户说以下任意一种时激活本技能：
- "提取模板"、"学习SQL"、"从SQL中提取模式"
- "更新模板库"、"充实模板"

## 技能说明
从指定的已有SQL脚本中自动提取可复用的模式/CTE/结构，写入 sql_templates.md 作为实战模板。让助手从实际业务SQL中"学习"，而非依赖通用模板。

## 执行步骤

### 1. 确定输入源

```
请指定要从中提取模板的SQL文件：
A. 输入文件路径
B. 说"当前文件"
C. 说"全部需求"（扫描所有 requirements/*/sql_scripts/*.sql）
```

### 2. 读取并分析SQL结构

Agent读取SQL后，识别以下可复用模式：

| 模式类型 | 识别规则 | 示例 |
|----------|----------|------|
| CTE模式 | WITH子句中的命名查询块 | `kucun_qingwei AS (...)` |
| DELETE+INSERT模式 | DELETE WHERE条件 + INSERT INTO SELECT | 幂等加载模式 |
| CASE分类模式 | 多条件CASE WHEN用于业务分类 | 产品线分类 |
| JOIN模式 | 特定的表关联方式 | 管报→MDG→型号 |
| 聚合模式 | GROUP BY + 聚合函数的组合 | ADS层汇总 |
| UNION ALL模式 | 多源数据合并 | 多源库存汇总 |

### 3. 展示提取结果

```
【模板提取结果】

从 {file_name} 中识别到以下可复用模式：

1. CTE: {cte_name}
   用途：{描述}
   可复用度：高/中/低
   是否已在模板库中：是/否

2. 模式: {pattern_name}
   用途：{描述}
   可复用度：高/中/低
   是否已在模板库中：是/否

...

建议新增到模板库的：[N]个
已存在无需新增的：[N]个

是否将建议项写入 sql_templates.md？
```

### 4. 用户确认后写入

将新模板追加到 `.kiro/steering/sql_templates.md` 的对应章节。

### 5. 模板去重

写入前检查：
- 新模板与已有模板的相似度是否>80%
- 如果高度相似，提示用户是否合并/替换/跳过

## 提取规则

### 高复用度判定
- 在多个需求的SQL中出现过相同结构 → 高
- 只在一个需求中出现但逻辑通用 → 中
- 高度业务特化，难以复用 → 低（不建议提取）

### 模板抽象规则
- 将具体的表名替换为 `{table_name}` 占位符
- 将具体的字段列表替换为 `{field_list}` 占位符
- 保留核心逻辑结构（CASE条件、JOIN方式、聚合方式）
- 保留注释说明

## 注意事项
- 通过 `#sql-template-extract` 手动引用激活
- 提取后的模板会标注来源（从哪个需求的哪个SQL提取）
- 不会修改原始SQL文件，只写入模板库
