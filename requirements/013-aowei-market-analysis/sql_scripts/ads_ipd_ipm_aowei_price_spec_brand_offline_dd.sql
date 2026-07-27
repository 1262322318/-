/*
 * 脚本名称: ads_ipd_ipm_aowei_price_spec_brand_offline_dd.sql
 * 功能描述: 表C 分价格段分品牌市场分析-线下（单元格拼接格式：额占有率+产品均价）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-21
 * 修改记录:
 *   2026-07-21 [Kiro] 初始创建（013扩增3表 - 表C）
 *   2026-07-23 [Kiro] 重写占有率逻辑：
 *     - 新增"总体"价格段行（品牌市占率+行业结构占比）
 *     - 具体价格段×总体行改为层级式占比（分母=同规格段合计，非固定100%）
 *     - 从表2-5/2-4取原始销额销量自行计算占有率，不再直接取占有率字段
 * 依赖关系:
 *   输入: ads.ads_ipd_ipm_aowei_price_spec_brand_dd（表2-5，筛选品牌销额/销量）
 *         ads.ads_ipd_ipm_aowei_price_spec_dd（表2-4，全市场销额/销量）
 *   输出: ads.ads_ipd_ipm_aowei_price_spec_brand_offline_dd
 * 业务规则（4种行类型）:
 *   ① price_segment='总体' + stat_brand='总体'：行业额占比（分母=全市场大盘）+ 均价
 *   ② price_segment='总体' + stat_brand=筛选品牌：品牌市占率（分母=同规格段全市场）+ 均价
 *   ③ price_segment=具体值 + stat_brand='总体'：层级式结构占比（分母=同规格段合计）+ 均价
 *   ④ price_segment=具体值 + stat_brand=筛选品牌：品牌市占率（分母=同价格段×同规格段全市场）+ 均价
 *   单元格拼接：val = CONCAT(占有率2位小数+'%', '，', 均价2位小数)；空值='—，—'
 */

TRUNCATE TABLE ads.ads_ipd_ipm_aowei_price_spec_brand_offline_dd;

INSERT INTO ads.ads_ipd_ipm_aowei_price_spec_brand_offline_dd (
    business_unit,       -- 事业部
    prdct_line_name,     -- 品线名称
    product_mid_class,   -- 产品中类
    product_small_class, -- 产品小类
    category_segment,    -- 品类细分
    o2o_type,            -- 线上线下（固定=线下）
    price_segment,       -- 价格段（具体值 或 '总体'）
    spec_segment,        -- 规格段
    stat_brand,          -- 统计品牌（筛选品牌 或 '总体'）
    val_y3,              -- 3年前【额占有率，产品均价】拼接值
    val_y2,              -- 2年前拼接值
    val_y1,              -- 1年前拼接值
    val_curr,            -- 当年T拼接值
    val_y1_ytd,          -- 去年同期拼接值
    load_dt              -- ETL加载日期
)

WITH
-- CTE1: 从表2-5取筛选品牌的原始销额/销量（线下）
brand_raw AS (
    SELECT
        business_unit,
        prdct_line_name,
        product_mid_class,
        product_small_class,
        category_segment,
        o2o_type,
        price_segment,
        spec_segment,
        stat_brand,
        -- 销额
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y3 AS DECIMALV3(20,4)) END)     AS amt_y3,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y2 AS DECIMALV3(20,4)) END)     AS amt_y2,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y1 AS DECIMALV3(20,4)) END)     AS amt_y1,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_curr AS DECIMALV3(20,4)) END)   AS amt_curr,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y1_ytd AS DECIMALV3(20,4)) END) AS amt_y1_ytd,
        -- 销量
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y3 AS DECIMALV3(20,4)) END)     AS qty_y3,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y2 AS DECIMALV3(20,4)) END)     AS qty_y2,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y1 AS DECIMALV3(20,4)) END)     AS qty_y1,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_curr AS DECIMALV3(20,4)) END)   AS qty_curr,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y1_ytd AS DECIMALV3(20,4)) END) AS qty_y1_ytd
    FROM ads.ads_ipd_ipm_aowei_price_spec_brand_dd
    WHERE o2o_type = '线下'
      AND metric_name IN ('总销额', '总销量')
      AND price_segment IS NOT NULL
      AND spec_segment IS NOT NULL
    GROUP BY business_unit, prdct_line_name, product_mid_class, product_small_class,
             category_segment, o2o_type, price_segment, spec_segment, stat_brand
),

