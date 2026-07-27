# 需求收纳区（Intake）

## 说明

本目录用于存放尚未进入正式开发流程的需求文件。**按需求分目录**组织，每个需求独立隔离。

## 目录结构

```
intake/
├── {YYYYMMDD}-{简称}/            ← 每个需求一个目录，按收纳日期命名
│   ├── raw/                       ← 该需求的原始素材（CSV、截图描述、邮件等）
│   └── converted/                 ← 该需求的标准化文档（.md 统一模板）
├── {YYYYMMDD}-{简称}/
│   ├── raw/
│   └── converted/
└── README.md
```

## 命名规范

| 位置 | 格式 | 示例 |
|------|------|------|
| 需求目录 | `{YYYYMMDD}-{英文简称}` | `20260521-xinpin-hit-rate-export` |
| `raw/` 文件 | 保留原始文件名 | `新品规划命中率调研表-外销 (1).csv` |
| `converted/` 文件 | `{YYYY-MM-DD}_{简述}.md` | `2026-05-21_新品规划命中率-外销.md` |

## 目录命名说明

- 目录名与 `requirements/` 的编号**无关**，intake 是收纳区，需求尚未正式立项
- 日期为收纳当天日期，简称用英文概括指标含义
- 同一天收纳多个需求时，简称自然区分即可
- 正式流程启动后，converted/ 中的文件通过 front-matter 的 `requirement_id` 字段关联到 requirements 目录

## 文件生命周期

```
原始文件 → intake/{需求ID}/raw/
    ↓ 调用 #requirement-converter 技能
标准化 .md → intake/{需求ID}/converted/
    ↓ 调用 #requirement-refiner 技能（或用户手工编写）
精化 PRD → refined/{需求ID}/*_prd.md（独立模块，见 refined/README.md）
    ↓ 用户在聊天中引用 refined 文件 + "开始处理"
正式流程启动 → requirements/{需求ID}/ 生成全套文档
    ↓ 完成后
converted/ 中对应文件 status 标记为 completed
```

## 与 refined 模块的关系

- `intake/` 只负责收纳和格式转换（MRD级别）
- `refined/` 负责语义精化（PRD级别），是独立模块
- 精化文档存放在项目根目录的 `refined/` 下，不在 intake 内
- 详见 `refined/README.md`

## 注意事项

- 原始文件不要删除，保留用于追溯
- converted/ 下的 .md 文件头部有 front-matter 标记状态（draft/completed/cancelled）
- 正式流程完成后无需手动清理，通过 status 字段区分即可
- 一个需求可以有多个原始文件（如多个CSV、多次沟通记录等），统一放在该需求的 raw/ 下
- 精化（refiner）环节已独立为 `refined/` 模块和 `requirement-refiner` 技能
