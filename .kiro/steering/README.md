# Steering 规则文件索引

## 概述

本目录包含24个规则文件，控制Kiro Agent在ETL开发过程中的行为。
按加载模式分为四类：always（每次自动加载）、fileMatch（条件加载）、manual（手动引用或流程引导加载）、Hook触发steering（按钮/事件触发）。

## 文件清单

### always 模式（每次对话自动加载，11个）

| 文件 | 职责 |
|------|------|
| `language.md` | 项目交流语言规范（强制中文） |
| `product.md` | 产品概述、核心功能、设计原则、技术栈与环境、调度参数 |
| `data_mapping.md` | 关键词→数据表映射、表间关联关系、核心SQL |
| `business_rules.md` | 9条跨需求公共规则（PUB-001~009） |
| `safety.md` | 安全规则：修改前必须确认 |
| `etl_dialogue_flow.md` | v3.0骨架先行+多指标编排对话流程（新建链路A + 变更链路B，含阶段门禁） |
| `etl_analysis_clarification.md` | 需求分析与澄清：关键词提取 + 模糊度评分 + 澄清问题 + 表匹配 + 分层识别 |
| `edit_consistency.md` | 修改一致性规则（含SQL修改时的变更规则加载提醒） |
| `output_safety.md` | 输出安全规则（防乱码 + 分段输出） |
| `requirement_patterns.md` | 需求模式库（自学习，每次需求完成自动追加） |
| `team-loader.md` | 团队能力包加载规则（XuebinLV/IPM研发效率域，含加载时机+匹配逻辑+分流规则） |

### fileMatch 模式（SQL文件在上下文时自动加载，3个）

| 文件 | 触发条件 | 职责 |
|------|----------|------|
| `sql_rules.md` | `**/*.sql` | SQL编码规范、Doris特定规范、标准数据类型映射 |
| `sql_templates.md` | `**/*.sql` | DWD/DWS/ADS/DIM各层SQL模板 |
| `etl_sql_generator.md` | `**/*.sql` | SQL生成流程（模板选择→变量替换→输出） |

### manual 模式（通过 `#` 手动引用或流程引导加载，4个）

| 文件 | 职责 | 何时引用 |
|------|------|----------|
| `etl_change_management.md` | 变更需求专属流程（6种变更类型、澄清维度、影响分析、草稿规则） | 链路B自动加载；修改SQL时由edit_consistency提醒 |
| `table_structures.md` | 表业务语义索引（用途、关联规则、关键词），字段详情查table_metadata | 需要表业务语义时 |
| `table_validation.md` | 权限检查流程（table_metadata验证+CSV权限） | 执行权限检查时 |
| `project_audit.md` | 项目审计规则 | 执行项目审计时 |

### Hook触发steering（按钮/事件触发，5个）

| 文件 | 职责 | 触发方式 |
|------|------|----------|
| `btn-health-check.md` | 一键执行知识库健康检查（5维度+评分+修复引导） | 用户点击按钮 |
| `btn-project-audit.md` | 一键执行项目审计，生成交互式HTML报告 | 用户点击按钮 |
| `btn-project-docs.md` | 一键生成项目文档（HTML格式，总览+模块详细介绍） | 用户点击按钮 |
| `btn-update-readmes.md` | 一键扫描并更新所有README文件清单 | 用户点击按钮 |
| `post-task-metrics.md` | 需求完成后执行度量记录+快速反馈采集 | 用户点击按钮 |

## 文件间依赖关系

```
etl_dialogue_flow.md（总控，分叉链路v2.0）
  ├── 状态2.5 需求分类判定
  │   └── requirement_patterns.md（模式匹配+依赖关系）
  ├── 链路A：新建需求
  │   ├── etl_analysis_clarification.md（关键词提取+模糊度评分+澄清+表匹配+分层识别）
  │   │   └── data_mapping.md（提供实际表映射数据）
  │   ├── sql_templates.md + etl_sql_generator.md（SQL生成）[fileMatch]
  │   │   ├── sql_rules.md（编码规范）[fileMatch]
  │   │   └── business_rules.md（公共业务规则）
  │   └── requirement_patterns.md（经验沉淀，自学习追加）
  ├── 链路B：变更需求
  │   ├── etl_change_management.md（变更分类+澄清+影响分析+修改策略）[manual，流程引导加载]
  │   │   └── requirement_patterns.md（下游依赖查找）
  │   └── business_rules.md（规则变更时引用）
  └── table_validation.md（权限检查）[manual]
```

## 优化记录

| 日期 | 变更 |
|------|------|
| 2026-05-09 | 初始版本（17个文件，全部always） |
| 2026-05-09 | 优化为12个文件：合并5个冗余文件，2个改fileMatch，2个改manual |
| 2026-05-09 | 新增 requirement_patterns.md（需求模式库+自学习），对话流程升级为9状态 |
| 2026-05-15 | 对话流程升级v2.0：分叉链路（新建链路A+变更链路B），新增etl_change_management.md，新增etl-requirement技能 |
| 2026-05-27 | table_structures.md精简为业务语义索引，字段详情改为查询postgres的table_metadata表；table_validation.md增加table_metadata验证步骤；knowledge-health-check增加交叉验证维度 |
| 2026-05-27 | 反馈驱动改进：A2增加高完整度快速通道（≥10分跳过逐项澄清）；模式库增加容量管理规则（≥20条触发inactive判定）；增加Steering降级决策框架；知识投喂改为MCP优先查表结构；A7/B5增加主动改进提醒；project-dashboard增加需求-脚本-逻辑三维视图 |
| 2026-05-28 | 新增 refined/ 独立模块：PRD模板（3个）+ requirement-refiner技能；对话流程增加refined入口；intake去掉分级管理（迁移到refined模块）；etl_refiner.md合并到技能文件后删除 |
| 2026-06-01 | 合并优化：tech.md并入product.md；etl_analysis.md+etl_clarification.md合并为etl_analysis_clarification.md；always文件从13个减至11个 |
| 2026-06-01 | 降级优化：etl_change_management.md改为manual（链路B流程引导加载）；sql_rules.md改为fileMatch；调度参数移入product.md；always文件从11个减至9个，总节省约9500 token |

## 维护说明

- always文件：修改后下次对话自动生效
- fileMatch文件：当匹配的文件被读入上下文时自动加载
- manual文件：在对话中通过 `#文件名` 引用
- 新增文件默认为always模式，如需条件加载请添加front-matter

## Steering降级决策框架

将always文件降级为fileMatch或manual前，**必须**提供以下分析：

| 评估维度 | 说明 |
|----------|------|
| 调用频率 | 最近10次对话中被实际引用的次数（0次=低频，≥5次=高频） |
| 遗忘风险 | 降级后用户忘记引用的概率（高/中/低） |
| 影响范围 | 缺失该规则时可能导致的错误类型和严重度 |
| 预防方案 | 降级后如何防止遗忘（如：在相关技能中增加提示、在对话开头自动检测是否需要） |

**降级决策规则**：
- 调用频率=低频 且 遗忘风险=低 → 可降级
- 调用频率=低频 但 遗忘风险=高 → 不降级，或降级后必须在相关技能入口增加自动加载提示
- 调用频率=高频 → 不降级
- 关键规则（safety.md、language.md、etl_dialogue_flow.md）→ 永不降级
