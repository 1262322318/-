# 014-product-retirement-management 数据血缘

## 数据流转图

```
┌─────────────────────────────────────────────────────────────────┐
│ 源层（DIM/ODS）                                                  │
├─────────────────────────────────────────────────────────────────┤
│ dim.dim_ipd_salemodel_dd                                        │
│   → PG00068(销售型号编码), PG00061(名称), PRODUCTMODEL(产品型号) │
│   → PG00025(上市时间), PG00026(停签时间), PG00027(停产时间)      │
│   → PG00023(规划上市时间)                                        │
│   → PC20080(营销部), HX00327(产品经理), HX00339(主销渠道)        │
│   → PG00002/PG00003(大类/中类筛选), PC20006(标准品)              │
│                                                                  │
│ dim.dim_ipd_productmodel_dd                                      │
│   → PG00020(内销/外销)                                           │
│   JOIN: PRODUCTMODEL_ID = ID                                     │
│                                                                  │
│ ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j│
│   （飞书退市滚动计划-JSON解析）                                   │
│   → $.销售型号编码[0].text → salemodelcode（关联键）              │
│   → $.营销部[0].text → marketing_department（飞书营销部）         │
│   → $.主要销售渠道[0].text → channel（飞书渠道，ajhwcl用）       │
│   → $.规划停止下单时间 → plan_tingqian_time                      │
│   → $.规划停止生产时间 → plan_tingchan_time                      │
│   → $.预停签时间 → plan_yutingqian_time（gjdsj脚本用）           │
│                                                                  │
│ dim.dim_ipd_td_weidu_nd                                          │
│   → zhibiao='渠道': udp1(营销部) → udp2(渠道)                   │
│   → zhibiao='事业部合计': udp1(参与合计的营销部)                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ DWS层                                                            │
├─────────────────────────────────────────────────────────────────┤
│ dws.dws_ipd_ipm_rili_ajhwcl_detail_dd                           │
│   粒度：销售型号 × data_type(停签/停产/上市)                     │
│   核心字段：plan_time, act_time, is_aqwc                         │
│   停签过滤：plan_tingqian_time IS NOT NULL                       │
│             AND YEAR(plan_tingqian_time) = YEAR(GP_START_DT)     │
│   停产plan_time计算：act_tingqian_time + 渠道周期                │
│   停产过滤：act_tingqian_time IS NOT NULL                        │
│             AND 渠道可映射 AND 计算结果年份=当年                  │
│     渠道周期由 main_sales_channels(HX00339) 决定：               │
│       家装/电商/全渠道→+1月, 公建/中小→+24月,                    │
│       地产/连锁→+12月, Commercial/Residential/JCH→+6月          │
│   上市过滤：plan_shangshi_time IS NOT NULL                       │
│             AND YEAR(plan_shangshi_time) = YEAR(GP_START_DT)     │
│                                                                  │
│ dws.dws_ipd_ipm_rili_gjdsj_detail_dd                            │
│   粒度：销售型号 × data_type(预停签-停签/停签-停产)              │
│   核心字段：yutingqian_tingqian_d, tingqian_tingchan_d           │
│   预停签-停签过滤：停签时间在当月 AND 飞书预停签时间不为空       │
│   停签-停产过滤：停产时间在当月                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ ADS层                                                            │
├─────────────────────────────────────────────────────────────────┤
│ ads.ads_ipd_ipm_rili_ajhwcl_result_dd                           │
│   聚合：COUNT(DISTINCT) 按时完成/总数 → 执行率                   │
│   维度：总体/PM/营销部 × 月/年                                   │
│   营销部下钻渠道：dimension_3='总体'(合计)/具体渠道              │
│   渠道组合由channel_config CTE硬编码配置                         │
│   weidu_dept CTE：dim.dim_ipd_td_weidu_nd(zhibiao='事业部')     │
│     → 全部营销部列表，用于补零（确保无数据营销部也出结果行）     │
│   data_type_list CTE：硬编码停签/停产/上市，用于CROSS JOIN补零   │
│                                                                  │
│ ads.ads_ipd_ipm_rili_gjdsj_result_dd                            │
│   聚合：AVG(天数) 本期/去年同期 → 缩减率                        │
│   维度：总体/渠道/营销部 × 月/年                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 表依赖矩阵

| 目标表 | 依赖源表 |
|--------|----------|
| dws.dws_ipd_ipm_rili_ajhwcl_detail_dd | dim.dim_ipd_salemodel_dd, dim.dim_ipd_productmodel_dd, ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j, dim.dim_ipd_td_weidu_nd |
| dws.dws_ipd_ipm_rili_gjdsj_detail_dd | dim.dim_ipd_salemodel_dd, dim.dim_ipd_productmodel_dd, ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j |
| ads.ads_ipd_ipm_rili_ajhwcl_result_dd | dws.dws_ipd_ipm_rili_ajhwcl_detail_dd, dim.dim_ipd_td_weidu_nd |
| ads.ads_ipd_ipm_rili_gjdsj_result_dd | dws.dws_ipd_ipm_rili_gjdsj_detail_dd, dim.dim_ipd_td_weidu_nd |

## 字段级血缘（dws_ipd_ipm_rili_ajhwcl_detail_dd）

| 目标字段 | 来源表 | 来源字段 | 转换逻辑 |
|----------|--------|----------|----------|
| dt_month | — | — | DATE_FORMAT('${GP_START_DT}', '%Y%m') |
| product_line | — | — | 固定值'中央空调' |
| data_type | — | — | 展开生成：'停签'/'停产'/'上市' |
| in_out_sale | dim.dim_ipd_productmodel_dd | PG00020 | 直接取值 |
| prdct_model | dim.dim_ipd_salemodel_dd | PRODUCTMODEL | 直接取值 |
| salemodel | dim.dim_ipd_salemodel_dd | PG00061 | 直接取值 |
| salemodelcode | dim.dim_ipd_salemodel_dd | PG00068 | 直接取值 |
| marketing_department | ods.ods_feishu_base_...飞书表 / dim.dim_ipd_salemodel_dd | $.营销部[0].text / PC20080 | 停签/停产从飞书plan_data取值；上市从base_model.PC20080取值 |
| channel | ods.ods_feishu_base_...飞书表 / dim.dim_ipd_td_weidu_nd | $.主要销售渠道[0].text / udp2 | 停签/停产：飞书plan_data.channel直接取值（新增）；上市：channel_map(营销部→渠道，zhibiao='渠道') |
| productmanager | dim.dim_ipd_salemodel_dd | HX00327 | 直接取值 |
| plan_time(停签) | ods.ods_feishu_base_...飞书表 | $.规划停止下单时间 | FROM_UNIXTIME(BIGINT/1000)；筛选：NOT NULL且年份=当年 |
| plan_time(停产) | dim.dim_ipd_salemodel_dd | PG00026 + HX00339 | act_tingqian_time + 按main_sales_channels渠道周期偏移 |
| plan_time(上市) | dim.dim_ipd_salemodel_dd | PG00023 | 规划上市时间直接取值；筛选：NOT NULL且年份=当年 |
| act_time(停签) | dim.dim_ipd_salemodel_dd | PG00026 | 直接取值 |
| act_time(停产) | dim.dim_ipd_salemodel_dd | PG00027 | 直接取值 |
| act_time(上市) | dim.dim_ipd_salemodel_dd | PG00025 | 直接取值 |
| is_aqwc | — | — | CASE: act_time IS NOT NULL AND plan_time IS NOT NULL AND act_time≤plan_time→'Y' ELSE 'N' |
| load_dt | — | — | NOW() |

## 字段级血缘（dws_ipd_ipm_rili_gjdsj_detail_dd）

| 目标字段 | 来源表 | 来源字段 | 转换逻辑 |
|----------|--------|----------|----------|
| dt_month | — | — | DATE_FORMAT('${GP_START_DT}', '%Y%m') |
| product_line | — | — | 固定值'中央空调' |
| data_type | — | — | 展开生成：'预停签-停签'/'停签-停产' |
| in_out_sale | dim.dim_ipd_productmodel_dd | PG00020 | 直接取值 |
| prdct_model | dim.dim_ipd_salemodel_dd | PRODUCTMODEL | 直接取值 |
| salemodel | dim.dim_ipd_salemodel_dd | PG00061 | 直接取值 |
| salemodelcode | dim.dim_ipd_salemodel_dd | PG00068 | 直接取值 |
| marketing_department | ods.ods_feishu_base_...飞书表 | $.营销部[0].text | 飞书plan_data直接取值 |
| channel | ods.ods_feishu_base_...飞书表 | $.主要销售渠道[0].text | 飞书plan_data直接取值 |
| productmanager | dim.dim_ipd_salemodel_dd | HX00327 | 直接取值 |
| yutingqian_time | ods.ods_feishu_base_...飞书表 | $.预停签时间 | FROM_UNIXTIME(BIGINT/1000) |
| tingqian_time | dim.dim_ipd_salemodel_dd | PG00026 | 直接取值 |
| tingchan_time | dim.dim_ipd_salemodel_dd | PG00027 | 直接取值 |
| yutingqian_tingqian_d | — | — | DATEDIFF(tingqian_time, yutingqian_time) |
| tingqian_tingchan_d | — | — | DATEDIFF(tingchan_time, tingqian_time) |
| main_sales_channels | dim.dim_ipd_salemodel_dd | HX00339 | 直接取值 |
| load_dt | — | — | NOW() |

## 字段级血缘（ads_ipd_ipm_rili_ajhwcl_result_dd）

| 目标字段 | 来源表 | 来源字段 | 转换逻辑 |
|----------|--------|----------|----------|
| dt_month | — | — | DATE_FORMAT('${GP_START_DT}', '%Y%m') |
| date_type | — | — | '月'(当月) / '年'(当年累计) |
| data_type | dws明细 | data_type | 透传：停签/停产/上市 |
| product_line | — | — | 固定值'中央空调' |
| in_out_sale | dws明细 / 固定值 | in_out_sale | 总体维度→固定值'全部'（不区分内外销）；PM/营销部维度→透传dws明细值 |
| dimension_1 | — | — | 展开生成：'总体'/'PM'/'营销部' |
| dimension_2 | dws明细 | productmanager/marketing_department | 按dimension_1取对应字段值：总体→'总体'，PM→productmanager，营销部→marketing_department |
| dimension_3 | dws明细 / channel_config | channel | 营销部维度下：'总体'（该营销部所有渠道合计）或具体渠道值（仅channel_config配置的营销部×渠道组合）；总体/PM维度下：NULL |
| numerator | dws明细 | salemodelcode + is_aqwc | COUNT(DISTINCT CASE WHEN is_aqwc='Y' THEN salemodelcode END) |
| denominator | dws明细 | salemodelcode | COUNT(DISTINCT salemodelcode) |
| act_value | — | — | ROUND(numerator / NULLIF(denominator, 0), 4) |
| plan_value | — | — | NULL |
| completion_rate | — | — | NULL |
| load_dt | — | — | NOW() |

### channel_config 配置（营销部×渠道下钻组合）

| 营销部 | 渠道 |
|--------|------|
| 大客户 | 地产 |
| 海信商空营销部 | 公建 |
| 海信商空营销部 | 家装 |
| 海信商空营销部 | 电商 |
| 日立商空营销部 | 公建 |
| 日立商空营销部 | 家装 |
| 日立商空营销部 | 电商 |
| 约克商空营销部 | 公建 |
| 约克商空营销部 | 家装 |

## 字段级血缘（ads_ipd_ipm_rili_gjdsj_result_dd）

| 目标字段 | 来源表 | 来源字段 | 转换逻辑 |
|----------|--------|----------|----------|
| dt_month | — | — | DATE_FORMAT('${GP_START_DT}', '%Y%m') |
| date_type | — | — | '月'(当月) / '年'(当年累计) |
| data_type | dws明细 | data_type | 透传：预停签-停签/停签-停产 |
| product_line | — | — | 固定值'中央空调' |
| in_out_sale | — | — | 固定值'全部'（不区分内外销） |
| dimension_1 | — | — | 展开生成：'总体'/'营销部' |
| dimension_2 | dws明细 / weidu_dept | marketing_department | 按dimension_1取值：总体→'总体'，营销部→marketing_department/'合计' |
| dimension_3 | dws明细 / channel_config | channel | 营销部维度下：'总体'（该营销部所有渠道合计）或具体渠道值；总体维度下：NULL |
| numerator | dws明细 | yutingqian_tingqian_d / tingqian_tingchan_d | AVG(CASE data_type选择对应天数字段)，本期数据 |
| denominator | dws明细(去年同期) | yutingqian_tingqian_d / tingqian_tingchan_d | AVG(CASE data_type选择对应天数字段)，去年同期数据（子查询） |
| act_value | — | — | ROUND(numerator / NULLIF(denominator, 0), 4)（缩减率） |
| plan_value | — | — | NULL |
| completion_rate | — | — | NULL |
| load_dt | — | — | NOW() |

### ADS gjdsj 维度组合

| 组 | dimension_1 | dimension_2 | dimension_3 | 说明 |
|----|-------------|-------------|-------------|------|
| 1 | 总体 | 总体 | NULL | 全部型号合计 |
| 2 | 营销部 | 具体营销部名称 | 总体 | 按营销部分组合计（CROSS JOIN补零） |
| 2.5 | 营销部 | 合计 | 总体 | 事业部合计（仅限weidu_dept配置的营销部） |
| 3 | 营销部 | 具体营销部名称 | 具体渠道 | 营销部×渠道下钻（仅channel_config配置的组合） |

### ADS gjdsj 去年同期对比逻辑

- 本期（numerator）：dws_data_current（当年1月~当月）
- 去年同期（denominator）：dws_data_lastyear（去年1月~去年当月），通过子查询计算
- 月度口径：本期当月 vs 去年同月
- 年累口径：本期1月~当月 vs 去年1月~去年当月

## 飞书ODS表JSON字段解析映射

| JSON路径 | 解析后字段 | 使用脚本 | 说明 |
|----------|-----------|----------|------|
| $.销售型号编码[0].text | salemodelcode | ajhwcl + gjdsj | 关联键 |
| $.营销部[0].text | marketing_department | ajhwcl + gjdsj | 飞书营销部 |
| $.主要销售渠道[0].text | channel | ajhwcl + gjdsj | 飞书渠道（停签/停产直接取值） |
| $.规划停止下单时间 | plan_tingqian_time | ajhwcl | UNIX时间戳/1000→datetime |
| $.规划停止生产时间 | plan_tingchan_time | ajhwcl | UNIX时间戳/1000→datetime（当前未使用） |
| $.预停签时间 | plan_yutingqian_time | gjdsj | UNIX时间戳/1000→datetime |

## 更新记录

| 日期 | 变更内容 |
|------|----------|
| 2026-07-13 | 初始版本：4张表完整血缘 |
| 2026-07-14 | plan_data CTE新增飞书营销部字段($.营销部[0].text)解析；修正飞书表为直接引用ODS层；补充gjdsj字段级血缘和ADS字段级血缘 |
| 2026-07-14 | plan_data CTE新增飞书渠道字段($.主要销售渠道[0].text→channel)；ajhwcl停签/停产的channel来源从channel_map改为飞书直接取值 |
| 2026-07-14 | gjdsj脚本数据源声明修正：移除dim.dim_ipd_td_weidu_nd依赖（实际未引用）；marketing_department和channel均从飞书plan_data直接取值 |
| 2026-07-14 | ADS ajhwcl血缘更新：dimension_1改为'总体'/'PM'/'营销部'（移除独立渠道维度）；dimension_3从NULL改为渠道下钻（'总体'/具体渠道值）；channel_config为硬编码CTE，移除dim.dim_ipd_td_weidu_nd依赖；补充channel_config营销部×渠道组合配置 |
| 2026-07-14 | ADS ajhwcl总体维度in_out_sale改为固定值'全部'（不区分内外销），GROUP BY移除in_out_sale；PM/营销部维度保持透传 |
| 2026-07-14 | ADS ajhwcl新增weidu_dept CTE（dim.dim_ipd_td_weidu_nd, zhibiao='事业部'→全部营销部列表）和data_type_list CTE（硬编码停签/停产/上市），用于CROSS JOIN补零；表依赖矩阵新增dim.dim_ipd_td_weidu_nd |
| 2026-07-14 | 补充ADS gjdsj字段级血缘表（含维度组合配置和去年同期对比逻辑说明） |
