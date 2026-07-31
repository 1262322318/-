# WS-13 数据血缘

## 数据流转路径

```
ODS → DWS
```

```
┌─────────────────────────────────────┐
│ ODS层                                │
│                                      │
│ odsplm_bm_hbmtprojectkpi           │
│   (项目主表)                         │
│       │                              │
│       │ productname = projectname    │
│       ▼                              │
│ odsplm_bm_hbmtprojectadjust        │
│   (变更单表)                         │
└──────────────────┬──────────────────┘
                   │
                   │ ETL: M1计算逻辑
                   │ - 应市类筛选(R1)
                   │ - 当月完成筛选(R3)
                   │ - 暂停期配对剔除(R5)
                   │ - 产品线维度映射(R7)
                   │ - 开发周期聚合平均
                   ▼
┌─────────────────────────────────────┐
│ DWS层                                │
│                                      │
│ dws_plm_project_dev_cycle_monthly   │
│   (应市项目平均开发周期月度表)        │
│   粒度: 产品线 × 统计月             │
└─────────────────────────────────────┘
```

## 字段级血缘（M1）

| 目标字段 | 来源 | 转换逻辑 |
|----------|------|----------|
| dt_month | hbmtprojectkpi.hbmtpproductionactualedate | DATE_FORMAT 取 YYYYMM |
| product_line_code | hbmtprojectkpi.hbmtpproductline | 直接取值 |
| product_line_name | hbmtprojectkpi.hbmtpproductline | CASE映射中文名 |
| business_division | hbmtprojectkpi.hbmtpproductline | CASE映射(终端/光模块) |
| project_count | hbmtprojectkpi | COUNT(DISTINCT productname) |
| avg_dev_cycle_days | hbmtprojectkpi + hbmtprojectadjust | ROUND(AVG(完成−立项−暂停天数), 1) |
| total_dev_cycle_days | hbmtprojectkpi + hbmtprojectadjust | SUM(完成−立项−暂停天数) |
| etl_time | 系统 | NOW() |

## 依赖关系

- 无上游 DWS/DWD 依赖（直接从 ODS 计算）
- 无下游依赖（首次创建）

## M2/M3 扩展血缘（待落地）

M2 落地时新增：目标值模拟表 → dws_plm_project_dev_cycle_monthly（completion_rate 字段）
M3 落地时新增：dws_plm_project_dev_cycle_monthly 自连接（去年同月 avg_dev_cycle_days → yoy_improvement 字段）
