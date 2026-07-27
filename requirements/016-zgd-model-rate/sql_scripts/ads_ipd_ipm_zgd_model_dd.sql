/*
 * 脚本名称: ads_ipd_ipm_zgd_model_dd.sql
 * 功能描述: 中高端型号数占比结果表（品牌×产品定位维度交叉统计）
 * 作者: Kiro Agent
 * 创建时间: 2026-07-20
 * 需求ID: 016-zgd-model-rate
 * 目标表: ads.ads_ipd_ipm_zgd_model_dd
 * 数据源:
 *   - dws.dws_ipd_ipm_dxhxl_detail_dd（上月：型号数+销量+销额）
 *   - dws.dws_ipd_ipm_sale_model_detail_dd（当月：仅型号数）
 *   - ods.odsmf_cm_tab28853（计划值）
 * 调度参数: ${GP_START_DT} = 脚本执行日期前一天（yyyymmdd）
 * 业务规则:
 *   1. 维度交叉：品牌(brand/总体) × 端位(低端/中端/高端/中高端)
 *   2. 视像科技仅做"中高端"维度，不做端位展开
 *   3. 汇总层：智慧生活BG(含视像) / 家电集团整体(不含视像)
 *   4. 计划值仅针对"型号数占比"，销量/收入占比无计划值
 */

-- ═══════════════════════════════════════════════════════════════════════════════
-- 段落1：上月实际值（3种zhibiao_type + 计划值LEFT JOIN）
-- 数据源：dws.dws_ipd_ipm_dxhxl_detail_dd
-- ═══════════════════════════════════════════════════════════════════════════════

DELETE FROM ads.ads_ipd_ipm_zgd_model_dd
WHERE zhibiao_type IN ('在销-品牌端位-销量占比','在销-品牌端位-型号数占比','在销-品牌端位-收入占比')
    AND dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    AND in_out_sale = '内销'
    AND product_line IN ('冰箱','冷柜','洗衣机','家用空调','视像科技');

INSERT INTO ads.ads_ipd_ipm_zgd_model_dd(
    zhibiao_type,                -- 数据类型
    dt_month,                    -- 月份
    dt_type,                     -- 日期维度
    product_line,                -- 产品线
    in_out_sale,                 -- 内外销
    dimension_1,                 -- 维度1（品牌）
    dimension_2,                 -- 维度2（产品定位）
    dimension_3,                 -- 维度3（不使用）
    act_num,                     -- 实际值
    all_num,                     -- 总数
    zhanbi,                      -- 占比
    plan_act_num,                -- 目标实际值
    plan_all_num,                -- 目标总数
    plan_zhanbi,                 -- 目标占比
    completionrate_act_num,      -- 实际值完成率
    completionrate_all_num,      -- 总数完成率
    completionrate_zhanbi,       -- 占比完成率
    load_dt                      -- 加载日期
)
WITH weidu_dimension_1 AS (
    SELECT '品牌' AS dimension_1
    UNION ALL
    SELECT '总体' AS dimension_1
)
,weidu_dimension_2 AS (
    SELECT '中高端' AS dimension_2
    UNION ALL
    SELECT '端位' AS dimension_2
)
-- 数据加工：非视像科技（冰箱/冷柜/洗衣机/家用空调）
,data_jiagong AS (
    SELECT
        t1.dt_month,                                                     -- 月份
        t1.dt_type,                                                      -- 日期维度
        t1.product_line,                                                 -- 产品线
        t1.in_out_sale,                                                  -- 内外销
        CASE WHEN t2.dimension_1 = '品牌' THEN t1.brand
             WHEN t2.dimension_1 = '总体' THEN '总体'
        END AS dimension_1,                                              -- 品牌维度
        CASE WHEN t3.dimension_2 = '端位' THEN
                CASE WHEN t1.chanpindingwei = '低档' THEN '低端'
                     WHEN t1.chanpindingwei = '中档' THEN '中端'
                     WHEN t1.chanpindingwei = '高档' THEN '高端'
                     ELSE t1.chanpindingwei
                END
             WHEN t3.dimension_2 = '中高端' THEN
                CASE WHEN t1.chanpindingwei = '低档' THEN '低端'
                     WHEN t1.chanpindingwei IN ('中档','中端','高档','高端') THEN '中高端'
                     ELSE t1.chanpindingwei
                END
        END AS dimension_2,                                              -- 产品定位维度
        t1.model,                                                        -- 产品型号（用于去重计数）
        t1.sales_qty,                                                    -- 销量
        t1.sales_amt,                                                    -- 销额
        CONCAT(t2.dimension_1, t3.dimension_2) AS datacopy               -- 辅助分区字段
    FROM dws.dws_ipd_ipm_dxhxl_detail_dd t1, weidu_dimension_1 t2, weidu_dimension_2 t3
    WHERE t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
        AND t1.product_line IN ('冰箱','冷柜','洗衣机','家用空调')
        AND t1.in_out_sale = '内销'
        AND t1.dt_type = '月'
        AND t1.is_project = 'N'
        AND t1.sales_type = '管报'

    UNION ALL

    -- 视像科技：仅中高端维度
    SELECT
        t1.dt_month,                                                     -- 月份
        t1.dt_type,                                                      -- 日期维度
        t1.product_line,                                                 -- 产品线
        t1.in_out_sale,                                                  -- 内外销
        CASE WHEN t2.dimension_1 = '品牌' THEN t1.brand
             WHEN t2.dimension_1 = '总体' THEN '总体'
        END AS dimension_1,                                              -- 品牌维度
        t1.chanpindingwei AS dimension_2,                                -- 视像科技保留原始产品定位
        t1.model,                                                        -- 产品型号
        t1.sales_qty,                                                    -- 销量
        t1.sales_amt,                                                    -- 销额
        CONCAT(t2.dimension_1, t3.dimension_2) AS datacopy               -- 辅助分区字段
    FROM dws.dws_ipd_ipm_dxhxl_detail_dd t1, weidu_dimension_1 t2, weidu_dimension_2 t3
    WHERE t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
        AND t1.product_line = '视像科技'
        AND t1.in_out_sale = '内销'
        AND t1.dt_type = '月'
        AND t1.is_project = 'N'
        AND t1.sales_type = '管报'
        AND t3.dimension_2 = '中高端'
)
-- 按品牌×端位聚合
,pinpai_duanwei AS (
    SELECT
        dt_month,                                                        -- 月份
        dt_type,                                                         -- 日期维度
        product_line,                                                    -- 产品线
        in_out_sale,                                                     -- 内外销
        dimension_1,                                                     -- 品牌维度
        dimension_2,                                                     -- 产品定位维度
        datacopy,                                                        -- 辅助分区字段
        COUNT(DISTINCT model) AS ct,                                     -- 型号去重数
        SUM(sales_qty) AS sales_qty,                                     -- 销量合计
        SUM(sales_amt) AS sales_amt                                      -- 销额合计
    FROM data_jiagong
    GROUP BY dt_month, dt_type, product_line, in_out_sale,
             dimension_1, dimension_2, datacopy
)

