-- ============================================================================
-- 脚本名称：ads_ipd_ipm_rili_ajhwcl_result_dd.sql
-- 功能描述：退市按计划执行率 - ADS结果层
-- 目标表：ads.ads_ipd_ipm_rili_ajhwcl_result_dd（已有表，不建表）
-- 数据源：
--   dws.dws_ipd_ipm_rili_ajhwcl_detail_dd（退市按计划执行率明细）
--   dim.dim_ipd_td_weidu_nd（维度配置-营销部列表，zhibiao='事业部'）
-- 产品线：海信日立（中央空调）
-- 粒度：月×date_type×data_type×product_line×in_out_sale×dimension_1×dimension_2×dimension_3
-- 更新策略：DELETE当月 + INSERT
-- 调度参数：${GP_START_DT}（脚本执行日期前一天，yyyymmdd）
-- 业务规则：
--   1. numerator = 按时完成的DISTINCT销售型号编码数
--   2. denominator = 全部DISTINCT销售型号编码数
--   3. act_value = numerator / NULLIF(denominator, 0)
--   4. date_type='月'取当月数据，date_type='年'取当年1月~当月累计
--   5. 维度交叉：总体/PM/营销部，通过UNION ALL生成多组
--   6. 营销部维度下钻渠道（dimension_3），仅特定营销部+渠道组合
-- 创建时间：2026-07-13
-- ============================================================================

-- 删除当月数据（幂等）
DELETE FROM ads.ads_ipd_ipm_rili_ajhwcl_result_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

-- 插入当月数据
INSERT INTO ads.ads_ipd_ipm_rili_ajhwcl_result_dd(
    dt_month                    -- 统计月份
    ,date_type                  -- 日期类型（月/年）
    ,data_type                  -- 数据类型（停签/停产/上市）
    ,product_line               -- 产品线
    ,in_out_sale                -- 内外销
    ,dimension_1                -- 维度1（总体/PM/营销部）
    ,dimension_2                -- 维度2（具体值）
    ,dimension_3                -- 维度3（渠道/总体/NULL）
    ,numerator                  -- 分子（按时完成型号数）
    ,denominator                -- 分母（总型号数）
    ,act_value                  -- 实际值（执行率）
    ,plan_value                 -- 计划值（本指标无，NULL）
    ,completion_rate            -- 完成率（本指标无，NULL）
    ,load_dt                    -- 加载时间
)

WITH
-- ============================================================================
-- CTE1: dws_data
-- 用途：读取DWS明细数据，支持月度和年累两种口径
-- ============================================================================
dws_data AS (
    SELECT
        dt_month                                                   -- 统计月份
        ,data_type                                                 -- 数据类型
        ,in_out_sale                                               -- 内外销
        ,salemodelcode                                             -- 销售型号编码
        ,marketing_department                                      -- 归属营销部
        ,channel                                                   -- 渠道
        ,productmanager                                            -- 产品经理
        ,is_aqwc                                                   -- 是否按时完成
    FROM dws.dws_ipd_ipm_rili_ajhwcl_detail_dd
    WHERE dt_month >= CONCAT(LEFT(DATE_FORMAT('${GP_START_DT}', '%Y%m'), 4), '01')
      AND dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
),

-- ============================================================================
-- CTE2: channel_config
-- 用途：营销部×渠道下钻配置（仅这些组合才生成渠道明细行）
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
-- CTE3: weidu_dept
-- 用途：全部营销部列表（确保结果表涵盖所有配置营销部，即使无数据也补零）
-- 数据源：dim.dim_ipd_td_weidu_nd WHERE zhibiao='事业部'
-- ============================================================================
weidu_dept AS (
    SELECT DISTINCT udp1 AS marketing_department
    FROM dim.dim_ipd_td_weidu_nd
    WHERE zhibiao = '事业部'
),

