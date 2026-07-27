/*
 * 脚本名称: validate_data_quality.sql
 * 功能描述: 变更模块变更明细汇总统计 - 数据质量检查
 * 作者: Kiro ETL助手
 * 创建时间: 2026-05-27
 * 数据源: ads.ads_ipd_irs_design_change_kccl_dd
 * 说明: 009需求为BI数据集查询（无需建表），本脚本验证源表数据质量
 *       确保BI报表查询结果的准确性和完整性
 */


-- ============================================================================
-- 检查1：源表数据行数检查（确保表非空且有近期数据）
-- ============================================================================
SELECT
    '1-源表总行数' AS check_name,
    COUNT(*) AS check_value,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS check_result,
    '源表ads_ipd_irs_design_change_kccl_dd应有数据' AS check_desc
FROM ads.ads_ipd_irs_design_change_kccl_dd;


-- ============================================================================
-- 检查2：关键字段空值率检查
-- 设计变更编号(name)、所属公司(company)、发布时间(approvedTIme)不应为空
-- ============================================================================
SELECT
    '2-关键字段空值率' AS check_name,
    ROUND(SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4) AS name_null_rate,
    ROUND(SUM(CASE WHEN company IS NULL OR company = '' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4) AS company_null_rate,
    ROUND(SUM(CASE WHEN approvedTIme IS NULL OR approvedTIme = '' THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 4) AS approvedtime_null_rate,
    CASE
        WHEN SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) = 0
            AND SUM(CASE WHEN company IS NULL OR company = '' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) < 0.05
            AND SUM(CASE WHEN approvedTIme IS NULL OR approvedTIme = '' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) < 0.05
        THEN 'PASS'
        ELSE 'WARN'
    END AS check_result
FROM ads.ads_ipd_irs_design_change_kccl_dd;


-- ============================================================================
-- 检查3：时间字段格式检查
-- approvedTIme应为 'YYYY-MM-DD HH:MM:SS' 格式，LEFT(,7)应为有效年月
-- ============================================================================
SELECT
    '3-时间字段格式' AS check_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN LEFT(approvedTIme, 7) REGEXP '^[0-9]{4}-[0-9]{2}$' THEN 1 ELSE 0 END) AS valid_format_count,
    ROUND(
        SUM(CASE WHEN LEFT(approvedTIme, 7) REGEXP '^[0-9]{4}-[0-9]{2}$' THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0),
        4) AS valid_format_rate,
    CASE
        WHEN SUM(CASE WHEN LEFT(approvedTIme, 7) REGEXP '^[0-9]{4}-[0-9]{2}$' THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*), 0) >= 0.99
        THEN 'PASS'
        ELSE 'WARN'
    END AS check_result
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE approvedTIme IS NOT NULL AND approvedTIme != '';


-- ============================================================================
-- 检查4：flag字段值域检查
-- flag应为1/2/3/4（1=设计变更报表/2=+MCA/3=+MCO/4=+kccl）
-- ============================================================================
SELECT
    '4-flag值域' AS check_name,
    flag,
    COUNT(*) AS row_count,
    CASE WHEN flag IN ('1','2','3','4') THEN 'PASS' ELSE 'WARN' END AS check_result
FROM ads.ads_ipd_irs_design_change_kccl_dd
GROUP BY flag
ORDER BY flag;


-- ============================================================================
-- 检查5：设计变更生命周期状态(design_current)值域检查
-- 确保状态值在预期范围内
-- ============================================================================
SELECT
    '5-生命周期状态值域' AS check_name,
    design_current,
    COUNT(DISTINCT name) AS distinct_name_count
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE design_current IS NOT NULL AND design_current != ''
GROUP BY design_current
ORDER BY distinct_name_count DESC;


-- ============================================================================
-- 检查6：MCO相关字段完整性检查
-- MCO_name非空时，MCO_current也应非空
-- ============================================================================
SELECT
    '6-MCO字段完整性' AS check_name,
    COUNT(DISTINCT CASE WHEN MCO_name IS NOT NULL AND MCO_name != '' THEN MCO_name END) AS mco_total,
    COUNT(DISTINCT CASE WHEN MCO_name IS NOT NULL AND MCO_name != '' AND (MCO_current IS NULL OR MCO_current = '') THEN MCO_name END) AS mco_missing_status,
    CASE
        WHEN COUNT(DISTINCT CASE WHEN MCO_name IS NOT NULL AND MCO_name != '' AND (MCO_current IS NULL OR MCO_current = '') THEN MCO_name END) = 0
        THEN 'PASS'
        ELSE 'WARN'
    END AS check_result
FROM ads.ads_ipd_irs_design_change_kccl_dd;


-- ============================================================================
-- 检查7：时长字段合理性检查
-- gypgclsc(工艺评估处理时长)和cgpgclsc(采购评估处理时长)应为非负数
-- ============================================================================
SELECT
    '7-时长字段合理性' AS check_name,
    SUM(CASE WHEN gypgclsc IS NOT NULL AND CAST(gypgclsc AS DECIMAL(10,2)) < 0 THEN 1 ELSE 0 END) AS gypgclsc_negative_count,
    SUM(CASE WHEN cgpgclsc IS NOT NULL AND CAST(cgpgclsc AS DECIMAL(10,2)) < 0 THEN 1 ELSE 0 END) AS cgpgclsc_negative_count,
    CASE
        WHEN SUM(CASE WHEN gypgclsc IS NOT NULL AND CAST(gypgclsc AS DECIMAL(10,2)) < 0 THEN 1 ELSE 0 END) = 0
            AND SUM(CASE WHEN cgpgclsc IS NOT NULL AND CAST(cgpgclsc AS DECIMAL(10,2)) < 0 THEN 1 ELSE 0 END) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS check_result
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE MCO_name IS NOT NULL AND MCO_name != '';


-- ============================================================================
-- 检查8：公司维度覆盖检查
-- 确保有多个公司的数据（非单一公司）
-- ============================================================================
SELECT
    '8-公司维度覆盖' AS check_name,
    COUNT(DISTINCT company) AS distinct_company_count,
    CASE
        WHEN COUNT(DISTINCT company) >= 3 THEN 'PASS'
        WHEN COUNT(DISTINCT company) >= 1 THEN 'WARN'
        ELSE 'FAIL'
    END AS check_result
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE company IS NOT NULL AND company != '';
