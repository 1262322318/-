---
name: interaction-metrics
version: 1.0.0
description: "交互度量记录。记录每次需求处理过程的交互度量数据，区分用户侧/框架侧问题，识别瓶颈阶段，生成归因分析和改进Backlog。"
inclusion: manual
metadata:
  requires:
    bins: []
---

# 交互度量记录技能

## 触发方式

### 自动触发（默认）
- 链路A的A7（文档生成+经验沉淀）完成后，自动调用本技能
- 链路B的B5（文档更新）完成后，自动调用本技能

### 手动触发
- 用户说"记录度量"、"生成metrics"、"度量本次交互"
- `#interaction-metrics`

## 技能说明
本技能用于记录每次需求处理过程的交互度量数据，用于：
1. 区分"用户侧问题"和"框架侧问题"
2. 识别瓶颈阶段，定位框架改进点
3. 积累样本，为未来的归因阈值优化提供依据
4. 多层复盘（用户级/需求级/框架级）

## 核心数据模型

### 输出文件
- 详细数据：`.kiro/data/interaction-metrics/{需求ID}-metrics-{YYYYMMDD}.json`
- 索引追加：`.kiro/data/interaction-metrics/index.csv`（一行一条）
- 改进追加：`.kiro/data/framework-improvement-backlog.md`（如有框架侧问题）
- 复盘样本：`.kiro/data/interaction-metrics/conversations/{需求ID}-{YYYYMMDD}.md`（对话简介）

### Metrics JSON Schema

```json
{
  "metric_version": "1.0",
  "requirement_id": "需求ID",
  "requirement_name": "需求名称",
  "session_info": {
    "start_time": "YYYY-MM-DD HH:MM:SS",
    "end_time": "YYYY-MM-DD HH:MM:SS",
    "total_duration_minutes": 0,
    "operator": "操作人",
    "link_type": "A 或 B",
    "link_subtype": "独立型/依赖型/相似型 或 CHG-01~06"
  },
  "input_quality": {
    "first_submission_text": "用户首次提交原文（截断200字）",
    "completeness_score": 0,
    "completeness_max": 14,
    "completeness_level": "明确/基本明确/模糊/非常模糊",
    "missing_dimensions": [],
    "provided_dimensions": []
  },
  "stage_metrics": {
    "state_2_keyword_extraction": {
      "rounds": 0, "duration_minutes": 0, "success": true,
      "user_corrections": 0, "notes": ""
    },
    "state_2_5_classification": {
      "rounds": 0, "duration_minutes": 0, "success": true,
      "user_corrections": 0, "notes": ""
    },
    "A1_dependency_identification": {
      "rounds": 0, "duration_minutes": 0, "success": true,
      "user_corrections": 0, "notes": ""
    },
    "A2_clarification": {
      "rounds": 0, "duration_minutes": 0, "questions_asked": 0,
      "user_corrections": 0, "repeated_questions": 0,
      "success": true, "bottleneck": false, "notes": ""
    },
    "A3_table_matching": {
      "rounds": 0, "duration_minutes": 0, "user_corrections": 0,
      "success": true, "bottleneck": false, "notes": ""
    },
    "A4_layer_design": {
      "rounds": 0, "duration_minutes": 0, "success": true,
      "user_corrections": 0, "notes": ""
    },
    "A5_final_confirmation": {
      "rounds": 0, "duration_minutes": 0, "success": true, "notes": ""
    },
    "A6_sql_generation": {
      "rounds": 0, "duration_minutes": 0, "files_generated": 0,
      "user_corrections": 0, "success": true,
      "bottleneck": false, "notes": ""
    },
    "A7_documentation": {
      "rounds": 0, "duration_minutes": 0, "files_generated": 0,
      "success": true, "notes": ""
    }
  },
  "interaction_summary": {
    "total_rounds": 0,
    "total_user_corrections": 0,
    "total_repeated_questions": 0,
    "total_rollbacks": 0,
    "bottleneck_stages": []
  },
  "sql_quality": {
    "generated_files_count": 0,
    "first_pass_acceptance": false,
    "revision_rounds": 0,
    "lines_of_code": 0,
    "user_modifications_after_generation": 0,
    "modification_categories": {
      "logic_fix": 0, "format_adjustment": 0,
      "field_addition": 0, "rule_application": 0
    }
  },
  "attribution": {
    "primary_cause": "user/framework/mixed/clean",
    "user_side_issues": [
      {"stage": "", "issue": "", "impact_rounds": 0}
    ],
    "framework_side_issues": [
      {"stage": "", "issue": "", "impact_rounds": 0,
       "suggested_improvement": ""}
    ],
    "tags": []
  },
  "reference_patterns": {
    "matched_pattern": "PAT-XXX",
    "match_score": 0.0,
    "depended_on_requirements": [],
    "applied_business_rules": []
  },
  "improvement_backlog_items": []
}
```

