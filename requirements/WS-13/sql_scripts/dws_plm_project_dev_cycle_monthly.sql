-- ============================================================================
-- 需求: WS-13 应市项目平均开发周期
-- 文件: dws_plm_project_dev_cycle_monthly.sql
-- 指标: M1 应市项目平均开发周期
-- 刷新策略: 日刷新，DELETE当月数据 + INSERT当月数据（幂等）
-- 调度参数: ${GP_START_DT} = 调度日期（昨天，格式 yyyymmdd）
-- 创建时间: 2026-07-31
-- ============================================================================
-- ⚠️ 假设声明:
--   1. ODS 列名采用 PRD §5 PLM 属性名小写，MCP 不可用未校验【待确认-MCP未匹配】
--   2. HBMTPDERIVETYPE 应市类筛选: PA全部子型 + PB全部子型 + PC1 + PC2
--      由于 MCP 不可用无法获取精确枚举值，使用 LIKE 'PA%' / LIKE 'PB%' 匹配
--      PA/PB 全部子型 + PC1/PC2 精确匹配【待确认-MCP未匹配: 字段域枚举值】
--   3. 暂停无对应恢复单时: 默认截至统计月末计暂停天数【默认待确认·Q1】
--   4. 小数位: 保留 1 位【默认待确认·遗留-2】
-- ============================================================================

-- Step 1: 删除当月已有数据（幂等保证）
DELETE FROM dws.dws_plm_project_dev_cycle_monthly
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

