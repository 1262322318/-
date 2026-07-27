/*
 * 脚本名称: ads_aowei_channel_brand.sql
 * 功能描述: 表1-2 分渠道分品牌数据（指标行格式）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-08
 * 修改记录:
 *   2026-07-08 [Kiro] 初始创建
 * 依赖关系:
 *   输入: ads.ads_ipd_ipm_aowei_wd
 *   输出: ads.ads_ipd_ipm_aowei_channel_brand_dd
 * 业务规则:
 *   1. 只展示筛选品牌（小天鹅/三星允许与系列重复计数）
 *   2. 占有率分母：同品类细分+同渠道下的全市场（不限品牌）总量
 *   3. 转为指标行格式
 */

DELETE FROM ads.ads_ipd_ipm_aowei_channel_brand_dd;

INSERT INTO ads.ads_ipd_ipm_aowei_channel_brand_dd (
    business_unit,       -- 事业部
    product_mid_class,   -- 产品中类
    product_small_class, -- 产品小类
    category_segment,    -- 品类细分
    o2o_type,            -- 线上线下
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
time_params AS (
    SELECT
        YEAR('${GP_START_DT}') AS curr_year,
        YEAR('${GP_START_DT}') - 1 AS y1_year,
        YEAR('${GP_START_DT}') - 2 AS y2_year,
        YEAR('${GP_START_DT}') - 3 AS y3_year,
        DATE_FORMAT('${GP_START_DT}', '%m') AS curr_month
),

-- 品牌映射（UNION ALL，允许重复计数）
brand_mapped AS (
    -- 空气/冰冷/洗护/厨电：5大系列
    SELECT t.business_unit, t.product_mid_class, t.product_small_class,
           t.category_segment, t.o2o_type, t.brand_series AS stat_brand,
           t.dt_wmcode, t.sale_amt, t.sale_qty
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit IN ('空气','冰冷','洗护','厨电')
      AND t.brand_series IN ('海信系列','海尔系列','美的系列','TCL系列','小米系列')

    UNION ALL

    -- 显示：4大系列
    SELECT t.business_unit, t.product_mid_class, t.product_small_class,
           t.category_segment, t.o2o_type, t.brand_series AS stat_brand,
           t.dt_wmcode, t.sale_amt, t.sale_qty
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '显示'
      AND t.brand_series IN ('海信系列','TCL系列','小米系列','创维系列')

    UNION ALL

    -- 小天鹅独立维度（洗护，允许与系列重复）
    SELECT t.business_unit, t.product_mid_class, t.product_small_class,
           t.category_segment, t.o2o_type, '小天鹅' AS stat_brand,
           t.dt_wmcode, t.sale_amt, t.sale_qty
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '洗护'
      AND t.sub_brand_name = '小天鹅'

    UNION ALL

    -- 三星独立维度（显示，允许与系列重复）
    SELECT t.business_unit, t.product_mid_class, t.product_small_class,
           t.category_segment, t.o2o_type, '三星' AS stat_brand,
           t.dt_wmcode, t.sale_amt, t.sale_qty
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '显示'
      AND t.brand_name = '三星'
),

-- 按品牌聚合
brand_agg AS (
    SELECT
        b.business_unit, b.product_mid_class, b.product_small_class,
        b.category_segment, b.o2o_type, b.stat_brand,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR) THEN b.sale_amt ELSE 0 END) AS amt_y3,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR) THEN b.sale_qty ELSE 0 END) AS qty_y3,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR) THEN b.sale_amt ELSE 0 END) AS amt_y2,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR) THEN b.sale_qty ELSE 0 END) AS qty_y2,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR) THEN b.sale_amt ELSE 0 END) AS amt_y1,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR) THEN b.sale_qty ELSE 0 END) AS qty_y1,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR) THEN b.sale_amt ELSE 0 END) AS amt_curr,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR) THEN b.sale_qty ELSE 0 END) AS qty_curr,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(b.dt_wmcode,5,2) <= p.curr_month THEN b.sale_amt ELSE 0 END) AS amt_y1_ytd,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(b.dt_wmcode,5,2) <= p.curr_month THEN b.sale_qty ELSE 0 END) AS qty_y1_ytd
    FROM brand_mapped b
    CROSS JOIN time_params p
    WHERE SUBSTRING(b.dt_wmcode,1,4) >= CAST(p.y3_year AS VARCHAR)
    GROUP BY b.business_unit, b.product_mid_class, b.product_small_class,
             b.category_segment, b.o2o_type, b.stat_brand
),

