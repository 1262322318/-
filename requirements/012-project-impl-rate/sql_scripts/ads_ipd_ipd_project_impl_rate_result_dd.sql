-- =====================================================================
-- 脚本名称：ads_ipd_ipd_project_impl_rate_result_dd.sql
-- 目标表：ads.ads_ipd_ipd_project_impl_rate_result_dd
-- 功能说明：应市项目按计划实施率汇总表，按事业部×产品线 和 项目经理 两个维度聚合
-- 数据来源：dws.dws_ipd_ipd_project_impl_rate_dd
-- 更新策略：DELETE当月 + INSERT
-- 调度频率：月度
-- 计算公式：实施率 = (正常+结题) / (正常+延期+暂停+结题) × 100%
-- 变更记录：补全维度骨架，确保所有事业部×产品线组合都有输出行
-- =====================================================================

DELETE FROM ads.ads_ipd_ipd_project_impl_rate_result_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

INSERT INTO ads.ads_ipd_ipd_project_impl_rate_result_dd (
    dt_month,                          -- 统计月份（YYYYMM）
    dim_type,                          -- 维度类型（事业部产品线/事业部小计/项目经理）
    business_division,                 -- 事业部（光模块/终端）
    product_line_display,              -- 产品线展示名
    productowner,                      -- 项目经理（仅项目经理维度有值）
    total_count,                       -- 合计项目数（正常+延期+暂停+结题）
    normal_count,                      -- 正常项目数
    delay_count,                       -- 延期项目数
    hold_count,                        -- 暂停项目数（累计）
    cancel_count,                      -- 终止项目数（当月，不进分母）
    complete_count,                    -- 结题项目数（当月）
    impl_rate,                         -- 按计划实施率
    load_dt                            -- 加载时间
)
WITH
-- CTE0: 维度骨架 — 硬编码事业部×产品线的全组合
dim_bd_pl AS (
    SELECT '光模块' AS business_division, 'TELECOM' AS product_line_display
    UNION ALL SELECT '光模块', '数通DATACOM'
    UNION ALL SELECT '光模块', 'FTTx'
    UNION ALL SELECT '光模块', '无线'
    UNION ALL SELECT '光模块', '相干产品线'
    UNION ALL SELECT '终端', 'BOX'
    UNION ALL SELECT '终端', '多媒体'
),

-- CTE0b: 事业部骨架（用于小计行）
dim_bd AS (
    SELECT '光模块' AS business_division
    UNION ALL SELECT '终端'
),

-- CTE1: 事业部×产品线维度的实际聚合数据
agg_bd_pl AS (
    SELECT
        dt_month,                                                             -- 统计月份
        business_division,                                                    -- 事业部
        product_line_display,                                                 -- 产品线展示名
        SUM(CASE WHEN project_situation IN ('正常','延期','暂停','结题') THEN 1 ELSE 0 END) AS total_count,
        SUM(CASE WHEN project_situation = '正常' THEN 1 ELSE 0 END)   AS normal_count,
        SUM(CASE WHEN project_situation = '延期' THEN 1 ELSE 0 END)   AS delay_count,
        SUM(CASE WHEN project_situation = '暂停' THEN 1 ELSE 0 END)   AS hold_count,
        SUM(CASE WHEN project_situation = '终止' THEN 1 ELSE 0 END)   AS cancel_count,
        SUM(CASE WHEN project_situation = '结题' THEN 1 ELSE 0 END)   AS complete_count
    FROM dws.dws_ipd_ipd_project_impl_rate_dd
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY dt_month, business_division, product_line_display
),

-- CTE2: 事业部小计维度的实际聚合数据
agg_bd AS (
    SELECT
        dt_month,                                                             -- 统计月份
        business_division,                                                    -- 事业部
        SUM(CASE WHEN project_situation IN ('正常','延期','暂停','结题') THEN 1 ELSE 0 END) AS total_count,
        SUM(CASE WHEN project_situation = '正常' THEN 1 ELSE 0 END)   AS normal_count,
        SUM(CASE WHEN project_situation = '延期' THEN 1 ELSE 0 END)   AS delay_count,
        SUM(CASE WHEN project_situation = '暂停' THEN 1 ELSE 0 END)   AS hold_count,
        SUM(CASE WHEN project_situation = '终止' THEN 1 ELSE 0 END)   AS cancel_count,
        SUM(CASE WHEN project_situation = '结题' THEN 1 ELSE 0 END)   AS complete_count
    FROM dws.dws_ipd_ipd_project_impl_rate_dd
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY dt_month, business_division
)

