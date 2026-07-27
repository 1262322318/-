# 013-aowei-market-analysis 数据血缘

## 数据流转图

```
ads.ads_ipd_ipm_aowei_wd（010需求产出）
    │
    ├─────────────────────────────────────────────────────────────┐
    │                                                             │
    ▼                                                             ▼
dim.dim_ipd_ipm_aw_price_segment_dd                dim.dim_ipd_ipm_aw_spec_segment_dd
    │                                                             │
    └──────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
    ads.ads_ipd_ipm_aowei_model_price_spec_nd（表2-1，筛选品牌型号级）
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
    表2-3(品牌)       表2-2(全市场)     表2-4(全市场)
    price_brand       price_segment     price_spec
         │                                   │
         │                                   ▼
         │                              表2-5(品牌)
         │                           price_spec_brand
         │
         └── 分母来源：表2-2

ads.ads_ipd_ipm_aowei_wd（独立聚合）
    │
    ├──▶ ads.ads_ipd_ipm_aowei_industry_channel_dd（表1-1，全市场）
    │
    └──▶ ads.ads_ipd_ipm_aowei_channel_brand_dd（表1-2，筛选品牌）
              └── 分母来源：源表直接聚合全市场

═══ 模块3：2026-07-21扩增3张（单元格拼接格式） ═══

ads.ads_ipd_ipm_aowei_wd（源表聚合）
    │
    └──▶ ads.ads_ipd_ipm_aowei_industry_brand_dd（表A，含"总体"渠道虚拟维度 + 筛选品牌）
              └── 分母来源：源表聚合同粒度全市场（同渠道，不限品牌）
                  含"总体"渠道行占有率（与013表1-1"设NULL"规则不同）

ads.ads_ipd_ipm_aowei_price_spec_dd（表2-4）  ─┐
                                              ├── 二次聚合
ads.ads_ipd_ipm_aowei_price_spec_brand_dd（表2-5）─┘
    │
    ├──▶ ads.ads_ipd_ipm_aowei_price_spec_brand_online_dd（表B，filter 线上）
    │       ├── "总体"品牌行=表2-4的产品均价 + 占有率固定100.00%
    │       └── 筛选品牌行=表2-5的额占有率+产品均价（透视合并）
    │
    └──▶ ads.ads_ipd_ipm_aowei_price_spec_brand_offline_dd（表C，filter 线下）
            └── 结构完全同表B，仅渠道条件不同
```

## 表间依赖关系

| 目标表 | 依赖 |
|--------|------|
| 表2-1 | 源表 + dim价格段 + dim规格段 |
| 表1-1 | 源表（独立） |
| 表1-2 | 源表（独立） |
| 表2-2 | 源表 + dim价格段（独立聚合全市场） |
| 表2-3 | 表2-1（筛选品牌数据）+ 表2-2（全市场分母） |
| 表2-4 | 源表 + dim价格段 + dim规格段（独立聚合全市场） |
| 表2-5 | 表2-1（筛选品牌数据）+ 表2-4（全市场分母） |
| 表A（2026-07-21） | 源表（独立，含"总体"渠道虚拟维度 + 品牌 UNION ALL 筛选） |
| 表B（2026-07-21） | 表2-4（"总体"品牌行来源）+ 表2-5（筛选品牌行来源），filter o2o_type='线上' |
| 表C（2026-07-21） | 同表B，filter o2o_type='线下' |

## 脚本清单

