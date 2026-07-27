---
name: project-audit
version: 1.0.0
description: "项目审计。遍历所有需求文件夹逐项检查文档完整性、SQL质量、血缘质量、一致性等7个维度，生成交互式HTML审计报告。"
metadata:
  requires:
    bins: []
---

# 项目审计技能

## 触发词
用户说"执行项目审计"、"项目审查"、"审计一下项目"时激活本技能。

## 执行步骤

1. 读取 `.kiro/steering/project_audit.md` 获取审计规则
2. 遍历 `requirements/` 下所有需求文件夹，逐项检查（文档完整性、SQL质量、血缘质量、一致性）
3. 检查需求间依赖完整性（对照requirement_patterns.md的依赖字段）
4. 检查SQL幂等性（DELETE+INSERT模式是否正确）
5. 检查变更闭环（_draft.sql状态、changelog同步、参数一致性）
6. 检查 `.kiro/steering/` 规则文件完整性
7. 检查 `.kiro/data/` 配置文件
8. 对每个维度打分（10分制，7个维度）
9. 生成交互式HTML报告，保存为 `audit-feedback/audit-report-{YYYYMMDD}-{HHMMSS}.html`

## HTML报告要求

报告必须包含以下交互功能（纯前端，无需后端）：

### 交互功能
- 每条审计结果旁有"处理意见"下拉框：待处理/已处理/不处理/延后
- 每条审计结果旁有"备注"输入框
- "保存"按钮将所有处理意见和备注存入浏览器localStorage
- 页面加载时自动从localStorage恢复之前保存的数据
- "导出"按钮可将处理意见导出为JSON文件
- "清除"按钮可重置所有处理意见

### 技术实现
- 使用Chart.js CDN绘制评分图表
- 使用localStorage持久化用户反馈
- 纯HTML/CSS/JS，无需任何构建工具
- 文件名格式：`audit-feedback/audit-report-YYYYMMDD-HHMMSS.html`（如 audit-feedback/audit-report-20260515-143022.html）
- **每次审计生成独立文件，不覆盖历史报告**（通过时间戳到秒级保证唯一性）

### 报告结构
1. Header：标题 + 审计日期 + 审计范围
2. 评分卡：7个维度的可视化评分（代码质量、文档完整性、一致性、可维护性、项目完整度、依赖与幂等、变更管理）
3. 检查明细：按需求分组，每项显示PASS/FAIL/WARN + 交互控件
4. 问题汇总：按优先级P0~P3分类
5. 亮点：做得好的地方
6. 行动计划：带优先级和预估工作量的表格
7. Footer：生成时间 + 操作按钮（保存/导出/清除）
