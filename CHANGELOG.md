# 项目框架变更记录

本文件记录ETL开发助手项目**框架层面**的调整（Steering规则、技能、Hook、项目结构等），不记录具体业务需求的SQL变更（业务变更记录在各需求目录的 `changelog.md` 中）。

---

## [v2.5.1] - 2026-05-18

### 🔄 修订：反馈采集改为傻瓜式（适配独立电脑场景）

**背景**：原v2.5.0的反馈机制依赖工程师写模板、改文件名、维护tracker，对测试人员负担过重。且测试电脑独立、无git/云，需要适配"导出+发送"的传输方式。

**变更内容**：

#### 删除文件
- `feedback/weekly-feedback-template.md`（每周写8章节模板，太重）
- `feedback/issue-template.md`（手动填表，工程师不会用）
- `.kiro/data/test-pilot-tracker.md`（项目管理类文件，不该让工程师维护）

#### 新增文件
| 文件 | 说明 |
|------|------|
| `.kiro/skills/feedback-collector.md` | 反馈自动采集技能：A7/B5后自动询问3问 + 全局监听吐槽信号词 + 一键导出 |
| `.kiro/data/feedback-records/README.md` | 自动采集的反馈记录目录说明 |

#### 修改文件
| 文件 | 变更说明 |
|------|----------|
| `.kiro/steering/product.md` | 新增"反馈自动捕获模式"章节：信号词触发+背景静默记录+任务结束后追问1次 |
| `.kiro/steering/etl_dialogue_flow.md` | A7/B5增加"自动调用 feedback-collector 询问3个简短问题"步骤 |
| `.kiro/skills/feedback-review.md` | 改为支持单机/多人合并两种模式，适配 feedback/imports/ 接收导出文件 |
| `.kiro/skills/README.md` | 追加 feedback-collector 技能 |
| `feedback/README.md` | 改为"项目负责人接收导出文件"用途 |
| `USER-MANUAL.md` | 重写：测试人员行动清单只有3步，全自动反馈采集说明 |

#### 核心机制变化
| 维度 | v2.5.0 | v2.5.1 |
|------|--------|--------|
| 测试人员负担 | 写8章节模板+维护tracker | 0手工动作（除了"导出反馈"） |
| 反馈触发 | 工程师主动写文件 | Agent主动询问/被动捕获 |
| 文件命名 | 工程师手动 | Agent自动 |
| 数据传输 | 假设有共享路径 | 单文件导出，发钉钉/邮件 |
| 多人合并 | 无机制 | feedback/imports/ + 合并技能 |

#### 测试人员行动清单（v2.5.1）
```
Day 1：投喂知识 + 健康检查
日常：直接用，遇问题直接吐槽（Agent自动记录）
结束：说"导出反馈"，把md文件发给项目负责人
```

---

## [v2.5.0] - 2026-05-18

### 📊 新增：交互度量与归因分析体系

**背景**：作为初始使用阶段的程序，需要观测用户与Agent的交互过程，区分"用户侧问题"（如需求提交不完整）和"框架侧问题"（如模板缺失），定位开发效率低下的根因，形成持续改进闭环。

**变更内容**：

#### 新增文件
| 文件 | 类型 | 说明 |
|------|------|------|
| `.kiro/skills/interaction-metrics.md` | Skill (manual) | 交互度量记录技能：12步执行流程，自动评分、阶段度量、归因分析、改进Backlog自动追加 |
| `.kiro/data/interaction-metrics/README.md` | 文档 | 度量目录说明（字段速查 + 复盘用法） |
| `.kiro/data/interaction-metrics/index.csv` | 数据 | 度量索引（一行一条，用于快速聚合） |
| `.kiro/data/interaction-metrics/conversations/README.md` | 文档 | 对话样本目录（永久保留，用于多层复盘和未来训练） |
| `.kiro/data/framework-improvement-backlog.md` | 数据 | 框架改进Backlog（自动追加 + 高频问题检测 + 用户定制提示 + 阈值校准记录） |

#### 修改文件
| 文件 | 变更说明 |
|------|----------|
| `.kiro/steering/etl_dialogue_flow.md` | A7和B5增加"自动调用 interaction-metrics 技能"步骤 |
| `.kiro/skills/etl-requirement.md` | 链路A增加A7.5、链路B增加B5.5（度量自动触发节点） |
| `.kiro/skills/README.md` | 追加 interaction-metrics 技能条目（共8个技能） |
| `.kiro/data/README.md` | 重写，增加度量目录和Backlog说明 |

