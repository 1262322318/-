# 009 - 变更模块变更明细汇总统计 数据血缘

## 数据流转

```
ads.ads_ipd_irs_design_change_kccl_dd（源表）
    │
    ├── 表一~表六：按 DISTINCT name 去重，统计设计变更维度
    │   ├── 表一：company 维度 → 已实施率
    │   ├── 表二：HWA_ChangeReasonType 维度 → 原因占比
    │   ├── 表三：HWA_ChangePhase 维度 → 阶段占比
    │   ├── 表四：hwa_changelevel 维度 → 级别占比
    │   ├── 表五：design_current 维度 → 状态占比
    │   └── 表六：HWA_ChangeSubmittingDepartment 维度 → 部门已实施率
    │
    └── 表七~表十：按 DISTINCT MCO_name 去重，统计MCO维度
        ├── 表七①：werks_name 维度 → MCO已实施率/已完成率
        ├── 表七②：werks_name 维度 → 未实施率/超3月未实施率
        ├── 表八：werks_name 维度 → 工艺/采购评估未完成数量及超期
        ├── 表九：werks_name 维度 → 工艺/采购评估平均时长
        └── 表十：werks_name 维度 → 生效日已过未实施情况
```

## 源表依赖

| 源表 | 用途 |
|------|------|
| ads.ads_ipd_irs_design_change_kccl_dd | 设计变更全集（唯一数据源） |

## 下游消费

| 消费方 | 用途 |
|--------|------|
| BI报表前端 | 设计变更监控看板（10张图表） |