-- 承接第一段CTE：weidu_dimension_1, weidu_dimension_2, data_jiagong, pinpai_duanwei
-- 计划值CTE（非视像科技）
,plan_value AS (
    SELECT
        col_yuefen,                                                      -- 月份
        col_chanpinxian,                                                 -- 产品线
        col_neiwaixiao,                                                  -- 内外销
        CASE WHEN t2.dimension_1 = '总体' THEN '总体'
             ELSE col_pinpai
        END AS col_pinpai,                                               -- 品牌（总体/具体品牌）
        CASE WHEN t3.dimension_2 = '中高端' AND col_duanwei IN ('高端','中端') THEN '中高端'
             ELSE col_duanwei
        END AS col_duanwei,                                              -- 端位（中高端合并）
        CONCAT(t2.dimension_1, t3.dimension_2) AS datacopy,              -- 辅助分区字段
        SUM(col_xinghaoshu) AS col_xinghaoshu                            -- 型号数
    FROM ods.odsmf_cm_tab28853 t1, weidu_dimension_1 t2, weidu_dimension_2 t3
    WHERE t1.col_duanwei IN ('低端','中端','高端')
        AND col_chanpinxian <> '视像科技'
    GROUP BY col_yuefen, col_chanpinxian, col_neiwaixiao,
        CASE WHEN t2.dimension_1 = '总体' THEN '总体' ELSE col_pinpai END,
        CASE WHEN t3.dimension_2 = '中高端' AND col_duanwei IN ('高端','中端') THEN '中高端' ELSE col_duanwei END,
        CONCAT(t2.dimension_1, t3.dimension_2)
)
-- 计划值加工（算总数和占比）
,plan_jiagong AS (
    SELECT
        col_yuefen,                                                      -- 月份
        col_chanpinxian,                                                 -- 产品线
        col_neiwaixiao,                                                  -- 内外销
        col_pinpai,                                                      -- 品牌
        col_duanwei,                                                     -- 端位
        col_xinghaoshu,                                                  -- 计划型号数
        plan_zongshu AS col_zongshu,                                     -- 计划总型号数
        col_xinghaoshu / NULLIF(plan_zongshu, 0.0) AS col_zhanbi         -- 计划占比
    FROM (
        SELECT DISTINCT
            col_yuefen,
            col_chanpinxian,
            col_neiwaixiao,
            col_pinpai,
            col_duanwei,
            col_xinghaoshu,
            CASE WHEN col_pinpai = '总体'
                 THEN SUM(col_xinghaoshu) OVER(PARTITION BY col_yuefen, col_chanpinxian, col_neiwaixiao, datacopy)
                 ELSE SUM(col_xinghaoshu) OVER(PARTITION BY col_yuefen, col_chanpinxian, col_neiwaixiao, col_pinpai, datacopy)
            END AS plan_zongshu
        FROM plan_value
    ) t1

    UNION ALL

    -- 视像科技计划值（直接从源表读取，已有col_zongshu和col_zhanbi）
    SELECT
        col_yuefen,                                                      -- 月份
        col_chanpinxian,                                                 -- 产品线
        col_neiwaixiao,                                                  -- 内外销
        CASE WHEN col_pinpai = '全部' THEN '总体'
             ELSE col_pinpai
        END AS col_pinpai,                                               -- 品牌（全部→总体）
        col_duanwei,                                                     -- 端位
        col_xinghaoshu,                                                  -- 计划型号数
        col_zongshu,                                                     -- 计划总型号数
        col_zhanbi                                                       -- 计划占比
    FROM ods.odsmf_cm_tab28853
    WHERE col_chanpinxian = '视像科技'
)
-- 最终SELECT：3个UNION ALL
-- 1. 型号数占比（LEFT JOIN计划值）
SELECT DISTINCT
    '在销-品牌端位-型号数占比'                                            AS zhibiao_type,       -- 数据类型
    t1.dt_month                                                          AS dt_month,           -- 月份
    t1.dt_type                                                           AS dt_type,            -- 日期维度
    t1.product_line                                                      AS product_line,       -- 产品线
    t1.in_out_sale                                                       AS in_out_sale,        -- 内外销
    t1.dimension_1                                                       AS dimension_1,        -- 品牌维度
    t1.dimension_2                                                       AS dimension_2,        -- 产品定位维度
    NULL                                                                 AS dimension_3,        -- 维度3（不使用）
    t1.ct                                                                AS act_num,            -- 实际型号数
    SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type, t1.product_line,
        t1.in_out_sale, t1.dimension_1, t1.datacopy)                     AS all_num,            -- 总型号数
    t1.ct / NULLIF(SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type,
        t1.product_line, t1.in_out_sale, t1.dimension_1, t1.datacopy), 0) AS zhanbi,           -- 占比
    t2.col_xinghaoshu                                                    AS plan_act_num,       -- 目标型号数
    t2.col_zongshu                                                       AS plan_all_num,       -- 目标总数
    t2.col_zhanbi                                                        AS plan_zhanbi,        -- 目标占比
    t1.ct / NULLIF(t2.col_xinghaoshu, 0.0)                              AS completionrate_act_num, -- 实际值完成率
    SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type, t1.product_line,
        t1.in_out_sale, t1.dimension_1, t1.datacopy) / NULLIF(t2.col_zongshu, 0.0)
                                                                         AS completionrate_all_num, -- 总数完成率
    (t1.ct / NULLIF(SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type,
        t1.product_line, t1.in_out_sale, t1.dimension_1, t1.datacopy), 0))
        / NULLIF(t2.col_zhanbi, 0.0)                                    AS completionrate_zhanbi,  -- 占比完成率
    NOW()                                                                AS load_dt             -- 加载日期
