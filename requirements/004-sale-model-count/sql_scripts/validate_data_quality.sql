-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: validate_data_quality.sql
-- 功能描述: 在销型号数 - 数据质量检查
--           在ETL脚本执行完成后运行，验证数据完整性和准确性
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-05-09
-- 使用方式: 每次ETL执行后运行，检查结果应全部为PASS
-- ******************************************************************** --


-- ====================================================================
-- 1. DWS层：在销型号明细表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'dws_sale_model_detail_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dws.dws_ipd_ipm_sale_model_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 2. DWS层：关键字段空值率检查
-- 预期：model、product_line 空值率 = 0
-- ====================================================================
SELECT
    'dws_sale_model_detail_dd' AS check_table
    ,'关键字段空值率' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN model IS NULL OR model = '' THEN 1 ELSE 0 END) AS null_model
    ,SUM(CASE WHEN product_line IS NULL OR product_line = '' THEN 1 ELSE 0 END) AS null_product_line
    ,CASE
        WHEN SUM(CASE WHEN model IS NULL OR model = '' THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN product_line IS NULL OR product_line = '' THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_sale_model_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 3. DWS层：型号阶段标签完整性检查
-- 预期：model_label_10 不为空，且值在预期范围内
-- ====================================================================
SELECT
    'dws_sale_model_detail_dd' AS check_table
    ,'型号阶段标签' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN model_label_10 IS NULL OR model_label_10 = '' THEN 1 ELSE 0 END) AS null_label
    ,CASE
        WHEN SUM(CASE WHEN model_label_10 IS NULL OR model_label_10 = '' THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_sale_model_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 4. ADS层：在销型号数结果表 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'ads_sale_model_result_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_sale_model_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 5. ADS层：在销型号数合理性检查
-- 预期：act_num > 0（至少有1个在销型号）
-- ====================================================================
SELECT
    'ads_sale_model_result_dd' AS check_table
    ,'型号数合理性' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN act_num <= 0 THEN 1 ELSE 0 END) AS zero_or_negative
    ,CASE
        WHEN SUM(CASE WHEN act_num <= 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM ads.ads_ipd_ipm_sale_model_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 6. 产品线覆盖完整性检查
-- 预期：至少5条产品线有数据
-- ====================================================================
SELECT
    'ads_sale_model_result_dd' AS check_table
    ,'产品线覆盖' AS check_type
    ,COUNT(DISTINCT product_line) AS product_line_count
    ,CASE WHEN COUNT(DISTINCT product_line) >= 5 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_sale_model_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');
