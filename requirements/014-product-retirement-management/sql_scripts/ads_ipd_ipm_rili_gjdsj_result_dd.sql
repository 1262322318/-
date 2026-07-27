-- ============================================================================
-- 脚本名称：ads_ipd_ipm_rili_gjdsj_result_dd.sql
-- 功能描述：退市周期缩减率 - ADS结果层
-- 目标表：ads.ads_ipd_ipm_rili_gjdsj_result_dd（已有表，不建表）
-- 数据源：
--   dws.dws_ipd_ipm_rili_gjdsj_detail_dd（退市周期缩减率明细）
--   dim.dim_ipd_td_weidu_nd（维度配置-营销部列表，zhibiao='事业部'）
-- 产品线：海信日立（中央空调）
-- 粒度：月×date_type×data_type×product_line×in_out_sale×dimension_1×dimension_2×dimension_3
-- 更新策略：DELETE当月 + INSERT
-- 调度参数：${GP_START_DT}（脚本执行日期前一天，yyyymmdd）
-- 业务规则：
--   1. numerator = 本期平均退市周期用时（AVG天数）
--   2. denominator = 去年同期平均退市周期用时（AVG天数）
--   3. act_value = numerator / NULLIF(denominator, 0)（缩减率）
--      缩减率<1说明周期缩短（改善），>1说明周期延长（恶化）
--   4. date_type='月'取当月数据，date_type='年'取当年1月~当月累计
--   5. 维度交叉：总体/营销部（含渠道子维度）
--   6. 营销部维度用CROSS JOIN补零，确保所有配置营销部都有行
--   7. 渠道为营销部子维度（dimension_3），仅特定营销部×渠道组合下钻
-- 创建时间：2026-07-13
-- ============================================================================

-- 删除当月数据（幂等）
DELETE FROM ads.ads_ipd_ipm_rili_gjdsj_result_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

-- 插入当月数据
INSERT INTO ads.ads_ipd_ipm_rili_gjdsj_result_dd(
    dt_month                    -- 统计月份
    ,date_type                  -- 日期类型（月/年）
    ,data_type                  -- 数据类型（预停签-停签/停签-停产）
    ,product_line               -- 产品线
    ,in_out_sale                -- 内外销
    ,dimension_1                -- 维度1（总体/营销部）
    ,dimension_2                -- 维度2（具体值）
    ,dimension_3                -- 维度3（渠道/总体/NULL）
    ,numerator                  -- 分子（本期平均天数）
    ,denominator                -- 分母（去年同期平均天数）
    ,act_value                  -- 实际值（缩减率）
    ,plan_value                 -- 计划值（本指标无，NULL）
    ,completion_rate            -- 完成率（本指标无，NULL）
    ,load_dt                    -- 加载时间
)

WITH
-- ============================================================================
-- CTE1: dws_data_current
-- 用途：读取当年DWS明细数据（支持月度和年累）
-- ============================================================================
dws_data_current AS (
    SELECT
        dt_month                                                   -- 统计月份
        ,data_type                                                 -- 数据类型
        ,salemodelcode                                             -- 销售型号编码
        ,marketing_department                                      -- 归属营销部
        ,channel                                                   -- 渠道
        ,yutingqian_tingqian_d                                     -- 预停签→停签天数
        ,tingqian_tingchan_d                                       -- 停签→停产天数
    FROM dws.dws_ipd_ipm_rili_gjdsj_detail_dd
    WHERE dt_month >= CONCAT(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4), '01')
      AND dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
),

-- ============================================================================
-- CTE2: dws_data_lastyear
-- 用途：读取去年同期DWS明细数据（用于缩减率分母）
-- ============================================================================
dws_data_lastyear AS (
    SELECT
        dt_month                                                   -- 统计月份
        ,data_type                                                 -- 数据类型
        ,marketing_department                                      -- 归属营销部
        ,channel                                                   -- 渠道
        ,yutingqian_tingqian_d                                     -- 预停签→停签天数
        ,tingqian_tingchan_d                                       -- 停签→停产天数
    FROM dws.dws_ipd_ipm_rili_gjdsj_detail_dd
    WHERE dt_month >= CONCAT(CAST(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4) AS INT) - 1, '01')
      AND dt_month <= CONCAT(CAST(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4) AS INT) - 1,
                             RIGHT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 2))
),