FROM pinpai_duanwei t1
LEFT JOIN plan_jiagong t2
    ON t1.dt_month = t2.col_yuefen
    AND t1.product_line = t2.col_chanpinxian
    AND t1.in_out_sale = t2.col_neiwaixiao
    AND t1.dimension_1 = t2.col_pinpai
    AND t1.dimension_2 = t2.col_duanwei

UNION ALL

-- 2. 销量占比（无计划值）
SELECT DISTINCT
    '在销-品牌端位-销量占比'                                              AS zhibiao_type,       -- 数据类型
    dt_month                                                             AS dt_month,           -- 月份
    dt_type                                                              AS dt_type,            -- 日期维度
    product_line                                                         AS product_line,       -- 产品线
    in_out_sale                                                          AS in_out_sale,        -- 内外销
    dimension_1                                                          AS dimension_1,        -- 品牌维度
    dimension_2                                                          AS dimension_2,        -- 产品定位维度
    NULL                                                                 AS dimension_3,        -- 维度3
    sales_qty                                                            AS act_num,            -- 实际销量
    SUM(sales_qty) OVER(PARTITION BY dt_month, dt_type, product_line,
        in_out_sale, dimension_1, datacopy)                              AS all_num,            -- 总销量
    sales_qty / NULLIF(SUM(sales_qty) OVER(PARTITION BY dt_month, dt_type,
        product_line, in_out_sale, dimension_1, datacopy), 0)            AS zhanbi,             -- 占比
    NULL                                                                 AS plan_act_num,       -- 目标实际值（无）
    NULL                                                                 AS plan_all_num,       -- 目标总数（无）
    NULL                                                                 AS plan_zhanbi,        -- 目标占比（无）
    NULL                                                                 AS completionrate_act_num, -- 完成率（无）
    NULL                                                                 AS completionrate_all_num, -- 完成率（无）
    NULL                                                                 AS completionrate_zhanbi,  -- 完成率（无）
    NOW()                                                                AS load_dt             -- 加载日期
