/*
 * 脚本名称: ads_aowei_industry_channel.sql
 * 功能描述: 表1-1 行业分渠道数据（全市场，指标行格式）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-08
 * 修改记录:
 *   2026-07-08 [Kiro] 初始创建
 * 依赖关系:
 *   输入: ads.ads_ipd_ipm_aowei_wd
 *   输出: ads.ads_ipd_ipm_aowei_industry_channel_dd
 * 业务规则:
 *   1. 全市场数据（不限品牌），只取月维度
 *   2. 按事业部+产品中类+产品小类+品类细分+渠道+年度聚合
 *   3. 生成"总体"虚拟维度行（线上+线下合计）
 *   4. 占有率：线上(线下)销额(量)/总体销额(量)，总体行=NULL
 *   5. 转为指标行格式（总销额/总销量/产品均价/额占有率/量占有率）
 */

truncate table ads.ads_ipd_ipm_aowei_industry_channel_dd;

INSERT INTO ads.ads_ipd_ipm_aowei_industry_channel_dd (
    business_unit,       -- 事业部
    product_mid_class,   -- 产品中类
    product_small_class, -- 产品小类
    category_segment,    -- 品类细分
    channel_type_agg,    -- 统计渠道（总体/线上/线下）
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

-- 按渠道聚合（线上/线下各一行）
channel_agg AS (
    SELECT
        t.business_unit,
        t.product_mid_class,
        t.product_small_class,
        t.category_segment,
        t.o2o_type AS channel_type_agg,
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
    GROUP BY t.business_unit, t.product_mid_class, t.product_small_class,
             t.category_segment, t.o2o_type
),

-- 生成总体行（线上+线下合计）
total_agg AS (
    SELECT
        business_unit,
        product_mid_class,
        product_small_class,
        category_segment,
        '总体' AS channel_type_agg,
        SUM(amt_y3) AS amt_y3, SUM(qty_y3) AS qty_y3,
        SUM(amt_y2) AS amt_y2, SUM(qty_y2) AS qty_y2,
        SUM(amt_y1) AS amt_y1, SUM(qty_y1) AS qty_y1,
        SUM(amt_curr) AS amt_curr, SUM(qty_curr) AS qty_curr,
        SUM(amt_y1_ytd) AS amt_y1_ytd, SUM(qty_y1_ytd) AS qty_y1_ytd
    FROM channel_agg
    GROUP BY business_unit, product_mid_class, product_small_class, category_segment
),

-- 合并：线上/线下 + 总体
all_channels AS (
    SELECT * FROM channel_agg
    UNION ALL
    SELECT * FROM total_agg
),

-- 关联总体行用于计算占有率分母
with_share AS (
    SELECT
        ac.*,
        ta.amt_y3 AS total_amt_y3, ta.qty_y3 AS total_qty_y3,
        ta.amt_y2 AS total_amt_y2, ta.qty_y2 AS total_qty_y2,
        ta.amt_y1 AS total_amt_y1, ta.qty_y1 AS total_qty_y1,
        ta.amt_curr AS total_amt_curr, ta.qty_curr AS total_qty_curr,
        ta.amt_y1_ytd AS total_amt_y1_ytd, ta.qty_y1_ytd AS total_qty_y1_ytd
    FROM all_channels ac
    LEFT JOIN total_agg ta
        ON ac.business_unit = ta.business_unit
        AND ac.product_mid_class = ta.product_mid_class
        AND ac.product_small_class = ta.product_small_class
        AND ac.category_segment = ta.category_segment
)

-- 指标1：总销额
SELECT
    business_unit,                                  -- 事业部
    product_mid_class,                              -- 产品中类
    product_small_class,                            -- 产品小类
    category_segment,                               -- 品类细分
    channel_type_agg,                               -- 统计渠道
    '总销额'                  AS metric_name,       -- 指标名称
    CAST(amt_y3 AS VARCHAR(50))    AS val_y3,       -- 3年前总销额
    CAST(amt_y2 AS VARCHAR(50))    AS val_y2,       -- 2年前总销额
    CAST(amt_y1 AS VARCHAR(50))    AS val_y1,       -- 1年前总销额
    CAST(amt_curr AS VARCHAR(50))  AS val_curr,     -- 当年T总销额
    CAST(amt_y1_ytd AS VARCHAR(50)) AS val_y1_ytd,  -- 去年同期总销额
    NOW()                          AS load_dt       -- ETL加载日期
FROM with_share
UNION ALL
-- 指标2：总销量
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    channel_type_agg,
    '总销量'                  AS metric_name,
    CAST(qty_y3 AS VARCHAR(50)),    CAST(qty_y2 AS VARCHAR(50)),
    CAST(qty_y1 AS VARCHAR(50)),    CAST(qty_curr AS VARCHAR(50)),
    CAST(qty_y1_ytd AS VARCHAR(50)), NOW()
FROM with_share
UNION ALL
-- 指标3：产品均价
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    channel_type_agg,
    '产品均价'                AS metric_name,
    CAST(CASE WHEN qty_y3 > 0 THEN amt_y3/qty_y3 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_y2 > 0 THEN amt_y2/qty_y2 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_y1 > 0 THEN amt_y1/qty_y1 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_curr > 0 THEN amt_curr/qty_curr ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN qty_y1_ytd > 0 THEN amt_y1_ytd/qty_y1_ytd ELSE NULL END AS VARCHAR(50)),
    NOW()
FROM with_share
UNION ALL
-- 指标4：额占有率（总体行不输出）
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    channel_type_agg,
    '额占有率'                AS metric_name,
    CAST(CASE WHEN total_amt_y3 > 0 THEN amt_y3/total_amt_y3 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_y2 > 0 THEN amt_y2/total_amt_y2 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_y1 > 0 THEN amt_y1/total_amt_y1 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_curr > 0 THEN amt_curr/total_amt_curr ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_amt_y1_ytd > 0 THEN amt_y1_ytd/total_amt_y1_ytd ELSE NULL END AS VARCHAR(50)),
    NOW()
FROM with_share
WHERE channel_type_agg != '总体'
UNION ALL
-- 指标5：量占有率（总体行不输出）
SELECT
    business_unit, product_mid_class, product_small_class, category_segment,
    channel_type_agg,
    '量占有率'                AS metric_name,
    CAST(CASE WHEN total_qty_y3 > 0 THEN qty_y3/total_qty_y3 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_y2 > 0 THEN qty_y2/total_qty_y2 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_y1 > 0 THEN qty_y1/total_qty_y1 ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_curr > 0 THEN qty_curr/total_qty_curr ELSE NULL END AS VARCHAR(50)),
    CAST(CASE WHEN total_qty_y1_ytd > 0 THEN qty_y1_ytd/total_qty_y1_ytd ELSE NULL END AS VARCHAR(50)),
    NOW()
FROM with_share
WHERE channel_type_agg != '总体'
;
