# 血缘关系文档：010-aowei-data-processing（奥维数据加工）

> 自动生成，基于 sql_scripts/ 下所有脚本解析。

## 一、数据流转总览

```
dwd.dwd_mrs_mr_avcdtl_wd（源表）
        │
        ├──→ dim.dim_ipd_ipm_awproduct_dd（三级映射表，手工初始化28条）
        │
        └──LEFT JOIN──→ ads.ads_ipd_ipm_aowei_wd（目标宽表）
```

## 二、表级血缘

| 目标表 | 源表 | 关系类型 | 脚本 |
|--------|------|----------|------|
| dim.dim_ipd_ipm_awproduct_dd | — | DDL建表 | create_tables.sql |
| ads.ads_ipd_ipm_aowei_wd | — | DDL建表 | create_tables.sql |
| dim.dim_ipd_ipm_awproduct_dd | 手工INSERT 28条 | 初始化 | dim_ipd_ipm_awproduct_dd_init.sql |
| ads.ads_ipd_ipm_aowei_wd | dwd.dwd_mrs_mr_avcdtl_wd | LEFT JOIN主表 | ads_ipd_ipm_aowei_wd.sql |
| ads.ads_ipd_ipm_aowei_wd | dim.dim_ipd_ipm_awproduct_dd | LEFT JOIN映射表 | ads_ipd_ipm_aowei_wd.sql |

## 三、字段级血缘（ads.ads_ipd_ipm_aowei_wd）

| 目标字段 | 来源表 | 来源字段 | 转换逻辑 |
|----------|--------|----------|----------|
| business_unit | dim.dim_ipd_ipm_awproduct_dd | business_unit | 直接映射 |
| product_big_class | dim.dim_ipd_ipm_awproduct_dd | product_big_class | 直接映射 |
| product_mid_class | dim.dim_ipd_ipm_awproduct_dd | product_mid_class | 直接映射 |
| product_small_class | dim.dim_ipd_ipm_awproduct_dd | product_small_class | 直接映射 |
| category_segment | dim.dim_ipd_ipm_awproduct_dd | category_segment | 直接映射 |
| dt_wmcode | dwd.dwd_mrs_mr_avcdtl_wd | dt_wmcode | 直接取值 |
| o2o_type | dwd.dwd_mrs_mr_avcdtl_wd | o2o_type | CASE映射：XX→线下，XS→线上，其余保留原值 |
| wm_type | dwd.dwd_mrs_mr_avcdtl_wd | wm_type | CASE映射：M→月，W→周，其余保留原值 |
| prdct_line_name | dwd.dwd_mrs_mr_avcdtl_wd | prdct_line_name | 直接取值 |
| markt_center | dwd.dwd_mrs_mr_avcdtl_wd | markt_center | 直接取值 |
| province | dwd.dwd_mrs_mr_avcdtl_wd | province | 直接取值 |
| city_name | dwd.dwd_mrs_mr_avcdtl_wd | city_name | 直接取值 |
| city_level | dwd.dwd_mrs_mr_avcdtl_wd | city_level | 直接取值 |
| hisense_city_level | dwd.dwd_mrs_mr_avcdtl_wd | hisense_city_level | 直接取值 |
| channel_type | dwd.dwd_mrs_mr_avcdtl_wd | channel_type | 直接取值 |
| top | dwd.dwd_mrs_mr_avcdtl_wd | top | 直接取值 |
| hisense_agency | dwd.dwd_mrs_mr_avcdtl_wd | hisense_agency | 直接取值 |
| if_top | dwd.dwd_mrs_mr_avcdtl_wd | if_top | 直接取值 |
| sale_qty | dwd.dwd_mrs_mr_avcdtl_wd | sale_qty | 直接取值 |
| sale_amt | dwd.dwd_mrs_mr_avcdtl_wd | sale_amt | 直接取值 |
| prdct_model | dwd.dwd_mrs_mr_avcdtl_wd | prdct_model | 直接取值 |
| brand_series | dwd.dwd_mrs_mr_avcdtl_wd | sub_brand_name | CASE WHEN品牌归类（海信/海尔/美的/TCL/小米/创维/容声/科龙/vidda→对应系列，其余→其他） |
| brand_name | dwd.dwd_mrs_mr_avcdtl_wd | brand_name | 直接取值 |
| sub_brand_name | dwd.dwd_mrs_mr_avcdtl_wd | sub_brand_name | 直接取值 |
| core_spec | dwd.dwd_mrs_mr_avcdtl_wd + dim映射 | match_size / spec_size | CASE：家用空调取match_size，其他取CAST(spec_size AS varchar(300)) |
| prdct_cate_dtl | dwd.dwd_mrs_mr_avcdtl_wd | prdct_cate_dtl | 直接取值（字段改名：产品属性细分→产品属性） |
| energy_level | dwd.dwd_mrs_mr_avcdtl_wd | energy_level | 直接取值 |
| freq | dwd.dwd_mrs_mr_avcdtl_wd | freq | 直接取值 |
| if_laser | dwd.dwd_mrs_mr_avcdtl_wd | if_laser | 直接取值 |
| online_week | dwd.dwd_mrs_mr_avcdtl_wd | online_week | 直接取值 |
| online_month | dwd.dwd_mrs_mr_avcdtl_wd | online_month | 直接取值 |
| door_diverse | dwd.dwd_mrs_mr_avcdtl_wd | door_diverse | 直接取值 |
| if_fresh_ac | dwd.dwd_mrs_mr_avcdtl_wd | if_fresh_ac | 直接取值 |
| washing_type | dwd.dwd_mrs_mr_avcdtl_wd | washing_type | 直接取值 |
| tec_type1 | dwd.dwd_mrs_mr_avcdtl_wd | tec_type1 | 直接取值 |
| product_4_segment | dwd.dwd_mrs_mr_avcdtl_wd | product_4_segment_headquarters | CASE映射：H→高端，HM→中高端，ML→中低端，L→低端，其余保留原值 |

