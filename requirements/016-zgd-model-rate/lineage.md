# 016-zgd-model-rate 数据血缘

## 血缘图

```
dws.dws_ipd_ipm_dxhxl_detail_dd（上月：型号+销量+销额）
    │
    ├── 筛选：dt_type='月', in_out_sale='内销', is_project='N', sales_type='管报'
    │   product_line IN ('冰箱','冷柜','洗衣机','家用空调','视像科技')
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ads.ads_ipd_ipm_zgd_model_dd                     │
│ (段落1：上月3种zhibiao_type)                      │
└─────────────────────────────────────────────────┘
    ▲
    │
dws.dws_ipd_ipm_sale_model_detail_dd（当月：仅型号数）
    │
    ├── 筛选：dt_type='月', in_out_sale='内销', is_project='N'
    │   product_line IN ('冰箱','冷柜','洗衣机','家用空调','视像科技')
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ads.ads_ipd_ipm_zgd_model_dd                     │
│ (段落2：当月型号数占比)                           │
└─────────────────────────────────────────────────┘
    ▲
    │
ods.odsmf_cm_tab28853（计划值）
    │
    ├── 非视像科技：CROSS JOIN维度展开 + 窗口函数算总数占比
    ├── 视像科技：直接读取已有的col_zongshu/col_zhanbi
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ads.ads_ipd_ipm_zgd_model_dd                     │
│ (段落3：未来月份计划值)                           │
└─────────────────────────────────────────────────┘

ads.ads_ipd_ipm_zgd_model_dd（自身已写入数据）
    │
    ├── 智慧生活BG：冰箱/冷柜/洗衣机/视像(总体) + 家空(Hisense)
    ├── 家电集团整体：冰箱/冷柜/洗衣机(总体) + 家空(Hisense)
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ads.ads_ipd_ipm_zgd_model_dd                     │
│ (段落4：汇总层)                                   │
└─────────────────────────────────────────────────┘
```

## 字段血缘

| 目标字段 | 来源 |
|----------|------|
| zhibiao_type | 常量 |
| dt_month | 源表.dt_month |
| product_line | 源表.product_line / 汇总层常量 |
| in_out_sale | 源表.in_out_sale / 汇总层='全部' |
| dimension_1 | 源表.brand 或 '总体' |
| dimension_2 | CASE映射(chanpindingwei→端位/中高端) |
| act_num | COUNT(DISTINCT model) / SUM(sales_qty) / SUM(sales_amt) |
| all_num | 窗口函数SUM(act_num) OVER(品牌+datacopy分区) |
| zhanbi | act_num / all_num |
| plan_* | ods.odsmf_cm_tab28853 |
| completionrate_* | act / plan |
