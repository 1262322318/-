-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: dws_ipd_ipm_qihua_hit_detail_dd.sql
-- 功能描述: 企划命中率明细表（央空/日立）— 正式版
--           第一段：型号口径 — 基础数据
--           第二段：项目口径 — 项目级7阶段判定（stage_calc集中判定）
--           第三段：事业部口径 — 事业部+项目级7阶段判定
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-04-24
-- 修改时间: 2026-06-16
-- 变更说明: 正式版逻辑（PRD: 2026-06-16_003_央空企划命中率正式版_prd.md）
-- 【状态：✅ 已合入正式脚本  合入日期：2026-06-18  含stage编码修正41/42/43】
-- ******************************************************************** --


-- ====================================================================
-- 第一段：型号口径（基础数据，不做阶段判定）
-- 作用：确定取数范围、上下市时间、关联实际销量和规划量
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '型号口径';

INSERT INTO dws.dws_ipd_ipm_qihua_hit_detail_dd (
    dt_month              -- 统计月份（YYYYMM）
    ,data_type            -- 数据类型：型号口径
    ,salemodel_code       -- 销售型号编码
    ,salemodel_name       -- 销售型号名称
    ,project_code         -- 项目编码
    ,project_name         -- 项目名称
    ,pc20080              -- 归属营销部
    ,product_big          -- 产品大类
    ,product_mid          -- 产品中类
    ,product_sml          -- 产品小类
    ,sale_brand           -- 销售品牌
    ,listing_date         -- 实际上市时间
    ,stop_production_date -- 实际停止生产时间（PG00027）
    ,stop_order_date      -- 实际停止下单时间（PG00026）
    ,shangshi_month       -- 上市月份数
    ,cum_sales_qty        -- 累计销量（全生命周期）
    ,recent_12m_qty       -- 近12个月销量（阶段5-7使用）
    ,plan_first_year_qty  -- 首年规划量（HX00020）
    ,is_stopped           -- 是否停产（Y/N）
    ,is_stop_order        -- 是否停止下单（Y/N）
    ,lifecycle_status     -- 生命周期状态（PG00057）
    ,load_dt              -- 加载时间
)