| 序号 | 脚本 | 类型 | 输入表 | 输出表 |
|------|------|------|--------|--------|
| 1 | create_tables.sql | DDL | — | dim价格段 + dim规格段 + 7张ads表 |
| 2 | dim_price_segment_init.sql | DML | —（静态数据，74条） | dim.dim_ipd_ipm_aw_price_segment_dd |
| 3 | dim_spec_segment_init.sql | DML | —（静态数据，52条） | dim.dim_ipd_ipm_aw_spec_segment_dd |
| 4 | ads_aowei_model_price_spec.sql | DML | ads_ipd_ipm_aowei_wd + dim价格段 + dim规格段 | ads_ipd_ipm_aowei_model_price_spec_nd |
| 5 | ads_ipd_ipm_aowei_industry_channel_dd.sql | DML | ads_ipd_ipm_aowei_wd | ads_ipd_ipm_aowei_industry_channel_dd（TRUNCATE+INSERT） |
| 6 | ads_aowei_channel_brand.sql | DML | ads_ipd_ipm_aowei_wd | ads_ipd_ipm_aowei_channel_brand_dd（TRUNCATE+INSERT） |
| 7 | ads_aowei_price_segment.sql | DML | ads_ipd_ipm_aowei_wd + dim价格段 | ads_ipd_ipm_aowei_price_segment_nd |
| 8 | ads_aowei_price_brand.sql | DML | model_price_spec_nd + price_segment_nd | ads_ipd_ipm_aowei_price_brand_nd |
| 9 | ads_aowei_price_spec.sql | DML | ads_ipd_ipm_aowei_wd + dim价格段 + dim规格段 | ads_ipd_ipm_aowei_price_spec_nd |
| 10 | ads_aowei_price_spec_brand.sql | DML | model_price_spec_nd + price_spec_nd | ads_ipd_ipm_aowei_price_spec_brand_nd |
| 11 | ads_ipd_ipm_aowei_industry_brand_dd.sql | DML | ads_ipd_ipm_aowei_wd | ads_ipd_ipm_aowei_industry_brand_dd（TRUNCATE+INSERT，单元格拼接） |
| 12 | ads_ipd_ipm_aowei_price_spec_brand_online_dd.sql | DML | price_spec_dd（表2-4）+ price_spec_brand_dd（表2-5） | ads_ipd_ipm_aowei_price_spec_brand_online_dd（TRUNCATE+INSERT，单元格拼接） |
| 13 | ads_ipd_ipm_aowei_price_spec_brand_offline_dd.sql | DML | price_spec_dd（表2-4）+ price_spec_brand_dd（表2-5） | ads_ipd_ipm_aowei_price_spec_brand_offline_dd（TRUNCATE+INSERT，单元格拼接） |
| 14 | validate_data_quality.sql | 验证 | dim价格段 + dim规格段 + 10张ads表 | — (验证结果集) |

## 字段级血缘：ads_ipd_ipm_aowei_industry_channel_dd（表1-1）

> 时间参数：curr_year = YEAR('${GP_START_DT}')，curr_month = DATE_FORMAT('${GP_START_DT}', '%m')

| 目标字段 | 来源 | 转换逻辑 |
|----------|------|----------|
| business_unit | ads.ads_ipd_ipm_aowei_wd.business_unit | 直接映射 |
| product_mid_class | ads.ads_ipd_ipm_aowei_wd.product_mid_class | 直接映射 |
| product_small_class | ads.ads_ipd_ipm_aowei_wd.product_small_class | 直接映射 |
| category_segment | ads.ads_ipd_ipm_aowei_wd.category_segment | 直接映射 |
| channel_type_agg | ads.ads_ipd_ipm_aowei_wd.o2o_type + 虚拟维度 | 线上/线下直接映射o2o_type；"总体"为线上+线下SUM合计生成的虚拟维度行 |
| metric_name | 计算字段 | 枚举值：总销额/总销量/产品均价/额占有率/量占有率 |
| val_y3 | ads.ads_ipd_ipm_aowei_wd.sale_amt / sale_qty | 按dt_wmcode前4位=curr_year-3筛选聚合，不同metric_name不同计算 |
| val_y2 | ads.ads_ipd_ipm_aowei_wd.sale_amt / sale_qty | 按dt_wmcode前4位=curr_year-2筛选聚合 |
| val_y1 | ads.ads_ipd_ipm_aowei_wd.sale_amt / sale_qty | 按dt_wmcode前4位=curr_year-1筛选聚合 |
| val_curr | ads.ads_ipd_ipm_aowei_wd.sale_amt / sale_qty | 按dt_wmcode前4位=curr_year筛选聚合 |
| val_y1_ytd | ads.ads_ipd_ipm_aowei_wd.sale_amt / sale_qty | 去年同期（dt_wmcode前4位=curr_year-1 且 月份<=curr_month） |
| load_dt | NOW() | ETL加载时间 |

