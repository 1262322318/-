# 需求文档 - {requirement_name}

## 基本信息
- **需求ID**: {requirement_id}
- **创建日期**: {create_date}
- **创建人**: ETL智能辅助工具
- **业务部门**: {business_department}
- **优先级**: {priority}
- **状态**: 分析完成
- **数据仓库分层**: {layer}

## 业务背景
{business_background}

## 问题陈述
{problem_statement}

## 业务目标
{business_goals}

## 技术目标
{technical_goals}

## 涉及数据表
### 源表（读取）
{source_tables}

### 目标表（写入）
{target_tables}

### 维度表（关联）
{dimension_tables}

## 数据流程
```
{data_flow}
```

## 关键指标
{key_metrics}

## 业务规则
{business_rules}

## 数据质量要求
{data_quality}

## 性能要求
{performance}

## 验收标准
### 功能验收标准
- [ ] 能够正确提取源表数据
- [ ] 能够正确关联维度信息
- [ ] 能够生成目标表数据
- [ ] SQL语法兼容Apache Doris 2.1+

### 数据验收标准
- [ ] 数据完整性达到99%以上
- [ ] 数据准确性达到100%
- [ ] 关联匹配率符合预期

### 性能验收标准
- [ ] 满足性能要求

## 相关文档
- 表清单：tables.txt
- SQL脚本：sql_scripts/
- 血缘关系：lineage.md
- 权限检查：permission_check.md

## 变更记录
| 日期 | 版本 | 变更描述 | 变更人 |
|------|------|----------|--------|
| {create_date} | 1.0 | 初始版本（自动生成） | ETL智能辅助工具 |
