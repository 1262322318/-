/*
 * 脚本名称: ads_aowei_model_price_spec.sql
 * 功能描述: 表2-1 各型号均价及价格段（筛选品牌，指标行格式）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-08
 * 修改记录:
 *   2026-07-08 [Kiro] 初始创建
 * 依赖关系:
 *   输入: ads.ads_ipd_ipm_aowei_wd, dim.dim_ipd_ipm_aw_price_segment_dd,
 *         dim.dim_ipd_ipm_aw_spec_segment_dd
 *   输出: ads.ads_ipd_ipm_aowei_model_price_spec_dd
 * 业务规则:
 *   1. 只取月维度数据（wm_type='月'）
 *   2. 只展示筛选品牌（小天鹅/三星允许与系列重复计数）
 *   3. 价格段按年度均价匹配dim表（左闭右开）
 *   4. 规格段：空调按字面值匹配，其他品类按数值区间匹配
 *   5. 转为指标行格式（销额/销量/产品均价/所属价格段/所属规格段）
 */

truncate table ads.ads_ipd_ipm_aowei_model_price_spec_dd;

INSERT INTO ads.ads_ipd_ipm_aowei_model_price_spec_dd (
    business_unit,       -- 事业部
    prdct_line_name,     -- 品线名称
    product_mid_class,   -- 产品中类
    product_small_class, -- 产品小类
    category_segment,    -- 品类细分
    o2o_type,            -- 线上线下
    stat_brand,          -- 统计品牌
    prdct_model,         -- 型号名称
    metric_name,         -- 指标名称
    val_y3,              -- 3年前值
    val_y2,              -- 2年前值
    val_y1,              -- 1年前值
    val_curr,            -- 当年T值
    val_y1_ytd,          -- 去年同期值
    load_dt              -- ETL加载日期
)

WITH
-- 时间参数计算
time_params AS (
    SELECT
        YEAR('${GP_START_DT}') AS curr_year,
        YEAR('${GP_START_DT}') - 1 AS y1_year,
        YEAR('${GP_START_DT}') - 2 AS y2_year,
        YEAR('${GP_START_DT}') - 3 AS y3_year,
        DATE_FORMAT('${GP_START_DT}', '%m') AS curr_month
),

-- 品牌映射（UNION ALL，允许一条数据生成多个stat_brand行，小天鹅/三星可与系列重复计数）
brand_mapped AS (
    -- 空气/冰冷/洗护/厨电：5大系列
    SELECT t.*, t.brand_series AS stat_brand
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit IN ('空气','冰冷','洗护','厨电')
      AND t.brand_series IN ('海信系列','海尔系列','美的系列','TCL系列','小米系列')

    UNION ALL

    -- 显示：4大系列
    SELECT t.*, t.brand_series AS stat_brand
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '显示'
      AND t.brand_series IN ('海信系列','TCL系列','小米系列','创维系列')

    UNION ALL

    -- 小天鹅独立维度（洗护，允许与系列重复）
    SELECT t.*, '小天鹅' AS stat_brand
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '洗护'
      AND t.sub_brand_name = '小天鹅'

    UNION ALL

    -- 三星独立维度（显示，允许与系列重复）
    SELECT t.*, '三星' AS stat_brand
    FROM ads.ads_ipd_ipm_aowei_wd t
    WHERE t.wm_type = '月'
      AND t.business_unit = '显示'
      AND t.brand_name = '三星'
),

-- 按维度+型号+年度聚合
base_agg AS (
    SELECT
        b.business_unit,
        b.prdct_line_name,
        b.product_mid_class,
        b.product_small_class,
        b.category_segment,
        b.o2o_type,
        b.stat_brand,
        b.prdct_model,
        b.core_spec,
        -- 3年前
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y3_year AS VARCHAR)
            THEN b.sale_amt ELSE 0 END) AS sale_amt_y3,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y3_year AS VARCHAR)
            THEN b.sale_qty ELSE 0 END) AS sale_qty_y3,
        -- 2年前
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y2_year AS VARCHAR)
            THEN b.sale_amt ELSE 0 END) AS sale_amt_y2,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y2_year AS VARCHAR)
            THEN b.sale_qty ELSE 0 END) AS sale_qty_y2,
        -- 1年前
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y1_year AS VARCHAR)
            THEN b.sale_amt ELSE 0 END) AS sale_amt_y1,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y1_year AS VARCHAR)
            THEN b.sale_qty ELSE 0 END) AS sale_qty_y1,
        -- 当年T
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.curr_year AS VARCHAR)
            THEN b.sale_amt ELSE 0 END) AS sale_amt_curr,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.curr_year AS VARCHAR)
            THEN b.sale_qty ELSE 0 END) AS sale_qty_curr,
        -- 去年同期（去年1月~去年同月）
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(b.dt_wmcode, 5, 2) <= p.curr_month
            THEN b.sale_amt ELSE 0 END) AS sale_amt_y1_ytd,
        SUM(CASE WHEN SUBSTRING(b.dt_wmcode, 1, 4) = CAST(p.y1_year AS VARCHAR)
                  AND SUBSTRING(b.dt_wmcode, 5, 2) <= p.curr_month
            THEN b.sale_qty ELSE 0 END) AS sale_qty_y1_ytd
    FROM brand_mapped b
    CROSS JOIN time_params p
    WHERE SUBSTRING(b.dt_wmcode, 1, 4) >= CAST(p.y3_year AS VARCHAR)
    GROUP BY
        b.business_unit, b.prdct_line_name, b.product_mid_class,
        b.product_small_class, b.category_segment, b.o2o_type,
        b.stat_brand, b.prdct_model, b.core_spec
),