FROM pinpai_duanwei

UNION ALL

-- 3. 收入占比（无计划值）
SELECT DISTINCT
    '在销-品牌端位-收入占比'                                              AS zhibiao_type,       -- 数据类型
    dt_month                                                             AS dt_month,           -- 月份
    dt_type                                                              AS dt_type,            -- 日期维度
    product_line                                                         AS product_line,       -- 产品线
    in_out_sale                                                          AS in_out_sale,        -- 内外销
    dimension_1                                                          AS dimension_1,        -- 品牌维度
    dimension_2                                                          AS dimension_2,        -- 产品定位维度
    NULL                                                                 AS dimension_3,        -- 维度3
    sales_amt                                                            AS act_num,            -- 实际销额
    SUM(sales_amt) OVER(PARTITION BY dt_month, dt_type, product_line,
        in_out_sale, dimension_1, datacopy)                              AS all_num,            -- 总销额
    sales_amt / NULLIF(SUM(sales_amt) OVER(PARTITION BY dt_month, dt_type,
        product_line, in_out_sale, dimension_1, datacopy), 0)            AS zhanbi,             -- 占比
    NULL                                                                 AS plan_act_num,       -- 目标实际值（无）
    NULL                                                                 AS plan_all_num,       -- 目标总数（无）
    NULL                                                                 AS plan_zhanbi,        -- 目标占比（无）
    NULL                                                                 AS completionrate_act_num, -- 完成率（无）
    NULL                                                                 AS completionrate_all_num, -- 完成率（无）
    NULL                                                                 AS completionrate_zhanbi,  -- 完成率（无）
    NOW()                                                                AS load_dt             -- 加载日期
FROM pinpai_duanwei
;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 段落2：当月型号数占比（仅型号数，无销量/收入）
-- 数据源：dws.dws_ipd_ipm_sale_model_detail_dd
-- ═══════════════════════════════════════════════════════════════════════════════

DELETE FROM ads.ads_ipd_ipm_zgd_model_dd
WHERE zhibiao_type = '在销-品牌端位-型号数占比'
    AND dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND in_out_sale = '内销'
    AND product_line IN ('冰箱','冷柜','洗衣机','家用空调','视像科技');

