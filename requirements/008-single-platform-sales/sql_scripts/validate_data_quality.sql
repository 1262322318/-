-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: validate_data_quality.sql
-- 功能描述: 单平台销量 - 数据质量检查
--           在ETL脚本执行完成后运行，验证数据完整性和准确性
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-05-09
-- 使用方式: 每次ETL执行后运行，检查结果应全部为PASS
-- ******************************************************************** --


-- ====================================================================
-- 1. DWS层：单平台销量明细表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'dws_dptxl_detail_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dws.dws_ipd_ipm_dptxl_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 2. DWS层：关键字段空值率检查
-- 预期：platform、product_line 空值率 = 0
-- ====================================================================
SELECT
    'dws_dptxl_detail_dd' AS check_table
    ,'关键字段空值率' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN platform IS NULL OR platform = '' THEN 1 ELSE 0 END) AS null_platform
    ,SUM(CASE WHEN product_line IS NULL OR product_line = '' THEN 1 ELSE 0 END) AS null_product_line
    ,CASE
        WHEN SUM(CASE WHEN platform IS NULL OR platform = '' THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN product_line IS NULL OR product_line = '' THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_dptxl_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 3. DWS层：销量合理性检查
-- 预期：sales_qty >= 0（不应为负数）
-- ====================================================================
SELECT
    'dws_dptxl_detail_dd' AS check_table
    ,'销量合理性' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN sales_qty < 0 THEN 1 ELSE 0 END) AS negative_qty
    ,CASE
        WHEN SUM(CASE WHEN sales_qty < 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_dptxl_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 4. ADS层：单平台销量结果表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'ads_dptxl_result_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_dptxl_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 5. ADS层：单平台销量合理性检查
-- 预期：dptxl > 0（单平台销量应为正数）
-- ====================================================================
SELECT
    'ads_dptxl_result_dd' AS check_table
    ,'单平台销量合理性' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN dptxl <= 0 THEN 1 ELSE 0 END) AS zero_or_negative
    ,CASE
        WHEN SUM(CASE WHEN dptxl <= 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM ads.ads_ipd_ipm_dptxl_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 6. ADS层：平台数分母校验
-- 预期：platform_num > 0（分母不能为0）
-- ====================================================================
SELECT
    'ads_dptxl_result_dd' AS check_table
    ,'平台数分母校验' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN platform_num <= 0 THEN 1 ELSE 0 END) AS zero_platform
    ,CASE
        WHEN SUM(CASE WHEN platform_num <= 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM ads.ads_ipd_ipm_dptxl_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');
