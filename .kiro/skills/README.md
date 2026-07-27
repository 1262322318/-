# Skills 技能目录

## 说明

本目录存放Kiro Agent的技能文件。技能是一组预定义的执行步骤，通过触发词或 `#技能名` 手动引用激活。

## 文件清单

| 文件 | 触发方式 | 功能 |
|------|----------|------|
| `etl-requirement.md` | `#etl-requirement` 或说"新需求/修改需求/修复bug" | ETL需求处理（分叉链路：新建链路A + 变更链路B） |
| `knowledge-feeding.md` | `#knowledge-feeding` 或说"投喂知识/录入表信息" | 知识投喂（含智能校验引擎 + 推理反馈 + 日志记录） |
| `knowledge-health-check.md` | `#knowledge-health-check` 或说"健康检查" | 知识库全面体检（5维度检查 + 健康评分） |
| `sql-review.md` | `#sql-review` 或说"审查SQL/review一下" | SQL审查（6维度：规范/性能/业务/幂等/字段/可维护） |
| `sql-template-extract.md` | `#sql-template-extract` 或说"提取模板/学习SQL" | 从已有SQL中提取可复用模式写入模板库 |
| `interaction-metrics.md` | 自动（A7/B5后）/ `#interaction-metrics` / 说"记录度量" | 交互度量记录（输入质量评分 + 阶段轮次 + 归因分析 + 改进Backlog） |
| `feedback-collector.md` | 自动（A7/B5后询问）/ 全局监听吐槽信号词 / 说"导出反馈" | 反馈自动采集（傻瓜式，0手工填表）+ 一键导出打包 |
| `feedback-review.md` | `#feedback-review` 或说"反馈复盘"/"合并反馈" | 反馈复盘（项目负责人用，合并多人反馈生成改进报告） |
| `project-audit.md` | 说"执行项目审计" | 项目审计（生成交互式HTML报告） |
| `requirement-converter.md` | `#requirement-converter` 或说"转换需求/整理需求/标准化需求" | 将原始需求输入转换为标准化 .md 文件（纯格式化，不做业务判定） |
| `requirement-refiner.md` | `#requirement-refiner` 或说"精化需求/生成PRD/refine" | 需求精化（将converted的MRD文档精化为PRD级别，含字段映射、确定度标记、参考指令） |
| `update-readmes.md` | `#update-readmes` 或说"更新README" | 扫描所有目录并同步更新README文件清单 |
| `project-dashboard.md` | `#project-dashboard` 或说"看板/项目状态/需求进度" | 需求看板（全局状态汇总 + 依赖关系 + 阻塞提醒 + 周报） |
| `data-lineage-viz.md` | `#data-lineage-viz` 或说"血缘/血缘图/依赖关系图" | 数据血缘可视化（SQL解析 + Mermaid图 + HTML页面 + 影响分析） |
| `project-docs-generator.md` | `#project-docs-generator` 或说"生成项目文档" | 项目文档生成（模块流水线HTML页面） |
| `knowledge-curator/` | `#knowledge-curator` 或说"提炼知识/维护能力包/投喂经验" | 知识提炼与维护（从文本/文档/对话中提取经验，维护到团队能力包） |

## 使用方式

- **手动引用**：在对话中输入 `#文件名`（不含.md后缀）
- **触发词**：直接说出对应的触发词，Agent自动识别并激活

## 技能加载模式

所有技能文件均为 `inclusion: manual`，不会自动加载到每次对话中，只在需要时激活。

## 新增技能

新增技能文件时请遵循以下格式：
```markdown
---
inclusion: manual
---
# 技能名称

## 触发词
[列出触发词]

## 技能说明
[一句话描述]

## 执行步骤
[详细步骤]
```

## 外部技能引入规则

从外部（社区/团队/其他项目）引入新技能前，**必须经过人为确认**：

1. **可行性分析**：Agent先分析该技能是否适配当前项目（技术栈、业务域、依赖关系）
2. **负载评估**：评估引入后对上下文占用、Hook触发频率、文件数量的影响
3. **冲突检测**：检查是否与已有技能/规则存在功能重叠或逻辑冲突
4. **用户确认**：向用户展示分析结果，获得明确确认后才执行引入
5. **试用期**：新引入的技能标记为"试用"，使用3次后由用户决定保留或移除

**禁止**：未经用户确认直接引入外部技能定义。