INSERT INTO ads.ads_ipd_ipm_zgd_model_dd(
    zhibiao_type,                -- 数据类型
    dt_month,                    -- 月份
    dt_type,                     -- 日期维度
    product_line,                -- 产品线
    in_out_sale,                 -- 内外销
    dimension_1,                 -- 维度1（品牌）
    dimension_2,                 -- 维度2（产品定位）
    dimension_3,                 -- 维度3（不使用）
    act_num,                     -- 实际值
    all_num,                     -- 总数
    zhanbi,                      -- 占比
    plan_act_num,                -- 目标实际值
    plan_all_num,                -- 目标总数
    plan_zhanbi,                 -- 目标占比
    completionrate_act_num,      -- 实际值完成率
    completionrate_all_num,      -- 总数完成率
    completionrate_zhanbi,       -- 占比完成率
    load_dt                      -- 加载日期
)
WITH weidu_dimension_1 AS (
    SELECT '品牌' AS dimension_1
    UNION ALL
    SELECT '总体' AS dimension_1
)
,weidu_dimension_2 AS (
    SELECT '中高端' AS dimension_2
    UNION ALL
    SELECT '端位' AS dimension_2
)
-- 当月数据加工：非视像科技
,data_jiagong AS (
    SELECT
        t1.dt_month,                                                     -- 月份
        '月' AS dt_type,                                                 -- 日期维度
        t1.product_line,                                                 -- 产品线
        t1.in_out_sale,                                                  -- 内外销
        CASE WHEN t2.dimension_1 = '品牌' THEN t1.brand
             WHEN t2.dimension_1 = '总体' THEN '总体'
        END AS dimension_1,                                              -- 品牌维度
        CASE WHEN t3.dimension_2 = '端位' THEN
                CASE WHEN t1.chanpindingwei = '低档' THEN '低端'
                     WHEN t1.chanpindingwei = '中档' THEN '中端'
                     WHEN t1.chanpindingwei = '高档' THEN '高端'
                     ELSE t1.chanpindingwei
                END
             WHEN t3.dimension_2 = '中高端' THEN
                CASE WHEN t1.chanpindingwei = '低档' THEN '低端'
                     WHEN t1.chanpindingwei IN ('中档','中端','高档','高端') THEN '中高端'
                     ELSE t1.chanpindingwei
                END
        END AS dimension_2,                                              -- 产品定位维度
        t1.model,                                                        -- 产品型号
        CONCAT(t2.dimension_1, t3.dimension_2) AS datacopy               -- 辅助分区字段
    FROM dws.dws_ipd_ipm_sale_model_detail_dd t1, weidu_dimension_1 t2, weidu_dimension_2 t3
    WHERE t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND t1.product_line IN ('冰箱','冷柜','洗衣机','家用空调')
        AND t1.in_out_sale = '内销'
        AND t1.dt_type = '月'
        AND t1.is_project = 'N'

    UNION ALL

    -- 视像科技：仅中高端维度
    SELECT
        t1.dt_month,                                                     -- 月份
        '月' AS dt_type,                                                 -- 日期维度
        t1.product_line,                                                 -- 产品线
        t1.in_out_sale,                                                  -- 内外销
        CASE WHEN t2.dimension_1 = '品牌' THEN t1.brand
             WHEN t2.dimension_1 = '总体' THEN '总体'
        END AS dimension_1,                                              -- 品牌维度
        t1.chanpindingwei AS dimension_2,                                -- 视像科技保留原始产品定位
        t1.model,                                                        -- 产品型号
        CONCAT(t2.dimension_1, t3.dimension_2) AS datacopy               -- 辅助分区字段
    FROM dws.dws_ipd_ipm_sale_model_detail_dd t1, weidu_dimension_1 t2, weidu_dimension_2 t3
    WHERE t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND t1.product_line = '视像科技'
        AND t1.in_out_sale = '内销'
        AND t1.dt_type = '月'
        AND t1.is_project = 'N'
        AND t3.dimension_2 = '中高端'
)
-- 按品牌×端位聚合（仅型号数）
,pinpai_duanwei AS (
    SELECT
        dt_month,                                                        -- 月份
        dt_type,                                                         -- 日期维度
        product_line,                                                    -- 产品线
        in_out_sale,                                                     -- 内外销
        dimension_1,                                                     -- 品牌维度
        dimension_2,                                                     -- 产品定位维度
        datacopy,                                                        -- 辅助分区字段
        COUNT(DISTINCT model) AS ct                                      -- 型号去重数
    FROM data_jiagong
    GROUP BY dt_month, dt_type, product_line, in_out_sale,
             dimension_1, dimension_2, datacopy
)
-- 计划值（复用段落1相同逻辑）
,plan_value AS (
    SELECT
        col_yuefen,
        col_chanpinxian,
        col_neiwaixiao,
        CASE WHEN t2.dimension_1 = '总体' THEN '总体' ELSE col_pinpai END AS col_pinpai,
        CASE WHEN t3.dimension_2 = '中高端' AND col_duanwei IN ('高端','中端') THEN '中高端'
             ELSE col_duanwei
        END AS col_duanwei,
        CONCAT(t2.dimension_1, t3.dimension_2) AS datacopy,
        SUM(col_xinghaoshu) AS col_xinghaoshu
    FROM ods.odsmf_cm_tab28853 t1, weidu_dimension_1 t2, weidu_dimension_2 t3
    WHERE t1.col_duanwei IN ('低端','中端','高端')
        AND col_chanpinxian <> '视像科技'
    GROUP BY col_yuefen, col_chanpinxian, col_neiwaixiao,
        CASE WHEN t2.dimension_1 = '总体' THEN '总体' ELSE col_pinpai END,
        CASE WHEN t3.dimension_2 = '中高端' AND col_duanwei IN ('高端','中端') THEN '中高端' ELSE col_duanwei END,
        CONCAT(t2.dimension_1, t3.dimension_2)
)
,plan_jiagong AS (
    SELECT
        col_yuefen, col_chanpinxian, col_neiwaixiao, col_pinpai, col_duanwei,
        col_xinghaoshu,
        plan_zongshu AS col_zongshu,
        col_xinghaoshu / NULLIF(plan_zongshu, 0.0) AS col_zhanbi
    FROM (
        SELECT DISTINCT
            col_yuefen, col_chanpinxian, col_neiwaixiao, col_pinpai, col_duanwei, col_xinghaoshu,
            CASE WHEN col_pinpai = '总体'
                 THEN SUM(col_xinghaoshu) OVER(PARTITION BY col_yuefen, col_chanpinxian, col_neiwaixiao, datacopy)
                 ELSE SUM(col_xinghaoshu) OVER(PARTITION BY col_yuefen, col_chanpinxian, col_neiwaixiao, col_pinpai, datacopy)
            END AS plan_zongshu
        FROM plan_value
    ) t1

    UNION ALL

    SELECT
        col_yuefen, col_chanpinxian, col_neiwaixiao,
        CASE WHEN col_pinpai = '全部' THEN '总体' ELSE col_pinpai END AS col_pinpai,
        col_duanwei, col_xinghaoshu, col_zongshu, col_zhanbi
    FROM ods.odsmf_cm_tab28853
    WHERE col_chanpinxian = '视像科技'
)
-- 最终SELECT：当月仅型号数占比
SELECT DISTINCT
    '在销-品牌端位-型号数占比'                                            AS zhibiao_type,       -- 数据类型
    t1.dt_month                                                          AS dt_month,           -- 月份
    t1.dt_type                                                           AS dt_type,            -- 日期维度
    t1.product_line                                                      AS product_line,       -- 产品线
    t1.in_out_sale                                                       AS in_out_sale,        -- 内外销
    t1.dimension_1                                                       AS dimension_1,        -- 品牌维度
    t1.dimension_2                                                       AS dimension_2,        -- 产品定位维度
    NULL                                                                 AS dimension_3,        -- 维度3
    t1.ct                                                                AS act_num,            -- 实际型号数
    SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type, t1.product_line,
        t1.in_out_sale, t1.dimension_1, t1.datacopy)                     AS all_num,            -- 总型号数
    t1.ct / NULLIF(SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type,
        t1.product_line, t1.in_out_sale, t1.dimension_1, t1.datacopy), 0) AS zhanbi,           -- 占比
    t2.col_xinghaoshu                                                    AS plan_act_num,       -- 目标型号数
    t2.col_zongshu                                                       AS plan_all_num,       -- 目标总数
    t2.col_zhanbi                                                        AS plan_zhanbi,        -- 目标占比
    t1.ct / NULLIF(t2.col_xinghaoshu, 0.0)                              AS completionrate_act_num, -- 实际值完成率
    SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type, t1.product_line,
        t1.in_out_sale, t1.dimension_1, t1.datacopy) / NULLIF(t2.col_zongshu, 0.0)
                                                                         AS completionrate_all_num, -- 总数完成率
    (t1.ct / NULLIF(SUM(t1.ct) OVER(PARTITION BY t1.dt_month, t1.dt_type,
        t1.product_line, t1.in_out_sale, t1.dimension_1, t1.datacopy), 0))
        / NULLIF(t2.col_zhanbi, 0.0)                                    AS completionrate_zhanbi,  -- 占比完成率
    NOW()                                                                AS load_dt             -- 加载日期
