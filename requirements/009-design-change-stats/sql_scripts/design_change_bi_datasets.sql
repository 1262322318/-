/*
 * 脚本名称: design_change_bi_datasets.sql
 * 功能描述: 变更模块变更明细汇总统计 - BI报表数据集SQL
 * 作者: Kiro ETL助手
 * 创建时间: 2026-05-18
 * 数据源: ads.ads_ipd_irs_design_change_kccl_dd
 * 产出形式: 10条查询SQL（BI数据集，无需建表）
 * 业务域: IRS（管理研发支撑）
 * 
 * 公共筛选条件说明（BI前端参数，所有报表共用）：
 *   - ${start_month}: 开始月度，格式 YYYY-MM，如 '2025-01'
 *   - ${end_month}: 结束月度，格式 YYYY-MM，如 '2025-12'
 *   - ${company}: 所属公司（多选，默认全选时传 '%' 或不传）
 *   - ${department}: 发起部门（多选，默认全选时传 '%' 或不传）
 *   - ${factory}: 所属工厂（多选，默认全选时传 '%' 或不传）
 *   - ${change_reason}: 变更原因分类（多选，默认全选时传 '%' 或不传）
 *   - ${change_phase}: 变更阶段（多选，默认全选时传 '%' 或不传）
 *   - ${change_level}: 变更级别（多选，默认全选时传 '%' 或不传）
 *   - ${flag}: flag场景类型（多选，默认全选时传 '%' 或不传）
 *
 * 注意事项：
 *   1. 设计变更编号去重：COUNT(DISTINCT name)
 *   2. MCO编号去重：COUNT(DISTINCT MCO_name)
 *   3. 时间字段 approvedTIme 为 varchar，格式 '2025-09-13 09:44:23'，按月度筛选用 LEFT(approvedTIme, 7)
 *   4. 时长字段 gypgclsc/cgpgclsc 为小时数（整数），超期判断需除以24转天
 *   5. MCOcjsj/HWA_BreakpointDate 为 varchar，格式同 approvedTIme，比较时需 CAST 为 DATE
 *   6. 当前日期使用 CURDATE()
 */


-- ============================================================================
-- 表一：设计变更单实施率完成情况（按公司维度）
-- 图表类型：柱状图
-- 已实施率 = (已完成+变更已实施) / (除草稿外全部)
-- ============================================================================
SELECT
    company                                                         AS 所属公司,
    COUNT(DISTINCT CASE 
        WHEN design_current IN ('已完成', '变更已实施') 
        THEN name END)                                              AS 已实施数量,
    COUNT(DISTINCT CASE 
        WHEN design_current != '草稿' 
        THEN name END)                                              AS 总数量_除草稿,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN design_current IN ('已完成', '变更已实施') 
            THEN name END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE 
            WHEN design_current != '草稿' 
            THEN name END), 0),
        4)                                                          AS 已实施率
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
GROUP BY company
ORDER BY company;


-- ============================================================================
-- 表二：变更原因分类占比（饼图）
-- 条目只取括号外的文字
-- ============================================================================
SELECT
    CASE 
        WHEN LOCATE('(', HWA_ChangeReasonType) > 0 
        THEN TRIM(LEFT(HWA_ChangeReasonType, LOCATE('(', HWA_ChangeReasonType) - 1))
        WHEN LOCATE('（', HWA_ChangeReasonType) > 0 
        THEN TRIM(LEFT(HWA_ChangeReasonType, LOCATE('（', HWA_ChangeReasonType) - 1))
        ELSE HWA_ChangeReasonType
    END                                                             AS 变更原因分类,
    COUNT(DISTINCT name)                                            AS 变更单数量
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
GROUP BY 
    CASE 
        WHEN LOCATE('(', HWA_ChangeReasonType) > 0 
        THEN TRIM(LEFT(HWA_ChangeReasonType, LOCATE('(', HWA_ChangeReasonType) - 1))
        WHEN LOCATE('（', HWA_ChangeReasonType) > 0 
        THEN TRIM(LEFT(HWA_ChangeReasonType, LOCATE('（', HWA_ChangeReasonType) - 1))
        ELSE HWA_ChangeReasonType
    END
ORDER BY 变更单数量 DESC;


-- ============================================================================
-- 表三：变更阶段占比（饼图）
-- ============================================================================
SELECT
    HWA_ChangePhase                                                 AS 变更阶段,
    COUNT(DISTINCT name)                                            AS 变更单数量
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
GROUP BY HWA_ChangePhase
ORDER BY 变更单数量 DESC;


-- ============================================================================
-- 表四：变更级别占比（饼图）
-- ============================================================================
SELECT
    hwa_changelevel                                                 AS 变更级别,
    COUNT(DISTINCT name)                                            AS 变更单数量
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
GROUP BY hwa_changelevel
ORDER BY 变更单数量 DESC;