-- CTE2: 从表2-4取全市场的原始销额/销量（线下）
market_raw AS (
    SELECT
        business_unit,
        prdct_line_name,
        product_mid_class,
        product_small_class,
        category_segment,
        o2o_type,
        price_segment,
        spec_segment,
        -- 销额
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y3 AS DECIMALV3(20,4)) END)     AS amt_y3,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y2 AS DECIMALV3(20,4)) END)     AS amt_y2,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y1 AS DECIMALV3(20,4)) END)     AS amt_y1,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_curr AS DECIMALV3(20,4)) END)   AS amt_curr,
        MAX(CASE WHEN metric_name = '总销额' THEN CAST(val_y1_ytd AS DECIMALV3(20,4)) END) AS amt_y1_ytd,
        -- 销量
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y3 AS DECIMALV3(20,4)) END)     AS qty_y3,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y2 AS DECIMALV3(20,4)) END)     AS qty_y2,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y1 AS DECIMALV3(20,4)) END)     AS qty_y1,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_curr AS DECIMALV3(20,4)) END)   AS qty_curr,
        MAX(CASE WHEN metric_name = '总销量' THEN CAST(val_y1_ytd AS DECIMALV3(20,4)) END) AS qty_y1_ytd
    FROM ads.ads_ipd_ipm_aowei_price_spec_dd
    WHERE o2o_type = '线下'
      AND metric_name IN ('总销额', '总销量')
      AND price_segment IS NOT NULL
      AND spec_segment IS NOT NULL
    GROUP BY business_unit, prdct_line_name, product_mid_class, product_small_class,
             category_segment, o2o_type, price_segment, spec_segment
),

-- CTE3: 同规格段合计（SUM掉price_segment）— 作为①②③的分母/分子
spec_total AS (
    SELECT
        business_unit,
        prdct_line_name,
        product_mid_class,
        product_small_class,
        category_segment,
        o2o_type,
        spec_segment,
        SUM(amt_y3) AS amt_y3,       SUM(qty_y3) AS qty_y3,
        SUM(amt_y2) AS amt_y2,       SUM(qty_y2) AS qty_y2,
        SUM(amt_y1) AS amt_y1,       SUM(qty_y1) AS qty_y1,
        SUM(amt_curr) AS amt_curr,   SUM(qty_curr) AS qty_curr,
        SUM(amt_y1_ytd) AS amt_y1_ytd, SUM(qty_y1_ytd) AS qty_y1_ytd
    FROM market_raw
    GROUP BY business_unit, prdct_line_name, product_mid_class, product_small_class,
             category_segment, o2o_type, spec_segment
),

-- CTE4: 全市场大盘（SUM掉price_segment+spec_segment）— 作为①的分母
grand_total AS (
    SELECT
        business_unit,
        prdct_line_name,
        product_mid_class,
        product_small_class,
        category_segment,
        o2o_type,
        SUM(amt_y3) AS amt_y3,       SUM(qty_y3) AS qty_y3,
        SUM(amt_y2) AS amt_y2,       SUM(qty_y2) AS qty_y2,
        SUM(amt_y1) AS amt_y1,       SUM(qty_y1) AS qty_y1,
        SUM(amt_curr) AS amt_curr,   SUM(qty_curr) AS qty_curr,
        SUM(amt_y1_ytd) AS amt_y1_ytd, SUM(qty_y1_ytd) AS qty_y1_ytd
    FROM spec_total
    GROUP BY business_unit, prdct_line_name, product_mid_class, product_small_class,
             category_segment, o2o_type
),

