/*
 * 脚本名称: dim_ipd_ipm_rili_syb_xm_shangshitime_dd.sql
 * 功能描述: 海信日立事业部与项目上市时间维度表
 *           计算事业部口径和事业部-项目口径的上市时间，展开为36个月对应年月
 * 需求编号: 015-rili-xpqd-migration
 * 创建时间: 2026-07-15
 * 依赖关系:
 *   输入: dim.dim_ipd_salemodel_dd（HDRP产品维度）
 *         dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd（自身，data_type='新品期月份'种子数据）
 *   输出: dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd（data_type='事业部'/'事业部-项目'）
 * 调度参数: ${GP_START_DT} = 调度日期（昨天，yyyymmdd）
 */

-- 删除当前批次的事业部和事业部-项目数据（保留种子数据）
DELETE FROM dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd
WHERE data_type IN ('事业部-项目', '事业部');

INSERT INTO dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd(
    data_type,              -- 口径
    marketing_department,   -- 事业部
    project_id,             -- 项目编码
    project_name,           -- 项目名称
    shangshi_time,          -- 上市时间
    n_month,                -- 第几月
    dt_month,               -- 对应月份
    load_dt                 -- 加载时间
)

-- CTE1: rili_model — 筛选新品范围（上市/预停签，1-36月内）
WITH rili_model AS (
    SELECT
        PG00068,                                                                -- 销售型号编码
        PG00061,                                                                -- 型号名称
        project_code,                                                           -- 项目编码
        project_name,                                                           -- 项目名称
        PG00025,                                                                -- 实际上市时间
        DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m') AS first_month,-- 首月
        TIMESTAMPDIFF(MONTH, PG00025, CAST('${GP_START_DT}' AS DATE)) AS shangshi_now_m, -- 上市月数
        PC20080 AS marketing_department,                                        -- 归属营销部（事业部）
        PG00057,                                                                -- 销售型号生命周期状态
        HX00327,                                                                -- 所有者（产品经理）
        HX00379,                                                                -- 是否模块组合
        PC20006                                                                 -- 标准品/定制产品
    FROM dim.dim_ipd_salemodel_dd
    WHERE PG00002 IN ('空气调节类产品', '外购产品')                              -- 产品大类
        AND PG00003 IN ('中央空调', '外购设备', '空气调节类配件')                -- 产品中类
        AND PG00004 IN ('单元式内机', '单元式外机', '多联机内机', '多联机外机',
                        '空气源热泵两联供', '空气源热泵三联供', '新风换气机', '热泵热水机') -- 产品小类
        AND PG00057 IN ('上市', '预停签')                                        -- 生命周期状态
        AND PG00025 IS NOT NULL                                                  -- 上市时间非空
        AND TIMESTAMPDIFF(MONTH, PG00025, CAST('${GP_START_DT}' AS DATE)) >= 1
        AND TIMESTAMPDIFF(MONTH, PG00025, CAST('${GP_START_DT}' AS DATE)) <= 36
        -- [待确认] 模块组合排除：AND HX00379 != '是'
        -- [待确认] 非标排除：AND PC20006 = '标准品'
)

-- CTE2: shangshitime_xm — 事业部-项目口径上市时间（取项目下最早上市时间）
,shangshitime_xm AS (
    SELECT
        project_code,                                                           -- 项目编码
        project_name,                                                           -- 项目名称
        marketing_department,                                                   -- 事业部
        MIN(PG00025) AS shangshi_time_xm                                        -- 项目口径上市时间
    FROM rili_model
    GROUP BY project_code, project_name, marketing_department
)

-- CTE3: shangshitime_syb — 事业部口径上市时间（取事业部下最早上市时间）
,shangshitime_syb AS (
    SELECT
        marketing_department,                                                   -- 事业部
        MIN(PG00025) AS shangshi_time_syb                                       -- 事业部口径上市时间
    FROM rili_model
    GROUP BY marketing_department
)

-- 输出1：事业部口径
SELECT
    '事业部' AS data_type,                                                      -- 口径
    t1.marketing_department,                                                    -- 事业部
    NULL AS project_id,                                                         -- 项目编码（事业部口径无）
    NULL AS project_name,                                                       -- 项目名称（事业部口径无）
    t1.shangshi_time_syb,                                                       -- 上市时间
    t2.n_month,                                                                 -- 第几月
    DATE_FORMAT(DATE_ADD(t1.shangshi_time_syb, INTERVAL CAST(t2.n_month AS INT) MONTH), '%Y%m'), -- 对应月份
    NOW()                                                                       -- 加载时间
FROM shangshitime_syb t1
CROSS JOIN (
    SELECT n_month
    FROM dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd
    WHERE data_type = '新品期月份'
) t2

UNION ALL

-- 输出2：事业部-项目口径
SELECT
    '事业部-项目' AS data_type,                                                 -- 口径
    t1.marketing_department,                                                    -- 事业部
    t1.project_code,                                                            -- 项目编码
    t1.project_name,                                                            -- 项目名称
    t1.shangshi_time_xm,                                                        -- 上市时间
    t2.n_month,                                                                 -- 第几月
    DATE_FORMAT(DATE_ADD(t1.shangshi_time_xm, INTERVAL CAST(t2.n_month AS INT) MONTH), '%Y%m'), -- 对应月份
    NOW()                                                                       -- 加载时间
FROM shangshitime_xm t1
CROSS JOIN (
    SELECT n_month
    FROM dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd
    WHERE data_type = '新品期月份'
) t2
;