-- 计算年度均价 + 匹配价格段（各年度独立JOIN）
with_price AS (
    SELECT
        a.*,
        -- 年度均价
        CASE WHEN a.sale_qty_y3 > 0 THEN a.sale_amt_y3 / a.sale_qty_y3 ELSE NULL END AS avg_price_y3,
        CASE WHEN a.sale_qty_y2 > 0 THEN a.sale_amt_y2 / a.sale_qty_y2 ELSE NULL END AS avg_price_y2,
        CASE WHEN a.sale_qty_y1 > 0 THEN a.sale_amt_y1 / a.sale_qty_y1 ELSE NULL END AS avg_price_y1,
        CASE WHEN a.sale_qty_curr > 0 THEN a.sale_amt_curr / a.sale_qty_curr ELSE NULL END AS avg_price_curr,
        CASE WHEN a.sale_qty_y1_ytd > 0 THEN a.sale_amt_y1_ytd / a.sale_qty_y1_ytd ELSE NULL END AS avg_price_y1_ytd,
        -- 价格段匹配
        ps3.price_segment AS price_seg_y3,
        ps2.price_segment AS price_seg_y2,
        ps1.price_segment AS price_seg_y1,
        psc.price_segment AS price_seg_curr,
        psy.price_segment AS price_seg_y1_ytd
    FROM base_agg a
    -- 3年前价格段
    LEFT JOIN dim.dim_ipd_ipm_aw_price_segment_dd ps3
        ON a.prdct_line_name = ps3.prdct_line_name
        AND (a.sale_amt_y3 / NULLIF(a.sale_qty_y3, 0)) >= ps3.min_price
        AND (a.sale_amt_y3 / NULLIF(a.sale_qty_y3, 0)) < ps3.max_price
    -- 2年前价格段
    LEFT JOIN dim.dim_ipd_ipm_aw_price_segment_dd ps2
        ON a.prdct_line_name = ps2.prdct_line_name
        AND (a.sale_amt_y2 / NULLIF(a.sale_qty_y2, 0)) >= ps2.min_price
        AND (a.sale_amt_y2 / NULLIF(a.sale_qty_y2, 0)) < ps2.max_price
    -- 1年前价格段
    LEFT JOIN dim.dim_ipd_ipm_aw_price_segment_dd ps1
        ON a.prdct_line_name = ps1.prdct_line_name
        AND (a.sale_amt_y1 / NULLIF(a.sale_qty_y1, 0)) >= ps1.min_price
        AND (a.sale_amt_y1 / NULLIF(a.sale_qty_y1, 0)) < ps1.max_price
    -- 当年T价格段
    LEFT JOIN dim.dim_ipd_ipm_aw_price_segment_dd psc
        ON a.prdct_line_name = psc.prdct_line_name
        AND (a.sale_amt_curr / NULLIF(a.sale_qty_curr, 0)) >= psc.min_price
        AND (a.sale_amt_curr / NULLIF(a.sale_qty_curr, 0)) < psc.max_price
    -- 去年同期价格段
    LEFT JOIN dim.dim_ipd_ipm_aw_price_segment_dd psy
        ON a.prdct_line_name = psy.prdct_line_name
        AND (a.sale_amt_y1_ytd / NULLIF(a.sale_qty_y1_ytd, 0)) >= psy.min_price
        AND (a.sale_amt_y1_ytd / NULLIF(a.sale_qty_y1_ytd, 0)) < psy.max_price
),

-- 匹配规格段
with_all AS (
    SELECT
        wp.*,
        COALESCE(ss.spec_segment, NULL) AS spec_seg
    FROM with_price wp
    -- 规格段：空调按字面值匹配，其他按数值区间
    LEFT JOIN dim.dim_ipd_ipm_aw_spec_segment_dd ss
        ON wp.prdct_line_name = ss.prdct_line_name
        AND (
            (wp.prdct_line_name = '空调' AND wp.core_spec = ss.spec_segment)
            OR
            (wp.prdct_line_name != '空调'
             AND ss.min_spec IS NOT NULL
             AND CAST(wp.core_spec AS DECIMALV3(20,4)) >= ss.min_spec
             AND CAST(wp.core_spec AS DECIMALV3(20,4)) <= ss.max_spec)
        )
)

-- ============================================================
-- 转为指标行格式：5个指标各一行
-- ============================================================