### 指标行生成逻辑

| metric_name | 计算公式 | 总体行处理 |
|-------------|----------|-----------|
| 总销额 | SUM(sale_amt) | 正常输出（线上+线下合计） |
| 总销量 | SUM(sale_qty) | 正常输出（线上+线下合计） |
| 产品均价 | SUM(sale_amt)/SUM(sale_qty)，分母为0时NULL | 正常输出 |
| 额占有率 | 当前渠道销额/总体销额 | 总体行不输出（WHERE过滤） |
| 量占有率 | 当前渠道销量/总体销量 | 总体行输出固定值1 |

### 占有率分母来源

| 分母字段 | 来源 | 聚合条件 |
|----------|------|----------|
| total_amt/qty_y3~y1_ytd | total_agg CTE（线上+线下SUM） | 同business_unit + product_mid_class + product_small_class + category_segment |

### CTE结构

| CTE名称 | 用途 | 数据来源 |
|----------|------|----------|
| time_params | 时间参数计算（当年/去年/前年/大前年/当月） | ${GP_START_DT} |
| channel_agg | 按渠道（线上/线下）聚合5个年度的销额销量 | ads.ads_ipd_ipm_aowei_wd（wm_type='月'） |
| total_agg | 生成"总体"虚拟维度行（线上+线下合计） | channel_agg |
| all_channels | 合并线上/线下行 + 总体行 | channel_agg UNION ALL total_agg |
| with_share | 关联总体行作为占有率分母 | all_channels LEFT JOIN total_agg |

## 字段级血缘：ads_ipd_ipm_aowei_price_spec_brand_dd（表2-5）

> 分价格段分规格段分品牌数据（筛选品牌），占有率分母来自表2-4（全市场）

| 目标字段 | 来源 | 转换逻辑 |
|----------|------|----------|
| business_unit | ads_ipd_ipm_aowei_model_price_spec_dd.business_unit | 从表2-1聚合传递 |
| prdct_line_name | ads_ipd_ipm_aowei_model_price_spec_dd.prdct_line_name | 从表2-1聚合传递 |
| product_mid_class | ads_ipd_ipm_aowei_model_price_spec_dd.product_mid_class | 从表2-1聚合传递 |
| product_small_class | ads_ipd_ipm_aowei_model_price_spec_dd.product_small_class | 从表2-1聚合传递 |
| category_segment | ads_ipd_ipm_aowei_model_price_spec_dd.category_segment | 从表2-1聚合传递 |
| o2o_type | ads_ipd_ipm_aowei_model_price_spec_dd.o2o_type | 从表2-1聚合传递 |
| price_segment | ads_ipd_ipm_aowei_model_price_spec_dd（metric_name='所属价格段'时的val_curr） | 从表2-1型号级价格段标记聚合 |
| spec_segment | ads_ipd_ipm_aowei_model_price_spec_dd（metric_name='所属规格段'时的val_curr） | 从表2-1型号级规格段标记聚合 |
| stat_brand | ads_ipd_ipm_aowei_model_price_spec_dd.stat_brand | 从表2-1聚合传递 |
| metric_name | 计算字段 | 枚举值：总销额/总销量/产品均价/额占有率/量占有率 |
| val_y3~val_y1_ytd | 计算字段 | 不同metric_name不同计算（见下方） |
| load_dt | NOW() | ETL加载时间 |

### 指标行生成逻辑

| metric_name | 计算公式 | 说明 |
|-------------|----------|------|
| 总销额 | SUM(CAST(表2-1销额行.val_yX AS DECIMALV3(20,4))) | 按价格段+规格段+品牌聚合 |
| 总销量 | SUM(CAST(表2-1销量行.val_yX AS DECIMALV3(20,4))) | 按价格段+规格段+品牌聚合 |
| 产品均价 | amt/qty，分母为0时NULL | 聚合后计算 |
| 额占有率 | amt / total_amt（来自表2-4同维度全市场销额） | 分母=同品类细分+同渠道+同价格段+同规格段全市场 |
| 量占有率 | qty / total_qty（来自表2-4同维度全市场销量） | 分母=同品类细分+同渠道+同价格段+同规格段全市场 |

