/*
 * 脚本名称: ads_ipd_ipm_aowei_industry_brand_dd.sql
 * 功能描述: 表A 行业总体分析（单元格拼接格式：额占有率+产品均价）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-21
 * 修改记录:
 *   2026-07-21 [Kiro] 初始创建（013扩增3表 - 表A）
 * 依赖关系:
 *   输入: ads.ads_ipd_ipm_aowei_wd
 *   输出: ads.ads_ipd_ipm_aowei_industry_brand_dd
 * 业务规则:
 *   1. 只取月维度数据（wm_type='月'），时间范围：当年往前推3年
 *   2. 渠道维度含"总体"虚拟行（总体=线上+线下合计）
 *   3. "总体"渠道行占有率**输出具体数值**（与013表1-1"设NULL"规则不同）
 *   4. 品牌筛选沿用013规则2.3（5大系列 + 洗护小天鹅 + 显示三星）
 *   5. 单元格拼接：val字段=CONCAT(占有率2位小数+%, '，', 均价2位小数)
 *   6. 空值统一：`—，—`
 */

TRUNCATE TABLE ads.ads_ipd_ipm_aowei_industry_brand_dd;

INSERT INTO ads.ads_ipd_ipm_aowei_industry_brand_dd (
    business_unit,       -- 事业部
    product_mid_class,   -- 产品中类
    product_small_class, -- 产品小类
    category_segment,    -- 品类细分
    channel_type_agg,    -- 统计渠道（总体/线上/线下）
    stat_brand,          -- 统计品牌（含小天鹅/三星）
    val_y3,              -- 3年前【额占有率，产品均价】拼接值
    val_y2,              -- 2年前拼接值
    val_y1,              -- 1年前拼接值
    val_curr,            -- 当年T拼接值
    val_y1_ytd,          -- 去年同期拼接值
    load_dt              -- ETL加载日期
)

WITH
-- 时间参数
time_params AS (
    SELECT
        YEAR('${GP_START_DT}') AS curr_year,
        YEAR('${GP_START_DT}') - 1 AS y1_year,
        YEAR('${GP_START_DT}') - 2 AS y2_year,
        YEAR('${GP_START_DT}') - 3 AS y3_year,
        DATE_FORMAT('${GP_START_DT}', '%m') AS curr_month
),

-- 渠道虚拟维度（总体/线上/线下）
weidu_channel AS (
    SELECT '总体' AS channel_type_agg UNION ALL
    SELECT '线上' AS channel_type_agg UNION ALL
    SELECT '线下' AS channel_type_agg
),

-- 品牌筛选（UNION ALL 各事业部，小天鹅/三星允许与系列重复计数）
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

    -- 小天鹅独立维度（洗护）
    SELECT t.business_unit, t.product_mid_class, t.product_small_class,
           t.category_segment, t.o2o_type, '小天鹅' AS stat_brand,
           t.dt_wmcode, t.sale_amt, t.sale_qty
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '洗护'
      AND t.sub_brand_name = '小天鹅'

    UNION ALL

    -- 三星独立维度（显示）
    SELECT t.business_unit, t.product_mid_class, t.product_small_class,
           t.category_segment, t.o2o_type, '三星' AS stat_brand,
           t.dt_wmcode, t.sale_amt, t.sale_qty
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '显示'
      AND t.brand_name = '三星'
),

-- 承接前段CTE：time_params, weidu_channel, brand_mapped
-- 品牌×渠道聚合（用CROSS JOIN虚拟渠道 + CASE WHEN 分渠道求和）
brand_agg AS (
    SELECT
        b.business_unit,
        b.product_mid_class,
        b.product_small_class,
        b.category_segment,
        w.channel_type_agg,
        b.stat_brand,
        -- 3年前
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_amt ELSE 0 END) AS amt_y3,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_qty ELSE 0 END) AS qty_y3,
        -- 2年前
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_amt ELSE 0 END) AS amt_y2,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_qty ELSE 0 END) AS qty_y2,
        -- 1年前
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_amt ELSE 0 END) AS amt_y1,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_qty ELSE 0 END) AS qty_y1,
        -- 当年T
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_amt ELSE 0 END) AS amt_curr,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_qty ELSE 0 END) AS qty_curr,
        -- 去年同期
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(b.dt_wmcode,5,2) <= p.curr_month
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_amt ELSE 0 END) AS amt_y1_ytd,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(b.dt_wmcode,5,2) <= p.curr_month
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = b.o2o_type)
                 THEN b.sale_qty ELSE 0 END) AS qty_y1_ytd
    FROM brand_mapped b
    CROSS JOIN weidu_channel w
    CROSS JOIN time_params p
    WHERE SUBSTRING(b.dt_wmcode,1,4) >= CAST(p.y3_year AS VARCHAR)
    GROUP BY b.business_unit, b.product_mid_class, b.product_small_class,
             b.category_segment, w.channel_type_agg, b.stat_brand
),

