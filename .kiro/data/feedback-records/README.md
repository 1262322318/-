# 反馈记录目录

## 说明

本目录由 `.kiro/skills/feedback-collector.md` 技能**自动维护**，工程师无需手动写入文件。

## 文件类型

| 文件名格式 | 来源 |
|-----------|------|
| `{YYYYMMDD}-{需求ID}-quickfeedback.md` | 需求完成后Agent主动询问3个问题（评分+满意点+不爽点） |
| `{YYYYMMDD}-{HHMMSS}-issue.md` | 用户吐槽时Agent捕获信号词自动记录 |
| `{YYYYMMDD}-{HHMMSS}-suggestion.md` | 用户主动说"反馈/建议"时引导式采集 |

## 工程师只需要做什么

**什么都不用做**。

- 需求结束后Agent会主动问3个问题（10秒答完，可跳过）
- 平时吐槽直接对Agent说，它会自己记录
- 想看自己的反馈直接说"看我的反馈"

## 一键导出

试用结束（或每周一次）：
```
对Agent说："导出反馈"
```

Agent会把所有反馈+度量数据打包到项目根目录的 `feedback-export-{name}-{date}.md`，
直接复制内容或把文件发给项目负责人即可。
