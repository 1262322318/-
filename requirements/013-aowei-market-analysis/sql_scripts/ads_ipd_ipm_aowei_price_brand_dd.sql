/*
 * 脚本名称: ads_aowei_price_brand.sql
 * 功能描述: 表2-3 分价格段分品牌数据（指标行格式）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-08
 * 修改记录:
 *   2026-07-08 [Kiro] 初始创建
 * 依赖关系:
 *   输入: ads.ads_ipd_ipm_aowei_model_price_spec_dd（表2-1，筛选品牌）
 *   输出: ads.ads_ipd_ipm_aowei_price_brand_dd
 * 业务规则:
 *   1. 只展示筛选品牌（从表2-1聚合）
 *   2. 占有率分母：同品类细分+同渠道+同价格段下的全市场总量
 *   3. 转为指标行格式
 */

truncate table ads.ads_ipd_ipm_aowei_price_brand_dd;

INSERT INTO ads.ads_ipd_ipm_aowei_price_brand_dd (
    business_unit,       -- 事业部
    prdct_line_name,     -- 品线名称
    product_mid_class,   -- 产品中类
    product_small_class, -- 产品小类
    category_segment,    -- 品类细分
    o2o_type,            -- 线上线下
    price_segment,       -- 价格段
    stat_brand,          -- 统计品牌
    metric_name,         -- 指标名称
    val_y3,              -- 3年前值
    val_y2,              -- 2年前值
    val_y1,              -- 1年前值
    val_curr,            -- 当年T值
    val_y1_ytd,          -- 去年同期值
    load_dt              -- ETL加载日期
)

WITH
-- 从表2-1取筛选品牌的销额/销量数据（metric_name='销额'/'销量'行）
brand_sales AS (
    SELECT
        business_unit, prdct_line_name, product_mid_class, product_small_class,
        category_segment, o2o_type, stat_brand, prdct_model,
        MAX(CASE WHEN metric_name = '销额' THEN val_y3 END) AS amt_y3,
        MAX(CASE WHEN metric_name = '销额' THEN val_y2 END) AS amt_y2,
        MAX(CASE WHEN metric_name = '销额' THEN val_y1 END) AS amt_y1,
        MAX(CASE WHEN metric_name = '销额' THEN val_curr END) AS amt_curr,
        MAX(CASE WHEN metric_name = '销额' THEN val_y1_ytd END) AS amt_y1_ytd,
        MAX(CASE WHEN metric_name = '销量' THEN val_y3 END) AS qty_y3,
        MAX(CASE WHEN metric_name = '销量' THEN val_y2 END) AS qty_y2,
        MAX(CASE WHEN metric_name = '销量' THEN val_y1 END) AS qty_y1,
        MAX(CASE WHEN metric_name = '销量' THEN val_curr END) AS qty_curr,
        MAX(CASE WHEN metric_name = '销量' THEN val_y1_ytd END) AS qty_y1_ytd,
        MAX(CASE WHEN metric_name = '所属价格段' THEN val_curr END) AS price_segment
    FROM ads.ads_ipd_ipm_aowei_model_price_spec_dd
    WHERE metric_name IN ('销额','销量','所属价格段')
    GROUP BY business_unit, prdct_line_name, product_mid_class, product_small_class,
             category_segment, o2o_type, stat_brand, prdct_model
),

-- 按价格段+品牌聚合
brand_price_agg AS (
    SELECT
        business_unit, prdct_line_name, product_mid_class, product_small_class,
        category_segment, o2o_type, price_segment, stat_brand,
        SUM(CAST(amt_y3 AS DECIMALV3(20,4))) AS amt_y3,
        SUM(CAST(qty_y3 AS DECIMALV3(20,4))) AS qty_y3,
        SUM(CAST(amt_y2 AS DECIMALV3(20,4))) AS amt_y2,
        SUM(CAST(qty_y2 AS DECIMALV3(20,4))) AS qty_y2,
        SUM(CAST(amt_y1 AS DECIMALV3(20,4))) AS amt_y1,
        SUM(CAST(qty_y1 AS DECIMALV3(20,4))) AS qty_y1,
        SUM(CAST(amt_curr AS DECIMALV3(20,4))) AS amt_curr,
        SUM(CAST(qty_curr AS DECIMALV3(20,4))) AS qty_curr,
        SUM(CAST(amt_y1_ytd AS DECIMALV3(20,4))) AS amt_y1_ytd,
        SUM(CAST(qty_y1_ytd AS DECIMALV3(20,4))) AS qty_y1_ytd
    FROM brand_sales
    WHERE price_segment IS NOT NULL
    GROUP BY business_unit, prdct_line_name, product_mid_class, product_small_class,
             category_segment, o2o_type, price_segment, stat_brand
),

-- 占有率分母：同品类细分+同渠道+同价格段下全市场总量（从表2-2的price_segment表取）
market_total AS (
    SELECT
        business_unit, prdct_line_name, product_mid_class, product_small_class,
        category_segment, o2o_type, price_segment,
        CAST(val_y3 AS DECIMALV3(20,4)) AS total_amt_y3,
        CAST(val_y2 AS DECIMALV3(20,4)) AS total_amt_y2,
        CAST(val_y1 AS DECIMALV3(20,4)) AS total_amt_y1,
        CAST(val_curr AS DECIMALV3(20,4)) AS total_amt_curr,
        CAST(val_y1_ytd AS DECIMALV3(20,4)) AS total_amt_y1_ytd
    FROM ads.ads_ipd_ipm_aowei_price_segment_dd
    WHERE metric_name = '总销额'
),

