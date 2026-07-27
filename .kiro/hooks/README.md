# Hooks 自动化目录

## 说明

本目录存放Kiro Agent的Hook配置文件。Hook在特定IDE事件发生时自动触发Agent执行动作。

## 文件清单

### v1格式（.kiro.hook）

| 文件 | 触发事件 | 触发条件 | 执行动作 |
|------|----------|----------|----------|
| `auto-sql-review.kiro.hook` | fileEdited | `requirements/*/sql_scripts/*.sql` | SQL快检（关键字大写/MDG过滤/字段对齐）+ 自动更新lineage.md血缘文档 |
| `auto-health-check-reminder.kiro.hook` | fileEdited | `.kiro/steering/data_mapping.md` 等4个核心文件 | 累计修改≥5次后提醒执行知识库健康检查 |
| `btn-project-audit.kiro.hook` | userTriggered | 用户点击按钮 | 一键执行项目审计，生成HTML报告 |
| `btn-health-check.kiro.hook` | userTriggered | 用户点击按钮 | 一键执行知识库健康检查 |
| `btn-update-readmes.kiro.hook` | userTriggered | 用户点击按钮 | 一键扫描并更新所有README |
| `btn-project-docs.kiro.hook` | userTriggered | 用户点击按钮 | 一键生成项目文档 |
| `post-task-metrics.kiro.hook` | userTriggered | 用户点击按钮 | 需求完成后执行度量记录+快速反馈采集 |
| `sync-knowledge-pack.kiro.hook` | agentStop | Agent对话结束时 | 检查本次对话是否涉及需求变更，提醒用户同步更新能力包 |

### v2格式（.json，Agent直接执行）

| 文件 | 触发事件 | Matcher | 执行动作 |
|------|----------|---------|----------|
| `auto-sql-review.json` | PostFileSave | `\\.sql$` | SQL快检（与v1版同功能，v2格式） |
| `auto-health-check-reminder.json` | PostFileSave | 核心steering文件 | 累计修改≥5次后提醒健康检查（与v1版同功能，v2格式） |

## Hook工作原理

```
IDE事件（文件编辑/创建/删除）
    │
    ▼
匹配 when.patterns
    │
    ▼ 匹配成功
执行 then.type（askAgent 或 runCommand）
```

## Hook文件格式

### v1格式（.kiro.hook）
```json
{
  "name": "Hook名称",
  "version": "1.0.0",
  "description": "描述",
  "when": {
    "type": "fileEdited",
    "patterns": ["匹配模式"]
  },
  "then": {
    "type": "askAgent",
    "prompt": "Agent执行指令"
  }
}
```

### v2格式（.json，Agent直接执行）
```json
{
  "version": "v1",
  "hooks": [{
    "name": "Hook名称",
    "trigger": "PostFileSave",
    "matcher": "正则匹配",
    "action": { "type": "command", "command": "shell命令" }
  }]
}
```

## 注意事项

- Hook触发是自动的，无需用户手动操作
- Hook执行结果会显示在对话中
- 如需临时禁用某个Hook，可在文件名前加 `_` 前缀
