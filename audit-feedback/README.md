# 审计反馈目录

## 说明

本目录存储项目审计报告的处理意见文件。

## 文件来源

由审计报告HTML页面（`audit-report-YYYYMMDD.html`）通过 File System Access API 生成并保存到此目录。

## 文件命名规范

```
audit-feedback-YYYYMMDD.md
```

示例：`audit-feedback-20260509.md`

## 工作流程

1. 在对话中说"执行项目审计" → Agent生成 `audit-report-YYYYMMDD.html`
2. 用Chrome/Edge打开HTML → 填写处理意见 → 点"提交到本地文件"
3. 保存到本目录（`audit-feedback/`）
4. Hook自动触发 → Agent读取反馈文件并执行处理意见

## 处理意见类型

| 意见 | Agent行为 |
|------|-----------|
| 待处理 | 立即执行修复 |
| 已处理 | 跳过（仅记录） |
| 不处理 | 跳过（仅记录） |
| 延后 | 跳过，下次审计时提醒 |
