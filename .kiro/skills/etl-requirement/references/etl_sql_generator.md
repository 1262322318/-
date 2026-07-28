---
inclusion: fileMatch
fileMatchPattern: "**/*.sql"
---
# SQL生成器规则（纯Kiro方案）

## 概述

本文档指导Kiro Agent如何在对话中完成SQL生成，包括模板选择、变量替换和分层SQL生成。Agent读取 `sql_templates.md` 中的模板，根据需求分析结果替换变量，生成最终SQL。

## SQL生成流程

```
需求分析结果 → 选择分层模板 → 准备变量映射 → 替换变量 → 输出SQL
```

### 步骤0：强制预检（不可跳过）
**在生成任何SQL之前**，Agent必须确认已读取以下规范：
- `sql_rules.md` — 特别是"INSERT+SELECT字段注释（强制）"规则
- `sql_templates.md` — 选择合适的实战模板

如果当前上下文中未加载这两个文件，Agent必须先读取后再开始生成。

### 步骤1：根据分层选择模板
- ADS层需求（报表、日报、月报）→ 使用ADS报表模板
- DWS层需求（分析、趋势、统计）→ 使用DWS分析模板
- DWD层需求（明细、清洗、转换）→ 使用DWD明细模板
- DIM层需求（维度、分类、属性）→ 使用DIM维度模板

### 步骤2：准备变量映射
从需求分析结果中提取变量值：

| 变量 | 来源 | 默认值 |
|------|------|--------|
| `{start_date}` | 用户指定的时间范围 | 最近30天的起始日期 |
| `{end_date}` | 用户指定的时间范围 | 当前日期 |
| `{product_dimension}` | 关键词匹配结果 | 从data_mapping.md获取 |
| `{region_dimension}` | 关键词匹配结果 | 从data_mapping.md获取 |
| `{time_granularity}` | 时间关键词（日报→day，月报→month） | day |
| `{fact_table_name}` | 根据主题和粒度生成 | [主题]_fact_[粒度] |
| `{summary_table_name}` | 根据主题和粒度生成 | [主题]_summary_[粒度] |
| `{report_table_name}` | 根据主题和粒度生成 | [主题]_[粒度]_report |

> **注意**：实际的表名、字段名从 `data_mapping.md` 中获取。如果 `data_mapping.md` 中无数据，提示用户先录入表映射。

### 步骤3：替换变量
Agent在对话中直接将模板中的 `{变量名}` 替换为实际值。

### 步骤4：输出SQL
将替换后的SQL用fsWrite写入 `sql_scripts/` 目录。

## 生成示例格式

**需求**："[需求描述]"

**变量映射**：
```
start_date = '[日期]'
end_date = '[日期]'
[维度变量] = [字段名]
```

**生成的SQL**：
```sql
-- Agent根据模板和变量生成的SQL
SELECT ...
FROM ...
WHERE ...;
```

## 错误处理

| 错误场景 | 处理方式 |
|----------|----------|
| data_mapping.md 中无表数据 | 提示用户先录入表映射数据 |
| 模板中有变量但未提供值 | 使用默认值，并提示用户 |
| 用户指定的时间格式不正确 | 提示正确格式，使用默认值 |
| 无法确定分层 | 默认使用ADS层，提示用户确认 |

## SQL编码规范

生成的SQL必须遵循以下规范（详见 `sql_rules.md`）：
- 关键字大写（SELECT、FROM、WHERE等）
- 4空格缩进
- 每行不超过100字符
- 包含标准文档头注释
- 兼容Apache Doris 2.1+语法
