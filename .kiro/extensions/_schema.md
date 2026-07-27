# 团队能力包开发指南（_schema.md）

> 团队能力以**知识文件**形式存在（不是代码、不是配置）。按本指南填写标准格式文件即可，**无需审批即可使用**，下次执行自动生效。

## 一、设计原则

- **本地存语义和经验，技术事实走平台 API**。
- 本地文件 = AI 的"大脑"（理解、口径、经验）；平台 API = AI 的"眼睛"（表结构、血缘、数据量）。
- 团队间互不影响，各自维护 `extensions/{team}/` 目录，**永不改动核心 Skill 或 core/ 基线**。
- 文件格式标准化，按 `_template/` 模板填写即可。

## 二、能力包目录结构

```
extensions/{team}/
├── extension.json                       # 能力包元信息 + scope + capabilities
│
│  ── 语义理解层（AI 的"大脑"）──
├── vocabulary.yaml                      # 业务概念消歧（实体/动作/场景）
├── metrics/                             # ★ 指标语义层（基础度量→派生度量→复合指标）
│   ├── _index.yaml                      #   快速匹配（name + type + synonyms + table.field）
│   └── {domain}.yaml                    #   按主题域的完整定义
├── dimensions.yaml                      # ★ 维度知识（精简版：编码对齐坑 + 使用经验）
├── aggregation-rules.yaml               # ★ 聚合规则（精简版：non_additive 映射 + 反模式）
├── business-rules/                      # 全局业务规则（非指标的）
│   ├── status-machines.yaml             #   实体状态机
│   └── time-rules.yaml                  #   班次/SLA/调度
│
│  ── 缓存层（快速定位，详情走 API）──
├── catalog.yaml                         # 表目录缓存（name + layer + granularity + depends_on + notes）
├── source-systems.yaml                  # 源系统缓存（表 + 用途 + 坑 + 系统间关联）
│
│  ── 经验层（AI 的"记忆"）──
├── cases/                               # 项目案例
│   ├── _index.yaml                      #   案例索引
│   └── {project}.yaml                   #   项目详情（决策/踩坑/复用经验）
├── patterns/{name}.md                   # 设计与加工模式（五段式）
│
│  ── 规范保障层（AI 的"纪律"）──
├── word-roots.yaml                      # 字段命名词根
├── gates/extra-checks.md                # 闸门额外检查项
├── prd-guide/extra-collection-items.md  # PRD 额外采集项
│
│  ── 可视化产出（自动生成，不手动编辑）──
└── viz/
    └── knowledge-map.html               # 知识地图（由 knowledge-curator skill 生成）
```

## 三、三层寻路逻辑

```
用户问题
    │
    ▼ Step 1：语义理解（本地，0延迟）
    vocabulary → 理解术语
    metrics/_index → synonyms 匹配 → 定位 table.field + 口径
    dimensions → 确定分析维度 + 层次 + 编码对齐方案
    │
    ▼ Step 2：快速定位（本地缓存）
    catalog.yaml → 有哪些表/中间层可复用
    source-systems.yaml → 数据从哪来、有什么坑
    │
    ▼ Step 3：技术补全（平台 API，按需兜底）
    表完整字段结构 / 血缘关系 / 数据量 / 新鲜度
    │
    ▼ Step 4：经验补充（本地）
    business-rules → 状态机/时间规则
    aggregation-rules → 粒度转换怎么聚合（防比率取平均）
    cases → 类似项目参考
    patterns → 适用的设计模式
```

## 四、各文件标准格式

### 语义理解层

| 文件 | 用途 | 格式要点 |
| --- | --- | --- |
| `vocabulary.yaml` | 业务概念消歧 | YAML 列表：term / definition / confused_with / related_metrics。只放实体/动作/场景概念，可计算的指标放 metrics |
| `metrics/_index.yaml` | 快速匹配 | name + type + synonyms + table.field + domain |
| `metrics/{domain}.yaml` | 指标完整定义 | 分三层：基础度量 / 派生度量 / 复合指标 |
| `dimensions.yaml` | 维度知识（精简版） | 每维度：name + dim_table + key + cross_system_alignment + usage_notes。只存编码对齐坑和使用经验，层次/SCD 等通用知识由 AI 推理 |
| `aggregation-rules.yaml` | 聚合规则（精简版） | 只列 non_additive 映射（field → numerator/denominator）+ 1 个粒度转换示例 + 反模式清单。可加型默认 SUM 无需列出 |
| `business-rules/*.yaml` | 全局业务规则 | 只放非指标的规则（状态机/班次/SLA） |