-- CTE5: 品牌在同规格段的合计（SUM掉price_segment）— 作为②的分子+均价
brand_spec_total AS (
    SELECT
        business_unit,
        prdct_line_name,
        product_mid_class,
        product_small_class,
        category_segment,
        o2o_type,
        spec_segment,
        stat_brand,
        SUM(amt_y3) AS amt_y3,       SUM(qty_y3) AS qty_y3,
        SUM(amt_y2) AS amt_y2,       SUM(qty_y2) AS qty_y2,
        SUM(amt_y1) AS amt_y1,       SUM(qty_y1) AS qty_y1,
        SUM(amt_curr) AS amt_curr,   SUM(qty_curr) AS qty_curr,
        SUM(amt_y1_ytd) AS amt_y1_ytd, SUM(qty_y1_ytd) AS qty_y1_ytd
    FROM brand_raw
    GROUP BY business_unit, prdct_line_name, product_mid_class, product_small_class,
             category_segment, o2o_type, spec_segment, stat_brand
)


-- 承接第一段CTE：brand_raw, market_raw, spec_total, grand_total, brand_spec_total

-- =========== ④ 具体价格段 × 筛选品牌 ===========
-- 占有率 = 品牌销额 / 同规格段×同价格段全市场销额（候选2）
-- 均价 = 品牌销额 / 品牌销量
SELECT
    b.business_unit,                                                 -- 事业部
    b.prdct_line_name,                                               -- 品线名称
    b.product_mid_class,                                             -- 产品中类
    b.product_small_class,                                           -- 产品小类
    b.category_segment,                                              -- 品类细分
    b.o2o_type,                                                      -- 线上线下（固定=线下）
    b.price_segment,                                                 -- 价格段（具体值）
    b.spec_segment,                                                  -- 规格段
    b.stat_brand,                                                    -- 统计品牌（筛选品牌）
    -- val_y3
    CASE
        WHEN b.amt_y3 IS NULL OR m.amt_y3 IS NULL OR m.amt_y3 = 0 OR b.qty_y3 IS NULL OR b.qty_y3 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y3 / m.amt_y3 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y3 / b.qty_y3, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y3,
    -- val_y2
    CASE
        WHEN b.amt_y2 IS NULL OR m.amt_y2 IS NULL OR m.amt_y2 = 0 OR b.qty_y2 IS NULL OR b.qty_y2 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y2 / m.amt_y2 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y2 / b.qty_y2, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y2,
    -- val_y1
    CASE
        WHEN b.amt_y1 IS NULL OR m.amt_y1 IS NULL OR m.amt_y1 = 0 OR b.qty_y1 IS NULL OR b.qty_y1 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y1 / m.amt_y1 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y1 / b.qty_y1, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1,
    -- val_curr
    CASE
        WHEN b.amt_curr IS NULL OR m.amt_curr IS NULL OR m.amt_curr = 0 OR b.qty_curr IS NULL OR b.qty_curr = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_curr / m.amt_curr * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_curr / b.qty_curr, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_curr,
    -- val_y1_ytd
    CASE
        WHEN b.amt_y1_ytd IS NULL OR m.amt_y1_ytd IS NULL OR m.amt_y1_ytd = 0 OR b.qty_y1_ytd IS NULL OR b.qty_y1_ytd = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y1_ytd / m.amt_y1_ytd * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y1_ytd / b.qty_y1_ytd, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1_ytd,
    NOW() AS load_dt                                                 -- ETL加载日期
FROM brand_raw b
LEFT JOIN market_raw m
    ON b.business_unit <=> m.business_unit AND b.prdct_line_name <=> m.prdct_line_name
    AND b.product_mid_class <=> m.product_mid_class AND b.product_small_class <=> m.product_small_class
    AND b.category_segment <=> m.category_segment AND b.o2o_type <=> m.o2o_type
    AND b.price_segment <=> m.price_segment AND b.spec_segment <=> m.spec_segment

UNION ALL

