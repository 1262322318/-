# 设计文档 — 纯Kiro方案

## 系统定位

ETL智能辅助工具是一个完全基于Kiro Agent的对话式ETL开发助手。系统不依赖任何Python脚本或外部程序，所有核心逻辑（需求分析、澄清、SQL生成、文件创建、权限检查、血缘记录）均由Kiro Agent通过对话能力 + steering规则文件 + 内置工具（readFile、fsWrite、fsAppend等）完成。

## 核心设计原则

1. **零代码实现**：不编写任何Python/Shell脚本，完全依赖Kiro Agent的对话能力和内置工具
2. **规则驱动**：所有业务逻辑、映射关系、SQL模板均以steering文件（Markdown）形式存储，Agent在对话中读取并应用
3. **对话式交互**：用户通过自然语言描述需求，Agent通过多轮对话完成分析、澄清、生成
4. **人工验证**：生成的SQL和文档由人工审核确认，Agent定位为"提效辅助"而非"全自动"

## 整体架构

```
用户（自然语言需求）
        ↓
Kiro Agent（核心引擎）
  ├── 读取 .kiro/steering/ 规则文件
  │     ├── data_mapping.md        → 关键词到数据表映射
  │     ├── sql_templates.md       → SQL模板库
  │     ├── business_rules.md      → 业务规则
  │     ├── etl_clarification_engine.md → 澄清规则
  │     ├── etl_dialogue_flow.md   → 对话流程定义
  │     └── ...其他规则文件
  ├── 使用内置工具
  │     ├── readFile    → 读取规则文件和CSV数据
  │     ├── fsWrite     → 创建需求文档、SQL文件
  │     ├── fsAppend    → 追加文件内容
  │     └── listDirectory → 查看目录结构
  └── 输出
        └── requirements/{需求ID}-{需求名称}/
              ├── requirement.md
              ├── tables.txt
              ├── lineage.md
              ├── permission_check.md
              └── sql_scripts/
                    ├── create_tables.sql
                    └── etl_script.sql
```

## 功能模块设计

### 模块1：需求分析（对话式）

Agent在对话中完成以下工作，不依赖任何脚本：

#### 1.1 关键词提取
- Agent读取 `etl_keyword_extraction.md` 中的关键词分类规则
- 从用户输入中识别业务关键词（销售、产品、区域等）、技术关键词（报表、分析、清洗等）、时间关键词（日报、月报等）、指标关键词（销售额、销量等）
- 输出结构化的关键词列表

#### 1.2 数据表识别
- Agent读取 `data_mapping.md` 中的映射规则
- 根据提取的关键词匹配数据表
- 确定主表、维度表及关联关系（JOIN字段）
- 输出表组合和关联关系

#### 1.3 分层识别
- Agent读取 `etl_layer_identification_simple.md` 中的分层规则
- 根据需求类型确定数据仓库分层（DWD/DWS/ADS/DIM）
- 设计数据流转路径

### 模块2：需求澄清（对话式）

#### 2.1 模糊度评估
Agent根据 `etl_clarification_engine.md` 中的规则，对需求进行模糊度评分：

| 维度 | 权重 | 评分标准 |
|------|------|----------|
| 报表/分析类型 | 高 | 0=缺失, 1=模糊, 2=明确 |
| 分析维度 | 高 | 0=缺失, 1=模糊, 2=明确 |
| 核心指标 | 高 | 0=缺失, 1=模糊, 2=明确 |
| 时间范围 | 中 | 0=缺失, 2=明确 |
| 时间粒度 | 中 | 0=缺失, 2=明确 |

- 总分 ≥ 10：需求明确，直接进入SQL生成
- 总分 6-9：基本明确，少量澄清（1-2个问题）
- 总分 3-5：模糊，需要重点澄清（3-4个问题）
- 总分 < 3：非常模糊，需要引导式提问