-- Step 2: 插入当月统计数据
INSERT INTO dws.dws_plm_project_dev_cycle_monthly (
    dt_month,                -- 统计月份
    product_line_code,       -- 产品线编码
    product_line_name,       -- 产品线名称
    business_division,       -- 事业部维度
    project_count,           -- 当月完成项目数量
    total_dev_cycle_days,    -- 开发周期总天数
    avg_dev_cycle_days,      -- 平均开发周期(天)
    etl_time                 -- ETL加载时间
)
WITH
-- CTE1: 筛选当月完成的应市类项目
completed_projects AS (
    SELECT
        productname,                                        -- 项目名称(关联键)
        hbmtprojectcreatedate,                              -- 立项时间
        hbmtpproductionactualedate,                         -- 完成时间
        hbmtpproductline,                                   -- 产品线编码
        hbmtpderivetype                                     -- 应市类型
    FROM ods.odsplm_bm_hbmtprojectkpi
    WHERE
        -- R3: 完成时间落在当月
        DATE_FORMAT(hbmtpproductionactualedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
        -- R1: 仅应市类项目（PA全部子型 + PB全部子型 + PC1 + PC2）
        AND (
            hbmtpderivetype LIKE 'PA%'                      -- PA全部子型
            OR hbmtpderivetype LIKE 'PB%'                   -- PB全部子型
            OR hbmtpderivetype = 'PC1'                      -- PC1
            OR hbmtpderivetype = 'PC2'                      -- PC2
        )
        -- R7: 仅纳入终端/光模块维度的产品线
        AND hbmtpproductline IN ('A1', 'A2', 'A3', 'A4', 'Coherent', 'BOX', 'Multimedia')
),

-- CTE2: 获取暂停/恢复变更单，按项目+发布日期排序
hold_resume_events AS (
    SELECT
        projectname,                                        -- 项目名称(关联键)
        type,                                               -- 变更类型
        releasedate,                                        -- 发布日期(暂停/恢复时间)
        ROW_NUMBER() OVER (
            PARTITION BY projectname, type
            ORDER BY releasedate ASC
        ) AS rn                                             -- 同类型序号(用于配对)
    FROM ods.odsplm_bm_hbmtprojectadjust
    WHERE type IN ('HBMTProjectHoldRequest', 'HBMTProjectResumeRequest')
),

-- CTE3: 暂停-恢复配对，计算每段暂停天数
hold_resume_paired AS (
    SELECT
        h.projectname,                                      -- 项目名称
        h.releasedate AS hold_date,                         -- 暂停日期
        COALESCE(
            r.releasedate,
            -- Q1默认假设: 暂停无恢复时截至统计月末
            LAST_DAY(CAST('${GP_START_DT}' AS DATE))
        ) AS resume_date,                                   -- 恢复日期(无恢复则取月末)
        DATEDIFF(
            COALESCE(
                r.releasedate,
                LAST_DAY(CAST('${GP_START_DT}' AS DATE))
            ),
            h.releasedate
        ) AS hold_days                                      -- 该段暂停天数
    FROM hold_resume_events h
    LEFT JOIN hold_resume_events r
        ON h.projectname = r.projectname
        AND r.type = 'HBMTProjectResumeRequest'
        AND h.rn = r.rn                                     -- 按序号配对
    WHERE h.type = 'HBMTProjectHoldRequest'
),

-- CTE4: 按项目汇总暂停总天数
project_hold_total AS (
    SELECT
        projectname,                                        -- 项目名称
        COALESCE(SUM(hold_days), 0) AS total_hold_days      -- 暂停总天数
    FROM hold_resume_paired
    GROUP BY projectname
),

-- CTE5: 计算每个项目的开发周期（扣除暂停期）
project_dev_cycle AS (
    SELECT
        cp.productname,                                     -- 项目名称
        cp.hbmtpproductline,                                -- 产品线编码
        -- R4+R5: 开发周期 = (完成−立项) − 暂停总天数，单位=自然日
        DATEDIFF(cp.hbmtpproductionactualedate, cp.hbmtprojectcreatedate)
            - COALESCE(pht.total_hold_days, 0) AS dev_cycle_days  -- 开发周期(天)
    FROM completed_projects cp
    LEFT JOIN project_hold_total pht
        ON cp.productname = pht.projectname
),

-- CTE6: 产品线维度映射
project_with_dimension AS (
    SELECT
        pdc.productname,                                    -- 项目名称
        pdc.hbmtpproductline AS product_line_code,          -- 产品线编码
        -- 产品线中文名映射
        CASE pdc.hbmtpproductline
            WHEN 'A1' THEN 'TELECOM'
            WHEN 'A2' THEN '数通DATACOM'
            WHEN 'A3' THEN 'FTTx'
            WHEN 'A4' THEN '无线'
            WHEN 'Coherent' THEN '相干产品线'
            WHEN 'BOX' THEN 'BOX'
            WHEN 'Multimedia' THEN '多媒体'
            ELSE pdc.hbmtpproductline
        END AS product_line_name,                           -- 产品线名称
        -- R7: 事业部维度归类
        CASE
            WHEN pdc.hbmtpproductline IN ('BOX', 'Multimedia') THEN '终端'
            WHEN pdc.hbmtpproductline IN ('A1', 'A2', 'A3', 'A4', 'Coherent') THEN '光模块'
            ELSE '其他'
        END AS business_division,                           -- 事业部维度
        pdc.dev_cycle_days                                  -- 开发周期(天)
    FROM project_dev_cycle pdc
)

-- 最终聚合: 按产品线×月汇总
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m')                  AS dt_month,             -- 统计月份
    pwd.product_line_code                                   AS product_line_code,    -- 产品线编码
    pwd.product_line_name                                   AS product_line_name,    -- 产品线名称
    pwd.business_division                                   AS business_division,    -- 事业部维度
    COUNT(*)                                                AS project_count,        -- 当月完成项目数量
    SUM(pwd.dev_cycle_days)                                 AS total_dev_cycle_days, -- 开发周期总天数
    ROUND(AVG(pwd.dev_cycle_days), 1)                       AS avg_dev_cycle_days,   -- 平均开发周期(天,R9:1位小数)
    NOW()                                                   AS etl_time              -- ETL加载时间
FROM project_with_dimension pwd
GROUP BY
    pwd.product_line_code,
    pwd.product_line_name,
    pwd.business_division;