-- ============================================================================
-- CTE4: data_type_list
-- 用途：生成data_type维度（停签/停产/上市），用于CROSS JOIN补零
-- ============================================================================
data_type_list AS (
    SELECT '停签' AS data_type
    UNION ALL SELECT '停产'
    UNION ALL SELECT '上市'
),

-- ============================================================================
-- CTE3: agg_result
-- 用途：多维度聚合
-- 组1：总体维度（dimension_1='总体', dimension_2='总体', dimension_3=NULL）
-- 组2：PM维度（dimension_1='PM', dimension_2=产品经理, dimension_3=NULL）
-- 组3：营销部维度-总体（dimension_1='营销部', dimension_2=营销部, dimension_3='总体'）
-- 组4：营销部维度-渠道明细（dimension_1='营销部', dimension_2=营销部, dimension_3=渠道）
-- 每组内区分 date_type='月' 和 date_type='年'
-- ============================================================================
agg_result AS (

    -- ========== 组1：总体维度 - 月 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month        -- 统计月份
        ,'月'                                    AS date_type       -- 月度
        ,data_type                                                 -- 数据类型
        ,'中央空调'                              AS product_line    -- 产品线
        ,'全部'                                  AS in_out_sale     -- 内外销（不区分）
        ,'总体'                                  AS dimension_1     -- 维度1
        ,'总体'                                  AS dimension_2     -- 维度2
        ,NULL                                    AS dimension_3     -- 维度3
        ,COUNT(DISTINCT CASE WHEN is_aqwc = 'Y'
             THEN salemodelcode END)             AS numerator       -- 按时完成数
        ,COUNT(DISTINCT salemodelcode)           AS denominator     -- 总数
    FROM dws_data
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY data_type

    UNION ALL

    -- ========== 组1：总体维度 - 年 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'总体'                                  AS dimension_1
        ,'总体'                                  AS dimension_2
        ,NULL                                    AS dimension_3
        ,COUNT(DISTINCT CASE WHEN is_aqwc = 'Y'
             THEN salemodelcode END)             AS numerator
        ,COUNT(DISTINCT salemodelcode)           AS denominator
    FROM dws_data
    GROUP BY data_type

    UNION ALL

    -- ========== 组2：PM维度 - 月 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'PM'                                    AS dimension_1
        ,productmanager                          AS dimension_2
        ,NULL                                    AS dimension_3
        ,COUNT(DISTINCT CASE WHEN is_aqwc = 'Y'
             THEN salemodelcode END)             AS numerator
        ,COUNT(DISTINCT salemodelcode)           AS denominator
    FROM dws_data
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
      AND productmanager IS NOT NULL
    GROUP BY data_type, productmanager

    UNION ALL

    -- ========== 组2：PM维度 - 年 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'PM'                                    AS dimension_1
        ,productmanager                          AS dimension_2
        ,NULL                                    AS dimension_3
        ,COUNT(DISTINCT CASE WHEN is_aqwc = 'Y'
             THEN salemodelcode END)             AS numerator
        ,COUNT(DISTINCT salemodelcode)           AS denominator
    FROM dws_data
    WHERE productmanager IS NOT NULL
    GROUP BY data_type, productmanager

    UNION ALL

    -- ========== 组3：营销部维度-总体 - 月（全部配置营销部，补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,wd.marketing_department                 AS dimension_2
        ,'总体'                                  AS dimension_3
        ,COUNT(DISTINCT CASE WHEN d.is_aqwc = 'Y'
             THEN d.salemodelcode END)           AS numerator
        ,COUNT(DISTINCT d.salemodelcode)         AS denominator
    FROM weidu_dept wd
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data d
        ON d.marketing_department = wd.marketing_department
       AND d.data_type = dt.data_type
       AND d.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY dt.data_type, wd.marketing_department

    UNION ALL

    -- ========== 组3：营销部维度-总体 - 年（全部配置营销部，补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,wd.marketing_department                 AS dimension_2
        ,'总体'                                  AS dimension_3
        ,COUNT(DISTINCT CASE WHEN d.is_aqwc = 'Y'
             THEN d.salemodelcode END)           AS numerator
        ,COUNT(DISTINCT d.salemodelcode)         AS denominator
    FROM weidu_dept wd
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data d
        ON d.marketing_department = wd.marketing_department
       AND d.data_type = dt.data_type
    GROUP BY dt.data_type, wd.marketing_department

    UNION ALL

    -- ========== 组3.5：事业部合计 - 月 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,'合计'                                  AS dimension_2
        ,'总体'                                  AS dimension_3
        ,COUNT(DISTINCT CASE WHEN d.is_aqwc = 'Y'
             THEN d.salemodelcode END)           AS numerator
        ,COUNT(DISTINCT d.salemodelcode)         AS denominator
    FROM data_type_list dt
    LEFT JOIN (
        SELECT dws.* FROM dws_data dws
        INNER JOIN weidu_dept wd ON dws.marketing_department = wd.marketing_department
        WHERE dws.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    ) d ON d.data_type = dt.data_type
    GROUP BY dt.data_type

    UNION ALL

    -- ========== 组3.5：事业部合计 - 年 ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,'合计'                                  AS dimension_2
        ,'总体'                                  AS dimension_3
        ,COUNT(DISTINCT CASE WHEN d.is_aqwc = 'Y'
             THEN d.salemodelcode END)           AS numerator
        ,COUNT(DISTINCT d.salemodelcode)         AS denominator
    FROM data_type_list dt
    LEFT JOIN (
        SELECT dws.* FROM dws_data dws
        INNER JOIN weidu_dept wd ON dws.marketing_department = wd.marketing_department
    ) d ON d.data_type = dt.data_type
    GROUP BY dt.data_type

    UNION ALL

    -- ========== 组4：营销部维度-渠道明细 - 月（配置的营销部×渠道，补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'月'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,cc.marketing_department                 AS dimension_2
        ,cc.channel                              AS dimension_3
        ,COUNT(DISTINCT CASE WHEN d.is_aqwc = 'Y'
             THEN d.salemodelcode END)           AS numerator
        ,COUNT(DISTINCT d.salemodelcode)         AS denominator
    FROM channel_config cc
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data d
        ON d.marketing_department = cc.marketing_department
       AND d.channel = cc.channel
       AND d.data_type = dt.data_type
       AND d.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY dt.data_type, cc.marketing_department, cc.channel

    UNION ALL

    -- ========== 组4：营销部维度-渠道明细 - 年（配置的营销部×渠道，补零） ==========
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month
        ,'年'                                    AS date_type
        ,dt.data_type
        ,'中央空调'                              AS product_line
        ,'全部'                                  AS in_out_sale
        ,'营销部'                                AS dimension_1
        ,cc.marketing_department                 AS dimension_2
        ,cc.channel                              AS dimension_3
        ,COUNT(DISTINCT CASE WHEN d.is_aqwc = 'Y'
             THEN d.salemodelcode END)           AS numerator
        ,COUNT(DISTINCT d.salemodelcode)         AS denominator
    FROM channel_config cc
    CROSS JOIN data_type_list dt
    LEFT JOIN dws_data d
        ON d.marketing_department = cc.marketing_department
       AND d.channel = cc.channel
       AND d.data_type = dt.data_type
    GROUP BY dt.data_type, cc.marketing_department, cc.channel
)

-- ============================================================================
-- 最终输出：计算act_value，补充NULL字段
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
    ,numerator                                                     -- 分子
    ,denominator                                                   -- 分母
    ,ROUND(numerator / NULLIF(denominator, 0), 4) AS act_value     -- 实际值（执行率）
    ,NULL                                       AS plan_value      -- 计划值（无）
    ,NULL                                       AS completion_rate -- 完成率（无）
    ,NOW()                                      AS load_dt         -- 加载时间
FROM agg_result
;
