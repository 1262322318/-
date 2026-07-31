-- ============================================================================
-- 需求: WS-13 应市项目平均开发周期
-- 文件: validate_data_quality.sql
-- 用途: 数据质量校验（ETL上线后逐条执行验证）
-- 创建时间: 2026-07-31
-- ============================================================================

-- ===== 校验1: 目标表有数据 =====
-- 预期: 当月有记录
SELECT '校验1: 目标表有数据' AS check_name,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    COUNT(*) AS record_count
FROM dws.dws_plm_project_dev_cycle_monthly
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

-- ===== 校验2: 产品线维度覆盖 =====
-- 预期: business_division 只有 '终端' 和 '光模块'
SELECT '校验2: 产品线维度覆盖' AS check_name,
    CASE WHEN cnt_other = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    cnt_other AS unexpected_count
FROM (
    SELECT COUNT(CASE WHEN business_division NOT IN ('终端', '光模块') THEN 1 END) AS cnt_other
    FROM dws.dws_plm_project_dev_cycle_monthly
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
) t;

-- ===== 校验3: 平均开发周期合理性 =====
-- 预期: avg_dev_cycle_days > 0 且 < 1500（约4年，合理上界）
SELECT '校验3: 平均开发周期合理性' AS check_name,
    CASE WHEN cnt_abnormal = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    cnt_abnormal AS abnormal_count
FROM (
    SELECT COUNT(CASE WHEN avg_dev_cycle_days <= 0 OR avg_dev_cycle_days > 1500 THEN 1 END) AS cnt_abnormal
    FROM dws.dws_plm_project_dev_cycle_monthly
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
) t;

-- ===== 校验4: 项目数与总天数一致性 =====
-- 预期: total_dev_cycle_days / project_count ≈ avg_dev_cycle_days（误差<0.1）
SELECT '校验4: 聚合一致性' AS check_name,
    CASE WHEN cnt_mismatch = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    cnt_mismatch AS mismatch_count
FROM (
    SELECT COUNT(CASE
        WHEN ABS(total_dev_cycle_days / project_count - avg_dev_cycle_days) > 0.1 THEN 1
    END) AS cnt_mismatch
    FROM dws.dws_plm_project_dev_cycle_monthly
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
      AND project_count > 0
) t;

-- ===== 校验5: 无重复记录 =====
-- 预期: 同一月份+产品线只有一条记录
SELECT '校验5: 无重复记录' AS check_name,
    CASE WHEN cnt_dup = 0 THEN 'PASS' ELSE 'FAIL' END AS result,
    cnt_dup AS duplicate_count
FROM (
    SELECT COUNT(*) AS cnt_dup
    FROM (
        SELECT dt_month, product_line_code, COUNT(*) AS cnt
        FROM dws.dws_plm_project_dev_cycle_monthly
        WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
        GROUP BY dt_month, product_line_code
        HAVING COUNT(*) > 1
    ) dup
) t;

-- ===== 校验6: 源表数据覆盖率 =====
-- 预期: 目标表项目总数 = 源表当月完成的应市项目数（在终端/光模块维度范围内）
SELECT '校验6: 源表覆盖率' AS check_name,
    CASE WHEN ABS(target_cnt - source_cnt) = 0 THEN 'PASS' ELSE 'WARN' END AS result,
    source_cnt AS source_project_count,
    target_cnt AS target_project_count
FROM (
    SELECT
        (SELECT SUM(project_count)
         FROM dws.dws_plm_project_dev_cycle_monthly
         WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
        ) AS target_cnt,
        (SELECT COUNT(*)
         FROM ods.odsplm_bm_hbmtprojectkpi
         WHERE DATE_FORMAT(hbmtpproductionactualedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
           AND (hbmtpderivetype LIKE 'PA%' OR hbmtpderivetype LIKE 'PB%'
                OR hbmtpderivetype = 'PC1' OR hbmtpderivetype = 'PC2')
           AND hbmtpproductline IN ('A1', 'A2', 'A3', 'A4', 'Coherent', 'BOX', 'Multimedia')
        ) AS source_cnt
) t;