#### 度量维度设计
- **input_quality**：7维度评分（满分14），自动识别缺失维度
- **stage_metrics**：每个阶段独立度量（rounds/duration/corrections/bottleneck）
- **attribution**：4种主因（user/framework/mixed/clean），70%阈值，待样本充足后校准
- **sql_quality**：首次通过率、修订轮次、修改类别分布
- **conversations**：完整对话样本永久保留，支持多层复盘和未来训练

#### 改进闭环
- 同一改进项最近5次出现≥3次 → 标记"⚠️ 高频问题"
- 同一用户最近3次输入完整度&lt;6 → 提示定制需求填空模板
- 累计5个需求 → 提示样本积累通知
- 累计10个需求 → 建议人工抽样校准阈值
- 累计30个需求 → 考虑引入多因子加权归因模型

---

## [v2.4.0] - 2026-05-15

### 🚀 框架审视后的全面改进

**背景**：框架审视发现SQL生成质量、Code Review能力、多人协作追溯、模板库内容等方面存在Gap，逐项执行改进。

**变更内容**：

#### Gap 6（P0）：充实sql_templates.md
- 从已有7个需求的SQL中提取12个实战模板
- 覆盖：幂等模式、冰冷洗分类、空调分类、库存汇总、ADS汇总、管报关联、日立口径等
- 新增模板选择规则表（场景→模板组合映射）

#### Gap 3（P0）：SQL审查技能
- 新增 `.kiro/skills/sql-review.md`
- 6个审查维度：编码规范/性能风险/业务合规/幂等安全/字段完整/可维护性
- 100分制评分 + 自动修复能力

#### Gap 4（P1）：投喂日志
- 新增 `.kiro/data/feeding-log.md`（投喂追溯日志）
- 修改 knowledge-feeding.md，每次投喂后自动追加日志记录

#### Gap 5（P2）：快速问答优化
- 修改 product.md，明确"简短问题直接回答，不启动流程"的行为规则

#### Gap 1（P2）：SQL模板提取技能
- 新增 `.kiro/skills/sql-template-extract.md`
- 从已有SQL中自动识别可复用模式并写入模板库

---

## [v2.3.0] - 2026-05-15

### 🔍 新增：知识库智能校验与健康检查体系

**背景**：投喂数据的准确性和完整性直接决定助手的"聪明程度"。需要在录入时实时校验、推理反馈，并在大量投喂后自动触发全面体检。

**变更内容**：

#### 新增/升级文件
| 文件 | 操作 | 说明 |
|------|------|------|
| `.kiro/skills/knowledge-feeding.md` | 升级 | 内嵌智能校验引擎：录入时实时格式检查 + 推理性反馈（关联链延伸、命名一致性、覆盖度推理等7种推理类型） |
| `.kiro/skills/knowledge-health-check.md` | 新建 | 知识库健康检查技能（手动触发），5个维度检查 + 健康评分 + 修复引导 |
| `.kiro/hooks/auto-health-check-reminder.kiro.hook` | 新建 | 自动触发：steering核心文件被修改时累计计数，≥5次自动提醒执行健康检查 |
| `.kiro/data/feeding-counter.json` | 新建 | 投喂计数器（记录累计投喂次数和上次检查时间） |

#### 三层校验设计
| 层次 | 时机 | 能力 |
|------|------|------|
| 层次1：实时校验 | 每条录入时 | 格式检查、类型规范、关联存在性 |
| 层次2：推理反馈 | 每条录入后 | 关联链延伸、产品线覆盖、命名一致性、规则冲突、缺失推理等 |
| 层次3：健康检查 | 手动触发 + 累计≥5次自动提醒 | 5维度全面体检（表完整性/规则一致性/模式有效性/交叉一致性/覆盖度） |

---

## [v2.2.0] - 2026-05-15

### 📥 新增：知识投喂技能

**背景**：助手当前只包含一个人负责的IPD研发指标知识，需要支持不同开发工程师投喂各自业务域的表、规则和模式知识。

**变更内容**：

#### 新增文件
| 文件 | 类型 | 说明 |
|------|------|------|
| `.kiro/skills/knowledge-feeding.md` | Skill (manual) | 知识投喂技能，通过 `#knowledge-feeding` 引用激活 |

#### 设计要点
- 支持4种投喂类型：表知识 / 规则知识 / 模式知识 / 批量投喂
- 每种类型有标准化的采集流程（逐项询问→确认→写入）
- 支持直接粘贴DDL/SQL/文档，Agent自动解析
- 投喂后执行质量检查（关键词冲突、关联完整性等）
- 写入对应的steering文件永久生效

---

## [v2.1.0] - 2026-05-15