-- ============================================================================
-- CTE3: channel_config
-- 用途：营销部×渠道下钻配置
-- ============================================================================
channel_config AS (
    SELECT '大客户' AS marketing_department, '地产' AS channel
    UNION ALL SELECT '海信商空营销部', '公建'
    UNION ALL SELECT '海信商空营销部', '家装'
    UNION ALL SELECT '海信商空营销部', '电商'
    UNION ALL SELECT '日立商空营销部', '公建'
    UNION ALL SELECT '日立商空营销部', '家装'
    UNION ALL SELECT '日立商空营销部', '电商'
    UNION ALL SELECT '约克商空营销部', '公建'
    UNION ALL SELECT '约克商空营销部', '家装'
),

-- ============================================================================
-- CTE4: weidu_dept
-- 用途：全部营销部列表（补零用）
-- ============================================================================
weidu_dept AS (
    SELECT DISTINCT udp1 AS marketing_department
    FROM dim.dim_ipd_td_weidu_nd
    WHERE zhibiao = '事业部'
),

-- ============================================================================
-- CTE5: data_type_list
-- 用途：data_type维度（用于CROSS JOIN补零）
-- ============================================================================
data_type_list AS (
    SELECT '预停签-停签' AS data_type
    UNION ALL SELECT '停签-停产'
),

-- ============================================================================
-- CTE6: lastyear_agg
-- 用途：预先聚合去年同期数据，避免相关子查询
-- ============================================================================
lastyear_agg AS (
    -- 总体维度-月
    SELECT
        'month' AS period_type
        ,'总体' AS dimension_1
        ,'总体' AS dimension_2
        ,NULL AS dimension_3
        ,data_type
        ,AVG(CASE WHEN data_type = '预停签-停签' THEN yutingqian_tingqian_d
                  WHEN data_type = '停签-停产' THEN tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear
    WHERE dt_month = CONCAT(CAST(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4) AS INT) - 1,
                            RIGHT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 2))
    GROUP BY data_type
    
    UNION ALL
    -- 总体维度-年
    SELECT
        'year' AS period_type
        ,'总体' AS dimension_1
        ,'总体' AS dimension_2
        ,NULL AS dimension_3
        ,data_type
        ,AVG(CASE WHEN data_type = '预停签-停签' THEN yutingqian_tingqian_d
                  WHEN data_type = '停签-停产' THEN tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear
    GROUP BY data_type
    
    UNION ALL
    -- 营销部-总体-月
    SELECT
        'month' AS period_type
        ,'营销部' AS dimension_1
        ,marketing_department AS dimension_2
        ,'总体' AS dimension_3
        ,data_type
        ,AVG(CASE WHEN data_type = '预停签-停签' THEN yutingqian_tingqian_d
                  WHEN data_type = '停签-停产' THEN tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear
    WHERE dt_month = CONCAT(CAST(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4) AS INT) - 1,
                            RIGHT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 2))
    GROUP BY data_type, marketing_department
    
    UNION ALL
    -- 营销部-总体-年
    SELECT
        'year' AS period_type
        ,'营销部' AS dimension_1
        ,marketing_department AS dimension_2
        ,'总体' AS dimension_3
        ,data_type
        ,AVG(CASE WHEN data_type = '预停签-停签' THEN yutingqian_tingqian_d
                  WHEN data_type = '停签-停产' THEN tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear
    GROUP BY data_type, marketing_department
    
    UNION ALL
    -- 事业部合计-月
    SELECT
        'month' AS period_type
        ,'营销部' AS dimension_1
        ,'合计' AS dimension_2
        ,'总体' AS dimension_3
        ,l.data_type
        ,AVG(CASE WHEN l.data_type = '预停签-停签' THEN l.yutingqian_tingqian_d
                  WHEN l.data_type = '停签-停产' THEN l.tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear l
    INNER JOIN weidu_dept wd ON l.marketing_department = wd.marketing_department
    WHERE l.dt_month = CONCAT(CAST(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4) AS INT) - 1,
                              RIGHT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 2))
    GROUP BY l.data_type
    
    UNION ALL
    -- 事业部合计-年
    SELECT
        'year' AS period_type
        ,'营销部' AS dimension_1
        ,'合计' AS dimension_2
        ,'总体' AS dimension_3
        ,l.data_type
        ,AVG(CASE WHEN l.data_type = '预停签-停签' THEN l.yutingqian_tingqian_d
                  WHEN l.data_type = '停签-停产' THEN l.tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear l
    INNER JOIN weidu_dept wd ON l.marketing_department = wd.marketing_department
    GROUP BY l.data_type
    
    UNION ALL
    -- 营销部-渠道-月
    SELECT
        'month' AS period_type
        ,'营销部' AS dimension_1
        ,marketing_department AS dimension_2
        ,channel AS dimension_3
        ,data_type
        ,AVG(CASE WHEN data_type = '预停签-停签' THEN yutingqian_tingqian_d
                  WHEN data_type = '停签-停产' THEN tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear
    WHERE dt_month = CONCAT(CAST(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4) AS INT) - 1,
                            RIGHT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 2))
    GROUP BY data_type, marketing_department, channel
    
    UNION ALL
    -- 营销部-渠道-年
    SELECT
        'year' AS period_type
        ,'营销部' AS dimension_1
        ,marketing_department AS dimension_2
        ,channel AS dimension_3
        ,data_type
        ,AVG(CASE WHEN data_type = '预停签-停签' THEN yutingqian_tingqian_d
                  WHEN data_type = '停签-停产' THEN tingqian_tingchan_d END) AS avg_days
    FROM dws_data_lastyear
    GROUP BY data_type, marketing_department, channel
),