-- 指标1：销额
SELECT
    business_unit,                                   -- 事业部
    prdct_line_name,                                 -- 品线名称
    product_mid_class,                               -- 产品中类
    product_small_class,                             -- 产品小类
    category_segment,                                -- 品类细分
    o2o_type,                                        -- 线上线下
    stat_brand,                                      -- 统计品牌
    prdct_model,                                     -- 型号名称
    '销额'                         AS metric_name,   -- 指标名称
    CAST(sale_amt_y3 AS VARCHAR(50))    AS val_y3,   -- 3年前销额
    CAST(sale_amt_y2 AS VARCHAR(50))    AS val_y2,   -- 2年前销额
    CAST(sale_amt_y1 AS VARCHAR(50))    AS val_y1,   -- 1年前销额
    CAST(sale_amt_curr AS VARCHAR(50))  AS val_curr, -- 当年T销额
    CAST(sale_amt_y1_ytd AS VARCHAR(50)) AS val_y1_ytd, -- 去年同期销额
    NOW()                              AS load_dt    -- ETL加载日期
FROM with_all

UNION ALL

-- 指标2：销量
SELECT
    business_unit,                                   -- 事业部
    prdct_line_name,                                 -- 品线名称
    product_mid_class,                               -- 产品中类
    product_small_class,                             -- 产品小类
    category_segment,                                -- 品类细分
    o2o_type,                                        -- 线上线下
    stat_brand,                                      -- 统计品牌
    prdct_model,                                     -- 型号名称
    '销量'                         AS metric_name,   -- 指标名称
    CAST(sale_qty_y3 AS VARCHAR(50))    AS val_y3,   -- 3年前销量
    CAST(sale_qty_y2 AS VARCHAR(50))    AS val_y2,   -- 2年前销量
    CAST(sale_qty_y1 AS VARCHAR(50))    AS val_y1,   -- 1年前销量
    CAST(sale_qty_curr AS VARCHAR(50))  AS val_curr, -- 当年T销量
    CAST(sale_qty_y1_ytd AS VARCHAR(50)) AS val_y1_ytd, -- 去年同期销量
    NOW()                              AS load_dt    -- ETL加载日期
FROM with_all

UNION ALL

-- 指标3：产品均价
SELECT
    business_unit,                                   -- 事业部
    prdct_line_name,                                 -- 品线名称
    product_mid_class,                               -- 产品中类
    product_small_class,                             -- 产品小类
    category_segment,                                -- 品类细分
    o2o_type,                                        -- 线上线下
    stat_brand,                                      -- 统计品牌
    prdct_model,                                     -- 型号名称
    '产品均价'                     AS metric_name,   -- 指标名称
    CAST(avg_price_y3 AS VARCHAR(50))   AS val_y3,   -- 3年前均价
    CAST(avg_price_y2 AS VARCHAR(50))   AS val_y2,   -- 2年前均价
    CAST(avg_price_y1 AS VARCHAR(50))   AS val_y1,   -- 1年前均价
    CAST(avg_price_curr AS VARCHAR(50)) AS val_curr, -- 当年T均价
    CAST(avg_price_y1_ytd AS VARCHAR(50)) AS val_y1_ytd, -- 去年同期均价
    NOW()                              AS load_dt    -- ETL加载日期
FROM with_all

UNION ALL

-- 指标4：所属价格段
SELECT
    business_unit,                                   -- 事业部
    prdct_line_name,                                 -- 品线名称
    product_mid_class,                               -- 产品中类
    product_small_class,                             -- 产品小类
    category_segment,                                -- 品类细分
    o2o_type,                                        -- 线上线下
    stat_brand,                                      -- 统计品牌
    prdct_model,                                     -- 型号名称
    '所属价格段'                   AS metric_name,   -- 指标名称
    price_seg_y3                       AS val_y3,    -- 3年前所属价格段
    price_seg_y2                       AS val_y2,    -- 2年前所属价格段
    price_seg_y1                       AS val_y1,    -- 1年前所属价格段
    price_seg_curr                     AS val_curr,  -- 当年T所属价格段
    price_seg_y1_ytd                   AS val_y1_ytd,-- 去年同期所属价格段
    NOW()                              AS load_dt    -- ETL加载日期
FROM with_all

UNION ALL

-- 指标5：所属规格段（不随年度变化，5列值相同）
SELECT
    business_unit,                                   -- 事业部
    prdct_line_name,                                 -- 品线名称
    product_mid_class,                               -- 产品中类
    product_small_class,                             -- 产品小类
    category_segment,                                -- 品类细分
    o2o_type,                                        -- 线上线下
    stat_brand,                                      -- 统计品牌
    prdct_model,                                     -- 型号名称
    '所属规格段'                   AS metric_name,   -- 指标名称
    spec_seg                           AS val_y3,    -- 所属规格段
    spec_seg                           AS val_y2,    -- 所属规格段
    spec_seg                           AS val_y1,    -- 所属规格段
    spec_seg                           AS val_curr,  -- 所属规格段
    spec_seg                           AS val_y1_ytd,-- 所属规格段
    NOW()                              AS load_dt    -- ETL加载日期
FROM with_all
;