-- CTE1: 央空日立销售型号范围
-- 筛选条件：日立产品公司 + 7个小类 + 9个营销部 + 排除委外工厂 + 排除模块组合
WITH sale_model AS (
    SELECT
        t1.PG00068 AS salemodel_code
        ,t1.PG00061 AS salemodel_name
        ,t1.project_code
        ,t1.project_name
        ,t1.PC20080 AS pc20080
        ,t1.PG00002 AS product_big
        ,t1.PG00003 AS product_mid
        ,t1.PG00004 AS product_sml
        ,t1.PG00069 AS sale_brand
        ,CASE WHEN t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d')
              THEN NULL ELSE t1.PG00025 END AS listing_date
        ,CASE WHEN t1.PG00027 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d')
              THEN NULL ELSE t1.PG00027 END AS stop_production_date
        ,CASE WHEN t1.PG00026 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d')
              THEN NULL ELSE t1.PG00026 END AS stop_order_date
        ,(YEAR(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - YEAR(t1.PG00025)) * 12
         + (MONTH(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - MONTH(t1.PG00025)) AS shangshi_month
        ,CASE WHEN t1.PC20006 = '定制产品' THEN 0 ELSE COALESCE(t1.HX00020, 0) END AS plan_first_year_qty
        ,t1.PG00057 AS lifecycle_status
    FROM dim.dim_ipd_salemodel_dd t1
    LEFT JOIN dim.dim_ipd_productmodel_dd t2 ON t1.PRODUCTMODEL_ID = t2.ID
    WHERE t2.PG00015 = '日立'
      AND t1.PG00002 = '空气调节类产品'
      AND t1.PG00003 = '中央空调'
      AND t1.PG00004 IN ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机')
      AND t1.PC20080 IN ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','科龙商空营销部','海外业务部(氟系统)','海外业务部(大客户)')
      AND COALESCE(t1.PC00025, '') != '1000-海信日立委外工厂'
      AND COALESCE(t1.HX00379, '否') != '是'
      AND t1.PG00025 IS NOT NULL
      AND t1.project_code IS NOT NULL
)

-- CTE2: 累计销量（全生命周期，管报→MDG→sale_model_code）
,all_sales AS (
    SELECT t2.sale_model_code, SUM(t1.sale_qty) AS cum_sales_qty
    FROM ods.ods_mr_v_app_fm_imat_saledata t1
    LEFT JOIN (SELECT product_code, sale_model_code FROM dw.dim_product_base_info_dd
               WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y') t2 ON t1.matnr = t2.product_code
    WHERE t2.sale_model_code IS NOT NULL
      AND t1.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY t2.sale_model_code
)

-- CTE3: 近12个月销量（固定窗口，阶段5-7型号维度使用）
,recent_sales AS (
    SELECT t2.sale_model_code, SUM(t1.sale_qty) AS recent_12m_qty
    FROM ods.ods_mr_v_app_fm_imat_saledata t1
    LEFT JOIN (SELECT product_code, sale_model_code FROM dw.dim_product_base_info_dd
               WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y') t2 ON t1.matnr = t2.product_code
    WHERE t2.sale_model_code IS NOT NULL
      AND t1.yearmonth > DATE_FORMAT(DATE_SUB(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), INTERVAL 12 MONTH), '%Y%m')
      AND t1.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY t2.sale_model_code
)

-- 最终SELECT：型号口径基础数据输出
SELECT
    DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m') AS dt_month   -- 统计月份
    ,'型号口径'          AS data_type            -- 数据类型
    ,sm.salemodel_code                           -- 销售型号编码
    ,sm.salemodel_name                           -- 销售型号名称
    ,sm.project_code                             -- 项目编码
    ,sm.project_name                             -- 项目名称
    ,sm.pc20080                                  -- 归属营销部
    ,sm.product_big                              -- 产品大类
    ,sm.product_mid                              -- 产品中类
    ,sm.product_sml                              -- 产品小类
    ,sm.sale_brand                               -- 销售品牌
    ,sm.listing_date                             -- 实际上市时间
    ,sm.stop_production_date                     -- 实际停止生产时间
    ,sm.stop_order_date                          -- 实际停止下单时间
    ,sm.shangshi_month                           -- 上市月份数
    ,COALESCE(s.cum_sales_qty, 0)   AS cum_sales_qty    -- 累计销量
    ,COALESCE(rs.recent_12m_qty, 0) AS recent_12m_qty   -- 近12个月销量
    ,sm.plan_first_year_qty                      -- 首年规划量
    ,CASE WHEN sm.stop_production_date IS NOT NULL THEN 'Y' ELSE 'N' END AS is_stopped     -- 是否停产
    ,CASE WHEN sm.stop_order_date IS NOT NULL THEN 'Y' ELSE 'N' END AS is_stop_order       -- 是否停止下单
    ,sm.lifecycle_status                         -- 生命周期状态
    ,NOW()               AS load_dt              -- 加载时间
FROM sale_model sm
LEFT JOIN all_sales s ON sm.salemodel_code = s.sale_model_code
LEFT JOIN recent_sales rs ON sm.salemodel_code = rs.sale_model_code
WHERE sm.listing_date IS NOT NULL
;


-- ====================================================================
-- 第二段：项目口径（stage_calc集中阶段判定，消除重复条件）
-- 数据流：型号口径(未停产) → 项目汇总 → 按月销量 → 滑动窗口 → 近12月 → 阶段判定 → 输出
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '项目口径';

INSERT INTO dws.dws_ipd_ipm_qihua_hit_detail_dd (
    dt_month              -- 统计月份（YYYYMM）
    ,data_type            -- 数据类型：项目口径
    ,project_code         -- 项目编码
    ,project_name         -- 项目名称
    ,sku_count            -- 项目下SKU数量
    ,pc20080              -- 归属营销部（去重合并）
    ,listing_date         -- 项目最早上市时间
    ,stop_production_date -- 项目停产时间（所有SKU停产才有值）
    ,stop_order_date      -- 项目停止下单时间（所有SKU停止下单才有值）
    ,shangshi_month       -- 项目上市月份数
    ,cum_sales_qty        -- 项目累计销量
    ,recent_12m_qty       -- 项目近12个月销量
    ,max_rolling_12m_qty  -- 累计连续12个月最大销量（滑动窗口）
    ,plan_first_year_qty  -- 项目首年规划量
    ,sales_progress       -- 销量进度
    ,time_progress        -- 时间进度
    ,stage                -- 阶段（1-7，4含停产子类型）
    ,stage_label          -- 阶段标签
    ,is_hit               -- 是否达标（Y/N）
    ,hit_type             -- 达标类型
    ,is_stopped           -- 是否停产（Y/N）
    ,is_stop_order        -- 是否停止下单（Y/N）
    ,is_in_hongheibang    -- 是否上红黑榜（Y=阶段1-4，N=阶段5-7）
    ,is_kaohe             -- 是否考核（Y=阶段4，N=其余）
    ,load_dt              -- 加载时间
)

-- CTE1: 从型号口径汇总到项目级别（只取未停产型号）
WITH project_base AS (
    SELECT
        project_code                             -- 项目编码
        ,project_name                            -- 项目名称
        ,COUNT(DISTINCT salemodel_code) AS sku_count  -- SKU数量
        ,GROUP_CONCAT(DISTINCT pc20080, ',') AS pc20080  -- 营销部（去重合并）
        ,MIN(listing_date) AS listing_date       -- 项目上市时间（最早）
        ,CASE WHEN COUNT(CASE WHEN stop_production_date IS NULL THEN 1 END) = 0
              THEN MAX(stop_production_date) ELSE NULL END AS stop_production_date  -- 项目停产时间
        ,CASE WHEN COUNT(CASE WHEN stop_order_date IS NULL THEN 1 END) = 0
              THEN MAX(stop_order_date) ELSE NULL END AS stop_order_date  -- 项目停止下单时间
        ,(YEAR(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - YEAR(MIN(listing_date))) * 12
         + (MONTH(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - MONTH(MIN(listing_date))) AS shangshi_month  -- 上市月份
        ,SUM(COALESCE(cum_sales_qty, 0)) AS cum_sales_qty  -- 累计销量
        ,SUM(COALESCE(plan_first_year_qty, 0)) AS plan_first_year_qty  -- 首年规划量
    FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
    WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
      AND data_type = '型号口径'
      AND project_code IS NOT NULL
      AND stop_production_date IS NULL           -- 只取未停产型号参与项目汇总
    GROUP BY project_code, project_name
)

-- CTE2: 项目级按月销量（用于滑动窗口和近12月计算）
,project_monthly_sales AS (
    SELECT sm.project_code, ms.yearmonth, SUM(ms.sale_qty) AS sale_qty
    FROM (
        SELECT t2.sale_model_code, t1.yearmonth, SUM(t1.sale_qty) AS sale_qty
        FROM ods.ods_mr_v_app_fm_imat_saledata t1
        LEFT JOIN (SELECT product_code, sale_model_code FROM dw.dim_product_base_info_dd
                   WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y') t2
            ON t1.matnr = t2.product_code
        WHERE t2.sale_model_code IS NOT NULL
        GROUP BY t2.sale_model_code, t1.yearmonth
    ) ms
    INNER JOIN (
        SELECT DISTINCT salemodel_code, project_code
        FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
        WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
          AND data_type = '型号口径'
    ) sm ON ms.sale_model_code = sm.salemodel_code
    GROUP BY sm.project_code, ms.yearmonth
)

-- CTE3: 滑动窗口12个月最大销量（阶段2-4使用，从上市后取所有12月窗口的MAX）
,rolling_12m_detail AS (
    SELECT pb.project_code, offsets.offset
        ,SUM(COALESCE(pms.sale_qty, 0)) AS window_sum
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
       AND pms.yearmonth >= DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (1 + offsets.offset) MONTH), '%Y%m')
       AND pms.yearmonth < DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
    WHERE pb.listing_date IS NOT NULL
      AND DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
          <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY pb.project_code, offsets.offset
)
,rolling_12m AS (
    SELECT project_code, MAX(window_sum) AS max_rolling_12m_qty
    FROM rolling_12m_detail WHERE window_sum > 0
    GROUP BY project_code
)

-- CTE4: 近12个月连续销量（固定窗口，阶段5-7使用）
,recent_12m AS (
    SELECT pms.project_code, SUM(pms.sale_qty) AS recent_12m_qty
    FROM project_monthly_sales pms
    WHERE pms.yearmonth > DATE_FORMAT(DATE_SUB(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), INTERVAL 12 MONTH), '%Y%m')
      AND pms.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY pms.project_code
)

-- CTE5: stage_calc — 集中阶段判定（核心逻辑只写一次）
-- 阶段规则：
--   1  = 未停产 + 上市1-6月
--   2  = 未停产 + 上市7-18月
--   3  = 未停产 + 上市19-23月
--   4  = 未停产 + 上市=24月 + 未停止下单（考核：企划命中率）
--   42 = 本月停产 + 上市13-23月（考核：企划命中率-停产②）
--   43 = 本月停产 + 上市7-12月（考核：企划命中率-停产③）
--   5  = 未停产 + 未停止下单 + 上市25-35月
--   6  = 未停产 + 未停止下单 + 上市≥36月
--   7  = 已停止下单 + 未停产 + 上市≥25月
,stage_calc AS (
    SELECT pb.*
        ,COALESCE(r12.max_rolling_12m_qty, 0) AS max_rolling_12m_qty  -- 滑动窗口最大值
        ,COALESCE(rc12.recent_12m_qty, 0) AS recent_12m_qty           -- 近12个月销量
        ,CASE
            -- 本月停产优先判定（stop_production_date在本月内）
            WHEN pb.stop_production_date IS NOT NULL
                 AND pb.stop_production_date >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y-%m'), '-01'), '%Y-%m-%d')
                 AND pb.shangshi_month BETWEEN 7 AND 12 THEN 43       -- 本月停产 + 上市7-12月
            WHEN pb.stop_production_date IS NOT NULL
                 AND pb.stop_production_date >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y-%m'), '-01'), '%Y-%m-%d')
                 AND pb.shangshi_month BETWEEN 13 AND 23 THEN 42      -- 本月停产 + 上市13-23月
            -- 阶段1-4：取数终点=停止生产时间为空
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month BETWEEN 1 AND 6 THEN 1
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month BETWEEN 7 AND 18 THEN 2
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month BETWEEN 19 AND 23 THEN 3
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month = 24 AND pb.stop_order_date IS NULL THEN 4
            -- 阶段7：已停止下单 + 未停产
            WHEN pb.stop_production_date IS NULL AND pb.stop_order_date IS NOT NULL AND pb.shangshi_month >= 25 THEN 7
            -- 阶段5-6：取数终点=停止下单时间为空 + 未停产
            WHEN pb.stop_production_date IS NULL AND pb.stop_order_date IS NULL AND pb.shangshi_month BETWEEN 25 AND 35 THEN 5
            WHEN pb.stop_production_date IS NULL AND pb.stop_order_date IS NULL AND pb.shangshi_month >= 36 THEN 6
            ELSE 0
        END AS stage
    FROM project_base pb
    LEFT JOIN rolling_12m r12 ON pb.project_code = r12.project_code
    LEFT JOIN recent_12m rc12 ON pb.project_code = rc12.project_code
)

-- 最终SELECT：项目口径输出（引用stage值，不再重复条件）
SELECT
    DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m') AS dt_month   -- 统计月份
    ,'项目口径'          AS data_type            -- 数据类型
    ,sc.project_code                             -- 项目编码
    ,sc.project_name                             -- 项目名称
    ,sc.sku_count                                -- 项目下SKU数量
    ,sc.pc20080                                  -- 归属营销部
    ,sc.listing_date                             -- 项目最早上市时间
    ,sc.stop_production_date                     -- 项目停产时间
    ,sc.stop_order_date                          -- 项目停止下单时间
    ,sc.shangshi_month                           -- 项目上市月份数
    ,sc.cum_sales_qty                            -- 项目累计销量
    ,sc.recent_12m_qty                           -- 项目近12个月销量
    ,sc.max_rolling_12m_qty                      -- 累计连续12个月最大销量
    ,sc.plan_first_year_qty                      -- 项目首年规划量
    -- 销量进度
    ,CASE
        WHEN sc.stage = 1  THEN sc.cum_sales_qty / NULLIF(sc.plan_first_year_qty, 0)
        WHEN sc.stage IN (2,3,4,42) THEN sc.max_rolling_12m_qty / NULLIF(sc.plan_first_year_qty, 0)
        WHEN sc.stage = 43 THEN sc.cum_sales_qty / NULLIF(sc.plan_first_year_qty * sc.shangshi_month / 12.0, 0)
        ELSE NULL
    END                  AS sales_progress       -- 销量进度
    -- 时间进度（仅阶段1-2有意义：上市月数/18）
    ,CASE WHEN sc.stage IN (1,2) THEN sc.shangshi_month / 18.0 ELSE NULL
    END                  AS time_progress        -- 时间进度
    -- 阶段（对外输出1-7，42/43统一输出为4）
    ,CASE WHEN sc.stage IN (42,43) THEN 4 ELSE sc.stage
    END                  AS stage                -- 阶段编号
    -- 阶段标签
    ,CASE sc.stage
        WHEN 1  THEN '上市1-6个月'
        WHEN 2  THEN '上市7-18个月'
        WHEN 3  THEN '上市19-23个月'
        WHEN 4  THEN '上市24个月(企划命中率)'
        WHEN 42 THEN '企划命中率(本月停产12-24月)'
        WHEN 43 THEN '企划命中率(本月停产6-12月)'
        WHEN 5  THEN '上市25-35个月'
        WHEN 6  THEN '上市≥36个月'
        WHEN 7  THEN '停止下单状态'
        ELSE '其他'
    END                  AS stage_label          -- 阶段标签
    -- 是否达标
    ,CASE
        WHEN sc.stage = 1  THEN CASE WHEN sc.cum_sales_qty / NULLIF(sc.plan_first_year_qty, 0) < sc.shangshi_month / 18.0 THEN 'N' ELSE 'Y' END
        WHEN sc.stage = 2  THEN CASE WHEN sc.max_rolling_12m_qty / NULLIF(sc.plan_first_year_qty, 0) < sc.shangshi_month / 18.0 THEN 'N' ELSE 'Y' END
        WHEN sc.stage IN (3,4,42) THEN CASE WHEN sc.max_rolling_12m_qty < sc.plan_first_year_qty THEN 'N' ELSE 'Y' END
        WHEN sc.stage = 43 THEN CASE WHEN sc.cum_sales_qty < sc.plan_first_year_qty * sc.shangshi_month / 12.0 THEN 'N' ELSE 'Y' END
        WHEN sc.stage IN (5,6,7) THEN CASE WHEN sc.recent_12m_qty < 0 THEN 'N' ELSE 'Y' END  -- 门槛=0，全部达标
        ELSE 'Y'
    END                  AS is_hit               -- 是否达标
    -- 达标类型
    ,CASE sc.stage
        WHEN 1  THEN '销售进度不达标'
        WHEN 2  THEN '销售进度不达标'
        WHEN 3  THEN '企划未命中预警'
        WHEN 4  THEN '企划未命中'
        WHEN 42 THEN '企划未命中(本月停产)'
        WHEN 43 THEN '企划未命中(本月停产)'
        WHEN 5  THEN '低销预警'
        WHEN 6  THEN '低销通报'
        WHEN 7  THEN '低销(停止下单)'
        ELSE '其他'
    END                  AS hit_type             -- 达标类型
    ,CASE WHEN sc.stop_production_date IS NOT NULL THEN 'Y' ELSE 'N'
    END                  AS is_stopped           -- 是否停产
    ,CASE WHEN sc.stop_order_date IS NOT NULL THEN 'Y' ELSE 'N'
    END                  AS is_stop_order        -- 是否停止下单
    ,CASE WHEN sc.stage IN (1,2,3,4,42,43) THEN 'Y' ELSE 'N'
    END                  AS is_in_hongheibang    -- 是否上红黑榜
    ,CASE WHEN sc.stage IN (4,42,43) THEN 'Y' ELSE 'N'
    END                  AS is_kaohe             -- 是否考核
    ,NOW()               AS load_dt              -- 加载时间
FROM stage_calc sc
WHERE sc.stage > 0
;


-- ====================================================================
-- 第三段：事业部口径（与第二段结构一致，GROUP BY增加pc20080维度）
-- 作用：同一项目在不同营销部各出一行，用于各营销部独立统计红黑榜
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '事业部口径';

INSERT INTO dws.dws_ipd_ipm_qihua_hit_detail_dd (
    dt_month              -- 统计月份（YYYYMM）
    ,data_type            -- 数据类型：事业部口径
    ,project_code         -- 项目编码
    ,project_name         -- 项目名称
    ,sku_count            -- 该营销部下项目SKU数量
    ,pc20080              -- 归属营销部（单个）
    ,listing_date         -- 该营销部项目最早上市时间
    ,stop_production_date -- 该营销部项目停产时间
    ,stop_order_date      -- 该营销部项目停止下单时间
    ,shangshi_month       -- 该营销部项目上市月份数
    ,cum_sales_qty        -- 该营销部项目累计销量
    ,recent_12m_qty       -- 该营销部项目近12个月销量
    ,max_rolling_12m_qty  -- 累计连续12个月最大销量
    ,plan_first_year_qty  -- 该营销部项目首年规划量
    ,sales_progress       -- 销量进度
    ,time_progress        -- 时间进度
    ,stage                -- 阶段（1-7）
    ,stage_label          -- 阶段标签
    ,is_hit               -- 是否达标（Y/N）
    ,hit_type             -- 达标类型
    ,is_stopped           -- 是否停产（Y/N）
    ,is_stop_order        -- 是否停止下单（Y/N）
    ,is_in_hongheibang    -- 是否上红黑榜
    ,is_kaohe             -- 是否考核
    ,load_dt              -- 加载时间
)

-- CTE1: 从型号口径按事业部+项目汇总（与第二段差异：GROUP BY多pc20080）
WITH project_base AS (
    SELECT
        project_code                             -- 项目编码
        ,project_name                            -- 项目名称
        ,pc20080                                 -- 归属营销部（单个）
        ,COUNT(DISTINCT salemodel_code) AS sku_count
        ,MIN(listing_date) AS listing_date
        ,CASE WHEN COUNT(CASE WHEN stop_production_date IS NULL THEN 1 END) = 0
              THEN MAX(stop_production_date) ELSE NULL END AS stop_production_date
        ,CASE WHEN COUNT(CASE WHEN stop_order_date IS NULL THEN 1 END) = 0
              THEN MAX(stop_order_date) ELSE NULL END AS stop_order_date
        ,(YEAR(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - YEAR(MIN(listing_date))) * 12
         + (MONTH(date_sub('${GP_START_DT}', INTERVAL 1 MONTH)) - MONTH(MIN(listing_date))) AS shangshi_month
        ,SUM(COALESCE(cum_sales_qty, 0)) AS cum_sales_qty
        ,SUM(COALESCE(plan_first_year_qty, 0)) AS plan_first_year_qty
    FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
    WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
      AND data_type = '型号口径'
      AND project_code IS NOT NULL
      AND stop_production_date IS NULL
    GROUP BY project_code, project_name, pc20080
)

-- CTE2: 事业部项目级按月销量
,project_monthly_sales AS (
    SELECT sm.project_code, sm.pc20080, ms.yearmonth, SUM(ms.sale_qty) AS sale_qty
    FROM (
        SELECT t2.sale_model_code, t1.yearmonth, SUM(t1.sale_qty) AS sale_qty
        FROM ods.ods_mr_v_app_fm_imat_saledata t1
        LEFT JOIN (SELECT product_code, sale_model_code FROM dw.dim_product_base_info_dd
                   WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y') t2
            ON t1.matnr = t2.product_code
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

-- CTE3: 滑动窗口12个月最大销量
,rolling_12m_detail AS (
    SELECT pb.project_code, pb.pc20080, offsets.offset
        ,SUM(COALESCE(pms.sale_qty, 0)) AS window_sum
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
        ON pb.project_code = pms.project_code AND pb.pc20080 = pms.pc20080
       AND pms.yearmonth >= DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (1 + offsets.offset) MONTH), '%Y%m')
       AND pms.yearmonth < DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
    WHERE pb.listing_date IS NOT NULL
      AND DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
          <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY pb.project_code, pb.pc20080, offsets.offset
)
,rolling_12m AS (
    SELECT project_code, pc20080, MAX(window_sum) AS max_rolling_12m_qty
    FROM rolling_12m_detail WHERE window_sum > 0
    GROUP BY project_code, pc20080
)

-- CTE4: 近12个月连续销量
,recent_12m AS (
    SELECT pms.project_code, pms.pc20080, SUM(pms.sale_qty) AS recent_12m_qty
    FROM project_monthly_sales pms
    WHERE pms.yearmonth > DATE_FORMAT(DATE_SUB(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), INTERVAL 12 MONTH), '%Y%m')
      AND pms.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY pms.project_code, pms.pc20080
)

-- CTE5: stage_calc — 集中阶段判定（与第二段逻辑完全一致）
,stage_calc AS (
    SELECT pb.*
        ,COALESCE(r12.max_rolling_12m_qty, 0) AS max_rolling_12m_qty
        ,COALESCE(rc12.recent_12m_qty, 0) AS recent_12m_qty
        ,CASE
            -- 本月停产优先判定（stop_production_date在本月内）
            WHEN pb.stop_production_date IS NOT NULL
                 AND pb.stop_production_date >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y-%m'), '-01'), '%Y-%m-%d')
                 AND pb.shangshi_month BETWEEN 7 AND 12 THEN 43
            WHEN pb.stop_production_date IS NOT NULL
                 AND pb.stop_production_date >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y-%m'), '-01'), '%Y-%m-%d')
                 AND pb.shangshi_month BETWEEN 13 AND 23 THEN 42
            -- 阶段1-4：取数终点=停止生产时间为空
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month BETWEEN 1 AND 6 THEN 1
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month BETWEEN 7 AND 18 THEN 2
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month BETWEEN 19 AND 23 THEN 3
            WHEN pb.stop_production_date IS NULL AND pb.shangshi_month = 24 AND pb.stop_order_date IS NULL THEN 4
            -- 阶段7：已停止下单 + 未停产
            WHEN pb.stop_production_date IS NULL AND pb.stop_order_date IS NOT NULL AND pb.shangshi_month >= 25 THEN 7
            -- 阶段5-6：取数终点=停止下单时间为空 + 未停产
            WHEN pb.stop_production_date IS NULL AND pb.stop_order_date IS NULL AND pb.shangshi_month BETWEEN 25 AND 35 THEN 5
            WHEN pb.stop_production_date IS NULL AND pb.stop_order_date IS NULL AND pb.shangshi_month >= 36 THEN 6
            ELSE 0
        END AS stage
    FROM project_base pb
    LEFT JOIN rolling_12m r12 ON pb.project_code = r12.project_code AND pb.pc20080 = r12.pc20080
    LEFT JOIN recent_12m rc12 ON pb.project_code = rc12.project_code AND pb.pc20080 = rc12.pc20080
)

-- 最终SELECT：事业部口径输出（与第二段完全一致，仅data_type不同）
SELECT
    DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m') AS dt_month   -- 统计月份
    ,'事业部口径'        AS data_type            -- 数据类型
    ,sc.project_code                             -- 项目编码
    ,sc.project_name                             -- 项目名称
    ,sc.sku_count                                -- 该营销部下SKU数量
    ,sc.pc20080                                  -- 归属营销部（单个）
    ,sc.listing_date                             -- 该营销部项目最早上市时间
    ,sc.stop_production_date                     -- 该营销部项目停产时间
    ,sc.stop_order_date                          -- 该营销部项目停止下单时间
    ,sc.shangshi_month                           -- 该营销部项目上市月份数
    ,sc.cum_sales_qty                            -- 该营销部项目累计销量
    ,sc.recent_12m_qty                           -- 该营销部项目近12个月销量
    ,sc.max_rolling_12m_qty                      -- 累计连续12个月最大销量
    ,sc.plan_first_year_qty                      -- 该营销部项目首年规划量
    -- 销量进度
    ,CASE
        WHEN sc.stage = 1  THEN sc.cum_sales_qty / NULLIF(sc.plan_first_year_qty, 0)
        WHEN sc.stage IN (2,3,4,42) THEN sc.max_rolling_12m_qty / NULLIF(sc.plan_first_year_qty, 0)
        WHEN sc.stage = 43 THEN sc.cum_sales_qty / NULLIF(sc.plan_first_year_qty * sc.shangshi_month / 12.0, 0)
        ELSE NULL
    END                  AS sales_progress       -- 销量进度
    -- 时间进度
    ,CASE WHEN sc.stage IN (1,2) THEN sc.shangshi_month / 18.0 ELSE NULL
    END                  AS time_progress        -- 时间进度
    -- 阶段
    ,CASE WHEN sc.stage IN (42,43) THEN 4 ELSE sc.stage
    END                  AS stage                -- 阶段编号
    -- 阶段标签
    ,CASE sc.stage
        WHEN 1  THEN '上市1-6个月'
        WHEN 2  THEN '上市7-18个月'
        WHEN 3  THEN '上市19-23个月'
        WHEN 4  THEN '上市24个月(企划命中率)'
        WHEN 42 THEN '企划命中率(本月停产12-24月)'
        WHEN 43 THEN '企划命中率(本月停产6-12月)'
        WHEN 5  THEN '上市25-35个月'
        WHEN 6  THEN '上市≥36个月'
        WHEN 7  THEN '停止下单状态'
        ELSE '其他'
    END                  AS stage_label          -- 阶段标签
    -- 是否达标
    ,CASE
        WHEN sc.stage = 1  THEN CASE WHEN sc.cum_sales_qty / NULLIF(sc.plan_first_year_qty, 0) < sc.shangshi_month / 18.0 THEN 'N' ELSE 'Y' END
        WHEN sc.stage = 2  THEN CASE WHEN sc.max_rolling_12m_qty / NULLIF(sc.plan_first_year_qty, 0) < sc.shangshi_month / 18.0 THEN 'N' ELSE 'Y' END
        WHEN sc.stage IN (3,4,42) THEN CASE WHEN sc.max_rolling_12m_qty < sc.plan_first_year_qty THEN 'N' ELSE 'Y' END
        WHEN sc.stage = 43 THEN CASE WHEN sc.cum_sales_qty < sc.plan_first_year_qty * sc.shangshi_month / 12.0 THEN 'N' ELSE 'Y' END
        WHEN sc.stage IN (5,6,7) THEN CASE WHEN sc.recent_12m_qty < 0 THEN 'N' ELSE 'Y' END
        ELSE 'Y'
    END                  AS is_hit               -- 是否达标
    -- 达标类型
    ,CASE sc.stage
        WHEN 1  THEN '销售进度不达标'
        WHEN 2  THEN '销售进度不达标'
        WHEN 3  THEN '企划未命中预警'
        WHEN 4  THEN '企划未命中'
        WHEN 42 THEN '企划未命中(本月停产)'
        WHEN 43 THEN '企划未命中(本月停产)'
        WHEN 5  THEN '低销预警'
        WHEN 6  THEN '低销通报'
        WHEN 7  THEN '低销(停止下单)'
        ELSE '其他'
    END                  AS hit_type             -- 达标类型
    ,CASE WHEN sc.stop_production_date IS NOT NULL THEN 'Y' ELSE 'N'
    END                  AS is_stopped           -- 是否停产
    ,CASE WHEN sc.stop_order_date IS NOT NULL THEN 'Y' ELSE 'N'
    END                  AS is_stop_order        -- 是否停止下单
    ,CASE WHEN sc.stage IN (1,2,3,4,42,43) THEN 'Y' ELSE 'N'
    END                  AS is_in_hongheibang    -- 是否上红黑榜
    ,CASE WHEN sc.stage IN (4,42,43) THEN 'Y' ELSE 'N'
    END                  AS is_kaohe             -- 是否考核
    ,NOW()               AS load_dt              -- 加载时间
FROM stage_calc sc
WHERE sc.stage > 0
;