-- 全市场分母（同品类细分+同渠道，不限品牌）
market_total AS (
    SELECT
        t.business_unit, t.product_mid_class, t.product_small_class,
        t.category_segment, t.o2o_type,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS total_amt_y3,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS total_qty_y3,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS total_amt_y2,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS total_qty_y2,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS total_amt_y1,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS total_qty_y1,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR) THEN t.sale_amt ELSE 0 END) AS total_amt_curr,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR) THEN t.sale_qty ELSE 0 END) AS total_qty_curr,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(t.dt_wmcode,5,2) <= p.curr_month THEN t.sale_amt ELSE 0 END) AS total_amt_y1_ytd,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(t.dt_wmcode,5,2) <= p.curr_month THEN t.sale_qty ELSE 0 END) AS total_qty_y1_ytd
    FROM ads.ads_ipd_ipm_aowei_wd t
    CROSS JOIN time_params p
    WHERE t.wm_type = '月'
      AND SUBSTRING(t.dt_wmcode,1,4) >= CAST(p.y3_year AS VARCHAR)
    GROUP BY t.business_unit, t.product_mid_class, t.product_small_class,
             t.category_segment, t.o2o_type
),

-- 关联分母
with_share AS (
    SELECT
        ba.*,
        mt.total_amt_y3, mt.total_qty_y3,
        mt.total_amt_y2, mt.total_qty_y2,
        mt.total_amt_y1, mt.total_qty_y1,
        mt.total_amt_curr, mt.total_qty_curr,
        mt.total_amt_y1_ytd, mt.total_qty_y1_ytd
    FROM brand_agg ba
    LEFT JOIN market_total mt
        ON ba.business_unit = mt.business_unit
        AND ba.product_mid_class = mt.product_mid_class
        AND ba.product_small_class = mt.product_small_class
        AND ba.category_segment = mt.category_segment
        AND ba.o2o_type = mt.o2o_type
)

-- 指标1：总销额
SELECT
    business_unit,                                       -- 事业部
    product_mid_class,                                   -- 产品中类
    product_small_class,                                 -- 产品小类
    category_segment,                                    -- 品类细分
    o2o_type,                                            -- 线上线下
    stat_brand,                                          -- 统计品牌
    '总销额'                       AS metric_name,       -- 指标名称
    CAST(amt_y3 AS VARCHAR(50))    AS val_y3,            -- 3年前总销额
    CAST(amt_y2 AS VARCHAR(50))    AS val_y2,            -- 2年前总销额
    CAST(amt_y1 AS VARCHAR(50))    AS val_y1,            -- 1年前总销额
    CAST(amt_curr AS VARCHAR(50))  AS val_curr,          -- 当年T总销额
    CAST(amt_y1_ytd AS VARCHAR(50)) AS val_y1_ytd,       -- 去年同期总销额
    NOW()                          AS load_dt            -- ETL加载日期
FROM with_share
UNION ALL
-- 指标2：总销量
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    o2o_type, stat_brand, '总销量',
    CAST(qty_y3 AS VARCHAR(50)), CAST(qty_y2 AS VARCHAR(50)),
    CAST(qty_y1 AS VARCHAR(50)), CAST(qty_curr AS VARCHAR(50)),
    CAST(qty_y1_ytd AS VARCHAR(50)), NOW()
FROM with_share
UNION ALL
-- 指标3：产品均价
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    o2o_type, stat_brand, '产品均价',
    CAST(CASE WHEN qty_y3>0 THEN amt_y3/qty_y3 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_y2>0 THEN amt_y2/qty_y2 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_y1>0 THEN amt_y1/qty_y1 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_curr>0 THEN amt_curr/qty_curr ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_y1_ytd>0 THEN amt_y1_ytd/qty_y1_ytd ELSE NULL END AS VARCHAR(50)),
    NOW()
FROM with_share
UNION ALL
-- 指标4：额占有率
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    o2o_type, stat_brand, '额占有率',
    CAST(CASE WHEN total_amt_y3>0 THEN amt_y3/total_amt_y3 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_y2>0 THEN amt_y2/total_amt_y2 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_y1>0 THEN amt_y1/total_amt_y1 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_curr>0 THEN amt_curr/total_amt_curr ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_y1_ytd>0 THEN amt_y1_ytd/total_amt_y1_ytd ELSE NULL END AS VARCHAR(50)),
    NOW()
FROM with_share
UNION ALL
-- 指标5：量占有率
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    o2o_type, stat_brand, '量占有率',
    CAST(CASE WHEN total_qty_y3>0 THEN qty_y3/total_qty_y3 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_y2>0 THEN qty_y2/total_qty_y2 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_y1>0 THEN qty_y1/total_qty_y1 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_curr>0 THEN qty_curr/total_qty_curr ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_y1_ytd>0 THEN qty_y1_ytd/total_qty_y1_ytd ELSE NULL END AS VARCHAR(50)),
    NOW()
FROM with_share
;