market_total_qty AS (
    SELECT
        business_unit, prdct_line_name, product_mid_class, product_small_class,
        category_segment, o2o_type, price_segment,
        CAST(val_y3 AS DECIMALV3(20,4)) AS total_qty_y3,
        CAST(val_y2 AS DECIMALV3(20,4)) AS total_qty_y2,
        CAST(val_y1 AS DECIMALV3(20,4)) AS total_qty_y1,
        CAST(val_curr AS DECIMALV3(20,4)) AS total_qty_curr,
        CAST(val_y1_ytd AS DECIMALV3(20,4)) AS total_qty_y1_ytd
    FROM ads.ads_ipd_ipm_aowei_price_segment_dd
    WHERE metric_name = '总销量'
),

-- 关联分母
with_share AS (
    SELECT
        bpa.*,
        mt.total_amt_y3, mt.total_amt_y2, mt.total_amt_y1,
        mt.total_amt_curr, mt.total_amt_y1_ytd,
        mq.total_qty_y3, mq.total_qty_y2, mq.total_qty_y1,
        mq.total_qty_curr, mq.total_qty_y1_ytd
    FROM brand_price_agg bpa
    LEFT JOIN market_total mt
        ON bpa.business_unit = mt.business_unit AND bpa.prdct_line_name = mt.prdct_line_name
        AND bpa.product_mid_class = mt.product_mid_class AND bpa.product_small_class = mt.product_small_class
        AND bpa.category_segment = mt.category_segment AND bpa.o2o_type = mt.o2o_type
        AND bpa.price_segment = mt.price_segment
    LEFT JOIN market_total_qty mq
        ON bpa.business_unit = mq.business_unit AND bpa.prdct_line_name = mq.prdct_line_name
        AND bpa.product_mid_class = mq.product_mid_class AND bpa.product_small_class = mq.product_small_class
        AND bpa.category_segment = mq.category_segment AND bpa.o2o_type = mq.o2o_type
        AND bpa.price_segment = mq.price_segment
)

-- 指标1：总销额
SELECT
    business_unit,        -- 事业部
    prdct_line_name,      -- 品线名称
    product_mid_class,    -- 产品中类
    product_small_class,  -- 产品小类
    category_segment,     -- 品类细分
    o2o_type,             -- 线上线下
    price_segment,        -- 价格段
    stat_brand,           -- 统计品牌
    '总销额'              AS metric_name, -- 指标名称
    CAST(amt_y3 AS VARCHAR(50)),     -- 3年前总销额
    CAST(amt_y2 AS VARCHAR(50)),     -- 2年前总销额
    CAST(amt_y1 AS VARCHAR(50)),     -- 1年前总销额
    CAST(amt_curr AS VARCHAR(50)),   -- 当年T总销额
    CAST(amt_y1_ytd AS VARCHAR(50)), -- 去年同期总销额
    NOW()                            -- ETL加载日期
FROM with_share
UNION ALL
-- 指标2：总销量
SELECT business_unit, prdct_line_name, product_mid_class, product_small_class,
       category_segment, o2o_type, price_segment, stat_brand, '总销量',
       CAST(qty_y3 AS VARCHAR(50)), CAST(qty_y2 AS VARCHAR(50)),
       CAST(qty_y1 AS VARCHAR(50)), CAST(qty_curr AS VARCHAR(50)),
       CAST(qty_y1_ytd AS VARCHAR(50)), NOW()
FROM with_share
UNION ALL
-- 指标3：产品均价
SELECT business_unit, prdct_line_name, product_mid_class, product_small_class,
       category_segment, o2o_type, price_segment, stat_brand, '产品均价',
       CAST(CASE WHEN qty_y3>0 THEN amt_y3/qty_y3 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN qty_y2>0 THEN amt_y2/qty_y2 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN qty_y1>0 THEN amt_y1/qty_y1 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN qty_curr>0 THEN amt_curr/qty_curr ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN qty_y1_ytd>0 THEN amt_y1_ytd/qty_y1_ytd ELSE NULL END AS VARCHAR(50)),
       NOW()
FROM with_share
UNION ALL
-- 指标4：额占有率
SELECT business_unit, prdct_line_name, product_mid_class, product_small_class,
       category_segment, o2o_type, price_segment, stat_brand, '额占有率',
       CAST(CASE WHEN total_amt_y3>0 THEN amt_y3/total_amt_y3 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_amt_y2>0 THEN amt_y2/total_amt_y2 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_amt_y1>0 THEN amt_y1/total_amt_y1 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_amt_curr>0 THEN amt_curr/total_amt_curr ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_amt_y1_ytd>0 THEN amt_y1_ytd/total_amt_y1_ytd ELSE NULL END AS VARCHAR(50)),
       NOW()
FROM with_share
UNION ALL
-- 指标5：量占有率
SELECT business_unit, prdct_line_name, product_mid_class, product_small_class,
       category_segment, o2o_type, price_segment, stat_brand, '量占有率',
       CAST(CASE WHEN total_qty_y3>0 THEN qty_y3/total_qty_y3 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_y2>0 THEN qty_y2/total_qty_y2 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_y1>0 THEN qty_y1/total_qty_y1 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_curr>0 THEN qty_curr/total_qty_curr ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_y1_ytd>0 THEN qty_y1_ytd/total_qty_y1_ytd ELSE NULL END AS VARCHAR(50)),
       NOW()
FROM with_share
;