**链路B专属字段**（替换stage_metrics内容）：
```json
"stage_metrics": {
  "state_2_keyword_extraction": {...},
  "state_2_5_classification": {...},
  "B1_locate_assets": {...},
  "B2_change_clarification": {...},
  "B3_impact_analysis": {...},
  "B4_execute_modification": {...},
  "B5_documentation_update": {...},
  "B6_downstream_sync": {...}
}
```

## 执行步骤

### 步骤1：回顾本次对话

从对话历史回顾每个阶段的交互过程：
- 识别每个阶段的起止位置
- 数清每个阶段的来回轮次（1次=Agent输出+用户回复）
- 统计用户修正信号（"不对/调整/修改/重来"）次数
- 记录用户回退信号（"回到上一步"）次数
- 估算每个阶段的耗时（基于消息时间间隔，无时间戳时按平均轮次时长估算）

### 步骤2：评估输入质量

按 `etl_analysis_clarification.md` 的7维度对用户首次提交评分：

| 维度 | 权重 | 0分（缺失）| 1分（模糊）| 2分（明确）|
|------|------|-----------|-----------|-----------|
| 报表/分析类型 | 高 | 未提及 | 笼统说"报表" | 明确"日报/月报/趋势分析" |
| 分析维度 | 高 | 未提及 | "分析一下" | "按产品型号和区域" |
| 核心指标 | 高 | 未提及 | "看看数据" | "统计销售额和销量" |
| 时间范围 | 中 | 未提及 | 模糊"最近" | "最近90天" |
| 时间粒度 | 中 | 未提及 | — | "按日/月" |
| 数据源 | 低 | 未提及 | — | "从销售数据表" |
| 输出格式 | 低 | 未提及 | — | "ADS层报表" |

判定等级：≥10明确 / 6-9基本明确 / 3-5模糊 / <3非常模糊

### 步骤3：度量每个阶段

对每个阶段计算：
- `rounds`：交互轮次
- `duration_minutes`：耗时
- `user_corrections`：用户修正次数
- `bottleneck`：true 当 `rounds≥3` 或 `duration_minutes/total_duration ≥ 0.30`
- `notes`：自由文本说明发生了什么

### 步骤4：归因分析

判定 `primary_cause`：

| 取值 | 判定条件 |
|------|---------|
| `user` | 用户侧问题轮次 / 总修正轮次 ≥ 70%（阈值待样本量充足后调整） |
| `framework` | 框架侧问题轮次 / 总修正轮次 ≥ 70% |
| `mixed` | 两者均有但无明显主因 |
| `clean` | 全程无修正 |

**用户侧问题判定**：
- 用户首次提交完整度 < 6
- 用户回答澄清问题时模糊导致追问
- 用户中途改变需求口径或目标
- 用户对自己的业务规则描述不一致

**框架侧问题判定**：
- 表匹配遗漏（data_mapping.md 关键词缺失）
- SQL生成需多轮修订（sql_templates.md 模板不实战）
- 影响分析未识别下游（requirement_patterns.md 依赖不全）
- 同一澄清问题在不同需求中重复出现（etl_analysis_clarification.md 模板缺失）
- Agent判定分类错误
- Agent对业务规则的理解与用户不一致

为每个 framework_side_issue 必须给出 `suggested_improvement`。

### 步骤5：归类tags

标签格式：`[侧:类型]`，例如：
- `用户侧:需求不完整`
- `用户侧:口径未明`
- `用户侧:中途变更`
- `框架侧:模板缺失`
- `框架侧:关键词遗漏`
- `框架侧:依赖不全`
- `框架侧:分类误判`

### 步骤6：写入Metrics文件

