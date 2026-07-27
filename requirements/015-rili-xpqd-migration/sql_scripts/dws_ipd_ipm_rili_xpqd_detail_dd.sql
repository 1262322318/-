/*
 * 脚本名称: dws_ipd_ipm_rili_xpqd_detail_dd.sql
 * 功能描述: 海信日立上市三年期新品签单情况月度汇总明细
 *           关联规划量，计算签单/出货完成率，输出型号/项目/事业部三种口径
 * 需求编号: 015-rili-xpqd-migration
 * 创建时间: 2026-07-15
 * 依赖关系:
 *   输入: dim.dim_ipd_salemodel_dd（HDRP产品维度，取新品范围）
 *         dws.dws_ipd_ipm_rili_qdch_m_detail_dd（上游，data_type='型号口径-sap编码合计'）
 *         dwd.dwd_ipd_ipm_bp_lx_model_mid_dd（LX规划量）
 *   输出: dws.dws_ipd_ipm_rili_xpqd_detail_dd
 * 调度参数: ${GP_START_DT} = 调度日期（昨天，yyyymmdd）
 */

DELETE FROM dws.dws_ipd_ipm_rili_xpqd_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND data_type IN ('型号口径', '项目口径', '事业部口径');

INSERT INTO dws.dws_ipd_ipm_rili_xpqd_detail_dd(
    data_type,              -- 数据口径
    dt_month,               -- 月份
    in_out_sale,            -- 内外销
    sap_number,             -- sap编码
    prdct_model,            -- 型号名称
    project_name,           -- 项目名称
    project_id,             -- 项目编码
    shangshi_time,          -- 上市时间
    first_month,            -- 首月
    shangshi_now_m,         -- 统计周期
    marketing_department,   -- 营销部
    productmanager,         -- 产品经理
    guihuaxiaoliang_m,      -- 本月规划销量
    guihuaxiaoliang_lj,     -- 累计规划销量
    qiandan_m,              -- 本月签单量
    qiandan_lj,             -- 累计签单量
    qiandan_12m,            -- 上市12个月累计签单量
    qiandan_24m,            -- 上市24个月累计签单量
    qiandan_36m,            -- 上市36个月累计签单量
    chuhuo_m,               -- 本月出货量
    chuhuo_lj,              -- 累计出货量
    chuhuo_12m,             -- 上市12个月累计出货量
    chuhuo_24m,             -- 上市24个月累计出货量
    chuhuo_36m,             -- 上市36个月累计出货量
    ljqd_rate,              -- 累计签单量/累计规划量
    ljch_rate,              -- 累计出货量/累计规划量
    product_current,        -- 型号生命周期状态
    is_project,             -- 是否保护期
    dimension_1,            -- 维度1（口径）
    load_dt,                -- 加载时间
    salemodelcode             -- 维度2（销售型号编码）
)

-- CTE1: weidu_koujing — 三种口径维度
WITH weidu_koujing AS (
    SELECT '型号' AS koujing
    UNION ALL SELECT '项目' AS koujing
    UNION ALL SELECT '事业部' AS koujing
)

-- CTE2: rili_model — 新品型号范围（同DIM脚本逻辑）
,rili_model AS (
    SELECT
        PG00068 AS salemodelcode,                                                -- 销售型号编码
        PG00061 AS prdct_model,                                                 -- 型号名称
        project_name AS project_mingcheng,                                      -- 项目名称
        project_code AS project_id,                                             -- 项目编码
        PG00025 AS ha_pclmarkettime,                                            -- 上市时间
        TIMESTAMPDIFF(MONTH, PG00025, CAST('${GP_START_DT}' AS DATE)) AS shangshi_now_m, -- 上市月数
        PC20080 AS marketing_department,                                        -- 事业部
        PG00057 AS product_current,                                             -- 生命周期状态
        HX00327 AS productmanager                                               -- 产品经理
    FROM dim.dim_ipd_salemodel_dd
    WHERE PG00002 IN ('空气调节类产品', '外购产品')
        AND PG00003 IN ('中央空调', '外购设备', '空气调节类配件')
        AND PG00004 IN ('单元式内机', '单元式外机', '多联机内机', '多联机外机',
                        '空气源热泵两联供', '空气源热泵三联供', '新风换气机', '热泵热水机')
        AND PG00057 IN ('上市', '预停签')
        AND PG00025 IS NOT NULL
        AND TIMESTAMPDIFF(MONTH, PG00025, CAST('${GP_START_DT}' AS DATE)) >= 1
        AND TIMESTAMPDIFF(MONTH, PG00025, CAST('${GP_START_DT}' AS DATE)) <= 36
)