### 🔀 核心升级：需求处理链路分叉

**背景**：原有9状态单链路对新需求和旧需求（变更/修复/扩展）一视同仁，导致变更类需求走了不必要的完整分析流程，且无法精准定位已有SQL进行修改。

**变更内容**：

#### 新增文件
| 文件 | 类型 | 说明 |
|------|------|------|
| `.kiro/steering/etl_change_management.md` | Steering (always) | 变更需求专属流程：6种变更类型（CHG-01~06）、专属澄清维度、影响分析规则、修改策略 |
| `.kiro/skills/etl-requirement.md` | Skill (manual) | ETL需求处理技能，通过 `#etl-requirement` 引用激活 |
| `project-overview.html` | 文档 | 项目全景介绍HTML（含架构图、流程图、文件说明） |
| `requirement-pipeline-analysis.html` | 文档 | 需求处理链路详解与优化分析报告 |

#### 重写文件
| 文件 | 变更说明 |
|------|----------|
| `.kiro/steering/etl_dialogue_flow.md` | 从v1.0（9状态单链路）升级为v2.0（分叉链路）：新增状态2.5需求分类判定，分流到链路A（新建）和链路B（变更），每步强制阶段门禁 |

#### 更新文件
| 文件 | 变更说明 |
|------|----------|
| `.kiro/steering/README.md` | 更新文件索引（12→13个）、依赖关系图、优化记录 |

#### 关键设计决策
1. **阶段门禁（Gate）**：每个状态输出后必须等用户明确确认才进入下一步，禁止跳步
2. **需求分类判定**：通过"是否提及已有需求ID + 动词类型（新建/变更/修复）"自动分流
3. **变更链路独立**：B1定位资产 → B2变更澄清 → B3影响分析 → B4执行修改 → B5文档更新 → B6下游同步
4. **技能选择manual模式**：避免影响日常自由对话，需要时通过 `#etl-requirement` 激活

---

## [v2.0.0] - 2026-05-09

### 📚 Steering规则体系建立

**背景**：项目初始化，建立完整的AI Agent行为控制体系。

**变更内容**：

#### 规则文件整合
- 从17个文件优化为12个：合并5个冗余文件
- 2个文件改为fileMatch模式（`sql_templates.md`、`etl_sql_generator.md`）
- 2个文件改为manual模式（`table_structures.md`、`table_validation.md`）

#### 新增文件
| 文件 | 说明 |
|------|------|
| `.kiro/steering/requirement_patterns.md` | 需求模式库（自学习），7个已有模式 |
| `.kiro/steering/etl_dialogue_flow.md` | 9状态对话流程状态机 |
| `.kiro/steering/etl_analysis.md` | 需求分析三合一 |
| `.kiro/steering/etl_clarification.md` | 需求澄清规则 |
| `.kiro/steering/data_mapping.md` | 领域数据表映射库 |
| `.kiro/steering/business_rules.md` | 8条公共业务规则 |
| `.kiro/steering/sql_rules.md` | SQL编码规范 |
| `.kiro/steering/sql_templates.md` | SQL模板库 |
| `.kiro/steering/etl_sql_generator.md` | SQL生成器规则 |
| `.kiro/steering/language.md` | 语言规范（强制中文） |
| `.kiro/steering/product.md` | 产品概述 |
| `.kiro/steering/tech.md` | 技术栈 |
| `.kiro/steering/table_structures.md` | 完整表DDL |
| `.kiro/steering/table_validation.md` | 权限检查流程 |
| `.kiro/steering/project_audit.md` | 项目审计规则 |
| `.kiro/steering/README.md` | 规则文件索引 |

#### Hook配置
| 文件 | 说明 |
|------|------|
| `.kiro/hooks/auto-update-lineage.kiro.hook` | SQL文件变更时自动更新血缘关系文档 |

#### 技能文件
| 文件 | 说明 |
|------|------|
| `.kiro/skills/project-audit.md` | 项目审计技能 |

---

## [v1.0.0] - 2026-04-23

### 🏗️ 项目初始化

**变更内容**：
- 建立 `requirements/` 目录结构
- 录入已有需求（002~008）的SQL脚本和文档
- 建立需求模板（`requirements/templates/`）
- 配置MCP连接（PostgreSQL）
- 建立审计反馈工作流（`audit-feedback/`）

---

## 版本号规则

- **主版本号**（x.0.0）：框架架构级变更（如链路重构）
- **次版本号**（0.x.0）：新增功能模块（如新增规则文件、新增技能）
- **修订号**（0.0.x）：小修小补（如规则微调、文档修正）
