-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: validate_data_quality.sql
-- 功能描述: 企划命中率 - 数据质量检查
--           在ETL脚本执行完成后运行，验证数据完整性和准确性
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-05-09
-- 使用方式: 每次ETL执行后运行，检查结果应全部为PASS
-- ******************************************************************** --


-- ====================================================================
-- 1. DWS层：型号口径 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'dws_qihua_hit_detail_dd' AS check_table
    ,'型号口径行数' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '型号口径';


-- ====================================================================
-- 2. DWS层：项目口径 行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'dws_qihua_hit_detail_dd' AS check_table
    ,'项目口径行数' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '项目口径';


-- ====================================================================
-- 3. DWS层：关键字段空值率检查（型号口径）
-- 预期：salemodel_code、project_code 空值率 = 0
-- ====================================================================
SELECT
    'dws_qihua_hit_detail_dd' AS check_table
    ,'型号口径关键字段空值' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN salemodel_code IS NULL OR salemodel_code = '' THEN 1 ELSE 0 END) AS null_salemodel_code
    ,SUM(CASE WHEN project_code IS NULL OR project_code = '' THEN 1 ELSE 0 END) AS null_project_code
    ,CASE
        WHEN SUM(CASE WHEN salemodel_code IS NULL OR salemodel_code = '' THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN project_code IS NULL OR project_code = '' THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '型号口径';


-- ====================================================================
-- 4. DWS层：阶段判定完整性检查（项目口径）
-- 预期：stage 在 1~6 范围内，无NULL
-- ====================================================================
SELECT
    'dws_qihua_hit_detail_dd' AS check_table
    ,'阶段判定完整性' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN stage IS NULL OR stage < 1 OR stage > 6 THEN 1 ELSE 0 END) AS abnormal_stage
    ,CASE
        WHEN SUM(CASE WHEN stage IS NULL OR stage < 1 OR stage > 6 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '项目口径';


-- ====================================================================
-- 5. DWS层：首年规划量合理性检查
-- 预期：plan_first_year_qty >= 0（不应为负数）
-- ====================================================================
SELECT
    'dws_qihua_hit_detail_dd' AS check_table
    ,'首年规划量合理性' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN plan_first_year_qty < 0 THEN 1 ELSE 0 END) AS negative_plan
    ,CASE
        WHEN SUM(CASE WHEN plan_first_year_qty < 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '型号口径';


-- ====================================================================
-- 6. ADS层：结果表行数检查
-- 预期：当月数据行数 > 0
-- ====================================================================
SELECT
    'ads_qihua_hit_result_dd' AS check_table
    ,'行数检查' AS check_type
    ,COUNT(*) AS row_count
    ,CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM ads.ads_ipd_ipm_qihua_hit_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');


-- ====================================================================
-- 7. ADS层：达标率合理性检查
-- 预期：hit_rate 在 [0, 1] 范围内
-- ====================================================================
SELECT
    'ads_qihua_hit_result_dd' AS check_table
    ,'达标率合理性' AS check_type
    ,COUNT(*) AS total_rows
    ,SUM(CASE WHEN hit_rate < 0 OR hit_rate > 1 THEN 1 ELSE 0 END) AS abnormal_rows
    ,CASE
        WHEN SUM(CASE WHEN hit_rate < 0 OR hit_rate > 1 THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS result
FROM ads.ads_ipd_ipm_qihua_hit_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');
