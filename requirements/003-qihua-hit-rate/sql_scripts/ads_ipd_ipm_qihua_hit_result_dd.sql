-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: ads_ipd_ipm_qihua_hit_result_dd.sql
-- 功能描述: 企划命中率结果表（ADS层）
--           从DWS项目口径汇总，按归属营销部+阶段维度统计不达标项目数和SKU数
--           用于各营销部红黑榜展示
--           仅统计is_in_hongheibang='Y'的数据（阶段1-4）
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-04-24
-- 修改时间: 2026-06-16
-- 变更说明: 增加is_in_hongheibang='Y'筛选，仅红黑榜阶段进入ADS汇总
-- 依赖: dws.dws_ipd_ipm_qihua_hit_detail_dd (data_type='项目口径')
-- ******************************************************************** --


-- ====================================================================
-- ADS层：企划命中率汇总结果（按营销部+阶段维度）
-- ====================================================================
DELETE FROM ads.ads_ipd_ipm_qihua_hit_result_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m');

INSERT INTO ads.ads_ipd_ipm_qihua_hit_result_dd (
    dt_month              -- 统计月份（YYYYMM格式）
    ,pc20080              -- 归属营销部
    ,stage                -- 阶段（41/42/43=企划命中率三种子类型，1-3=前期阶段）
    ,stage_label          -- 阶段标签
    ,hit_type             -- 达标类型
    ,total_project_cnt    -- 该阶段总项目数
    ,total_sku_cnt        -- 该阶段总SKU数
    ,fail_project_cnt     -- 不达标项目数
    ,fail_sku_cnt         -- 不达标SKU数
    ,hit_rate             -- 达标率
    ,load_dt              -- 加载时间
)

-- 从DWS项目口径汇总
SELECT
    dt_month                                           -- 统计月份
    ,pc20080                                           -- 归属营销部
    ,stage                                             -- 阶段
    ,stage_label                                       -- 阶段标签
    ,hit_type                                          -- 达标类型

    ,COUNT(DISTINCT project_code) AS total_project_cnt -- 该阶段总项目数

    ,SUM(sku_count) AS total_sku_cnt                   -- 该阶段总SKU数

    ,COUNT(DISTINCT CASE WHEN is_hit = 'N' THEN project_code END) AS fail_project_cnt  -- 不达标项目数

    ,SUM(CASE WHEN is_hit = 'N' THEN sku_count ELSE 0 END) AS fail_sku_cnt  -- 不达标SKU数

    ,1 - COUNT(DISTINCT CASE WHEN is_hit = 'N' THEN project_code END)
         / NULLIF(COUNT(DISTINCT project_code), 0) AS hit_rate  -- 达标率 = 1 - 不达标项目数/总项目数

    ,NOW() AS load_dt                                  -- 加载时间

FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '项目口径'
  AND stage >= 1
  AND is_in_hongheibang = 'Y'
GROUP BY
    dt_month
    ,pc20080
    ,stage
    ,stage_label
    ,hit_type
ORDER BY
    pc20080
    ,stage
;


-- ====================================================================
-- ADS层补充：不达标合计行（按营销部汇总所有阶段）
-- ====================================================================
INSERT INTO ads.ads_ipd_ipm_qihua_hit_result_dd (
    dt_month              -- 统计月份（YYYYMM格式）
    ,pc20080              -- 归属营销部
    ,stage                -- 阶段（固定99表示合计）
    ,stage_label          -- 阶段标签（固定'不达标合计'）
    ,hit_type             -- 达标类型（固定'合计'）
    ,total_project_cnt    -- 该营销部总项目数
    ,total_sku_cnt        -- 该营销部总SKU数
    ,fail_project_cnt     -- 该营销部不达标项目数
    ,fail_sku_cnt         -- 该营销部不达标SKU数
    ,hit_rate             -- 达标率
    ,load_dt              -- 加载时间
)
SELECT
    dt_month                                           -- 统计月份
    ,pc20080                                           -- 归属营销部
    ,99 AS stage                                       -- 阶段（固定99表示合计）
    ,'不达标合计' AS stage_label                       -- 阶段标签（固定'不达标合计'）
    ,'合计' AS hit_type                                -- 达标类型（固定'合计'）

    ,COUNT(DISTINCT project_code) AS total_project_cnt -- 该营销部总项目数
    ,SUM(sku_count) AS total_sku_cnt                   -- 该营销部总SKU数
    ,COUNT(DISTINCT CASE WHEN is_hit = 'N' THEN project_code END) AS fail_project_cnt  -- 不达标项目数
    ,SUM(CASE WHEN is_hit = 'N' THEN sku_count ELSE 0 END) AS fail_sku_cnt  -- 不达标SKU数
    ,1 - COUNT(DISTINCT CASE WHEN is_hit = 'N' THEN project_code END)
         / NULLIF(COUNT(DISTINCT project_code), 0) AS hit_rate  -- 达标率
    ,NOW() AS load_dt                                  -- 加载时间

FROM dws.dws_ipd_ipm_qihua_hit_detail_dd
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
  AND data_type = '项目口径'
  AND stage >= 1
  AND is_in_hongheibang = 'Y'
GROUP BY
    dt_month
    ,pc20080
ORDER BY
    pc20080
;