### metrics 指标层次设计

指标通过 `type` 和 `derives_from` 建立层次关系：

```
基础度量（直接从源取，有 source 字段，无 derives_from）
    例：投入数量 ← odsmes_cv_lot_defect.orderqty
        │
        ▼ 组合计算
派生度量（由基础度量计算，有 derives_from）
    例：合格数量 = 投入数量 - 不良数量
        │
        ▼ 组合为比率
复合指标（由度量组合，有 derives_from + granularity）
    例：良率 = 合格数量 / 投入数量
```

**核心规则**：
- 同名度量只定义一次（唯一来源），其他指标通过 `derives_from` 引用
- 新增指标时检查：`derives_from` 引用的度量是否已有定义？口径是否一致？
- 如果口径不一致 → 定义为不同的基础度量（如"投入数量(含报废)" vs "净投入数量(不含报废)"）

### dimensions 维度知识设计（精简版）

维度文件只记录 **AI/API 查不到的领域使用经验**——编码对齐坑和使用注意事项。层次定义、SCD 类型等通用建模知识由 AI 自行推理，无需手动填写。

每个维度包含以下字段：

| 字段 | 必填 | 用途 |
| --- | --- | --- |
| `name` | 是 | 维度名称（业务语义名） |
| `dim_table` | 是 | 维表名（或"无（退化到事实表）"） |
| `key` | 是 | 主键字段列表 |
| `cross_system_alignment` | 选填 | 跨系统编码对齐的坑（无跨系统场景可省略） |
| `usage_notes` | 是 | AI 自己推不出来的使用经验 |

**精简原则**：如果一条信息 AI 凭通用建模知识就能推导，不写入文件。只写"坑"和"经验"。

### aggregation-rules 聚合规则设计（精简版）

聚合规则文件只需解决一个核心问题：**哪些字段不能直接 AVG/SUM，必须回到分子分母重算**。

文件结构：

```yaml
# 不可加型映射表（核心）
non_additive:
  - field: yield_rate       # 比率字段名
    numerator: qualified_qty  # 分子
    denominator: input_qty    # 分母
    table: dws_xxx           # 所在表
    # note: 可选，有特殊注意事项时填

# 粒度转换示例（1 个代表性场景）
granularity_example:
  scenario: "去掉物料维度"
  sql: |
    SELECT ... SUM(qualified_qty)/NULLIF(SUM(input_qty),0) AS yield_rate ...

# 反模式红线
anti_patterns:
  - id: avg_ratio
    severity: 阻塞
    detection: "AVG(xxx_rate)"
    fix: "SUM(numerator)/NULLIF(SUM(denominator),0)"
```

**精简原则**：
- 可加型字段（数量/金额/次数）默认 SUM，无需列出
- AI 本身理解"比率不能取平均"的原理，所以 `why` 解释删除
- 只保留 1 个粒度转换示例作为格式参照

### vocabulary 与 metrics 的分工

| | vocabulary.yaml | metrics/ |
| --- | --- | --- |
| 放什么 | 业务实体/动作/场景概念 | 可计算的指标和度量（含三层） |
| 举例 | 工单、工序、报工、大促备货期 | 投入数量、合格数量、良率 |
| 格式 | term + definition + confused_with + related_metrics | type + formula + derives_from + source |
| 交叉情况 | 如果概念同时是指标 → vocabulary 写"见 metrics/xxx" + related_metrics 填指标名 | — |

### 缓存层

| 文件 | 用途 | 格式要点 |
| --- | --- | --- |
| `catalog.yaml` | 表目录缓存 | 每表一条：name + layer + granularity + **depends_on**（上游表名列表，用于血缘 DAG） + notes |
| `source-systems.yaml` | 源系统缓存 | 系统清单 + 每表：name + 用途 + 坑 + 系统间关联 |

### 经验层

| 文件 | 用途 | 格式要点 |
| --- | --- | --- |
| `cases/_index.yaml` | 案例索引 | 项目名/时间/标签/参考价值 |
| `cases/{project}.yaml` | 案例详情 | 决策(含原因)/踩坑/产出表/可复用经验 |
| `patterns/{name}.md` | 设计与加工模式 | 五段式：适用场景/识别信号/处理规则(DDL+DML)/不适用条件/验证案例 |

### 规范保障层

| 文件 | 用途 | 格式要点 |
| --- | --- | --- |
| `word-roots.yaml` | 字段命名 | YAML 列表：category / abbr / full_name / data_type / domain / status |
| `gates/extra-checks.md` | 闸门检查 | 按 G0/G2 分组的 checklist |
| `prd-guide/extra-collection-items.md` | PRD 采集 | 团队特有必采信息项 |

