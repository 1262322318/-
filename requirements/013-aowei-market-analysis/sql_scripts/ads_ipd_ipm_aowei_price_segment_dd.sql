/*
 * 脚本名称: ads_aowei_price_segment.sql
 * 功能描述: 表2-2 分价格段数据（全市场，指标行格式）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-08
 * 修改记录:
 *   2026-07-08 [Kiro] 初始创建
 * 依赖关系:
 *   输入: ads.ads_ipd_ipm_aowei_model_price_spec_dd（表2-1）
 *   输出: ads.ads_ipd_ipm_aowei_price_segment_dd
 * 业务规则:
 *   1. 全市场数据（不限品牌），基于表2-1的全市场版本聚合
 *   2. 按事业部+品线+产品中类+产品小类+品类细分+线上线下+价格段聚合
 *   3. 占有率分母：同品类细分+同渠道下全价格段的全市场总量
 *   4. 转为指标行格式（总销额/总销量/产品均价/额占有率/量占有率）
 *   5. 注意：由于表2-1只含筛选品牌，此表需从源表直接聚合全市场数据
 */

truncate table ads.ads_ipd_ipm_aowei_price_segment_dd;

INSERT INTO ads.ads_ipd_ipm_aowei_price_segment_dd (
    business_unit,       -- 事业部
    prdct_line_name,     -- 品线名称
    product_mid_class,   -- 产品中类
    product_small_class, -- 产品小类
    category_segment,    -- 品类细分
    o2o_type,            -- 线上线下
    price_segment,       -- 价格段
    metric_name,         -- 指标名称
    val_y3,              -- 3年前值
    val_y2,              -- 2年前值
    val_y1,              -- 1年前值
    val_curr,            -- 当年T值
    val_y1_ytd,          -- 去年同期值
    load_dt              -- ETL加载日期
)

WITH
time_params AS (
    SELECT
        YEAR('${GP_START_DT}') AS curr_year,
        YEAR('${GP_START_DT}') - 1 AS y1_year,
        YEAR('${GP_START_DT}') - 2 AS y2_year,
        YEAR('${GP_START_DT}') - 3 AS y3_year,
        DATE_FORMAT('${GP_START_DT}', '%m') AS curr_month
),

-- 全市场型号级聚合（不限品牌）+ 匹配价格段
model_agg AS (
    SELECT
        t.business_unit,
        t.prdct_line_name,
        t.product_mid_class,
        t.product_small_class,
        t.category_segment,
        t.o2o_type,
        t.prdct_model,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS amt_y3,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS qty_y3,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS amt_y2,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS qty_y2,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS amt_y1,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS qty_y1,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS amt_curr,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS qty_curr,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(t.dt_wmcode,5,2) <= p.curr_month THEN t.sale_amt ELSE 0 END) AS amt_y1_ytd,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(t.dt_wmcode,5,2) <= p.curr_month THEN t.sale_qty ELSE 0 END) AS qty_y1_ytd
    FROM ads.ads_ipd_ipm_aowei_wd t
    CROSS JOIN time_params p
    WHERE t.wm_type = '月'
      AND SUBSTRING(t.dt_wmcode,1,4) >= CAST(p.y3_year AS VARCHAR)
    GROUP BY t.business_unit, t.prdct_line_name, t.product_mid_class,
             t.product_small_class, t.category_segment, t.o2o_type, t.prdct_model
),

-- 匹配价格段（按当年T均价匹配，用于分组）
-- 注意：此处按每个年度独立聚合到价格段级别
price_agg AS (
    SELECT
        m.business_unit,
        m.prdct_line_name,
        m.product_mid_class,
        m.product_small_class,
        m.category_segment,
        m.o2o_type,
        ps.price_segment,
        SUM(m.amt_y3) AS amt_y3, SUM(m.qty_y3) AS qty_y3,
        SUM(m.amt_y2) AS amt_y2, SUM(m.qty_y2) AS qty_y2,
        SUM(m.amt_y1) AS amt_y1, SUM(m.qty_y1) AS qty_y1,
        SUM(m.amt_curr) AS amt_curr, SUM(m.qty_curr) AS qty_curr,
        SUM(m.amt_y1_ytd) AS amt_y1_ytd, SUM(m.qty_y1_ytd) AS qty_y1_ytd
    FROM model_agg m
    -- 按当年T均价匹配价格段（用于分组维度）
    LEFT JOIN dim.dim_ipd_ipm_aw_price_segment_dd ps
        ON m.prdct_line_name = ps.prdct_line_name
        AND (m.amt_curr / NULLIF(m.qty_curr, 0)) >= ps.min_price
        AND (m.amt_curr / NULLIF(m.qty_curr, 0)) < ps.max_price
    GROUP BY m.business_unit, m.prdct_line_name, m.product_mid_class,
             m.product_small_class, m.category_segment, m.o2o_type, ps.price_segment
),

