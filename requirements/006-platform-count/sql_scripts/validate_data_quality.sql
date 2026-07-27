-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: validate_data_quality.sql
-- 功能描述: 平台数 - 数据质量检查
--           在ETL脚本执行完成后运行，验证数据完整性和准确性
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-05-09
-- 使用方式: 每次ETL执行后运行，检查结果应全部为PASS
-- ******************************************************************** --


-- ====================================================================
-- 1. DWS层：平台库明细表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'dws_platform_library_detail_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dws.dws_ipd_ipm_platform_library_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 2. DWS层：产品平台数明细表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'dws_platform_detail_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dws.dws_ipd_ipm_platform_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 3. DWS层：平台名称空值率检查
-- 预期：platform 字段空值率 = 0
-- ====================================================================
SELECT
    'dws_platform_library_detail_dd' AS check_table
    ,'平台名称空值率' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN platform IS NULL OR platform = '' THEN 1 ELSE 0 END) AS null_platform
    ,CASE
        WHEN SUM(CASE WHEN platform IS NULL OR platform = '' THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_platform_library_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 4. ADS层：平台库结果表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'ads_platform_library_result_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_platform_library_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 5. ADS层：产品平台数结果表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'ads_platform_result_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_platform_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 6. ADS层：平台数合理性检查
-- 预期：act_value > 0（至少有1个平台）
-- ====================================================================
SELECT
    'ads_platform_result_dd' AS check_table
    ,'平台数合理性' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN act_value <= 0 THEN 1 ELSE 0 END) AS zero_or_negative
    ,CASE
        WHEN SUM(CASE WHEN act_value <= 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM ads.ads_ipd_ipm_platform_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');
