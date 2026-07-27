---
inclusion: manual
---

# 项目审计规则（手动触发）

## 概述

本文件定义项目定期审计的检查规则。用户在对话中通过 `#project_audit` 手动触发，Agent执行全面审查并生成交互式HTML报告。

## 触发方式

用户在对话中输入：
- "执行项目审计" 或 "项目审查" 或引用 `#project_audit`

## 审计范围

### 1. 文档完整性检查
对每个需求文件夹（requirements/XXX-*/）检查以下文件是否存在且非空：

| 文件 | 必须 | 说明 |
|------|------|------|
| requirement.md | ✅ | 需求文档 |
| tables.txt | ✅ | 表清单 |
| lineage.md | ✅ | 血缘关系（需含字段级血缘） |
| sql_scripts/*.sql | ✅ | 至少1个ETL脚本 |
| sql_scripts/validate_data_quality.sql | ✅ | 数据质量检查脚本 |
| changelog.md | ✅ | 变更记录 |
| permission_check.md | 建议 | 权限检查（仅新需求必须） |
| sql_scripts/create_tables.sql | 建议 | 建表DDL（仅新需求必须，历史脚本002/004~008不要求） |

### 2. SQL代码质量检查
对每个SQL脚本检查：
- [ ] 是否有标准文件头注释（脚本名称、功能描述、作者、创建时间）
- [ ] 关键字是否大写（SELECT/FROM/WHERE/INSERT/DELETE等）
- [ ] 是否使用有意义的别名（非a/b/c）
- [ ] 复杂逻辑是否有注释说明
- [ ] 是否使用调度参数 `${GP_START_DT}`（非硬编码日期）

### 3. 血缘文档质量检查
对每个lineage.md检查：
- [ ] 是否有数据流转概览
- [ ] 是否有Mermaid血缘关系图
- [ ] 是否有源表/目标表清单
- [ ] 是否有字段级血缘映射表（源字段→目标字段+转换逻辑）
- [ ] 是否有变更记录

### 4. 需求文档一致性检查
- [ ] requirement.md中的涉及表是否与tables.txt一致
- [ ] requirement.md中的验收标准是否全部勾选（已完成需求）
- [ ] requirement.md中引用的公共规则编号是否在business_rules.md中存在

### 5. 规则引擎完整性检查
- [ ] data_mapping.md中的表是否都在table_structures.md中有定义
- [ ] business_rules.md中的规则是否都被至少一个需求引用
- [ ] sql_rules.md中的标准数据类型映射表是否完整

### 6. 配置文件检查
- [ ] .kiro/data/table_permissions.csv 格式是否正确（database,table_name,username,permission_level,last_verified,notes）
- [ ] .kiro/hooks/ 中的hook文件JSON格式是否合法
- [ ] .kiro/settings/mcp.json 是否可解析

### 7. 需求间依赖完整性检查
- [ ] lineage.md中声明的上游依赖表是否真实存在于对应需求的sql_scripts中
- [ ] requirement_patterns.md中的"依赖"字段是否与实际SQL中的FROM/JOIN引用一致
- [ ] 下游需求是否正确引用了上游需求的输出表（如005引用004的DWS表）
- [ ] 存在依赖关系的需求，上游变更时下游changelog是否有同步记录

### 8. SQL幂等性检查
- [ ] 每个INSERT语句前是否有对应的DELETE语句（DELETE+INSERT模式）
- [ ] DELETE的WHERE条件是否与INSERT的数据范围一致（避免删多或删少）
- [ ] 是否存在无DELETE直接INSERT的风险（可能导致数据重复）
- [ ] 多段DELETE+INSERT的分区条件是否互斥（避免交叉删除）

### 9. 变更闭环检查
- [ ] 是否存在_draft.sql文件但未在changelog中记录合入/废弃状态
- [ ] changelog最后一条变更日期是否与SQL文件最后修改时间大致匹配
- [ ] 变更类型标记（CHG-XX）是否与etl_change_management.md中的类型定义一致
- [ ] 草稿文件（_draft.sql）是否标注了"已合入"或"待合入"状态

### 10. 调度参数一致性检查
- [ ] 同一需求下所有SQL脚本是否统一使用${GP_START_DT}参数
- [ ] 是否存在混用硬编码日期和调度参数的情况
- [ ] 参数使用方式是否与sql_rules.md中的调度参数规范一致（date_sub取上月等）

## 评分标准

每个维度按10分制评分：
- **代码质量**：SQL规范遵循度（头注释、关键字大写、别名、注释、参数化）
- **文档完整性**：必须文件的覆盖率
- **一致性**：文档间交叉引用的准确性
- **可维护性**：变更记录、注释、模块化程度
- **项目完整度**：整体交付物齐全程度
- **依赖与幂等**：需求间依赖正确性 + SQL幂等性
- **变更管理**：变更闭环、草稿状态、参数一致性

## 输出格式

生成交互式HTML报告，保存到 `audit-feedback/audit-report-{YYYYMMDD}-{HHMMSS}.html`（每次生成独立文件，不覆盖历史），包含：
1. 总体评分卡（5个维度）
2. 各需求逐项检查结果（PASS/FAIL/WARN）
3. 问题清单（按P0/P1/P2/P3优先级分类）
4. 每条问题支持交互操作：
   - 处理意见下拉选择（待处理/已处理/不处理/延后）
   - 备注输入框
   - 保存按钮（数据存储在localStorage中）
5. 亮点总结
6. 行动计划表

## 历史报告对比

如果项目根目录存在之前的审计报告（audit-report-*.html），在新报告中标注：
- 上次发现的问题本次是否已修复
- 新增的问题
- 持续存在的问题

## 排除项

以下不纳入审计范围：
- `20260429投喂逻辑/` 文件夹（历史归档）
- 已明确标记为"示例"的需求
- ODS层源表的DDL（非本项目管理）
- 生产环境性能指标（本地无法验证）
