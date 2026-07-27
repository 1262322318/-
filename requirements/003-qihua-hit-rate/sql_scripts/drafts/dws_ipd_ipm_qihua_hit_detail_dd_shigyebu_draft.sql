-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: dws_ipd_ipm_qihua_hit_detail_dd_shigyebu_draft.sql
-- 功能描述: 企划命中率明细表 — 第三段：事业部口径
--           从型号口径按事业部(pc20080)+项目(project_code)汇总，
--           在事业部项目级别做阶段判定和达标判断
--           逻辑与第二段（项目口径）完全一致，唯一差异：GROUP BY增加pc20080维度
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-06-08
-- 参考: dws_ipd_ipm_qihua_hit_detail_dd.sql 第二段（项目口径）
-- ******************************************************************** --


-- ====================================================================
-- 第三段：事业部口径（从型号按事业部+项目汇总，在事业部项目级别做所有判定）
-- 与第二段逻辑完全一致，唯一差异：GROUP BY增加pc20080维度
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '事业部口径';

INSERT INTO dws.dws_ipd_ipm_qihua_hit_detail_dd (
    dt_month              -- 统计月份（YYYYMM格式）
    ,data_type            -- 数据类型（事业部口径）
    ,project_code         -- 项目编码
    ,project_name         -- 项目名称
    ,sku_count            -- 事业部下该项目SKU数量
    ,pc20080              -- 归属营销部（单个事业部）
    ,listing_date         -- 事业部项目最早上市时间
    ,stop_production_date -- 事业部项目停产时间
    ,shangshi_month       -- 事业部项目上市月份数
    ,cum_sales_qty        -- 事业部项目累计销量
    ,max_rolling_12m_qty  -- 累计连续12个月最大销量
    ,plan_first_year_qty  -- 事业部项目首年规划量
    ,sales_progress       -- 销量进度
    ,time_progress        -- 时间进度
    ,stage                -- 阶段（1-6）
    ,stage_label          -- 阶段标签
    ,is_hit               -- 是否达标（Y/N）
    ,hit_type             -- 达标类型
    ,is_stopped           -- 是否停产（Y/N）
    ,load_dt              -- 加载时间
)

-- Step1: 从型号口径按事业部+项目汇总（与第二段唯一差异：GROUP BY增加pc20080）
WITH project_base AS (
    SELECT
        project_code                                                                                                    -- 项目编码
        ,project_name                                                                                                   -- 项目名称
        ,pc20080                                                                                                        -- 归属营销部（单个事业部）
        ,COUNT(DISTINCT salemodel_code) AS sku_count                                                                   -- 事业部下SKU数量
        ,MIN(listing_date) AS listing_date                                                                             -- 事业部项目上市时间（最早）
        ,CASE WHEN COUNT(CASE WHEN stop_production_date IS NULL THEN 1 END) = 0                                        -- 事业部项目停产时间
              THEN MAX(stop_production_date) ELSE NULL END AS stop_production_date
        ,(YEAR(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - YEAR(MIN(listing_date))) * 12                           -- 上市月份
         + (MONTH(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - MONTH(MIN(listing_date))) AS shangshi_month
        ,SUM(COALESCE(cum_sales_qty, 0)) AS cum_sales_qty                                                               -- 事业部项目累计销量
        ,SUM(COALESCE(plan_first_year_qty, 0)) AS plan_first_year_qty                                                 -- 事业部项目首年规划量
    FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
    WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
      AND data_type = '型号口径'
      AND project_code IS NOT NULL
    GROUP BY project_code, project_name, pc20080
)

-- Step2: 事业部项目级按月销量（用于滑动窗口，按事业部+项目分组）
,project_monthly_sales AS (
    SELECT
        sm.project_code     -- 项目编码
        ,sm.pc20080         -- 归属营销部
        ,ms.yearmonth       -- 年月
        ,SUM(ms.sale_qty) AS sale_qty  -- 月销量
    FROM (
        SELECT t2.sale_model_code, t1.yearmonth, SUM(t1.sale_qty) AS sale_qty
        FROM ods.ods_mr_v_app_fm_imat_saledata t1
        LEFT JOIN (
            SELECT product_code, sale_model_code
            FROM dw.dim_product_base_info_dd
            WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y'
        ) t2 ON t1.matnr = t2.product_code
        WHERE t2.sale_model_code IS NOT NULL
        GROUP BY t2.sale_model_code, t1.yearmonth
    ) ms
    INNER JOIN (
        SELECT DISTINCT salemodel_code, project_code, pc20080
        FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
        WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
          AND data_type = '型号口径'
    ) sm ON ms.sale_model_code = sm.salemodel_code
    GROUP BY sm.project_code, sm.pc20080, ms.yearmonth
)

-- Step3: 事业部项目级滑动窗口12个月最大销量
,rolling_12m_detail AS (
    SELECT
        pb.project_code                         -- 项目编码
        ,pb.pc20080                             -- 归属营销部
        ,offsets.offset                         -- 窗口偏移量
        ,SUM(COALESCE(pms.sale_qty, 0)) AS window_sum  -- 窗口内销量合计
    FROM project_base pb
    CROSS JOIN (
        SELECT 0 AS offset UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
        UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
        UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
        UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
    ) offsets
    LEFT JOIN project_monthly_sales pms
        ON pb.project_code = pms.project_code
       AND pb.pc20080 = pms.pc20080
       AND pms.yearmonth >= DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (1 + offsets.offset) MONTH), '%Y%m')
       AND pms.yearmonth < DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
    WHERE pb.listing_date IS NOT NULL
      AND DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
          <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY pb.project_code, pb.pc20080, offsets.offset
)
,rolling_12m AS (
    SELECT
        project_code                         -- 项目编码
        ,pc20080                             -- 归属营销部
        ,MAX(window_sum) AS max_rolling_12m_qty  -- 累计连续12个月最大销量
    FROM rolling_12m_detail
    WHERE window_sum > 0
    GROUP BY project_code, pc20080
)

