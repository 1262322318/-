-- =====================================================================
-- 脚本名称：validate_data_quality.sql
-- 功能说明：应市项目按计划实施率 - 数据质量校验
-- 使用方式：手动执行，检查DWS和ADS层数据一致性
-- =====================================================================

-- ===== 校验1：DWS层项目情况分布（确认5种状态互斥且完整） =====
SELECT
    dt_month,
    project_situation,
    in_total_flag,
    COUNT(*) AS cnt
FROM dws.dws_ipd_itd_project_impl_rate_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
GROUP BY dt_month, project_situation, in_total_flag
ORDER BY project_situation;

-- ===== 校验2：DWS层 vs ADS层事业部小计行一致性 =====
-- DWS汇总
SELECT
    business_division,
    SUM(CASE WHEN project_situation IN ('正常','延期','暂停','结题') THEN 1 ELSE 0 END) AS dws_total,
    SUM(CASE WHEN project_situation IN ('正常','结题') THEN 1 ELSE 0 END) AS dws_numerator
FROM dws.dws_ipd_itd_project_impl_rate_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
GROUP BY business_division;

-- ADS事业部小计
SELECT
    business_division,
    total_count AS ads_total,
    normal_count + complete_count AS ads_numerator,
    impl_rate
FROM ads.ads_ipd_itd_project_impl_rate_result_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
  AND dim_type = '事业部小计';

-- ===== 校验3：终止项目确认不纳入分母 =====
SELECT
    projectname,
    project_situation,
    in_total_flag
FROM dws.dws_ipd_itd_project_impl_rate_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
  AND project_situation = '终止'
  AND in_total_flag != 'N';
-- 预期结果：0行（终止项目必须in_total_flag='N'）

-- ===== 校验4：结题项目不应同时被标记为延期 =====
SELECT
    projectname,
    project_situation,
    is_design_delay,
    is_production_delay
FROM dws.dws_ipd_itd_project_impl_rate_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
  AND project_situation = '结题'
  AND (is_design_delay = 'Y' OR is_production_delay = 'Y');
-- 说明：结题优先级高于延期，此处可能有记录（延期标记为Y但情况判定为结题），属于正常逻辑

-- ===== 校验5：项目经理维度汇总数 = 事业部小计汇总数 =====
SELECT '项目经理维度' AS dim, SUM(total_count) AS sum_total
FROM ads.ads_ipd_itd_project_impl_rate_result_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
  AND dim_type = '项目经理'
UNION ALL
SELECT '事业部小计' AS dim, SUM(total_count) AS sum_total
FROM ads.ads_ipd_itd_project_impl_rate_result_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
  AND dim_type = '事业部小计';
-- 预期结果：两行的sum_total应相等

-- ===== 校验6：产品线筛选正确性（不应包含非终端/光模块） =====
SELECT DISTINCT hbmtpproductline, business_division
FROM dws.dws_ipd_itd_project_impl_rate_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
  AND business_division NOT IN ('光模块', '终端');
-- 预期结果：0行