## 五、日常维护流程

```
新指标上线后
    → metrics/ 按层次补充（基础度量→派生→复合）
    → aggregation-rules.yaml 补充 non_additive 条目（如果是比率型）
    → catalog.yaml 追加新表（含 depends_on）
    → vocabulary.yaml 如有新概念则补一条

涉及新维度时
    → dimensions.yaml 追加（编码对齐坑 + 使用经验）
    → 确认是否有公共维表可复用（对照基线 public-dimensions.md）

对接新源系统或发现新坑时
    → source-systems.yaml 追加

项目上线后
    → cases/ 填一份（15 分钟）

遇到新术语时
    → vocabulary.yaml 追加一条（如果是指标则放 metrics）

沉淀复用经验时
    → patterns/ 新建一个 md

可视化更新
    → 激活 knowledge-curator，说"生成可视化"
    → 或手动运行：python <skill>/assets/generate_knowledge_map.py "<能力包路径>"

最后：更新 extension.json 的 version。
```

> 💡 推荐使用 `knowledge-curator` skill 辅助维护——丢入材料后自动识别知识类型、生成条目、确认后写入。

## 六、缓存 vs API 的分工

| 信息 | 本地缓存存 | 平台 API 查 |
| --- | --- | --- |
| 有哪些表 | ✅ catalog.yaml（摘要） | ✅ 完整列表 |
| 表的字段列表 | ❌ 不存 | ✅ API 查 |
| 表的血缘 | ❌ 不存 | ✅ API 查 |
| 表的数据量/新鲜度 | ❌ 不存 | ✅ API 查 |
| 指标口径和层次关系 | ✅ metrics/（API 没有） | ❌ |
| 维度层次/编码对齐/变更策略 | ✅ dimensions.yaml（API 没有） | ❌ |
| 粒度转换与聚合规则 | ✅ aggregation-rules.yaml（API 没有） | ❌ |
| 源表的坑/注意事项 | ✅ source-systems.yaml（API 没有） | ❌ |
| 业务规则/状态机 | ✅ business-rules/（API 没有） | ❌ |

原则：**API 能给的不存本地，API 给不了的才存本地。缓存和 API 矛盾时以 API 为准。**

## 七、约束

- 不能修改 `references/core/`（防止破坏基线）。
- 词根冲突：团队定义优先于基线。
- 设计模式与基线规范矛盾时，以基线规范为准。
- 同名度量只定义一次，新增指标引用已有度量时必须口径一致。


## 八、可视化

能力包支持自动生成可交互的知识地图 HTML 页面，覆盖全部知识文件。

### 生成方式

1. **通过 Skill（推荐）**：激活 `knowledge-curator`，说"生成可视化"或"知识地图"
2. **手动运行**：
   ```
   python .kiro/skills/knowledge-curator/assets/generate_knowledge_map.py "<能力包绝对路径>"
   ```

### 输出位置

```
extensions/{team}/viz/knowledge-map.html
```

浏览器直接打开即可，无需部署服务。

### 页面内容（11 个 Tab）

| Tab | 数据源 | 展示 |
| --- | --- | --- |
| 总览 | 全部文件 | 覆盖度数字卡片 + 雷达图 |
| 指标图谱 | metrics/ | 力导向图（三层关系）+ 指标清单 |
| 表血缘 | catalog.yaml (depends_on) | DAG 流向图 + 表目录 |
| 维度 | dimensions.yaml | 维度知识表格 |
| 聚合规则 | aggregation-rules.yaml | 不可加型映射 + 反模式红线 |
| 术语表 | vocabulary.yaml | 业务概念词表 |
| 词根 | word-roots.yaml | 字段命名速查 |
| 源系统 | source-systems.yaml | 系统卡片 + 各表的坑 |
| 业务规则 | business-rules/*.yaml | 状态机/时间规则 |
| 案例库 | cases/*.yaml | 决策摘要 + 踩坑 |
| 规范保障 | patterns/ + gates/ | 设计模式 + 闸门检查项 |

### 依赖

- Python 3.x + PyYAML
- HTML 使用 ECharts CDN（需联网加载图表库）

### 注意

- `viz/` 目录下的 HTML 是**自动生成产物**，不要手动编辑
- 能力包知识文件更新后重新运行即可刷新
- 生成脚本对 YAML 解析异常会 graceful 跳过并打印警告
