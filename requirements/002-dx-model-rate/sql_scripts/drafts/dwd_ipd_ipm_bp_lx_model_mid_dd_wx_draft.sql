-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: dwd_ipd_ipm_bp_lx_model_mid_dd_wx_draft.sql
-- 功能描述: 外销新品命中率 - DWD层LX立项规划量按月拆分
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-05-25
-- 变更类型: CHG-02 产品线扩展（外销）
-- 说明: 
--   外销LX规划量与内销不同：
--   - 内销：dim_ipd_productmodel_dd 有36个月规划字段(HX00506~HX00541)直接展开
--   - 外销：只有HX00020（第一年规划销量），需按各产品线比例拆分为12个月
--   各产品线分摊比例：
--     显示：规划量×50%，按 0/0/0/16/12/10/15/7/10/4/6/20 (差值)
--     冰冷/洗/厨电：前6月各占40%/6，后6月各占60%/6
--     空调(家空+轻商)：12个月平均
--     激光：规划量×50%，按 5/10/10/10/10/12/10/10/8/5/5/5
-- ******************************************************************** --


-- ====================================================================
-- 第一段：冰冷/洗衣机/厨电 外销LX规划量（前6月40%均摊，后6月60%均摊）
-- ====================================================================
DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big IN ('控温储藏类产品','清洁卫生器具','供热采暖类产品','厨房电器类产品')
    AND model_type = '产品型号口径'
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_product AS (
    SELECT
        PG00061        -- 产品型号名称
        ,PG00002       -- 产品大类
        ,PG00003       -- 产品中类
        ,PG00004       -- 产品小类
        ,PG00020       -- 内外销
        ,PG00025       -- 实际上市时间
        ,HX00020       -- 第一年规划销量
        -- 按实际上市时间生成12个月的月份序列
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 前6月各占40%/6，后6月各占60%/6
        ,CONCAT(
            CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_productmodel_dd
    WHERE PG00020 = '外销'
        AND HX00020 IS NOT NULL
        AND PG00025 IS NOT NULL
        AND PG00002 IN ('控温储藏类产品','清洁卫生器具','供热采暖类产品','厨房电器类产品')
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061
        ,PG00002
        ,PG00003
        ,PG00004
        ,PG00020
        ,PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;



-- ====================================================================
-- 第二段：空调(家空+轻商) 外销LX规划量（12个月平均）
-- ====================================================================
DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big IN ('空气调节类产品')
    AND model_type = '产品型号口径'
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_kt_product AS (
    SELECT
        PG00061        -- 产品型号名称
        ,PG00002       -- 产品大类
        ,PG00003       -- 产品中类
        ,PG00004       -- 产品小类
        ,PG00020       -- 内外销
        ,PG00025       -- 实际上市时间
        ,HX00020       -- 第一年规划销量
        -- 按实际上市时间生成12个月的月份序列
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 12个月平均
        ,CONCAT(
            CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_productmodel_dd
    WHERE PG00020 = '外销'
        AND HX00020 IS NOT NULL
        AND PG00025 IS NOT NULL
        AND PG00002 = '空气调节类产品'
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061
        ,PG00002
        ,PG00003
        ,PG00004
        ,PG00020
        ,PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_kt_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;



-- ====================================================================
-- 第三段：显示(平板电视) 外销LX规划量
-- 规划量×50%为年目标，累计比例：0/0/0/16/28/38/53/60/70/74/80/100
-- 差值（各月占比%）：0/0/0/16/12/10/15/7/10/4/6/20
-- ====================================================================
DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big = '显示类产品'
    AND model_type = '产品型号口径'
    AND product_sml IN ('平板电视')
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_tv_product AS (
    SELECT
        title AS PG00061                    -- 产品型号描述
        ,his_productbigcategories AS PG00002  -- 产品大类
        ,his_productmiddlecategories AS PG00003  -- 产品中类
        ,his_productsmallcategories AS PG00004  -- 产品小类
        ,'外销' AS PG00020
        ,his_actualtimetomarket AS PG00025  -- 实际上市时间
        ,CAST(his_plannedsalesvolume AS DECIMALV3(20,4)) AS HX00020  -- 规划销量
        -- 按实际上市时间生成12个月的月份序列
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 规划量×50%，按差值比例拆分：0/0/0/16/12/10/15/7/10/4/6/20
        ,CONCAT(
            CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.00 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.00 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.00 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.16 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.15 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.07 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.04 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.06 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.20 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_jtplm_his_productmodel_dd
    WHERE his_productbigcategories = '显示类产品'
        AND his_productsmallcategories = '平板电视'
        AND his_domesticsalesorexport = '外销'
        AND his_plannedsalesvolume IS NOT NULL
        AND his_actualtimetomarket IS NOT NULL
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061, PG00002, PG00003, PG00004, PG00020, PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_tv_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;



-- ====================================================================
-- 第四段：激光 外销LX规划量
-- 规划量×50%为年目标，按 5/10/10/10/10/12/10/10/8/5/5/5 拆分
-- ====================================================================
DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big = '显示类产品'
    AND product_sml IN ('激光电视','家用投影')
    AND model_type = '产品型号口径'
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_laser_product AS (
    SELECT
        title AS PG00061
        ,his_productbigcategories AS PG00002
        ,his_productmiddlecategories AS PG00003
        ,his_productsmallcategories AS PG00004
        ,'外销' AS PG00020
        ,his_actualtimetomarket AS PG00025
        ,CAST(his_plannedsalesvolume AS DECIMALV3(20,4)) AS HX00020
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 规划量×50%，按 5/10/10/10/10/12/10/10/8/5/5/5 拆分
        ,CONCAT(
            CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.08 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_jtplm_his_productmodel_dd
    WHERE his_pmdproductaffiliatedcompany = '激光显示'
        AND his_domesticsalesorexport = '外销'
        AND his_productsmallcategories IN ('激光电视','家用投影')
        AND his_plannedsalesvolume IS NOT NULL
        AND his_actualtimetomarket IS NOT NULL
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061, PG00002, PG00003, PG00004, PG00020, PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_laser_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;