-- 全市场分母（同事业部+中类+小类+品类细分+渠道 下的全市场销额/销量，不限品牌）
market_total AS (
    SELECT
        t.business_unit,
        t.product_mid_class,
        t.product_small_class,
        t.category_segment,
        w.channel_type_agg,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y3_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = t.o2o_type)
                 THEN t.sale_amt ELSE 0 END) AS total_amt_y3,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y2_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = t.o2o_type)
                 THEN t.sale_amt ELSE 0 END) AS total_amt_y2,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = t.o2o_type)
                 THEN t.sale_amt ELSE 0 END) AS total_amt_y1,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.curr_year AS VARCHAR)
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = t.o2o_type)
                 THEN t.sale_amt ELSE 0 END) AS total_amt_curr,
        SUM(CASE WHEN SUBSTRING(t.dt_wmcode,1,4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(t.dt_wmcode,5,2) <= p.curr_month
                  AND (w.channel_type_agg = '总体' OR w.channel_type_agg = t.o2o_type)
                 THEN t.sale_amt ELSE 0 END) AS total_amt_y1_ytd
    FROM ads.ads_ipd_ipm_aowei_wd t
    CROSS JOIN weidu_channel w
    CROSS JOIN time_params p
    WHERE t.wm_type = '月'
      AND SUBSTRING(t.dt_wmcode,1,4) >= CAST(p.y3_year AS VARCHAR)
    GROUP BY t.business_unit, t.product_mid_class, t.product_small_class,
             t.category_segment, w.channel_type_agg
),

-- 关联分母
with_share AS (
    SELECT
        ba.*,
        mt.total_amt_y3, mt.total_amt_y2, mt.total_amt_y1,
        mt.total_amt_curr, mt.total_amt_y1_ytd
    FROM brand_agg ba
    LEFT JOIN market_total mt
      ON  ba.business_unit       <=> mt.business_unit
      AND ba.product_mid_class   <=> mt.product_mid_class
      AND ba.product_small_class <=> mt.product_small_class
      AND ba.category_segment    <=> mt.category_segment
      AND ba.channel_type_agg    <=> mt.channel_type_agg
)

-- 最终 SELECT：单元格拼接输出（每维度组合1行）
SELECT
    business_unit,                                                   -- 事业部
    product_mid_class,                                               -- 产品中类
    product_small_class,                                             -- 产品小类
    category_segment,                                                -- 品类细分
    channel_type_agg,                                                -- 统计渠道
    stat_brand,                                                      -- 统计品牌
    -- 3年前【额占有率，产品均价】拼接
    CASE
        WHEN amt_y3 IS NULL OR qty_y3 IS NULL OR qty_y3 = 0
          OR total_amt_y3 IS NULL OR total_amt_y3 = 0
        THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(amt_y3 / total_amt_y3 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(amt_y3 / qty_y3, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y3,
    -- 2年前
    CASE
        WHEN amt_y2 IS NULL OR qty_y2 IS NULL OR qty_y2 = 0
          OR total_amt_y2 IS NULL OR total_amt_y2 = 0
        THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(amt_y2 / total_amt_y2 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(amt_y2 / qty_y2, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y2,
    -- 1年前
    CASE
        WHEN amt_y1 IS NULL OR qty_y1 IS NULL OR qty_y1 = 0
          OR total_amt_y1 IS NULL OR total_amt_y1 = 0
        THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(amt_y1 / total_amt_y1 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(amt_y1 / qty_y1, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1,
    -- 当年T
    CASE
        WHEN amt_curr IS NULL OR qty_curr IS NULL OR qty_curr = 0
          OR total_amt_curr IS NULL OR total_amt_curr = 0
        THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(amt_curr / total_amt_curr * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(amt_curr / qty_curr, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_curr,
    -- 去年同期
    CASE
        WHEN amt_y1_ytd IS NULL OR qty_y1_ytd IS NULL OR qty_y1_ytd = 0
          OR total_amt_y1_ytd IS NULL OR total_amt_y1_ytd = 0
        THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(amt_y1_ytd / total_amt_y1_ytd * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(amt_y1_ytd / qty_y1_ytd, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1_ytd,
    NOW()                                                            AS load_dt
FROM with_share
;