-- ============================================================================
-- 表五：生命周期状态占比（饼图）
-- ============================================================================
SELECT
    design_current                                                  AS 生命周期状态,
    COUNT(DISTINCT name)                                            AS 变更单数量
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
GROUP BY design_current
ORDER BY 变更单数量 DESC;


-- ============================================================================
-- 表六：各部门设计变更实施完成情况（柱状图+折线图）
-- 已实施率 = (已完成+变更已实施) / (除草稿外全部)
-- ============================================================================
SELECT
    HWA_ChangeSubmittingDepartment                                  AS 发起部门,
    COUNT(DISTINCT CASE 
        WHEN design_current IN ('已完成', '变更已实施') 
        THEN name END)                                              AS 已实施数量,
    COUNT(DISTINCT CASE 
        WHEN design_current != '草稿' 
        THEN name END)                                              AS 总数量_除草稿,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN design_current IN ('已完成', '变更已实施') 
            THEN name END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE 
            WHEN design_current != '草稿' 
            THEN name END), 0),
        4)                                                          AS 已实施率
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
GROUP BY HWA_ChangeSubmittingDepartment
ORDER BY 已实施率 DESC;


-- ============================================================================
-- 表七①：各工厂设计变更完成情况 - 实施完成情况（柱状图）
-- MCO已实施率 = MCO成熟度状态为'变更已实施'的数量 / MCO总数
-- MCO已完成率 = 生命周期状态为'MCO完成'的数量 / MCO总数
-- 注：按MCO编号去重
-- ============================================================================
SELECT
    werks_name                                                      AS 所属工厂,
    COUNT(DISTINCT CASE 
        WHEN MCO_current = '变更已实施' 
        THEN MCO_name END)                                          AS MCO已实施数量,
    COUNT(DISTINCT CASE 
        WHEN design_current = 'MCO完成' 
        THEN MCO_name END)                                          AS MCO已完成数量,
    COUNT(DISTINCT MCO_name)                                        AS MCO总数,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current = '变更已实施' 
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT MCO_name), 0),
        4)                                                          AS MCO已实施率,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN design_current = 'MCO完成' 
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT MCO_name), 0),
        4)                                                          AS MCO已完成率
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
    AND MCO_name IS NOT NULL AND MCO_name != ''
GROUP BY werks_name
ORDER BY werks_name;


-- ============================================================================
-- 表七②：各工厂设计变更完成情况 - 未实施完成情况（柱状图+折线图）
-- 未实施率 = MCO成熟度状态非'变更已实施'的数量 / MCO总数
-- 超3月未实施率 = (非'变更已实施' 且 CURDATE()-MCOcjsj > 90天) / MCO总数
-- ============================================================================
SELECT
    werks_name                                                      AS 所属工厂,
    COUNT(DISTINCT CASE 
        WHEN MCO_current != '变更已实施' 
        THEN MCO_name END)                                          AS 未实施数量,
    COUNT(DISTINCT MCO_name)                                        AS MCO总数,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current != '变更已实施' 
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT MCO_name), 0),
        4)                                                          AS 未实施率,
    COUNT(DISTINCT CASE 
        WHEN MCO_current != '变更已实施'
            AND DATEDIFF(CURDATE(), CAST(LEFT(MCOcjsj, 10) AS DATE)) > 90
        THEN MCO_name END)                                          AS 超3月未实施数量,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current != '变更已实施'
                AND DATEDIFF(CURDATE(), CAST(LEFT(MCOcjsj, 10) AS DATE)) > 90
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT MCO_name), 0),
        4)                                                          AS 超3月未实施率
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
    AND MCO_name IS NOT NULL AND MCO_name != ''
GROUP BY werks_name
ORDER BY werks_name;