### 占有率分母来源

| 分母字段 | 来源表 | 关联条件 |
|----------|--------|----------|
| total_amt_y3~y1_ytd | ads_ipd_ipm_aowei_price_spec_dd（metric_name='总销额'） | 同business_unit + prdct_line_name + product_mid_class + product_small_class + category_segment + o2o_type + price_segment + spec_segment |
| total_qty_y3~y1_ytd | ads_ipd_ipm_aowei_price_spec_dd（metric_name='总销量'） | 同上 |

### CTE结构

| CTE名称 | 用途 | 数据来源 |
|----------|------|----------|
| brand_sales | 从表2-1 PIVOT还原型号级销额/销量/价格段/规格段 | ads_ipd_ipm_aowei_model_price_spec_dd（metric_name IN 销额/销量/所属价格段/所属规格段） |
| brand_ps_agg | 按价格段+规格段+品牌聚合（过滤price_segment和spec_segment非NULL） | brand_sales |
| market_total_amt | 全市场分母（销额），从表2-4读取 | ads_ipd_ipm_aowei_price_spec_dd（metric_name='总销额'） |
| market_total_qty | 全市场分母（销量），从表2-4读取 | ads_ipd_ipm_aowei_price_spec_dd（metric_name='总销量'） |
| with_share | 关联筛选品牌数据与全市场分母 | brand_ps_agg LEFT JOIN market_total_amt + market_total_qty |

---

## 数据质量验证血缘（validate_data_quality.sql）

| 验证项 | 读取表 | 验证维度 |
|--------|--------|----------|
| dim记录数 | dim.dim_ipd_ipm_aw_price_segment_dd | COUNT = 74 |
| dim记录数 | dim.dim_ipd_ipm_aw_spec_segment_dd | COUNT = 52 |
| 非空验证 | ads.ads_ipd_ipm_aowei_industry_channel_dd | COUNT > 0 |
| 非空验证 | ads.ads_ipd_ipm_aowei_channel_brand_dd | COUNT > 0 |
| 非空验证 | ads.ads_ipd_ipm_aowei_model_price_spec_dd | COUNT > 0 |
| 非空验证 | ads.ads_ipd_ipm_aowei_price_segment_dd | COUNT > 0 |
| 非空验证 | ads.ads_ipd_ipm_aowei_price_brand_dd | COUNT > 0 |
| 非空验证 | ads.ads_ipd_ipm_aowei_price_spec_dd | COUNT > 0 |
| 非空验证 | ads.ads_ipd_ipm_aowei_price_spec_brand_dd | COUNT > 0 |
| 指标枚举 | ads_ipd_ipm_aowei_industry_channel_dd | metric_name 分布 |
| 指标枚举 | ads_ipd_ipm_aowei_model_price_spec_dd | metric_name 分布 |
| 总体行额占有率不存在 | ads_ipd_ipm_aowei_industry_channel_dd | channel_type_agg='总体' AND metric_name='额占有率' 应为0行 |
| 总体行量占有率=1 | ads_ipd_ipm_aowei_industry_channel_dd | channel_type_agg='总体' AND metric_name='量占有率' val值=1 |
| 品牌枚举 | ads_ipd_ipm_aowei_channel_brand_dd | stat_brand 分布 |
| 价格段覆盖 | dim_ipd_ipm_aw_price_segment_dd | 各品线区间完整性 |

## 字段级血缘：ads_ipd_ipm_aowei_industry_brand_dd（表A，2026-07-21扩增）

> 单元格拼接格式：val 字段= `"占有率%，均价"`，中文全角逗号，空值统一 `"—，—"`。无 metric_name 字段。

