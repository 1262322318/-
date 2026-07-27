---
name: feedback-review
version: 1.0.0
description: "反馈复盘。聚合度量数据、本地反馈和导入反馈，生成阶段性改进报告（含HTML报告），支持单机复盘和多人合并复盘。"
inclusion: manual
metadata:
  requires:
    bins: []
---

# 反馈复盘技能（项目负责人使用）

## 触发方式
- 用户说"反馈复盘"、"合并反馈"、"试用复盘"
- `#feedback-review`

## 技能说明
聚合三类数据生成阶段性改进报告：
1. **客观数据**：`.kiro/data/interaction-metrics/` 度量数据
2. **本地反馈**：`.kiro/data/feedback-records/` 自动采集的反馈
3. **导入反馈**：`feedback/imports/` 其他工程师发来的导出文件（独立电脑场景）

## 执行步骤

### 步骤1：判断使用场景
询问用户：
- 单机复盘（只看本机数据）→ 跳到步骤2
- 多人合并复盘（项目负责人收齐其他人发来的导出文件）→ 跳到步骤3

### 步骤2：单机数据聚合
读取本机的：
- `.kiro/data/interaction-metrics/index.csv` + 详细JSON
- `.kiro/data/feedback-records/*.md`

### 步骤3：多人数据合并
1. 扫描 `feedback/imports/feedback-export-*.md`
2. 解析每个文件的概览/评分/反馈/度量摘要
3. 按操作人聚合 + 跨操作人共性识别
4. 把合并结果写入 `feedback/merged-feedback-{YYYYMMDD}.md`

### 步骤4：客观数据指标
- 总需求数（链路A / 链路B 分别统计）
- 平均交互轮次、平均耗时
- 平均输入完整度
- primary_cause 分布（user/framework/mixed/clean 各占比）
- Top 3 瓶颈阶段
- Top 5 框架侧问题

### 步骤5：主观反馈聚合
- 平均评分（来自quickfeedback文件）
- 满意点高频词（Top 5）
- 不爽点高频词（Top 5）
- 吐槽分类分布（issue文件，按严重度+分类）
- 建议汇总（按提及频次排序）

### 步骤6：交叉分析
- **客观瓶颈 vs 主观痛点**：是否一致？
- **框架侧问题 vs 工程师建议**：建议是否覆盖了已识别的问题？
- **跨工程师共性**（多人场景）：哪些问题是普遍的？

### 步骤7：生成改进优先级
| 优先级 | 判定条件 |
|--------|----------|
| P0 | 多人提到 OR 阻塞性高严重度 OR 出现≥3次的框架侧问题 |
| P1 | 单人多次提到 OR 中严重度 OR 出现≥2次的框架侧问题 |
| P2 | 单次出现 OR 低严重度 |

### 步骤8：归档
- 处理过的 `feedback-records/*.md` 移到 `.kiro/data/feedback-records/archived-{YYYYMM}/`
- 处理过的 `feedback/imports/*.md` 移到 `feedback/imports/archived-{YYYYMM}/`
- 在 `framework-improvement-backlog.md` 标记本次复盘新增的P0/P1项

### 步骤9：生成HTML报告
路径：
- 单机：项目根目录 `feedback-review-report-{YYYYMMDD}.html`
- 多人：`feedback/feedback-review-report-{YYYYMMDD}.html`

报告结构：
1. 概览（时间范围、参与人、需求数）
2. 客观数据图表
3. 主观反馈聚合
4. 交叉分析
5. 改进优先级（P0/P1/P2）
6. 行动建议

### 步骤10：向用户展示摘要
```
【反馈复盘报告 - {时间范围}】

📊 数据概览
- 度量样本：N 条
- 自动采集反馈：N 条（评分N条/吐槽N条/建议N条）
- 参与工程师：N 人
- 平均满意度：{评分}/5

🚨 P0改进项（建议立即处理）
1. ...

📋 P1改进项
1. ...

📁 完整报告：{html路径}
归档完成：{archived路径}
```

## 注意事项
- 首次执行（样本<5）会提示"样本不足，仅做初步聚合"
- 跨工程师对比时去标识化（用代号）
- 改进项必须可执行（每条对应一个具体的文件修改）
