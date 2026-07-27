# 需求精化区（Refined）

## 说明

本目录存放经过精化的 PRD 级别需求文档。精化文档是 AI 生成 SQL 的直接输入，包含字段级映射、确定度标记、参考指令和禁止行为。

## 与 intake 的关系

```
intake/（MRD级别）          refined/（PRD级别）           requirements/（开发产物）
  ├── raw/（原始粘贴）         ├── {需求ID}/                  ├── {需求ID}/
  └── converted/（格式转换）       └── *_prd.md（精化文档）        ├── sql_scripts/
                                                                  └── requirement.md
       ↓ converter                    ↓ refiner                        ↓ 正式流程
    保持原意，格式化            语义增强，映射字段              生成SQL和文档
```

## 目录结构

```
refined/
├── {YYYYMMDD}-{简称}/        ← 与 intake 的需求目录名一致
│   └── {日期}_{名称}_prd.md  ← 精化文档
├── templates/                 ← PRD模板
│   ├── refined_new_single.md  ← 新建-单指标
│   ├── refined_new_multi.md   ← 新建-多指标
│   └── refined_change.md      ← 变更需求
└── README.md
```

## 文件命名规范

| 场景 | 命名格式 | 示例 |
|------|----------|------|
| 新建-单指标 | `{日期}_{指标名}_prd.md` | `2026-05-28_新品规划命中率_prd.md` |
| 新建-多指标 | `{日期}_{需求名}_prd.md` | `2026-05-28_激光产品效率管理_prd.md` |
| 变更 | `{日期}_{需求ID}_{变更简述}_prd.md` | `2026-05-28_002_激光扩展_prd.md` |

## 触发方式

| 方式 | 说明 |
|------|------|
| 自动提示 | converter 完成后，Agent 提示"是否生成精化文档" |
| 手动触发 | 用户说"精化需求" + 引用 converted 文件 |
| 手工编写 | 用户按模板直接编写 PRD 文档 |

## 确定度标记说明

| 标记 | 含义 | AI行为 |
|------|------|--------|
| 确定 | 有精确值/枚举/公式，或MCP已验证 | 直接使用，不可修改 |
| 待确认 | 模糊描述、"同XX"引用、MCP未匹配 | 按"AI默认假设"处理，SQL注释中标注 |

## 生命周期

| 状态 | 含义 |
|------|------|
| refined | 精化完成，待用户确认 |
| confirmed | 用户已确认，可进入正式流程 |
| in_progress | 正式流程进行中 |
| completed | 对应的 requirements 已完成 |

## 与正式流程的衔接

- 用户引用 `refined/**/*_prd.md` + "开始处理" → 直接进入正式流程
- 正式流程中 AI 生成 SQL 时，以 refined 文档为第一输入源
- refined 文档中标注"确定"的规则，优先级高于经验（已有SQL实现）
