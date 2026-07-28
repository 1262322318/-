# MCP 表结构查询契约（全项目唯一事实源）

> 本文件是整条链路（需求精化 PRD / 需求开发）查询表结构的**唯一入口**。
> 所有 skill 与 steering 文件**只引用本文件**，不得再各自内嵌 SQL 或连接信息。
> 引用写法：`见 .kiro/skills/etl-requirement/mcp-table-metadata.md`。

## 一、连接（不在本文件里）

- MCP server 名称：**`postgres`**
- 连接串（host/端口/库/账号/口令）**只存于运行 Agent 的 `mcp_config` / `custom_env`**，本文件与任何 skill/steering **都不写连接信息**。
- 迁移含义：更换数据库/主机/账号时，**只改 Agent 的 `mcp_config` 一处**；本契约与所有引用方均无需改动。
- 若 MCP server 名称变化（不再叫 `postgres`），**只改本文件"名称"这一行**，全链路引用自动生效。

## 二、标准查询范式（只用这几条，禁止自造变体）

```sql
-- Q1 查某张表的完整字段列表（最常用：字段映射、骨架校验、投喂采集）
SELECT column_name, column_type, column_comment
FROM public.table_metadata
WHERE table_name = '{表名}' ORDER BY id;

-- Q2 验证某张表是否存在
SELECT DISTINCT table_name, table_comment
FROM public.table_metadata
WHERE table_name = '{表名}';

-- Q3 验证某个字段是否存在
SELECT column_name, column_type, column_comment
FROM public.table_metadata
WHERE table_name = '{表名}' AND column_name = '{字段名}';

-- Q4 列出某个库下所有表
SELECT DISTINCT table_name, table_comment
FROM public.table_metadata
WHERE db_name = '{库名}' ORDER BY table_name;

-- Q5 按关键词搜索字段（跨表）
SELECT table_name, column_name, column_type, column_comment
FROM public.table_metadata
WHERE column_comment LIKE '%{关键词}%' ORDER BY table_name, id;
```

## 三、失败 / 降级（红线，全链路强制）

当 MCP 不可用、连接失败、或查询无结果（表/字段未录入 `table_metadata`）时：

1. **禁止凭记忆或假设编写字段名/类型**——这是硬规则，任何链路都不得绕过。
2. 立即停止当前字段推断，明确提示：`MCP 未命中：{表名}[.{字段名}]，需人工确认表结构`。
3. 把该项标注为 `【待确认-MCP未匹配】` 并列入待澄清项，交用户确认后再继续。

## 四、被引用方（改本文件 = 全链路生效）

| 阶段 | 文件 | 用途 |
|------|------|------|
| PRD 精化 | `.kiro/skills/requirement-refiner/SKILL.md` | 步骤3 字段映射、步骤4 确定度、步骤9 自检 → Q1 |
| 需求开发 | `.kiro/skills/etl-requirement/SKILL.md` | A3 表匹配 / A4 骨架校验 / 链路B 改前校验 → Q1/Q2/Q3 |
| 开发流程 | `.kiro/steering/etl_dialogue_flow.md` | 表可用性验证、PRD 字段核对 → Q1/Q3 |
| 权限检查 | `.kiro/steering/table_validation.md` | 表/字段存在性 → Q2/Q3 |
| 表语义索引 | `.kiro/steering/table_structures.md` | 字段详情 → Q1/Q4/Q5 |
| 关键词映射 | `.kiro/steering/data_mapping.md` | 字段详情 → Q1 |
| 知识投喂 | `.kiro/skills/knowledge-feeding/SKILL.md` | 字段采集 → Q1 |
| 健康检查 | `.kiro/skills/knowledge-health-check/SKILL.md` | 交叉验证 → Q2/Q3 |