-- ============================================================================
-- 表八：各工厂工艺评估和采购评估未完成数量（柱状图）
-- 工艺评估未完成：MCO_current = '草稿'
-- 采购评估未完成：MCO_current = '工艺评估完成'
-- 超期判断：gypgclsc(小时)/24 > 2天，cgpgclsc(小时)/24 > 3天
-- ============================================================================
SELECT
    werks_name                                                      AS 所属工厂,
    -- 基数：草稿+工艺评估完成+采购评估完成
    COUNT(DISTINCT CASE 
        WHEN MCO_current IN ('草稿', '工艺评估完成', '采购评估完成') 
        THEN MCO_name END)                                          AS 评估阶段MCO总数,
    -- 工艺评估未完成
    COUNT(DISTINCT CASE 
        WHEN MCO_current = '草稿' 
        THEN MCO_name END)                                          AS 工艺评估未完成数量,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current = '草稿' 
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE 
            WHEN MCO_current IN ('草稿', '工艺评估完成', '采购评估完成') 
            THEN MCO_name END), 0),
        4)                                                          AS 工艺评估未完成占比,
    -- 工艺未评估超2天
    COUNT(DISTINCT CASE 
        WHEN MCO_current = '草稿' 
            AND CAST(gypgclsc AS DECIMAL(10,2)) / 24 > 2
        THEN MCO_name END)                                          AS 工艺未评估超2天数量,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current = '草稿' 
                AND CAST(gypgclsc AS DECIMAL(10,2)) / 24 > 2
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE 
            WHEN MCO_current = '草稿' 
            THEN MCO_name END), 0),
        4)                                                          AS 工艺未评估超2天占比,
    -- 采购评估未完成
    COUNT(DISTINCT CASE 
        WHEN MCO_current = '工艺评估完成' 
        THEN MCO_name END)                                          AS 采购评估未完成数量,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current = '工艺评估完成' 
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE 
            WHEN MCO_current IN ('草稿', '工艺评估完成', '采购评估完成') 
            THEN MCO_name END), 0),
        4)                                                          AS 采购评估未完成占比,
    -- 采购评估超3天
    COUNT(DISTINCT CASE 
        WHEN MCO_current = '工艺评估完成' 
            AND CAST(cgpgclsc AS DECIMAL(10,2)) / 24 > 3
        THEN MCO_name END)                                          AS 采购评估超3天数量,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current = '工艺评估完成' 
                AND CAST(cgpgclsc AS DECIMAL(10,2)) / 24 > 3
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE 
            WHEN MCO_current = '工艺评估完成' 
            THEN MCO_name END), 0),
        4)                                                          AS 采购评估超3天占比
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
    AND MCO_name IS NOT NULL AND MCO_name != ''
GROUP BY werks_name
ORDER BY werks_name;


-- ============================================================================
-- 表九：各工厂工艺评估处理和采购评估处理平均时长（柱状图）
-- 工艺评估平均时长：MCO_current = '工艺评估完成'，取 gypgclsc 平均值（小时）
-- 采购评估平均时长：MCO_current = '采购评估完成'，取 cgpgclsc 平均值（小时）
-- ============================================================================
SELECT
    werks_name                                                      AS 所属工厂,
    ROUND(
        AVG(CASE 
            WHEN MCO_current = '工艺评估完成' 
            THEN CAST(gypgclsc AS DECIMAL(10,2)) 
            END),
        2)                                                          AS 工艺评估平均时长_小时,
    ROUND(
        AVG(CASE 
            WHEN MCO_current = '采购评估完成' 
            THEN CAST(cgpgclsc AS DECIMAL(10,2)) 
            END),
        2)                                                          AS 采购评估平均时长_小时
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
    AND MCO_name IS NOT NULL AND MCO_name != ''
    AND MCO_current IN ('工艺评估完成', '采购评估完成')
GROUP BY werks_name
ORDER BY werks_name;


-- ============================================================================
-- 表十：各工厂MCO生效日已过实施情况（柱状图+折线图）
-- 生效日已过未实施占比：MCO_current='MCO完成' 且 生效日<=今天 / (MCO完成+变更已实施)
-- 折线图（次坐标轴）：MCO_current='MCO完成' 且 生效日<=今天 的数量
-- ============================================================================
SELECT
    werks_name                                                      AS 所属工厂,
    COUNT(DISTINCT CASE 
        WHEN MCO_current = 'MCO完成' 
            AND CAST(LEFT(HWA_BreakpointDate, 10) AS DATE) <= CURDATE()
        THEN MCO_name END)                                          AS 生效日已过未实施数量,
    COUNT(DISTINCT CASE 
        WHEN MCO_current IN ('MCO完成', '变更已实施') 
        THEN MCO_name END)                                          AS MCO完成加已实施总数,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN MCO_current = 'MCO完成' 
                AND CAST(LEFT(HWA_BreakpointDate, 10) AS DATE) <= CURDATE()
            THEN MCO_name END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE 
            WHEN MCO_current IN ('MCO完成', '变更已实施') 
            THEN MCO_name END), 0),
        4)                                                          AS 生效日已过未实施占比
FROM ads.ads_ipd_irs_design_change_kccl_dd
WHERE LEFT(approvedTIme, 7) >= '${start_month}'
    AND LEFT(approvedTIme, 7) <= '${end_month}'
    AND (company IN (${company}) OR '${company}' = '%')
    AND (HWA_ChangeSubmittingDepartment IN (${department}) OR '${department}' = '%')
    AND (werks_name IN (${factory}) OR '${factory}' = '%')
    AND (HWA_ChangeReasonType IN (${change_reason}) OR '${change_reason}' = '%')
    AND (HWA_ChangePhase IN (${change_phase}) OR '${change_phase}' = '%')
    AND (hwa_changelevel IN (${change_level}) OR '${change_level}' = '%')
    AND (flag IN (${flag}) OR '${flag}' = '%')
    AND MCO_name IS NOT NULL AND MCO_name != ''
GROUP BY werks_name
ORDER BY werks_name;
