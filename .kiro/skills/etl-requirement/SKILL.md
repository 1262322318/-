---
name: etl-requirement
version: 1.0.0
description: "ETL需求处理。激活后按照分叉链路v2.0严格执行需求分析、SQL生成、文档生成全流程。"
inclusion: manual
metadata:
  requires:
    bins: []
---

# ETL需求处理技能

## 触发词
用户说以下任意一种时激活本技能：
- "新需求"、"新增指标"、"开发一个新的"
- "修改需求"、"变更"、"改一下"
- "修复bug"、"有个问题"
- "提交需求"、"需求分析"
- "启动ETL流程"

## 技能说明
本技能激活后，Agent严格按照 `etl_dialogue_flow.md`（v2.0分叉链路）执行，每一步必须获得用户确认后才进入下一阶段。

## 执行规则

### 1. 严格阶段门禁
- 每个状态输出后，必须等待用户明确确认（"确认/可以/没问题/对的/继续"）
- 用户未确认前，禁止进入下一状态
- 用户说"不对/修改/调整"时，停留在当前状态修正

### 2. 需求分类判定（状态2.5）
按以下优先级判定：
1. 提及已有需求ID + 变更动词 → 变更需求（链路B）
2. 提及已有指标名称 + 变更动词 → 变更需求（链路B）
3. Bug/错误/修复 + 已有指标 → 变更需求-Bug修复（链路B）
4. 新增/新建/创建 + 未命中模式 → 全新需求-独立型（链路A）
5. 新增 + 命中模式 + 基于/参考 → 全新需求-依赖型（链路A）
6. 命中模式 + 无变更动词 → 全新需求-相似型（链路A）
7. 无法判定 → 直接询问用户

### 3. 链路A（新建需求）执行步骤
```
A1 依赖识别 → 确认
A2 需求澄清（按类型选择澄清维度）→ 确认
A3 数据表匹配 → 确认
A4 分层识别与架构设计 → 确认
A5 需求确认（最终汇总）→ 确认
A6 SQL生成
A7 文档生成 + 经验沉淀
A7.5 自动调用 interaction-metrics 技能（生成度量数据）
```

### 4. 链路B（变更需求）执行步骤
```
B1 定位已有资产（读取requirement.md + SQL）→ 确认
B2 变更澄清（按CHG类型选择问题）→ 确认
B3 影响分析（定位修改点 + 下游影响）→ 确认
B4 执行修改（精准str_replace）
B5 文档更新（changelog + requirement）
B5.5 自动调用 interaction-metrics 技能（生成度量数据）
B6 下游同步（如有影响）
```

### 5. 读取的规则文件
- `etl_dialogue_flow.md` — 总控流程
- `etl_analysis_clarification.md` — 关键词提取 + 模糊度评分 + 澄清问题 + 表匹配 + 分层识别
- `etl_change_management.md` — 变更需求专属流程
- `requirement_patterns.md` — 模式匹配 + 依赖关系
- `data_mapping.md` — 关键词→表映射
- `business_rules.md` — 公共业务规则
- `sql_rules.md` — SQL编码规范
- `sql_templates.md` — SQL模板（fileMatch，SQL文件在上下文时加载）
- `etl_sql_generator.md` — SQL生成器（fileMatch）

### 6. 输出产物

#### 新建需求产物
- `requirements/{ID}/requirement.md`
- `requirements/{ID}/tables.txt`
- `requirements/{ID}/lineage.md`
- `requirements/{ID}/sql_scripts/*.sql`
- `requirements/{ID}/changelog.md`
- 更新 `requirements/README.md`
- 更新 `requirement_patterns.md`

#### 变更需求产物
- 修改后的SQL文件
- 更新 `requirements/{ID}/changelog.md`
- 更新 `requirements/{ID}/requirement.md`（如规则变化）
- lineage.md 由Hook自动更新

## 注意事项
- 本技能不自动激活，需要用户通过 `#etl-requirement` 手动引用或说出触发词
- 激活后Agent进入严格的阶段式对话模式，不再自由回答
- 如果用户中途想退出流程，说"取消"或"不做了"即可回到普通对话模式
- 如果用户通过 `#intake/converted/xxx.md` 引用了预处理过的需求文件，跳过状态1，从状态2开始，已填充字段视为已确认
