---
name: knowledge-curator
version: 1.0.0
description: "知识提炼与维护。当用户需要从文本/文档/图片/对话中提炼数据开发经验，并维护到团队能力包（extensions/{team}/）时使用。支持：识别知识类型→提取结构化内容→匹配目标文件→生成变更→用户确认→写入。可独立激活，也可在项目上线后作为收尾步骤。"
metadata:
  requires:
    bins: []
---

# Knowledge Curator（知识提炼与维护）

从非结构化输入（文本、文档、截图、对话记录、项目复盘等）中提取可复用的数据开发知识，结构化后维护到团队能力包中。

## 设计理念

- **降低维护门槛**：用户只需"丢材料"，AI 负责识别知识类型、匹配目标文件、生成符合格式的条目。
- **不破坏现有结构**：只追加/更新 `extensions/{team}/` 下的文件，永不触碰 `references/core/`。
- **人在回路**：所有变更先展示 diff 预览，用户确认后才写入。

## 输入获取策略

### 所需输入
| 输入项 | 必要性 | 说明 |
| --- | --- | --- |
| 知识材料 | 必须 | 任意形式：文字描述/粘贴文本/文档文件/截图/对话片段/项目产出文件 |
| 目标团队 | 可选 | 默认从项目路径或关键词自动匹配；无法匹配时询问 |

### 自动匹配逻辑
1. 从材料内容识别业务域关键词
2. 与 `.kiro/extensions/` 下各 `extension.json` 的 `scope.keywords` / `scope.project_patterns` 匹配
3. 匹配成功 → 锁定目标能力包路径
4. 无匹配 → 询问用户"这属于哪个团队的知识？"或提议新建能力包

## 知识分类与目标映射

AI 从输入材料中识别知识类型，映射到对应文件：

| 知识类型 | 识别信号 | 目标文件 | 操作 |
| --- | --- | --- | --- |
| 新指标/度量 | 含公式、口径、投入/产出/比率 | `metrics/{domain}.yaml` + `_index.yaml` | 追加条目（含 discrimination + coverage + scope_rule） |
| 聚合规则 | 含比率、不可加、分子分母 | `aggregation-rules.yaml` | 追加 non_additive 条目 |
| 指标区分信息 | 含 zhibiao_type、考核范围、完成率方向、产品线覆盖 | `metrics/{domain}.yaml` | 更新已有条目的 discrimination/coverage/scope_rule 字段 |
| 新术语/概念 | 业务用语解释、易混淆概念 | `vocabulary.yaml` | 追加行 |
| 新词根 | 字段缩写约定 | `word-roots.yaml` | 追加行 |
| 维度经验 | 编码对齐、跨系统坑 | `dimensions.yaml` | 追加/更新条目 |
| 源系统经验 | 某表的坑、注意事项 | `source-systems.yaml` | 追加/更新 |
| 设计模式 | 可复用的 ETL/建模方案 | `patterns/{name}.md` | 新建文件 |
| 业务规则 | 状态机、时间规则、口径规则 | `business-rules/*.yaml` | 追加/更新 |
| 项目经验 | 决策原因、踩坑、复用经验 | `cases/{project}.yaml` | 追加/新建 |
| 表目录 | 新表上线 | `catalog.yaml` | 追加条目 |
| 闸门检查项 | 评审必检项 | `gates/extra-checks.md` | 追加 |

## 执行流程

### Step 1：材料接收与解析

接收用户输入的材料，进行多模态解析：
- **文本/对话**：直接提取关键信息
- **文档（md/docx/pdf）**：读取全文提取
- **图片/截图**：识别文字内容和表格结构
- **项目产出文件**（设计文档/SQL/PRD）：提取可沉淀的决策和经验

### Step 2：知识识别与分类

从解析结果中：
1. 识别包含哪几类知识（一份材料可能涉及多类）
2. 判断每条知识的完整度（信息够不够写成标准条目）
3. 信息不足时 → 列出补充问题，向用户追问

输出：知识条目清单（含类型、摘要、完整度评估）

### Step 3：冲突检测

对每条待写入的知识，检查目标文件中是否已有：
- **同名指标**：比对口径是否一致。一致 → 跳过；不一致 → 标记冲突，请用户决定
- **同名术语**：是否需要更新定义
- **同表同坑**：是否已记录（避免重复）
- **同名 pattern**：是否需要合并