-- ============================================================================
-- CTE7: agg_result
-- ============================================================================
agg_result AS (

    -- ========== 组1：总体维度 - 月 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,c.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'总体'                                  AS dimension_1
        ,'总体'                                  AS dimension_2
        ,NULL                                    AS dimension_3
        ,AVG(CASE WHEN c.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN c.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM dws_data_current c
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'month'
       AND ly.dimension_1 = '总体'
       AND ly.dimension_2 = '总体'
       AND ly.dimension_3 IS NULL
       AND ly.data_type = c.data_type
    WHERE c.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY c.data_type, ly.avg_days

    UNION ALL

    -- ========== 组1：总体维度 - 年 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,c.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'总体'                                  AS dimension_1
        ,'总体'                                  AS dimension_2
        ,NULL                                    AS dimension_3
        ,AVG(CASE WHEN c.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN c.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM dws_data_current c
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'year'
       AND ly.dimension_1 = '总体'
       AND ly.dimension_2 = '总体'
       AND ly.dimension_3 IS NULL
       AND ly.data_type = c.data_type
    GROUP BY c.data_type, ly.avg_days

    UNION ALL

    -- ========== 组2：营销部-总体 - 月（CROSS JOIN补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,wd.marketing_department                 AS dimension_2
        ,'总体'                                  AS dimension_3
        ,AVG(CASE WHEN dt.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN dt.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM weidu_dept wd
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data_current c
        ON c.marketing_department = wd.marketing_department
       AND c.data_type = dt.data_type
       AND c.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'month'
       AND ly.dimension_1 = '营销部'
       AND ly.dimension_2 = wd.marketing_department
       AND ly.dimension_3 = '总体'
       AND ly.data_type = dt.data_type
    GROUP BY dt.data_type, wd.marketing_department, ly.avg_days

    UNION ALL

    -- ========== 组2：营销部-总体 - 年（CROSS JOIN补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,wd.marketing_department                 AS dimension_2
        ,'总体'                                  AS dimension_3
        ,AVG(CASE WHEN dt.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN dt.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM weidu_dept wd
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data_current c
        ON c.marketing_department = wd.marketing_department
       AND c.data_type = dt.data_type
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'year'
       AND ly.dimension_1 = '营销部'
       AND ly.dimension_2 = wd.marketing_department
       AND ly.dimension_3 = '总体'
       AND ly.data_type = dt.data_type
    GROUP BY dt.data_type, wd.marketing_department, ly.avg_days

    UNION ALL

    -- ========== 组2.5：事业部合计 - 月 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,'合计'                                  AS dimension_2
        ,'总体'                                  AS dimension_3
        ,AVG(CASE WHEN dt.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN dt.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM data_type_list dt
    LEFT JOIN (
        SELECT dws.* FROM dws_data_current dws
        INNER JOIN weidu_dept wd ON dws.marketing_department = wd.marketing_department
        WHERE dws.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    ) c ON c.data_type = dt.data_type
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'month'
       AND ly.dimension_1 = '营销部'
       AND ly.dimension_2 = '合计'
       AND ly.dimension_3 = '总体'
       AND ly.data_type = dt.data_type
    GROUP BY dt.data_type, ly.avg_days

    UNION ALL

    -- ========== 组2.5：事业部合计 - 年 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,'合计'                                  AS dimension_2
        ,'总体'                                  AS dimension_3
        ,AVG(CASE WHEN dt.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN dt.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM data_type_list dt
    LEFT JOIN (
        SELECT dws.* FROM dws_data_current dws
        INNER JOIN weidu_dept wd ON dws.marketing_department = wd.marketing_department
    ) c ON c.data_type = dt.data_type
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'year'
       AND ly.dimension_1 = '营销部'
       AND ly.dimension_2 = '合计'
       AND ly.dimension_3 = '总体'
       AND ly.data_type = dt.data_type
    GROUP BY dt.data_type, ly.avg_days

    UNION ALL

    -- ========== 组3：营销部-渠道明细 - 月（CROSS JOIN补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,cc.marketing_department                 AS dimension_2
        ,cc.channel                              AS dimension_3
        ,AVG(CASE WHEN dt.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN dt.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM channel_config cc
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data_current c
        ON c.marketing_department = cc.marketing_department
       AND c.channel = cc.channel
       AND c.data_type = dt.data_type
       AND c.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'month'
       AND ly.dimension_1 = '营销部'
       AND ly.dimension_2 = cc.marketing_department
       AND ly.dimension_3 = cc.channel
       AND ly.data_type = dt.data_type
    GROUP BY dt.data_type, cc.marketing_department, cc.channel, ly.avg_days

    UNION ALL

    -- ========== 组3：营销部-渠道明细 - 年（CROSS JOIN补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,cc.marketing_department                 AS dimension_2
        ,cc.channel                              AS dimension_3
        ,AVG(CASE WHEN dt.data_type = '预停签-停签' THEN c.yutingqian_tingqian_d
                  WHEN dt.data_type = '停签-停产' THEN c.tingqian_tingchan_d END)
                                                 AS numerator
        ,ly.avg_days                             AS denominator
    FROM channel_config cc
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data_current c
        ON c.marketing_department = cc.marketing_department
       AND c.channel = cc.channel
       AND c.data_type = dt.data_type
    LEFT JOIN lastyear_agg ly
        ON ly.period_type = 'year'
       AND ly.dimension_1 = '营销部'
       AND ly.dimension_2 = cc.marketing_department
       AND ly.dimension_3 = cc.channel
       AND ly.data_type = dt.data_type
    GROUP BY dt.data_type, cc.marketing_department, cc.channel, ly.avg_days
)

-- ============================================================================
-- 最终输出：计算缩减率(act_value)
-- ============================================================================
SELECT
    dt_month                                                       -- 统计月份
    ,date_type                                                     -- 日期类型
    ,data_type                                                     -- 数据类型
    ,product_line                                                  -- 产品线
    ,in_out_sale                                                   -- 内外销
    ,dimension_1                                                   -- 维度1
    ,dimension_2                                                   -- 维度2
    ,dimension_3                                                   -- 维度3
    ,ROUND(numerator, 4)                        AS numerator       -- 本期平均天数
    ,ROUND(denominator, 4)                      AS denominator     -- 去年同期平均天数
    ,ROUND(numerator / NULLIF(denominator, 0), 4) AS act_value     -- 缩减率
    ,NULL                                       AS plan_value      -- 计划值（无）
    ,NULL                                       AS completion_rate -- 完成率（无）
    ,NOW()                                      AS load_dt         -- 加载时间
FROM agg_result
;