-- 占有率分母：同品类细分+同渠道下全市场总量
market_total AS (
    SELECT
        business_unit, prdct_line_name, product_mid_class,
        product_small_class, category_segment, o2o_type,
        SUM(amt_y3) AS total_amt_y3, SUM(qty_y3) AS total_qty_y3,
        SUM(amt_y2) AS total_amt_y2, SUM(qty_y2) AS total_qty_y2,
        SUM(amt_y1) AS total_amt_y1, SUM(qty_y1) AS total_qty_y1,
        SUM(amt_curr) AS total_amt_curr, SUM(qty_curr) AS total_qty_curr,
        SUM(amt_y1_ytd) AS total_amt_y1_ytd, SUM(qty_y1_ytd) AS total_qty_y1_ytd
    FROM price_agg
    GROUP BY business_unit, prdct_line_name, product_mid_class,
             product_small_class, category_segment, o2o_type
),

-- 关联分母
with_share AS (
    SELECT
        pa.*,
        mt.total_amt_y3, mt.total_qty_y3,
        mt.total_amt_y2, mt.total_qty_y2,
        mt.total_amt_y1, mt.total_qty_y1,
        mt.total_amt_curr, mt.total_qty_curr,
        mt.total_amt_y1_ytd, mt.total_qty_y1_ytd
    FROM price_agg pa
    LEFT JOIN market_total mt
        ON pa.business_unit = mt.business_unit
        AND pa.prdct_line_name = mt.prdct_line_name
        AND pa.product_mid_class = mt.product_mid_class
        AND pa.product_small_class = mt.product_small_class
        AND pa.category_segment = mt.category_segment
        AND pa.o2o_type = mt.o2o_type
)

-- 指标1：总销额
SELECT
    business_unit,                                        -- 事业部
    prdct_line_name,                                      -- 品线名称
    product_mid_class,                                    -- 产品中类
    product_small_class,                                  -- 产品小类
    category_segment,                                     -- 品类细分
    o2o_type,                                             -- 线上线下
    price_segment,                                        -- 价格段
    '总销额'                        AS metric_name,       -- 指标名称
    CAST(amt_y3 AS VARCHAR(50))     AS val_y3,            -- 3年前总销额
    CAST(amt_y2 AS VARCHAR(50))     AS val_y2,            -- 2年前总销额
    CAST(amt_y1 AS VARCHAR(50))     AS val_y1,            -- 1年前总销额
    CAST(amt_curr AS VARCHAR(50))   AS val_curr,          -- 当年T总销额
    CAST(amt_y1_ytd AS VARCHAR(50)) AS val_y1_ytd,        -- 去年同期总销额
    NOW()                           AS load_dt             -- ETL加载日期
FROM with_share
UNION ALL
-- 指标2：总销量
SELECT business_unit, prdct_line_name, product_mid_class, product_small_class,
       category_segment, o2o_type, price_segment,
       '总销量',
       CAST(qty_y3 AS VARCHAR(50)), CAST(qty_y2 AS VARCHAR(50)),
       CAST(qty_y1 AS VARCHAR(50)), CAST(qty_curr AS VARCHAR(50)),
       CAST(qty_y1_ytd AS VARCHAR(50)), NOW()
FROM with_share
UNION ALL
-- 指标3：产品均价
SELECT business_unit, prdct_line_name, product_mid_class, product_small_class,
       category_segment, o2o_type, price_segment,
       '产品均价',
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
       category_segment, o2o_type, price_segment,
       '额占有率',
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
       category_segment, o2o_type, price_segment,
       '量占有率',
       CAST(CASE WHEN total_qty_y3>0 THEN qty_y3/total_qty_y3 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_y2>0 THEN qty_y2/total_qty_y2 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_y1>0 THEN qty_y1/total_qty_y1 ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_curr>0 THEN qty_curr/total_qty_curr ELSE NULL END AS VARCHAR(50)),
       CAST(CASE WHEN total_qty_y1_ytd>0 THEN qty_y1_ytd/total_qty_y1_ytd ELSE NULL END AS VARCHAR(50)),
       NOW()
FROM with_share
;