#### 2.2 澄清对话流程
- Agent根据缺失维度生成澄清问题（读取 `etl_clarification_questions.md`）
- 每轮最多问3个问题，按优先级P0 > P1 > P2排序
- 提供选项和默认值，减少用户输入负担
- 用户回答后，Agent更新分析结果并重新评估模糊度
- 直到需求足够清晰或用户确认

#### 2.3 对话模板
```
我理解您需要 [已识别的需求概要]。

为了更准确地生成SQL，还需要确认以下信息：
1. [P0问题]（建议：[默认值]）
2. [P1问题]（建议：[默认值]）

您可以直接回答，或者说"使用默认值"。
```

### 模块3：SQL生成（模板替换）

#### 3.1 模板读取
- Agent使用readFile读取 `sql_templates.md` 中的SQL模板
- 根据分层识别结果选择对应模板（ADS报表模板、DWS分析模板、DWD明细模板、DIM维度模板）

#### 3.2 变量替换
Agent在对话中直接完成字符串替换：

| 变量 | 来源 | 示例 |
|------|------|------|
| `{start_date}` | 用户指定或默认值 | '2024-01-01' |
| `{end_date}` | 用户指定或默认值 | '2024-01-31' |
| `{product_dimension}` | 关键词匹配结果 | model_name |
| `{region_dimension}` | 关键词匹配结果 | province_name |
| `{time_granularity}` | 分层识别结果 | month |

#### 3.3 分层SQL生成规范

##### DWD层（从ODS层开始）
- 表名格式：`dwd_{业务过程}_{数据粒度}`
- 包含：代理键、业务度量、维度外键、ETL元数据
- 分区：按业务日期RANGE分区
- 分桶：按代理键HASH分桶

```sql
CREATE TABLE dwd_sales_fact_daily (
    sales_fact_id BIGINT COMMENT '销售事实代理键',
    sale_quantity DECIMAL(15,3) COMMENT '销售数量',
    sale_amount DECIMAL(15,2) COMMENT '销售金额',
    product_key BIGINT COMMENT '产品维度外键',
    region_key BIGINT COMMENT '区域维度外键',
    business_date DATE COMMENT '业务日期',
    etl_create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    etl_update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    etl_batch_id VARCHAR(50) COMMENT 'ETL批次ID'
)
PARTITION BY RANGE(business_date) ()
DISTRIBUTED BY HASH(sales_fact_id) BUCKETS 10
COMMENT '销售明细事实表（DWD层）';
```

##### DWS层
- 表名格式：`dws_{汇总主题}_{汇总粒度}`
- 包含：维度组合键、汇总指标、衍生指标

##### ADS层
- 表名格式：`ads_{应用场景}_{数据粒度}`
- 包含：报表维度、业务指标、环比同比、排名信息

##### DIM层
- 表名格式：`dim_{维度主题}`
- 包含：代理键、业务键、维度属性、SCD处理字段

### 模块4：文件创建（内置工具）

Agent使用fsWrite/fsAppend工具直接创建文件：

#### 4.1 需求文件夹结构
```
requirements/{需求ID}-{需求名称}/
├── requirement.md          # 需求文档
├── tables.txt             # 表清单
├── lineage.md             # 血缘关系文档
├── permission_check.md    # 权限检查结果
└── sql_scripts/
    ├── create_tables.sql  # 建表语句
    └── etl_script.sql     # ETL脚本
```

#### 4.2 文件生成流程
1. Agent用fsWrite创建 `requirement.md`，填入需求分析结果
2. Agent用fsWrite创建 `tables.txt`，列出源表、目标表、维度表
3. Agent用fsWrite创建SQL文件，填入生成的SQL
4. Agent用fsWrite创建 `lineage.md`，记录数据血缘关系
5. Agent读取CSV权限文件，用fsWrite创建 `permission_check.md`

### 模块5：权限检查（读取CSV）

#### 5.1 实现方式
- Agent使用readFile读取 `.kiro/data/table_permissions.csv`
- 在对话中解析CSV内容，检查每个表的权限状态
- 用fsWrite输出权限检查报告到需求文件夹