| 目标字段 | 来源 | 转换逻辑 |
|----------|------|----------|
| business_unit | ads.ads_ipd_ipm_aowei_wd.business_unit | 直接映射 |
| product_mid_class | ads.ads_ipd_ipm_aowei_wd.product_mid_class | 直接映射 |
| product_small_class | ads.ads_ipd_ipm_aowei_wd.product_small_class | 直接映射 |
| category_segment | ads.ads_ipd_ipm_aowei_wd.category_segment | 直接映射 |
| channel_type_agg | ads.ads_ipd_ipm_aowei_wd.o2o_type + 虚拟维度 | CROSS JOIN weidu_channel(总体/线上/线下)，CASE WHEN分渠道求和 |
| stat_brand | ads.ads_ipd_ipm_aowei_wd.brand_series / brand_name / sub_brand_name | 品牌 UNION ALL 筛选（5大系列 + 洗护小天鹅 + 显示三星） |
| val_y3~val_y1_ytd | ads.ads_ipd_ipm_aowei_wd.sale_amt / sale_qty | `CASE WHEN 空值 THEN '—，—' ELSE CONCAT(占有率2位小数%, '，', 均价2位小数)` |
| load_dt | NOW() | ETL加载时间 |

### CTE结构（表A）

| CTE | 用途 |
|-----|------|
| time_params | 5个年份+当月的时间参数 |
| weidu_channel | 生成"总体"/"线上"/"线下"3行虚拟维度 |
| brand_mapped | 4段 UNION ALL 品牌筛选（空气/冰冷/洗护/厨电5系列、显示4系列、洗护小天鹅、显示三星） |
| brand_agg | CROSS JOIN weidu_channel + CASE WHEN 按渠道分类求和（10个SUM字段覆盖5年份的额+量） |
| market_total | 全市场分母（同粒度不限品牌，同样含"总体"渠道） |
| with_share | LEFT JOIN 分母 |

---

## 字段级血缘：ads_ipd_ipm_aowei_price_spec_brand_online_dd（表B，2026-07-21扩增）

> 基于013表2-4（"总体"品牌行来源）+ 表2-5（筛选品牌行来源）二次聚合。单元格拼接格式。

| 目标字段 | 来源 | 转换逻辑 |
|----------|------|----------|
| business_unit / prdct_line_name / product_mid_class / product_small_class / category_segment / price_segment / spec_segment | 表2-4（"总体"行）/ 表2-5（筛选品牌行） | 从对应表GROUP BY同名字段传递 |
| o2o_type | 常量 `'线上'` | 固定值 |
| stat_brand | 表2-5.stat_brand（筛选品牌行）/ 常量 `'总体'`（"总体"行） | UNION ALL两个分支 |
| val_y3~val_y1_ytd | 表2-4/表2-5的 val_y3~val_y1_ytd（metric_name='额占有率'/'产品均价'透视合并） | `CASE WHEN 空值 THEN '—，—' ELSE CONCAT(占有率2位小数%, '，', 均价2位小数)`。"总体"行占有率固定=`100.00%` |
| load_dt | NOW() | ETL加载时间 |

### CTE结构（表B）

| CTE | 用途 | 数据来源 |
|-----|------|----------|
| brand_data | 从表2-5 PIVOT 额占有率+产品均价合并到一行 | ads.ads_ipd_ipm_aowei_price_spec_brand_dd，filter o2o_type='线上' AND metric_name IN ('额占有率','产品均价') |
| total_data | 从表2-4 取"总体"品牌行的产品均价（占有率固定100%） | ads.ads_ipd_ipm_aowei_price_spec_dd，filter o2o_type='线上' AND metric_name='产品均价' |

### 数据组装

```
UNION ALL
├── 筛选品牌行：brand_data → CONCAT(占有率×100+%, '，', 均价)
└── 总体品牌行：total_data → CONCAT('100.00%', '，', 均价)
```

---

## 字段级血缘：ads_ipd_ipm_aowei_price_spec_brand_offline_dd（表C，2026-07-21扩增）

结构完全同表B，仅 filter `o2o_type='线下'`。字段血缘、CTE结构、数据组装均等同表B，此处不重复。