## 四、映射表字段级血缘（dim.dim_ipd_ipm_awproduct_dd）

| 字段 | 来源 | 说明 |
|------|------|------|
| map_level | 手工维护 | 映射级别（1=品线/2=品线+属性/3=品线+属性+属性细分） |
| prdct_line_name | 手工维护 | 映射输入：品线名称 |
| prdct_cate | 手工维护 | 映射输入：产品属性（空=全匹配） |
| prdct_cate_dtl | 手工维护 | 映射输入：产品属性细分（空=全匹配） |
| business_unit | 手工维护 | 映射输出：事业部 |
| product_big_class | 手工维护 | 映射输出：产品大类 |
| product_mid_class | 手工维护 | 映射输出：产品中类 |
| product_small_class | 手工维护 | 映射输出：产品小类 |
| category_segment | 手工维护 | 映射输出：品类细分 |

## 五、JOIN条件（三级映射分别JOIN）

| 左表 | 右表(别名) | JOIN类型 | 条件 |
|------|-----------|----------|------|
| dwd.dwd_mrs_mr_avcdtl_wd (t) | dim.dim_ipd_ipm_awproduct_dd (m1) | LEFT JOIN | m1.map_level = 1 AND t.prdct_line_name = m1.prdct_line_name |
| dwd.dwd_mrs_mr_avcdtl_wd (t) | dim.dim_ipd_ipm_awproduct_dd (m2) | LEFT JOIN | m2.map_level = 2 AND t.prdct_line_name = m2.prdct_line_name AND t.prdct_cate = m2.prdct_cate |
| dwd.dwd_mrs_mr_avcdtl_wd (t) | dim.dim_ipd_ipm_awproduct_dd (m3) | LEFT JOIN | m3.map_level = 3 AND t.prdct_line_name = m3.prdct_line_name AND t.prdct_cate = m3.prdct_cate AND t.prdct_cate_dtl = m3.prdct_cate_dtl |

**覆盖优先级**：COALESCE(m3.字段, m2.字段, m1.字段) — 三级 > 二级 > 一级

## 六、更新策略

| 表 | 策略 | 说明 |
|----|------|------|
| dim.dim_ipd_ipm_awproduct_dd | TRUNCATE + INSERT | 映射表全量重刷（28条固定数据） |
| ads.ads_ipd_ipm_aowei_wd | DELETE + INSERT | 目标表全量刷新 |

## 七、脚本执行顺序

| 序号 | 脚本 | 依赖 |
|------|------|------|
| 1 | create_tables.sql | 无（首次建表） |
| 2 | dim_ipd_ipm_awproduct_dd_init.sql | create_tables.sql（映射表需先存在） |
| 3 | ads_ipd_ipm_aowei_wd.sql | create_tables.sql + dim_ipd_ipm_awproduct_dd_init.sql |