#### 5.2 CSV文件格式
```csv
database,table_name,username,permission_level,last_verified,notes
ods,ods_mr_v_app_fm_imat_saledata,etl_developer,read,2024-01-20,销售原始数据表
```

#### 5.3 检查结果标记
- ✅ 表存在且有权限
- ❌ 表存在但无权限
- ⚠️ 表不在CSV中（未知状态）

### 模块6：血缘关系记录

#### 6.1 实现方式
- Agent在生成SQL脚本时，同步分析数据流转路径
- 用fsWrite创建 `lineage.md`，包含：
  - 数据流转概览（文本图）
  - Mermaid流程图
  - 源表→目标表的详细映射
  - 字段级血缘关系

#### 6.2 血缘文档结构
```markdown
# 血缘关系文档
## 数据流转概览
源表 → ETL处理 → 目标表

## 血缘关系图（Mermaid）
## 表级血缘
## 字段级血缘
## 变更记录
```

## 对话流程状态机

```
[初始状态] → 用户输入需求
    ↓
[需求接收] → 提取关键词、匹配表、识别分层
    ↓
[模糊度评估] → 评分 ≥ 6？
    ├── 是 → [需求确认] → 用户确认？
    │           ├── 是 → [SQL生成] → [文件创建] → [完成]
    │           └── 否 → [需求调整] → 回到[需求接收]
    └── 否 → [需求澄清] → 提问并等待回答 → 回到[模糊度评估]
```

## 规则文件清单

所有规则文件位于 `.kiro/steering/` 目录：

| 文件 | 用途 | 使用时机 |
|------|------|----------|
| `data_mapping.md` | 关键词→数据表映射 | 需求分析阶段 |
| `sql_templates.md` | SQL模板库 | SQL生成阶段 |
| `business_rules.md` | 业务计算规则 | SQL生成阶段 |
| `etl_clarification_engine.md` | 模糊度评估和澄清规则 | 需求澄清阶段 |
| `etl_clarification_questions.md` | 澄清问题模板 | 需求澄清阶段 |
| `etl_dialogue_flow.md` | 对话流程定义 | 全流程 |
| `etl_keyword_extraction.md` | 关键词分类和提取规则 | 需求分析阶段 |
| `etl_layer_identification_simple.md` | 分层识别规则 | 需求分析阶段 |
| `etl_table_identification_simple.md` | 数据表识别规则 | 需求分析阶段 |
| `sql_rules.md` | SQL编码规范 | SQL生成阶段 |
| `table_validation.md` | 表验证和权限检查流程 | 权限检查阶段 |

## 输出文件规范

### requirement.md 模板
```markdown
# 需求文档 - {需求名称}
## 基本信息（需求ID、日期、部门、优先级）
## 业务背景
## 涉及数据表（源表、目标表、维度表）
## 数据流程
## 关键指标
## 业务规则
## 验收标准
```

### tables.txt 模板
```
## 源表（数据读取）
ods.ods_mr_v_app_fm_imat_saledata

## 目标表（数据写入）
ads.sales_daily_report

## 维度表（关联查询）
dw.dim_product_base_info_dd
dw.dim_region_info_dd
```

### SQL脚本规范
- 关键字大写，4空格缩进
- 包含标准文档头（脚本名称、功能描述、作者、日期、依赖关系）
- 兼容Apache Doris 2.1+语法
- 遵循海信内部命名约定

## 使用方式

用户在Kiro对话中直接描述ETL需求，例如：

```
用户：我想创建一个销售日报表，按产品型号和区域统计日销售额

Kiro：好的，我来帮您分析这个ETL需求。
      [读取规则文件，提取关键词，匹配表，识别分层]
      [展示分析结果，确认或澄清]
      [生成SQL脚本和文档]
      [创建需求文件夹和所有文件]
```

整个过程在对话中完成，无需运行任何脚本。