-- =========== ③ 具体价格段 × 总体（层级式占比） ===========
-- 占有率 = 该价格段全市场销额 / 同规格段全市场合计销额
-- 均价 = 该价格段全市场销额 / 该价格段全市场销量
SELECT
    m.business_unit,                                                 -- 事业部
    m.prdct_line_name,                                               -- 品线名称
    m.product_mid_class,                                             -- 产品中类
    m.product_small_class,                                           -- 产品小类
    m.category_segment,                                              -- 品类细分
    m.o2o_type,                                                      -- 线上线下（固定=线下）
    m.price_segment,                                                 -- 价格段（具体值）
    m.spec_segment,                                                  -- 规格段
    '总体'                                                           AS stat_brand,   -- 总体品牌行
    -- val_y3
    CASE
        WHEN m.amt_y3 IS NULL OR s.amt_y3 IS NULL OR s.amt_y3 = 0 OR m.qty_y3 IS NULL OR m.qty_y3 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(m.amt_y3 / s.amt_y3 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(m.amt_y3 / m.qty_y3, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y3,
    -- val_y2
    CASE
        WHEN m.amt_y2 IS NULL OR s.amt_y2 IS NULL OR s.amt_y2 = 0 OR m.qty_y2 IS NULL OR m.qty_y2 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(m.amt_y2 / s.amt_y2 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(m.amt_y2 / m.qty_y2, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y2,
    -- val_y1
    CASE
        WHEN m.amt_y1 IS NULL OR s.amt_y1 IS NULL OR s.amt_y1 = 0 OR m.qty_y1 IS NULL OR m.qty_y1 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(m.amt_y1 / s.amt_y1 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(m.amt_y1 / m.qty_y1, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1,
    -- val_curr
    CASE
        WHEN m.amt_curr IS NULL OR s.amt_curr IS NULL OR s.amt_curr = 0 OR m.qty_curr IS NULL OR m.qty_curr = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(m.amt_curr / s.amt_curr * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(m.amt_curr / m.qty_curr, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_curr,
    -- val_y1_ytd
    CASE
        WHEN m.amt_y1_ytd IS NULL OR s.amt_y1_ytd IS NULL OR s.amt_y1_ytd = 0 OR m.qty_y1_ytd IS NULL OR m.qty_y1_ytd = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(m.amt_y1_ytd / s.amt_y1_ytd * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(m.amt_y1_ytd / m.qty_y1_ytd, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1_ytd,
    NOW() AS load_dt                                                 -- ETL加载日期
FROM market_raw m
LEFT JOIN spec_total s
    ON m.business_unit <=> s.business_unit AND m.prdct_line_name <=> s.prdct_line_name
    AND m.product_mid_class <=> s.product_mid_class AND m.product_small_class <=> s.product_small_class
    AND m.category_segment <=> s.category_segment AND m.o2o_type <=> s.o2o_type
    AND m.spec_segment <=> s.spec_segment

UNION ALL

-- =========== ② 总体价格段 × 筛选品牌 ===========
-- 占有率 = 品牌规格段合计销额 / 同规格段全市场合计销额
-- 均价 = 品牌规格段合计销额 / 品牌规格段合计销量
SELECT
    b.business_unit,                                                 -- 事业部
    b.prdct_line_name,                                               -- 品线名称
    b.product_mid_class,                                             -- 产品中类
    b.product_small_class,                                           -- 产品小类
    b.category_segment,                                              -- 品类细分
    b.o2o_type,                                                      -- 线上线下（固定=线下）
    '总体'                                                           AS price_segment, -- 总体价格段
    b.spec_segment,                                                  -- 规格段
    b.stat_brand,                                                    -- 统计品牌（筛选品牌）
    -- val_y3
    CASE
        WHEN b.amt_y3 IS NULL OR s.amt_y3 IS NULL OR s.amt_y3 = 0 OR b.qty_y3 IS NULL OR b.qty_y3 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y3 / s.amt_y3 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y3 / b.qty_y3, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y3,
    -- val_y2
    CASE
        WHEN b.amt_y2 IS NULL OR s.amt_y2 IS NULL OR s.amt_y2 = 0 OR b.qty_y2 IS NULL OR b.qty_y2 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y2 / s.amt_y2 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y2 / b.qty_y2, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y2,
    -- val_y1
    CASE
        WHEN b.amt_y1 IS NULL OR s.amt_y1 IS NULL OR s.amt_y1 = 0 OR b.qty_y1 IS NULL OR b.qty_y1 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y1 / s.amt_y1 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y1 / b.qty_y1, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1,
    -- val_curr
    CASE
        WHEN b.amt_curr IS NULL OR s.amt_curr IS NULL OR s.amt_curr = 0 OR b.qty_curr IS NULL OR b.qty_curr = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_curr / s.amt_curr * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_curr / b.qty_curr, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_curr,
    -- val_y1_ytd
    CASE
        WHEN b.amt_y1_ytd IS NULL OR s.amt_y1_ytd IS NULL OR s.amt_y1_ytd = 0 OR b.qty_y1_ytd IS NULL OR b.qty_y1_ytd = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(b.amt_y1_ytd / s.amt_y1_ytd * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(b.amt_y1_ytd / b.qty_y1_ytd, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1_ytd,
    NOW() AS load_dt                                                 -- ETL加载日期
FROM brand_spec_total b
LEFT JOIN spec_total s
    ON b.business_unit <=> s.business_unit AND b.prdct_line_name <=> s.prdct_line_name
    AND b.product_mid_class <=> s.product_mid_class AND b.product_small_class <=> s.product_small_class
    AND b.category_segment <=> s.category_segment AND b.o2o_type <=> s.o2o_type
    AND b.spec_segment <=> s.spec_segment

UNION ALL

-- =========== ① 总体价格段 × 总体（行业额占比） ===========
-- 占有率 = 该规格段全市场合计销额 / 全市场大盘销额
-- 均价 = 该规格段全市场合计销额 / 该规格段全市场合计销量
SELECT
    s.business_unit,                                                 -- 事业部
    s.prdct_line_name,                                               -- 品线名称
    s.product_mid_class,                                             -- 产品中类
    s.product_small_class,                                           -- 产品小类
    s.category_segment,                                              -- 品类细分
    s.o2o_type,                                                      -- 线上线下（固定=线下）
    '总体'                                                           AS price_segment, -- 总体价格段
    s.spec_segment,                                                  -- 规格段
    '总体'                                                           AS stat_brand,   -- 总体品牌行
    -- val_y3
    CASE
        WHEN s.amt_y3 IS NULL OR g.amt_y3 IS NULL OR g.amt_y3 = 0 OR s.qty_y3 IS NULL OR s.qty_y3 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(s.amt_y3 / g.amt_y3 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(s.amt_y3 / s.qty_y3, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y3,
    -- val_y2
    CASE
        WHEN s.amt_y2 IS NULL OR g.amt_y2 IS NULL OR g.amt_y2 = 0 OR s.qty_y2 IS NULL OR s.qty_y2 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(s.amt_y2 / g.amt_y2 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(s.amt_y2 / s.qty_y2, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y2,
    -- val_y1
    CASE
        WHEN s.amt_y1 IS NULL OR g.amt_y1 IS NULL OR g.amt_y1 = 0 OR s.qty_y1 IS NULL OR s.qty_y1 = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(s.amt_y1 / g.amt_y1 * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(s.amt_y1 / s.qty_y1, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1,
    -- val_curr
    CASE
        WHEN s.amt_curr IS NULL OR g.amt_curr IS NULL OR g.amt_curr = 0 OR s.qty_curr IS NULL OR s.qty_curr = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(s.amt_curr / g.amt_curr * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(s.amt_curr / s.qty_curr, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_curr,
    -- val_y1_ytd
    CASE
        WHEN s.amt_y1_ytd IS NULL OR g.amt_y1_ytd IS NULL OR g.amt_y1_ytd = 0 OR s.qty_y1_ytd IS NULL OR s.qty_y1_ytd = 0 THEN '—，—'
        ELSE CONCAT(
            CAST(CAST(ROUND(s.amt_y1_ytd / g.amt_y1_ytd * 100, 2) AS DECIMALV3(20,2)) AS VARCHAR(30)),
            '%，',
            CAST(CAST(ROUND(s.amt_y1_ytd / s.qty_y1_ytd, 2) AS DECIMALV3(20,2)) AS VARCHAR(30))
        )
    END AS val_y1_ytd,
    NOW() AS load_dt                                                 -- ETL加载日期
FROM spec_total s
LEFT JOIN grand_total g
    ON s.business_unit <=> g.business_unit AND s.prdct_line_name <=> g.prdct_line_name
    AND s.product_mid_class <=> g.product_mid_class AND s.product_small_class <=> g.product_small_class
    AND s.category_segment <=> g.category_segment AND s.o2o_type <=> g.o2o_type
;
