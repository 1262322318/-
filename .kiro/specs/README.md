# Specs 规格目录

## 说明

本目录存放Kiro Spec文件。Spec是结构化的功能开发流程，包含需求→设计→任务三个阶段。

## 目录清单

| 目录 | 功能 | 状态 |
|------|------|------|
| `etl-developer-assistant/` | ETL开发助手系统的整体规格 | 已完成 |

## Spec目录结构

每个Spec目录包含：
```
{spec-name}/
├── .config.kiro      # Spec配置
├── requirements.md   # 需求文档
├── design.md         # 设计文档
└── tasks.md          # 任务清单
```

## 使用方式

- Spec通过Kiro的Spec模式创建和管理
- 在Spec模式下，Agent按照 requirements → design → tasks 的顺序推进
- 每个任务完成后自动标记状态