冲突处理原则：
- 完全重复 → 自动跳过，告知用户
- 口径冲突 → 停下来问用户，不自作主张
- 补充性信息（如给已有条目加 note）→ 合并后展示 diff

### Step 4：结构化生成

按目标文件的格式规范生成条目内容：
- 严格遵循 `_schema.md` 定义的格式
- 参照同文件中已有条目的风格（缩进、字段顺序、注释风格）
- 精简原则：只写 AI 自己推不出来的信息，通用知识不写

### Step 5：变更预览与确认

向用户展示所有变更的预览：

```
━━━ 变更预览 ━━━

📁 metrics/quality.yaml （追加 1 条）
  + 新增基础度量：报废数量
    - field: scrap_qty
    - formula: SUM(scrap_qty)
    - source: odsmes_{plant}_co_pom_order.scrapqty

📁 aggregation-rules.yaml （追加 1 条）
  + scrap_qty → additive（可加型，无需特殊处理）
  [注：可加型无需写入，已默认 SUM]

📁 source-systems.yaml （更新 1 条）
  ~ odsmes_{plant}_co_pom_order 追加坑：
    + scrapqty 字段部分工厂为 NULL（非零），需 COALESCE(scrapqty, 0)

━━━━━━━━━━━━━━━
确认写入？[Y/n/修改]
```

用户可选：
- **Y**：全部写入
- **n**：取消
- **修改**：指出哪条需要调整，AI 修改后重新预览
- **逐条确认**：对每条单独 Y/n

### Step 6：写入与版本更新

用户确认后：
1. 写入目标文件（追加或更新）
2. 更新 `extension.json` 的 `version`（patch +1）和 `last_updated`
3. 输出变更摘要

## 批量模式

当输入材料信息量大（如一份完整的项目复盘文档），自动进入批量模式：
1. 一次性提取所有知识条目
2. 按文件分组展示
3. 用户可批量确认或逐条审核

## 快捷指令

| 用户说 | 行为 |
| --- | --- |
| "把这个加到知识库" | 自动识别类型，走完整流程 |
| "这是个新指标：xxx = yyy / zzz" | 直接走指标补充（metrics + aggregation-rules + _index） |
| "记一下这个坑：xxx表的yyy字段..." | 直接走 source-systems 更新 |
| "这个项目的经验总结一下" | 走 cases/ 案例生成 |
| "加个词根：xxx 缩写为 yyy" | 直接追加 word-roots.yaml |
| "看看知识库现状" | 展示能力包覆盖度摘要（各文件条目数 + 最后更新时间） |
| "生成可视化" / "知识地图" | 匹配目标能力包 → 调用生成脚本 → 输出 HTML |
| "同步能力包" / "更新能力包" | 走需求闭环自动提取模式（见下方） |

## 需求闭环自动提取模式

### 触发条件
- etl_dialogue_flow 的 A7 步骤第9项（能力包同步检查）用户确认"是"
- etl_dialogue_flow 的 B5 步骤第9项（能力包同步检查）用户确认"是"
- 用户直接说"同步能力包"/"更新能力包"

### 提取逻辑

Agent 从本次已完成的需求产出中自动提取：

| 检查对象 | 提取规则 | 目标文件 |
| --- | --- | --- |
| requirement.md 中的指标定义 | 新指标 → 生成 metrics 条目 | `metrics/{domain}.yaml` + `_index.yaml` |
| requirement.md 中的指标公式 | 比率/均值型 → 补充 non_additive | `aggregation-rules.yaml` |
| requirement.md 中的覆盖范围表 | 提取内销/外销产品线清单 → 填充 coverage 字段 | `metrics/{domain}.yaml` |
| requirement.md 中的指标口径/考核范围 | 提取 zhibiao_type、is_project规则、时间窗口、完成率方向 → 填充 discrimination + scope_rule 字段 | `metrics/{domain}.yaml` |
| ADS脚本中的 WHERE 条件差异 | 对比同表不同 zhibiao_type 的分子条件（如 is_dx='Y' vs 'N'）、完成率公式方向 → 填充 discrimination | `metrics/{domain}.yaml` |
| sql_scripts/ 中的 CREATE TABLE | 新表 → 生成 catalog 条目（含 depends_on） | `catalog.yaml` |
| sql_scripts/ 中的踩坑注释 | 含"注意"/"坑"/"特殊"标记 → 补充经验 | `source-systems.yaml` |
| 新增的公共规则引用 | 本需求新引入的 PUB 规则 → 检查 business-rules/ 是否覆盖 | `business-rules/*.yaml` |
| requirement.md 中的业务术语 | 未在 vocabulary 中出现的新术语 → 追加 | `vocabulary.yaml` |
| 整体项目经验 | 新需求 → 追加案例索引 | `cases/_index.yaml` |

