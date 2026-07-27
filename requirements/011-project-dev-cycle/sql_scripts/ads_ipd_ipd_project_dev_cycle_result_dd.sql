-- =====================================================================
-- 脚本名称：ads_ipd_ipd_project_dev_cycle_result_dd.sql
-- 目标表：ads.ads_ipd_ipd_project_dev_cycle_result_dd
-- 功能说明：应市项目平均开发周期结果表（按事业部×类型聚合，含目标值/完成率/同比改善）
-- 数据来源：dws.dws_ipd_ipd_project_dev_cycle_dd + 飞书目标值表
-- 更新策略：DELETE当月 + INSERT
-- 调度频率：月度
-- 三级域：管理集成产品开发/管理产品开发/整机产品开发
-- 变更记录：补全维度骨架，确保所有事业部×类型×时间类型组合都有输出行
-- =====================================================================

DELETE FROM ads.ads_ipd_ipd_project_dev_cycle_result_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

INSERT INTO ads.ads_ipd_ipd_project_dev_cycle_result_dd (
    dt_month,                      -- 统计月份（YYYYMM）
    hbmtpproductline,              -- 事业部（光模块/终端）
    derive_type_group,             -- 项目类型分组（PA/PB/PC/平均）
    dt_type,                       -- 时间范围类型（当月/年累）
    project_count,                 -- 项目数量
    avg_dev_cycle,                 -- 平均开发周期（天）
    target_value,                  -- 目标值（天）
    completion_rate,               -- 完成率 = 2 - 实际值/目标值
    last_year_value,               -- 同期值（去年同月平均开发周期）
    yoy_improvement,               -- 同比改善 = 1 - 实际值/同期值
    load_dt                        -- 加载时间
)
WITH
-- CTE0: 维度骨架 — 硬编码所有事业部×类型分组×时间类型的全组合
dim_combinations AS (
    SELECT pl.hbmtpproductline, tg.derive_type_group, dt.dt_type
    FROM (
        SELECT '光模块' AS hbmtpproductline
        UNION ALL SELECT '终端'
    ) pl
    CROSS JOIN (
        SELECT 'PA' AS derive_type_group
        UNION ALL SELECT 'PB'
        UNION ALL SELECT 'PC'
        UNION ALL SELECT '平均'
    ) tg
    CROSS JOIN (
        SELECT '当月' AS dt_type
        UNION ALL SELECT '年累'
    ) dt
),

-- CTE1: 当月聚合 — 按事业部×类型分组计算当月平均开发周期
current_month AS (
    SELECT
        hbmtpproductline,                                                    -- 事业部
        derive_type_group,                                                   -- 项目类型分组
        COUNT(*)                      AS project_count,                      -- 项目数量
        AVG(dev_cycle_days)           AS avg_dev_cycle                       -- 平均开发周期（天）
    FROM dws.dws_ipd_ipd_project_dev_cycle_dd
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY hbmtpproductline, derive_type_group
),

-- CTE2: 年累聚合 — 本年1月到当月，按事业部×类型分组计算累计平均开发周期
year_accum AS (
    SELECT
        hbmtpproductline,                                                    -- 事业部
        derive_type_group,                                                   -- 项目类型分组
        COUNT(*)                      AS project_count,                      -- 项目数量
        AVG(dev_cycle_days)           AS avg_dev_cycle                       -- 平均开发周期（天）
    FROM dws.dws_ipd_ipd_project_dev_cycle_dd
    WHERE dt_month >= CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y'), '01')      -- 本年1月起
      AND dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')                  -- 到当月止
    GROUP BY hbmtpproductline, derive_type_group
),

-- CTE3: 当月"平均"行 — 按事业部汇总所有类型的加权平均
current_month_avg AS (
    SELECT
        hbmtpproductline,                                                    -- 事业部
        '平均'                        AS derive_type_group,                  -- 固定为"平均"
        SUM(project_count)            AS project_count,                      -- 总项目数
        CASE WHEN SUM(project_count) > 0
            THEN SUM(avg_dev_cycle * project_count) / SUM(project_count)
            ELSE NULL
        END                           AS avg_dev_cycle                       -- 加权平均开发周期
    FROM current_month
    GROUP BY hbmtpproductline
),

-- CTE4: 年累"平均"行 — 按事业部汇总所有类型的加权平均
year_accum_avg AS (
    SELECT
        hbmtpproductline,                                                    -- 事业部
        '平均'                        AS derive_type_group,                  -- 固定为"平均"
        SUM(project_count)            AS project_count,                      -- 总项目数
        CASE WHEN SUM(project_count) > 0
            THEN SUM(avg_dev_cycle * project_count) / SUM(project_count)
            ELSE NULL
        END                           AS avg_dev_cycle                       -- 加权平均开发周期
    FROM year_accum
    GROUP BY hbmtpproductline
),