FROM pinpai_duanwei t1
LEFT JOIN plan_jiagong t2
    ON t1.dt_month = t2.col_yuefen
    AND t1.product_line = t2.col_chanpinxian
    AND t1.in_out_sale = t2.col_neiwaixiao
    AND t1.dimension_1 = t2.col_pinpai
    AND t1.dimension_2 = t2.col_duanwei
;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 段落3：未来月份计划值（仅型号数占比，当月之后同年）
-- ═══════════════════════════════════════════════════════════════════════════════

DELETE FROM ads.ads_ipd_ipm_zgd_model_dd
WHERE zhibiao_type = '在销-品牌端位-型号数占比'
    AND dt_month > DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND in_out_sale = '内销'
    AND product_line IN ('冰箱','冷柜','洗衣机','家用空调','视像科技');

INSERT INTO ads.ads_ipd_ipm_zgd_model_dd(
    zhibiao_type,                -- 数据类型
    dt_month,                    -- 月份
    dt_type,                     -- 日期维度
    product_line,                -- 产品线
    in_out_sale,                 -- 内外销
    dimension_1,                 -- 维度1（品牌）
    dimension_2,                 -- 维度2（产品定位）
    dimension_3,                 -- 维度3（不使用）
    plan_act_num,                -- 目标实际值
    plan_all_num,                -- 目标总数
    plan_zhanbi,                 -- 目标占比
    load_dt                      -- 加载日期
)
WITH weidu_dimension_1 AS (
    SELECT '品牌' AS dimension_1 UNION ALL SELECT '总体' AS dimension_1
)
,weidu_dimension_2 AS (
    SELECT '中高端' AS dimension_2 UNION ALL SELECT '端位' AS dimension_2
)
,plan_value AS (
    SELECT
        col_yuefen, col_chanpinxian, col_neiwaixiao,
        CASE WHEN t2.dimension_1 = '总体' THEN '总体' ELSE col_pinpai END AS col_pinpai,
        CASE WHEN t3.dimension_2 = '中高端' AND col_duanwei IN ('高端','中端') THEN '中高端'
             ELSE col_duanwei
        END AS col_duanwei,
        CONCAT(t2.dimension_1, t3.dimension_2) AS datacopy,
        SUM(col_xinghaoshu) AS col_xinghaoshu
    FROM ods.odsmf_cm_tab28853 t1, weidu_dimension_1 t2, weidu_dimension_2 t3
    WHERE t1.col_duanwei IN ('低端','中端','高端')
        AND col_chanpinxian <> '视像科技'
    GROUP BY col_yuefen, col_chanpinxian, col_neiwaixiao,
        CASE WHEN t2.dimension_1 = '总体' THEN '总体' ELSE col_pinpai END,
        CASE WHEN t3.dimension_2 = '中高端' AND col_duanwei IN ('高端','中端') THEN '中高端' ELSE col_duanwei END,
        CONCAT(t2.dimension_1, t3.dimension_2)
)
,plan_jiagong AS (
    SELECT
        col_yuefen, col_chanpinxian, col_neiwaixiao, col_pinpai, col_duanwei,
        col_xinghaoshu,
        plan_zongshu AS col_zongshu,
        col_xinghaoshu / NULLIF(plan_zongshu, 0.0) AS col_zhanbi
    FROM (
        SELECT DISTINCT
            col_yuefen, col_chanpinxian, col_neiwaixiao, col_pinpai, col_duanwei, col_xinghaoshu,
            CASE WHEN col_pinpai = '总体'
                 THEN SUM(col_xinghaoshu) OVER(PARTITION BY col_yuefen, col_chanpinxian, col_neiwaixiao, datacopy)
                 ELSE SUM(col_xinghaoshu) OVER(PARTITION BY col_yuefen, col_chanpinxian, col_neiwaixiao, col_pinpai, datacopy)
            END AS plan_zongshu
        FROM plan_value
    ) t1

    UNION ALL

    SELECT
        col_yuefen, col_chanpinxian, col_neiwaixiao,
        CASE WHEN col_pinpai = '全部' THEN '总体' ELSE col_pinpai END AS col_pinpai,
        col_duanwei, col_xinghaoshu, col_zongshu, col_zhanbi
    FROM ods.odsmf_cm_tab28853
    WHERE col_chanpinxian = '视像科技'
)
SELECT
    '在销-品牌端位-型号数占比'                                            AS zhibiao_type,       -- 数据类型
    col_yuefen                                                           AS dt_month,           -- 月份
    '月'                                                                 AS dt_type,            -- 日期维度
    col_chanpinxian                                                      AS product_line,       -- 产品线
    col_neiwaixiao                                                       AS in_out_sale,        -- 内外销
    col_pinpai                                                           AS dimension_1,        -- 品牌维度
    col_duanwei                                                          AS dimension_2,        -- 产品定位维度
    NULL                                                                 AS dimension_3,        -- 维度3
    col_xinghaoshu                                                       AS plan_act_num,       -- 目标型号数
    col_zongshu                                                          AS plan_all_num,       -- 目标总数
    col_zhanbi                                                           AS plan_zhanbi,        -- 目标占比
    NOW()                                                                AS load_dt             -- 加载日期