-- Step4: 在事业部项目级别做阶段判定和达标判断（逻辑与第二段完全一致）
SELECT
    DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m') AS dt_month                    -- 统计月份
    ,'事业部口径' AS data_type                                                                        -- 数据类型
    ,pb.project_code                                                                                 -- 项目编码
    ,pb.project_name                                                                                 -- 项目名称
    ,pb.sku_count                                                                                    -- 事业部下SKU数量
    ,pb.pc20080                                                                                      -- 归属营销部（单个事业部）
    ,pb.listing_date                                                                                 -- 事业部项目最早上市时间
    ,pb.stop_production_date                                                                         -- 事业部项目停产时间
    ,pb.shangshi_month                                                                               -- 事业部项目上市月份数
    ,pb.cum_sales_qty                                                                                -- 事业部项目累计销量
    ,COALESCE(r12.max_rolling_12m_qty, 0) AS max_rolling_12m_qty                                    -- 累计连续12个月最大销量
    ,pb.plan_first_year_qty                                                                          -- 事业部项目首年规划量

    -- 销量进度
    ,CASE
        WHEN pb.shangshi_month BETWEEN 1 AND 6 THEN
            pb.cum_sales_qty / NULLIF(pb.plan_first_year_qty, 0)
        ELSE
            COALESCE(r12.max_rolling_12m_qty, 0) / NULLIF(pb.plan_first_year_qty, 0)
    END AS sales_progress

    -- 时间进度
    ,CASE WHEN pb.shangshi_month BETWEEN 1 AND 18 THEN pb.shangshi_month / 18.0 ELSE NULL END AS time_progress

    -- 阶段
    ,CASE
        WHEN pb.shangshi_month BETWEEN 1 AND 6 THEN 1
        WHEN pb.stop_production_date IS NOT NULL AND pb.shangshi_month BETWEEN 7 AND 12 THEN 4
        WHEN pb.stop_production_date IS NOT NULL AND pb.shangshi_month BETWEEN 13 AND 23 THEN 4
        WHEN pb.shangshi_month BETWEEN 7 AND 18 THEN 2
        WHEN pb.shangshi_month BETWEEN 19 AND 23 THEN 3
        WHEN pb.shangshi_month = 24 THEN 4
        WHEN pb.shangshi_month BETWEEN 25 AND 35 THEN 5
        WHEN pb.shangshi_month >= 36 THEN 6
        ELSE 0
    END AS stage

    -- 阶段标签
    ,CASE
        WHEN pb.shangshi_month BETWEEN 1 AND 6 THEN '上市1-6个月'
        WHEN pb.stop_production_date IS NOT NULL AND pb.shangshi_month BETWEEN 7 AND 12 THEN '上市24个月(停产6-12月)'
        WHEN pb.stop_production_date IS NOT NULL AND pb.shangshi_month BETWEEN 13 AND 23 THEN '上市24个月(停产12-24月)'
        WHEN pb.shangshi_month BETWEEN 7 AND 18 THEN '上市7-18个月'
        WHEN pb.shangshi_month BETWEEN 19 AND 23 THEN '上市19-23个月'
        WHEN pb.shangshi_month = 24 THEN '上市24个月'
        WHEN pb.shangshi_month BETWEEN 25 AND 35 THEN '上市25-35个月'
        WHEN pb.shangshi_month >= 36 THEN '上市≥36个月'
        ELSE '上市0个月'
    END AS stage_label

    -- 是否达标
    ,CASE
        -- 阶段1: 累计销量/首年规划量 < 上市月数/18
        WHEN pb.shangshi_month BETWEEN 1 AND 6 THEN
            CASE WHEN pb.cum_sales_qty / NULLIF(pb.plan_first_year_qty, 0) < pb.shangshi_month / 18.0
                 THEN 'N' ELSE 'Y' END
        -- 停产②: 上市12-24个月已停产，滑动12个月最大 < 首年规划量
        WHEN pb.stop_production_date IS NOT NULL AND pb.shangshi_month BETWEEN 13 AND 23 THEN
            CASE WHEN COALESCE(r12.max_rolling_12m_qty, 0) < pb.plan_first_year_qty
                 THEN 'N' ELSE 'Y' END
        -- 停产③: 上市6-12个月已停产，累计销量 < 首年规划量 × 上市时长/12
        WHEN pb.stop_production_date IS NOT NULL AND pb.shangshi_month BETWEEN 7 AND 12 THEN
            CASE WHEN pb.cum_sales_qty < pb.plan_first_year_qty * pb.shangshi_month / 12.0
                 THEN 'N' ELSE 'Y' END
        -- 阶段2: 滑动12个月最大/首年规划量 < 上市月数/18
        WHEN pb.shangshi_month BETWEEN 7 AND 18 THEN
            CASE WHEN COALESCE(r12.max_rolling_12m_qty, 0) / NULLIF(pb.plan_first_year_qty, 0) < pb.shangshi_month / 18.0
                 THEN 'N' ELSE 'Y' END
        -- 阶段3: 滑动12个月最大 < 首年规划量
        WHEN pb.shangshi_month BETWEEN 19 AND 23 THEN
            CASE WHEN COALESCE(r12.max_rolling_12m_qty, 0) < pb.plan_first_year_qty
                 THEN 'N' ELSE 'Y' END
        -- 阶段4: 企划命中率（在产，上市满24个月）
        WHEN pb.shangshi_month = 24 THEN
            CASE WHEN COALESCE(r12.max_rolling_12m_qty, 0) < pb.plan_first_year_qty
                 THEN 'N' ELSE 'Y' END
        -- 阶段5: 低销预警（门槛暂定100）
        WHEN pb.shangshi_month BETWEEN 25 AND 35 THEN
            CASE WHEN COALESCE(r12.max_rolling_12m_qty, 0) < 100 THEN 'N' ELSE 'Y' END
        -- 阶段6: 低销通报（门槛暂定100）
        WHEN pb.shangshi_month >= 36 THEN
            CASE WHEN COALESCE(r12.max_rolling_12m_qty, 0) < 100 THEN 'N' ELSE 'Y' END
        ELSE 'Y'
    END AS is_hit

    -- 达标类型
    ,CASE
        WHEN pb.shangshi_month BETWEEN 1 AND 6 THEN '销售进度不达标'
        WHEN pb.stop_production_date IS NOT NULL AND pb.shangshi_month BETWEEN 7 AND 23 THEN '企划未命中(停产)'
        WHEN pb.shangshi_month BETWEEN 7 AND 18 THEN '销售进度不达标'
        WHEN pb.shangshi_month BETWEEN 19 AND 23 THEN '企划未命中预警'
        WHEN pb.shangshi_month = 24 THEN '企划未命中'
        WHEN pb.shangshi_month BETWEEN 25 AND 35 THEN '低销预警'
        WHEN pb.shangshi_month >= 36 THEN '低销通报'
        ELSE '保护期'
    END AS hit_type

    ,CASE WHEN pb.stop_production_date IS NOT NULL THEN 'Y' ELSE 'N' END AS is_stopped  -- 是否停产
    ,NOW() AS load_dt                                                                   -- 加载时间

FROM project_base pb
LEFT JOIN rolling_12m r12 ON pb.project_code = r12.project_code AND pb.pc20080 = r12.pc20080
WHERE pb.shangshi_month >= 1
;
