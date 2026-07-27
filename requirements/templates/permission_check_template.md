# 权限检查报告 - {requirement_name}

## 检查信息
- **检查日期**: {check_date}
- **检查用户**: {username}
- **需求ID**: {requirement_id}
- **数据来源**: .kiro/data/table_permissions.csv

## 检查结果摘要
- **总表数**: {total_count}
- **有权限表**: {granted_count}
- **无权限表**: {denied_count}
- **未知状态**: {unknown_count}

## 详细结果

### 有权限表 (✅)
| 表名 | 权限级别 | 最后验证 |
|------|----------|----------|
{granted_rows}

### 无权限表 (❌)
| 表名 | 问题描述 | 建议解决方案 |
|------|----------|--------------|
{denied_rows}

### 未知状态 (⚠️)
| 表名 | 问题描述 | 建议解决方案 |
|------|----------|--------------|
{unknown_rows}

## 权限问题处理

### 阻塞性问题（必须解决）
{blocking_issues}

### 警告性问题（建议解决）
{warning_issues}

## 下一步行动
{next_actions}