-- CTE5: 合并当月+年累实际数据（含各类型行和平均行）
actual_data AS (
    SELECT hbmtpproductline, derive_type_group, '当月' AS dt_type, project_count, avg_dev_cycle FROM current_month
    UNION ALL
    SELECT hbmtpproductline, derive_type_group, '当月' AS dt_type, project_count, avg_dev_cycle FROM current_month_avg
    UNION ALL
    SELECT hbmtpproductline, derive_type_group, '年累' AS dt_type, project_count, avg_dev_cycle FROM year_accum
    UNION ALL
    SELECT hbmtpproductline, derive_type_group, '年累' AS dt_type, project_count, avg_dev_cycle FROM year_accum_avg
),

-- CTE6: 目标值解析 — 从飞书多维表格JSON中提取目标值
target_data AS (
    SELECT
        JSON_EXTRACT_STRING(
            JSON_EXTRACT_STRING(record_data, '$.类型[0]'), '$.text'
        )                             AS productline,                        -- 事业部（终端/光模块事业部）
        JSON_EXTRACT_STRING(
            JSON_EXTRACT_STRING(record_data, '$.维度[0]'), '$.text'
        )                             AS type_group,                         -- 项目类型分组（PA/PB/PC/平均）
        CAST(JSON_EXTRACT_STRING(
            JSON_EXTRACT_STRING(record_data, '$.目标值[0]'), '$.text'
        ) AS DECIMAL(10,1))           AS target_value,                       -- 目标值（天）
        JSON_EXTRACT_STRING(
            JSON_EXTRACT_STRING(record_data, '$.时间[0]'), '$.text'
        )                             AS target_year                         -- 目标年份
    FROM ods.ODS_FEISHU_WIKI_LHK6WMDWWI3GFQK7ZIACKU3KNCB_TBLTRBIEBXRYRKO4
    WHERE JSON_EXTRACT_STRING(
            JSON_EXTRACT_STRING(record_data, '$.时间[0]'), '$.text'
        ) = DATE_FORMAT('${GP_START_DT}', '%Y')                              -- 当年目标
),

-- CTE7: 同期值 — 从ADS结果表取去年同月已计算的平均开发周期
last_year_all AS (
    SELECT
        hbmtpproductline,                                                    -- 事业部
        derive_type_group,                                                   -- 项目类型分组（含"平均"行）
        dt_type,                                                             -- 当月/年累
        avg_dev_cycle                 AS last_year_value                     -- 去年同期平均开发周期
    FROM ads.ads_ipd_ipd_project_dev_cycle_result_dd
    WHERE dt_month = DATE_FORMAT(DATE_SUB('${GP_START_DT}', INTERVAL 1 YEAR), '%Y%m')
)

-- 最终SELECT：以维度骨架为主，LEFT JOIN实际数据、目标值和同期值
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m')  AS dt_month,                      -- 统计月份
    dc.hbmtpproductline,                                                     -- 事业部
    dc.derive_type_group,                                                    -- 项目类型分组
    dc.dt_type,                                                              -- 当月/年累
    COALESCE(ad.project_count, 0)     AS project_count,                      -- 项目数量（无数据时为0）
    ROUND(ad.avg_dev_cycle, 1)        AS avg_dev_cycle,                      -- 平均开发周期（天）
    td.target_value,                                                         -- 目标值（天）
    CASE
        WHEN ad.avg_dev_cycle IS NOT NULL AND td.target_value IS NOT NULL AND td.target_value != 0
        THEN ROUND(2 - ad.avg_dev_cycle / td.target_value, 4)
        ELSE NULL
    END                               AS completion_rate,                    -- 完成率 = 2 - 实际/目标
    ROUND(ly.last_year_value, 1)      AS last_year_value,                    -- 同期值
    CASE
        WHEN ad.avg_dev_cycle IS NOT NULL AND ly.last_year_value IS NOT NULL AND ly.last_year_value != 0
        THEN ROUND(1 - ad.avg_dev_cycle / ly.last_year_value, 4)
        ELSE NULL
    END                               AS yoy_improvement,                    -- 同比改善 = 1 - 实际/同期
    NOW()                             AS load_dt                             -- 加载时间
FROM dim_combinations dc
LEFT JOIN actual_data ad
    ON dc.hbmtpproductline = ad.hbmtpproductline
    AND dc.derive_type_group = ad.derive_type_group
    AND dc.dt_type = ad.dt_type
LEFT JOIN target_data td
    ON dc.hbmtpproductline = td.productline
    AND dc.derive_type_group = td.type_group
LEFT JOIN last_year_all ly
    ON dc.hbmtpproductline = ly.hbmtpproductline
    AND dc.derive_type_group = ly.derive_type_group
    AND dc.dt_type = ly.dt_type
;
