/*
 * 脚本名称: validate_data_quality.sql
 * 功能描述: 013-aowei-market-analysis 数据质量验证
 * 作者: Kiro Agent
 * 创建时间: 2026-07-08
 * 说明: 用于验证7张ads目标表和2张dim表的数据质量
 */

-- ============================================================
-- 1. dim表记录数验证
-- ============================================================

-- 价格段dim应有74条
SELECT '价格段dim' AS check_item,
       COUNT(*) AS actual_count,
       74 AS expected_count,
       CASE WHEN COUNT(*) = 74 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dim.dim_ipd_ipm_aw_price_segment_dd;

-- 规格段dim应有52条
SELECT '规格段dim' AS check_item,
       COUNT(*) AS actual_count,
       52 AS expected_count,
       CASE WHEN COUNT(*) = 52 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dim.dim_ipd_ipm_aw_spec_segment_dd;

-- ============================================================
-- 2. 各ads表非空验证
-- ============================================================

SELECT '表1-1 行业分渠道' AS check_item, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_industry_channel_dd;

SELECT '表1-2 分渠道分品牌' AS check_item, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_channel_brand_dd;

SELECT '表2-1 型号均价' AS check_item, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_model_price_spec_dd;

SELECT '表2-2 分价格段' AS check_item, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_price_segment_dd;

SELECT '表2-3 价格段品牌' AS check_item, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_price_brand_dd;

SELECT '表2-4 价格段规格段' AS check_item, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_price_spec_dd;

SELECT '表2-5 价格段规格段品牌' AS check_item, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_price_spec_brand_dd;

-- ============================================================
-- 3. metric_name枚举值验证
-- ============================================================

-- 表1-1应有5种指标（总体行只有3种：总销额/总销量/产品均价）
SELECT '表1-1 指标枚举' AS check_item,
       metric_name, COUNT(*) AS cnt
FROM ads.ads_ipd_ipm_aowei_industry_channel_dd
GROUP BY metric_name
ORDER BY metric_name;

-- 表2-1应有5种指标
SELECT '表2-1 指标枚举' AS check_item,
       metric_name, COUNT(*) AS cnt
FROM ads.ads_ipd_ipm_aowei_model_price_spec_dd
GROUP BY metric_name
ORDER BY metric_name;

-- ============================================================
-- 4. 总体行占有率验证（表1-1总体行的额占有率/量占有率应全为NULL）
-- ============================================================

SELECT '表1-1 总体行占有率' AS check_item,
       COUNT(*) AS non_null_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_aowei_industry_channel_dd
WHERE channel_type_agg = '总体'
  AND metric_name IN ('额占有率','量占有率')
  AND (val_y3 IS NOT NULL OR val_y2 IS NOT NULL OR val_y1 IS NOT NULL
       OR val_curr IS NOT NULL OR val_y1_ytd IS NOT NULL);

-- ============================================================
-- 5. 品牌筛选验证（表1-2不应出现非筛选品牌）
-- ============================================================

SELECT '表1-2 品牌枚举' AS check_item,
       stat_brand, COUNT(*) AS cnt
FROM ads.ads_ipd_ipm_aowei_channel_brand_dd
GROUP BY stat_brand
ORDER BY stat_brand;

-- ============================================================
-- 6. 价格段区间完整性验证（dim表中每个品线的价格段应覆盖全范围）
-- ============================================================

SELECT '价格段覆盖' AS check_item,
       prdct_line_name,
       MIN(min_price) AS range_start,
       MAX(max_price) AS range_end,
       COUNT(*) AS segment_count
FROM dim.dim_ipd_ipm_aw_price_segment_dd
GROUP BY prdct_line_name;