路径：`.kiro/data/interaction-metrics/{需求ID}-metrics-{YYYYMMDD}.json`

格式：UTF-8编码，JSON格式化输出（缩进2空格）

### 步骤7：保存对话简介（复盘样本）

路径：`.kiro/data/interaction-metrics/conversations/{需求ID}-{YYYYMMDD}.md`

内容包含：
- 用户首次提交原文（完整版）
- 每个阶段的关键问答（用户问题+Agent回应+用户确认）摘要
- 出现修正/否定信号的对话片段（完整保留）
- 最终汇总确认时的对话片段

格式：
```markdown
# 需求 {ID} - {名称} 交互复盘

## 基本信息
- 日期：{YYYY-MM-DD}
- 操作人：{operator}
- 链路类型：{A/B}

## 一、首次提交
{用户原文}

## 二、关键交互节点

### 状态2.5 分类判定
**Agent**：[判定结论]
**用户**：[确认/否定]

### A2 需求澄清
**轮次1**：
- Agent问：...
- 用户答：...

### 出现修正/否定的片段
[完整保留对话]

### 最终汇总确认
[完整保留汇总文本和用户确认]

## 三、本次交互的关键发现
[1-3条文字总结，便于未来复盘]
```

### 步骤8：追加索引

文件：`.kiro/data/interaction-metrics/index.csv`

追加一行：
```csv
requirement_id,date,operator,link_type,total_rounds,total_duration_min,input_completeness,primary_cause,bottleneck_stages
```

`bottleneck_stages` 用 `;` 分隔多个阶段，例如 `A2;A6`。

### 步骤9：更新改进Backlog（如有框架侧问题）

文件：`.kiro/data/framework-improvement-backlog.md`

格式：
```markdown
## 待办改进项

- [ ] {YYYYMMDD} {需求ID} {改进项} | 来源：{阶段} | 严重度：{高/中/低}
```

严重度判定：
- 高：阻塞了SQL生成/文档生成
- 中：导致≥2轮修正
- 低：仅有1轮修正

### 步骤10：高频问题检测

读取 `index.csv` 和 `framework-improvement-backlog.md`：
- 如果同一改进项在最近5个需求中出现≥3次，在Backlog顶部标记为"⚠️ 高频问题"
- 如果同一用户最近3个需求 input_completeness < 6，在Backlog追加"建议为用户{operator}定制需求填空模板"

### 步骤11：阈值学习提示

每完成5个需求后，提示用户：
```
【度量样本积累通知】
已积累N个度量样本。当前归因阈值为70%，建议在样本≥10时执行一次阈值校准（人工抽样校验主因判定准确性，调整阈值）。
```

### 步骤12：向用户展示摘要

```
【本次交互度量摘要】

📊 基本数据
- 总耗时：{N}分钟
- 总轮次：{N}轮（修正{N}次，回退{N}次）
- 输入质量：{score}/14（{level}）

🔍 瓶颈分析
- 瓶颈阶段：{阶段列表}
- 主因归类：{primary_cause}

🛠️ 改进建议
{逐条列出 framework_side_issues 的 suggested_improvement}

📁 文件已写入
- 度量数据：{json路径}
- 对话样本：{md路径}
- 索引：{index.csv}
- 改进Backlog：{已追加N条 / 无新增}
```

## 注意事项

### 隐私与脱敏
- 默认保留用户首次提交原文（完整版用于复盘）
- 如果需求涉及敏感业务术语，可在JSON中设置 `"sanitized": true`，原文字段仅保留摘要
- conversations目录下的对话样本不外发，仅用于内部复盘

### 数据准确性
- 当前轮次/耗时由Agent自评，存在±20%偏差
- 当样本量≥10条且发现自评偏差较大时，考虑升级为 postToolUse Hook 客观采集

### 阈值调整规则
- 样本<10：使用默认阈值70%
- 样本≥10：建议人工抽样5条，校验主因判定准确性
  - 准确率≥80%：保持70%阈值
  - 准确率<80%：调整阈值（可能上调到80%或下调到60%）
- 样本≥30：考虑引入更精细的归因模型（多因子加权）

### 失败处理
- 如果无法回顾完整对话历史，记录"degraded: true"标记，仅填写能确认的字段
- 如果无法判定 primary_cause，标记为 "mixed" 而非随机猜测