-- CTE3: guihuaxiaoliang_m — 本月规划销量（LX）
,guihuaxiaoliang_m AS (
    SELECT
        salemodelcode,                                                          -- 销售型号编码
        dt_month,                                                               -- 月份
        MAX(plan_sales_qty) AS plan_sales_qty                                   -- 本月规划销量（取MAX去重）
    FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
    WHERE plan_type = 'LX'
        AND product_big IN ('空气调节类产品')
        AND model_type = '销售型号编码口径'
        AND dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY salemodelcode, dt_month
)

-- CTE4: guihuaxiaoliang_lj — 累计规划销量（LX，从首月到当月）
,guihuaxiaoliang_lj AS (
    SELECT
        salemodelcode,                                                          -- 销售型号编码
        SUM(plan_sales_qty) AS plan_sales_qty                                   -- 累计规划销量
    FROM (
        SELECT
            salemodelcode,
            dt_month,
            MAX(plan_sales_qty) AS plan_sales_qty
        FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
        WHERE plan_type = 'LX'
            AND product_big IN ('空气调节类产品')
            AND model_type = '销售型号编码口径'
            AND dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
        GROUP BY salemodelcode, dt_month
    ) a
    GROUP BY salemodelcode
)

-- 最终SELECT：通过CROSS JOIN weidu_koujing 一次生成三种口径
SELECT
    CONCAT(t5.koujing, '口径') AS data_type,                                    -- 数据口径
    DATE_FORMAT('${GP_START_DT}', '%Y%m') AS dt_month,                          -- 月份
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t2.in_out_sale END AS in_out_sale, -- 内外销
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t2.sap_number END AS sap_number,  -- sap编码（物料编码）
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.prdct_model END AS prdct_model, -- 型号名称
    CASE WHEN t5.koujing IN ('事业部') THEN NULL ELSE t1.project_mingcheng END AS project_name, -- 项目名称
    CASE WHEN t5.koujing IN ('事业部') THEN NULL ELSE t1.project_id END AS project_id,          -- 项目编码
    MIN(t1.ha_pclmarkettime) AS shangshi_time,                                  -- 上市时间
    DATE_FORMAT(DATE_ADD(MIN(t1.ha_pclmarkettime), INTERVAL 1 MONTH), '%Y%m') AS first_month, -- 首月
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.shangshi_now_m END AS shangshi_now_m, -- 统计周期
    t1.marketing_department,                                                    -- 营销部
    CASE WHEN t5.koujing IN ('事业部') THEN NULL ELSE MAX(t1.productmanager) END AS productmanager, -- 产品经理
    SUM(t3.plan_sales_qty) AS guihuaxiaoliang_m,                                -- 本月规划销量
    SUM(t4.plan_sales_qty) AS guihuaxiaoliang_lj,                               -- 累计规划销量
    SUM(t2.qiandan_m) AS qiandan_m,                                             -- 本月签单量
    SUM(t2.qiandan_lj) AS qiandan_lj,                                           -- 累计签单量
    SUM(CASE
        WHEN t5.koujing = '事业部' THEN t2.qiandan_12m_syb
        WHEN t5.koujing = '项目' THEN t2.qiandan_12m_xm
        ELSE t2.qiandan_12m
    END) AS qiandan_12m,                                                        -- 上市12个月签单量
    SUM(CASE
        WHEN t5.koujing = '事业部' THEN t2.qiandan_24m_syb
        WHEN t5.koujing = '项目' THEN t2.qiandan_24m_xm
        ELSE t2.qiandan_24m
    END) AS qiandan_24m,                                                        -- 上市24个月签单量
    SUM(CASE
        WHEN t5.koujing = '事业部' THEN t2.qiandan_36m_syb
        WHEN t5.koujing = '项目' THEN t2.qiandan_36m_xm
        ELSE t2.qiandan_36m
    END) AS qiandan_36m,                                                        -- 上市36个月签单量
    SUM(t2.chuhuo_m) AS chuhuo_m,                                               -- 本月出货量
    SUM(t2.chuhuo_lj) AS chuhuo_lj,                                             -- 累计出货量
    SUM(CASE
        WHEN t5.koujing = '事业部' THEN t2.chuhuo_12m_syb
        WHEN t5.koujing = '项目' THEN t2.chuhuo_12m_xm
        ELSE t2.chuhuo_12m
    END) AS chuhuo_12m,                                                         -- 上市12个月出货量
    SUM(CASE
        WHEN t5.koujing = '事业部' THEN t2.chuhuo_24m_syb
        WHEN t5.koujing = '项目' THEN t2.chuhuo_24m_xm
        ELSE t2.chuhuo_24m
    END) AS chuhuo_24m,                                                         -- 上市24个月出货量
    SUM(CASE
        WHEN t5.koujing = '事业部' THEN t2.chuhuo_36m_syb
        WHEN t5.koujing = '项目' THEN t2.chuhuo_36m_xm
        ELSE t2.chuhuo_36m
    END) AS chuhuo_36m,                                                         -- 上市36个月出货量
    SUM(t2.qiandan_lj) / NULLIF(COALESCE(SUM(t4.plan_sales_qty), 0.0), 0.0) AS ljqd_rate,  -- 累计签单量/累计规划量
    SUM(t2.chuhuo_lj) / NULLIF(COALESCE(SUM(t4.plan_sales_qty), 0.0), 0.0) AS ljch_rate,   -- 累计出货量/累计规划量
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.product_current END AS product_current, -- 型号生命周期状态
    'N' AS is_project,                                                          -- 是否保护期
    t5.koujing AS dimension_1,                                                  -- 维度1（口径类型）
    NOW() AS load_dt,                                                           -- 加载时间
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.salemodelcode END AS salemodelcode -- 维度2（销售型号编码）
FROM rili_model t1
LEFT JOIN (
    SELECT *
    FROM dws.dws_ipd_ipm_rili_qdch_m_detail_dd
    WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND data_type = '型号口径-sap编码合计'
) t2 ON t1.salemodelcode = t2.salemodelcode
LEFT JOIN guihuaxiaoliang_m t3 ON t1.salemodelcode = t3.salemodelcode
LEFT JOIN guihuaxiaoliang_lj t4 ON t1.salemodelcode = t4.salemodelcode
CROSS JOIN weidu_koujing t5
GROUP BY
    DATE_FORMAT('${GP_START_DT}', '%Y%m'),
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t2.in_out_sale END,
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t2.sap_number END,
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.prdct_model END,
    CASE WHEN t5.koujing IN ('事业部') THEN NULL ELSE t1.project_mingcheng END,
    CASE WHEN t5.koujing IN ('事业部') THEN NULL ELSE t1.project_id END,
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.shangshi_now_m END,
    t1.marketing_department,
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.product_current END,
    t5.koujing,
    CASE WHEN t5.koujing IN ('事业部', '项目') THEN NULL ELSE t1.salemodelcode END
;
