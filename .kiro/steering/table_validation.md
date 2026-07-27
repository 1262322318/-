---
inclusion: manual
---
# 表验证与权限检查流程（纯Kiro方案）

## 概述

本文档定义表验证与权限检查流程。Agent直接读取CSV文件检查权限，用fsWrite输出报告，不依赖任何Python脚本。

## 数据源

### 表元数据
- **数据源**：`public.table_metadata`（PostgreSQL）
- **用途**：验证表/字段是否存在

### 权限数据
- **数据源**：`public.table_privilege_type`（PostgreSQL）
- **用途**：查询账户对表的权限
- **字段说明**：
  - `table_schema`：数据库名
  - `table_name`：表名
  - `grantee`：账户名
  - `privilege_type`：权限类型（SELECT/INSERT/DROP/ALTER/CREATE）
  - `table_comment`：表备注

### 默认检查账户
| 配置项 | 值 |
|--------|-----|
| 默认用户名 | `ds_rd_rw` |
| 用途 | ETL开发和权限检查 |

## Agent执行流程

### 1. 识别涉及表
从需求分析结果中提取所有涉及的表（源表、目标表、维度表）

### 2. 验证表和字段存在性（通过 table_metadata）
Agent通过MCP postgres查询 `public.table_metadata` 验证：
```sql
-- 验证表是否存在
SELECT DISTINCT table_name, table_comment FROM public.table_metadata WHERE table_name = '{表名}';

-- 验证字段是否存在
SELECT column_name, column_type, column_comment FROM public.table_metadata 
WHERE table_name = '{表名}' AND column_name = '{字段名}';
```
- 表存在 → ✅ 继续检查权限
- 表不存在 → ❌ 表未录入元数据，需确认表名是否正确
- 字段不存在 → ⚠️ 字段可能拼写错误或表结构已变更

### 3. 查询权限（通过 table_privilege_type）
Agent通过MCP postgres查询 `public.table_privilege_type` 验证权限：
```sql
-- 查询指定账户对某张表的权限
SELECT table_schema, table_name, grantee, privilege_type, table_comment 
FROM public.table_privilege_type 
WHERE table_name = '{表名}' AND grantee = 'ds_rd_rw';
```

### 4. 逐表判定权限
对每个表，根据查询结果判定：
- 查到 privilege_type 包含 SELECT → ✅ 有读权限
- 查到 privilege_type 包含 INSERT → ✅ 有写权限
- 查到 privilege_type 包含 DROP → ✅ 有DDL权限
- 查询结果为空（无记录） → ❌ 无权限或 ⚠️ 未授权

### 5. 输出报告
Agent使用fsWrite创建 `permission_check.md` 到需求文件夹，格式参考 `requirements/templates/permission_check_template.md`

## 最佳实践
1. 需求分析完成后立即检查权限
2. 发现无权限的表及时反馈给用户
3. 权限数据来自线上系统，实时准确