FROM plan_jiagong
WHERE col_yuefen > DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND SUBSTRING(col_yuefen, 1, 4) = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y')
;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 段落4：汇总层（智慧生活BG + 家电集团整体）
-- 数据源：自身表已写入的明细数据
-- ═══════════════════════════════════════════════════════════════════════════════

DELETE FROM ads.ads_ipd_ipm_zgd_model_dd
WHERE zhibiao_type IN ('在销-品牌端位-销量占比','在销-品牌端位-型号数占比','在销-品牌端位-收入占比')
    AND dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    AND product_line IN ('智慧生活BG','家电集团整体');

INSERT INTO ads.ads_ipd_ipm_zgd_model_dd(
    zhibiao_type,                -- 数据类型
    dt_month,                    -- 月份
    dt_type,                     -- 日期维度
    product_line,                -- 产品线
    in_out_sale,                 -- 内外销
    dimension_1,                 -- 维度1（品牌）
    dimension_2,                 -- 维度2（产品定位）
    dimension_3,                 -- 维度3（不使用）
    act_num,                     -- 实际值
    all_num,                     -- 总数
    zhanbi,                      -- 占比
    plan_act_num,                -- 目标实际值
    plan_all_num,                -- 目标总数
    plan_zhanbi,                 -- 目标占比
    completionrate_act_num,      -- 实际值完成率
    completionrate_all_num,      -- 总数完成率
    completionrate_zhanbi,       -- 占比完成率
    load_dt                      -- 加载日期
)
-- 智慧生活BG（含视像科技）：冰箱总体+冷柜总体+洗衣机总体+视像科技总体+家用空调Hisense
SELECT
    zhibiao_type,                                                                               -- 数据类型
    dt_month,                                                                                   -- 月份
    dt_type,                                                                                    -- 日期维度
    '智慧生活BG'                                                         AS product_line,       -- 产品线
    '全部'                                                               AS in_out_sale,        -- 内外销
    '总体'                                                               AS dimension_1,        -- 品牌维度
    dimension_2,                                                                                -- 产品定位维度
    NULL                                                                 AS dimension_3,        -- 维度3
    SUM(act_num)                                                         AS act_num,            -- 实际值
    SUM(all_num)                                                         AS all_num,            -- 总数
    SUM(act_num) / NULLIF(SUM(all_num), 0.0)                            AS zhanbi,             -- 占比
    SUM(plan_act_num)                                                    AS plan_act_num,       -- 目标实际值
    SUM(plan_all_num)                                                    AS plan_all_num,       -- 目标总数
    SUM(plan_act_num) / NULLIF(SUM(plan_all_num), 0.0)                  AS plan_zhanbi,        -- 目标占比
    SUM(act_num) / NULLIF(SUM(plan_act_num), 0.0)                       AS completionrate_act_num, -- 实际值完成率
    SUM(all_num) / NULLIF(SUM(plan_all_num), 0.0)                       AS completionrate_all_num, -- 总数完成率
    (SUM(act_num) / NULLIF(SUM(all_num), 0.0))
        / NULLIF(SUM(plan_act_num) / NULLIF(SUM(plan_all_num), 0.0), 0.0)
                                                                         AS completionrate_zhanbi,  -- 占比完成率
    NOW()                                                                AS load_dt             -- 加载日期