### 执行流程（精简版，无需用户逐步确认）

1. **扫描**：读取本次需求的 requirement.md + sql_scripts/ + lineage.md
2. **比对**：与能力包现有内容比对，识别差异项
3. **生成变更清单**：按文件分组列出所有待追加/更新的条目
4. **一次性展示 diff 预览**：
   ```
   📦 能力包同步 — 变更预览

   📁 metrics/_index.yaml（追加 1 条）
     + 新增复合指标：xxx指标
       - field: xxx_rate
       - table: ads.xxx_dd

   📁 catalog.yaml（追加 2 条）
     + dws.dws_xxx_dd（DWS, 月×产品线×型号）
     + ads.ads_xxx_dd（ADS, 月×事业部）

   📁 cases/_index.yaml（追加 1 条）
     + 014-xxx（标签：[...]，参考价值：高）

   确认写入？[Y/n/逐条确认]
   ```
5. **用户确认后批量写入**
6. **更新 extension.json 的 version（patch +1）和 last_updated**

### 与标准 knowledge-curator 流程的区别

| | 标准流程（丢材料） | 需求闭环提取 |
| --- | --- | --- |
| 输入来源 | 用户提供的非结构化文本 | 本次需求的结构化产出（requirement.md + SQL） |
| 识别复杂度 | 高（需NLP解析） | 低（从已确认的结构化文档直接提取） |
| 冲突风险 | 中（可能与已有条目口径不一致） | 低（需求已闭环，口径已确认） |
| 交互轮次 | 多（可能需追问补充信息） | 少（一次性展示diff，确认即写入） |

## 可视化生成

当用户要求"可视化"/"生成知识地图"/"看看全貌"时：

### 流程
1. **匹配目标能力包**：与知识写入相同的匹配逻辑（关键词/项目路径 → extension.json scope）
2. **确定路径**：锁定能力包绝对路径（如 `.kiro/extensions/manufacturing`）
3. **调用脚本**：
   ```
   python <skill_assets>/generate_knowledge_map.py "<能力包绝对路径>"
   ```
   脚本自动：
   - 读取该能力包下所有 YAML/MD 知识文件
   - 生成单页 HTML → 输出到 `<能力包>/viz/knowledge-map.html`
4. **提示用户**：告知生成路径，建议浏览器打开

### 脚本位置
`<skill>/assets/generate_knowledge_map.py`

### 依赖
- Python 3.x + PyYAML（`pip install pyyaml`）
- 无其他依赖，HTML 内嵌 ECharts CDN

### 输出说明
生成的 HTML 包含 11 个 tab：总览/指标图谱/表血缘/维度/聚合规则/术语表/词根/源系统/业务规则/案例库/规范保障。
覆盖能力包全部知识文件，浏览器直接打开即可交互查看。

## 约束与安全

- **只写 extensions/{team}/**，绝不修改 `references/core/` 或任何 Skill 文件
- **不自动写入**，所有变更必须经过用户确认
- **同名度量口径冲突时阻塞**，不做隐式覆盖
- **词根冲突**：如果与基线重复且含义一致 → 跳过不追加；含义不同 → 团队定义优先，追加并标注
- 写入后建议用户 `git add` 变更文件（提示但不强制）

## 知识覆盖度检查

激活时或用户请求时，可输出能力包健康度报告：

```
━━━ 制造域能力包覆盖度 ━━━
  metrics/        : 10 条（基础5 + 派生1 + 复合4）
  vocabulary      : 11 条
  word-roots      : 12 条
  dimensions      : 5 个维度
  catalog         : 9 张表
  source-systems  : 2 系统, 5 源表
  cases           : 1 个案例
  patterns        : 1 个模式
  aggregation     : 4 条 non_additive
  ⚠️ 待确认项     : 3 个（orderstatus枚举/defectstatus含义/report_type值）
  最后更新        : 2026-07-02
━━━━━━━━━━━━━━━━━━━━━━━━
```