-- ===== 第一段：事业部×产品线维度（维度骨架LEFT JOIN） =====
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m')        AS dt_month,             -- 统计月份
    '事业部产品线'                               AS dim_type,             -- 维度类型
    d.business_division,                                                  -- 事业部
    d.product_line_display,                                               -- 产品线展示名
    NULL                                         AS productowner,         -- 项目经理（本维度无值）
    COALESCE(a.total_count, 0)                   AS total_count,          -- 合计项目数
    COALESCE(a.normal_count, 0)                  AS normal_count,         -- 正常项目数
    COALESCE(a.delay_count, 0)                   AS delay_count,          -- 延期项目数
    COALESCE(a.hold_count, 0)                    AS hold_count,           -- 暂停项目数
    COALESCE(a.cancel_count, 0)                  AS cancel_count,         -- 终止项目数
    COALESCE(a.complete_count, 0)                AS complete_count,       -- 结题项目数
    CASE
        WHEN COALESCE(a.total_count, 0) = 0 THEN NULL
        ELSE CAST(
            (COALESCE(a.normal_count, 0) + COALESCE(a.complete_count, 0)) * 1.0
            / COALESCE(a.total_count, 0)
        AS DECIMALV3(10,4))
    END                                          AS impl_rate,            -- 按计划实施率
    NOW()                                        AS load_dt               -- 加载时间
FROM dim_bd_pl d
LEFT JOIN agg_bd_pl a
    ON d.business_division = a.business_division
    AND d.product_line_display = a.product_line_display

UNION ALL

-- ===== 第二段：事业部小计行（维度骨架LEFT JOIN） =====
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m')        AS dt_month,             -- 统计月份
    '事业部小计'                                 AS dim_type,             -- 维度类型
    d.business_division,                                                  -- 事业部
    '小计'                                       AS product_line_display, -- 产品线展示名（固定"小计"）
    NULL                                         AS productowner,         -- 项目经理（本维度无值）
    COALESCE(a.total_count, 0)                   AS total_count,          -- 合计项目数
    COALESCE(a.normal_count, 0)                  AS normal_count,         -- 正常项目数
    COALESCE(a.delay_count, 0)                   AS delay_count,          -- 延期项目数
    COALESCE(a.hold_count, 0)                    AS hold_count,           -- 暂停项目数
    COALESCE(a.cancel_count, 0)                  AS cancel_count,         -- 终止项目数
    COALESCE(a.complete_count, 0)                AS complete_count,       -- 结题项目数
    CASE
        WHEN COALESCE(a.total_count, 0) = 0 THEN NULL
        ELSE CAST(
            (COALESCE(a.normal_count, 0) + COALESCE(a.complete_count, 0)) * 1.0
            / COALESCE(a.total_count, 0)
        AS DECIMALV3(10,4))
    END                                          AS impl_rate,            -- 按计划实施率
    NOW()                                        AS load_dt               -- 加载时间
FROM dim_bd d
LEFT JOIN agg_bd a
    ON d.business_division = a.business_division

UNION ALL

-- ===== 第三段：项目经理维度（保持原样，无法穷举人员） =====
SELECT
    dt_month,                                                             -- 统计月份
    '项目经理'                                   AS dim_type,             -- 维度类型
    business_division,                                                    -- 事业部（项目经理所属）
    NULL                                         AS product_line_display, -- 产品线展示名（本维度无值）
    productowner,                                                         -- 项目经理
    SUM(CASE WHEN project_situation IN ('正常','延期','暂停','结题') THEN 1 ELSE 0 END) AS total_count,
    SUM(CASE WHEN project_situation = '正常' THEN 1 ELSE 0 END)   AS normal_count,    -- 正常项目数
    SUM(CASE WHEN project_situation = '延期' THEN 1 ELSE 0 END)   AS delay_count,     -- 延期项目数
    SUM(CASE WHEN project_situation = '暂停' THEN 1 ELSE 0 END)   AS hold_count,      -- 暂停项目数
    SUM(CASE WHEN project_situation = '终止' THEN 1 ELSE 0 END)   AS cancel_count,    -- 终止项目数
    SUM(CASE WHEN project_situation = '结题' THEN 1 ELSE 0 END)   AS complete_count,  -- 结题项目数
    CASE
        WHEN SUM(CASE WHEN project_situation IN ('正常','延期','暂停','结题') THEN 1 ELSE 0 END) = 0
            THEN NULL
        ELSE CAST(
            SUM(CASE WHEN project_situation IN ('正常','结题') THEN 1 ELSE 0 END) * 1.0
            / SUM(CASE WHEN project_situation IN ('正常','延期','暂停','结题') THEN 1 ELSE 0 END)
        AS DECIMALV3(10,4))
    END                                          AS impl_rate,            -- 按计划实施率
    NOW()                                        AS load_dt               -- 加载时间
FROM dws.dws_ipd_ipd_project_impl_rate_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
GROUP BY dt_month, business_division, productowner
;
