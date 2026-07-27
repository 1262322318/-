# 任务列表（纯Kiro方案）— ETL智能辅助工具

## 概述

基于纯Kiro方案的设计文档，本任务列表的所有工作均围绕steering规则文件的编写和优化展开。系统不编写任何Python/Shell脚本，所有核心逻辑由Kiro Agent在对话中通过读取steering文件 + 使用内置工具完成。

## 核心原则

1. **零代码**：不编写任何脚本，所有逻辑以steering规则文件（Markdown）形式存在
2. **规则驱动**：Agent的行为完全由 `.kiro/steering/` 下的规则文件控制
3. **对话完成**：用户通过对话触发，Agent读取规则、分析需求、生成文件
4. **渐进验证**：每个任务完成后通过实际对话测试验证效果

## 任务列表

### 阶段1：规则文件整理与优化（基础）

- [x] 1.1 审查并精简现有steering文件，删除冗余和重复内容
  - [x] 1.1.1 合并 `etl_sql_generator.md` 和 `etl_sql_generator_implementation.md` 为一个文件
  - [x] 1.1.2 合并 `etl_table_identification_simple.md` 和 `etl_table_identification_example.md` 为一个文件
  - [x] 1.1.3 合并 `etl_layer_identification_simple.md` 和 `etl_layer_sql_generation.md` 为一个文件
  - [x] 1.1.4 删除面向Python脚本的测试文档（`etl_dialogue_test.md`、`etl_rule_test.md`、`etl_sql_generation_test.md`、`etl_parsing_test_simple.md`）
  - [x] 1.1.5 删除面向Python实现的文档（`etl_file_creation_system.md`、`etl_requirement_parser.md`、`structure.md`）
- [x] 1.2 优化核心数据映射文件 `data_mapping.md`
  - [x] 1.2.1 确保关键词→表映射关系完整且无歧义
  - [x] 1.2.2 确保JOIN字段和关联关系准确
  - [x] 1.2.3 补充常用分析场景的表组合示例
- [x] 1.3 优化SQL模板文件 `sql_templates.md`
  - [x] 1.3.1 确保DWD/DWS/ADS/DIM四层模板完整
  - [x] 1.3.2 确保模板变量命名统一且有明确说明
  - [x] 1.3.3 确保所有SQL兼容Apache Doris 2.1+语法
- [x] 1.4 优化业务规则文件 `business_rules.md`
  - [x] 1.4.1 确保规则编号和触发关键词对应关系清晰
  - [x] 1.4.2 精简冗余的SQL示例，保留核心规则

### 阶段2：对话流程规则完善（核心）

- [x] 2.1 完善对话流程定义 `etl_dialogue_flow.md`
  - [x] 2.1.1 定义完整的8个对话状态及转换条件
  - [x] 2.1.2 为每个状态定义Agent应执行的操作（读取哪个规则文件、使用哪个工具）
  - [x] 2.1.3 定义错误处理和回退机制
- [x] 2.2 完善澄清引擎 `etl_clarification_engine.md`
  - [x] 2.2.1 定义模糊度评分的5个维度和评分标准
  - [x] 2.2.2 定义澄清问题的优先级排序规则（P0/P1/P2）
  - [x] 2.2.3 定义默认值规则（日报默认30天、月报默认12个月等）
  - [x] 2.2.4 定义用户回答后的分析结果更新逻辑
- [x] 2.3 完善澄清问题模板 `etl_clarification_questions.md`
  - [x] 2.3.1 确保5类问题（报表类型、维度、指标、时间范围、时间粒度）都有完整的问题模板
  - [x] 2.3.2 每个问题提供选项列表和默认值
  - [x] 2.3.3 定义关键词触发规则（哪些关键词触发哪类问题）
- [x] 2.4 完善关键词提取规则 `etl_keyword_extraction.md`
  - [x] 2.4.1 确保业务关键词、技术关键词、时间关键词、指标关键词分类完整
  - [x] 2.4.2 定义同义词映射规则（销量=销售数量、销额=销售金额等）
  - [x] 2.4.3 定义关键词权重规则

### 阶段3：文件输出模板完善

- [x] 3.1 完善需求文档模板 `requirements/templates/requirement_template.md`
  - [x] 3.1.1 确保模板包含所有必要章节（基本信息、业务背景、数据表、数据流程、指标、规则、验收标准）
  - [x] 3.1.2 定义模板变量占位符，便于Agent替换
- [x] 3.2 完善表清单模板 `requirements/templates/table_list_template.txt`
  - [x] 3.2.1 确保模板按源表、目标表、维度表分组
- [x] 3.3 完善血缘关系模板 `requirements/templates/lineage_template.md`
  - [x] 3.3.1 确保模板包含数据流转概览、Mermaid图、表级血缘、字段级血缘
- [x] 3.4 完善权限检查模板 `requirements/templates/permission_check_template.md`
  - [x] 3.4.1 确保模板包含权限检查结果表格和问题记录
- [x] 3.5 准备权限CSV数据文件
  - [x] 3.5.1 在 `.kiro/data/` 下创建 `table_permissions.csv` 示例文件
  - [x] 3.5.2 填入已知表的权限信息

### 阶段4：端到端验证

- [x] 4.1 验证场景1：销售日报表（ADS层，完整流程）
  - [x] 4.1.1 用户输入"创建销售日报表，按产品型号和区域统计最近90天的日销售额和销量"
  - [x] 4.1.2 验证Agent能正确提取关键词、匹配表、识别ADS层
  - [x] 4.1.3 验证Agent能生成正确的SQL和完整的文件输出
- [x] 4.2 验证场景2：产品趋势分析（DWS层，需要澄清）
  - [x] 4.2.1 用户输入"分析各产品品类的销售趋势"
  - [x] 4.2.2 验证Agent能识别模糊度并提出澄清问题
  - [x] 4.2.3 验证澄清后能正确生成DWS层SQL
- [x] 4.3 验证场景3：模糊需求（高模糊度，多轮澄清）
  - [x] 4.3.1 用户输入"做个销售报表"
  - [x] 4.3.2 验证Agent能进行多轮澄清对话
  - [x] 4.3.3 验证澄清完成后能生成完整输出
- [x] 4.4 验证场景4：权限检查流程
  - [x] 4.4.1 验证Agent能读取CSV文件并检查表权限
  - [x] 4.4.2 验证Agent能生成权限检查报告