FROM ads.ads_ipd_ipm_zgd_model_dd
WHERE zhibiao_type IN ('在销-品牌端位-销量占比','在销-品牌端位-型号数占比','在销-品牌端位-收入占比')
    AND dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    AND in_out_sale = '内销'
    AND product_line IN ('冰箱','冷柜','洗衣机','家用空调','视像科技')
    AND CASE
        WHEN product_line IN ('冰箱','冷柜','洗衣机','视像科技') THEN dimension_1 = '总体'
        WHEN product_line = '家用空调' THEN dimension_1 = 'Hisense'
        ELSE FALSE
    END
GROUP BY zhibiao_type, dt_month, dt_type, dimension_2

UNION ALL

-- 家电集团整体（不含视像科技）：冰箱总体+冷柜总体+洗衣机总体+家用空调Hisense
SELECT
    zhibiao_type,                                                                               -- 数据类型
    dt_month,                                                                                   -- 月份
    dt_type,                                                                                    -- 日期维度
    '家电集团整体'                                                       AS product_line,       -- 产品线
    '全部'                                                               AS in_out_sale,        -- 内外销
    '总体'                                                               AS dimension_1,        -- 品牌维度
    dimension_2,                                                                                -- 产品定位维度
    NULL                                                                 AS dimension_3,        -- 维度3
    SUM(act_num)                                                         AS act_num,            -- 实际值
    SUM(all_num)                                                         AS all_num,            -- 总数
    SUM(act_num) / NULLIF(SUM(all_num), 0.0)                            AS zhanbi,             -- 占比
    SUM(plan_act_num)                                                    AS plan_act_num,       -- 目标实际值
    SUM(plan_all_num)                                                    AS plan_all_num,       -- 目标总数
    SUM(plan_act_num) / NULLIF(SUM(plan_all_num), 0.0)                  AS plan_zhanbi,        -- 目标占比
    SUM(act_num) / NULLIF(SUM(plan_act_num), 0.0)                       AS completionrate_act_num, -- 实际值完成率
    SUM(all_num) / NULLIF(SUM(plan_all_num), 0.0)                       AS completionrate_all_num, -- 总数完成率
    (SUM(act_num) / NULLIF(SUM(all_num), 0.0))
        / NULLIF(SUM(plan_act_num) / NULLIF(SUM(plan_all_num), 0.0), 0.0)
                                                                         AS completionrate_zhanbi,  -- 占比完成率
    NOW()                                                                AS load_dt             -- 加载日期
FROM ads.ads_ipd_ipm_zgd_model_dd
WHERE zhibiao_type IN ('在销-品牌端位-销量占比','在销-品牌端位-型号数占比','在销-品牌端位-收入占比')
    AND dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    AND in_out_sale = '内销'
    AND product_line IN ('冰箱','冷柜','洗衣机','家用空调')
    AND CASE
        WHEN product_line IN ('冰箱','冷柜','洗衣机') THEN dimension_1 = '总体'
        WHEN product_line = '家用空调' THEN dimension_1 = 'Hisense'
        ELSE FALSE
    END
GROUP BY zhibiao_type, dt_month, dt_type, dimension_2
;
