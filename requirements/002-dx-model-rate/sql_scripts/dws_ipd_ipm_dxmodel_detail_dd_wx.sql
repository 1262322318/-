-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/05/26 10:10:32 GMT+08:00
-- ******************************************************************** --
-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: dws_ipd_ipm_dxmodel_detail_dd_wx_draft.sql
-- 功能描述: 外销新品命中率 - DWS层明细计算
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-05-26
-- 变更类型: CHG-02 产品线扩展（外销）
-- 说明:
--   zhibiao_type = '4'（新品命中率）
--   时间频率：针对昨天（${GP_START_DT}）
--   核心逻辑：
--     1. 规划量：只取LX，取上市以来全部累计
--     2. 实际销量：GSS系统，取上市以来全部累计
--     3. 保护期(is_project)：
--        - 本月上市=第0月，不纳入总数 → 'Y'
--        - 超过新品期(shangshi_m>=13) → 'Y'
--        - 上市3个月内不考核(shangshi_m<=3) → 'Y'
--        - 各产品线剔除条件 → 'Y'
--     4. 命中率阈值：实际/规划 ≥0.8 为命中(is_dx='N')
--   产品线：冰箱、冷柜、洗衣机、家用空调、平板电视、厨电、激光
-- ******************************************************************** --


-- ====================================================================
-- 第一段：冰箱/冷柜/洗衣机 外销新品命中率明细
-- 剔除规则：
--   冰箱：标机、样机、欧洲/美洲/东盟大区CKD全散件(除俄罗斯直发)、OEM
--   冷柜：样机、外协、OEM
--   洗衣机：泰国工厂全散件(6014)、OEM
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_dxmodel_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND zhibiao_type = '4'
    AND product_line IN ('冰箱','冷柜','洗衣机')
    AND in_out_sale = '外销';

INSERT INTO dws.dws_ipd_ipm_dxmodel_detail_dd(
    dt_month
    ,business_division
    ,product_line
    ,in_out_sale
    ,zhibiao_type
    ,prdct_model
    ,ir_act_time
    ,juece_delistingtime
    ,act_sales_qty
    ,plan_sales_qty
    ,sales_qty_rate
    ,brand
    ,product_big
    ,product_mid
    ,product_sml
    ,shangshi_m
    ,is_dx
    ,is_project
    ,model_label_2
    ,load_dt
)
WITH all_model AS (
    SELECT
        product_line
        ,PG00061
        ,PG00005
        ,PG00002
        ,PG00003
        ,PG00004
        ,PG00025
        ,HX00501
        ,(YEAR('${GP_START_DT}') - YEAR(PG00025)) * 12
            + (MONTH('${GP_START_DT}') - MONTH(PG00025)) AS shangshi_m
        ,CASE
            -- OEM品牌剔除（所有产品线通用）
            WHEN COALESCE(PG00005, '') = 'OEM品牌' THEN 'Y'
            -- 冰箱：标机剔除
            WHEN product_line = '冰箱' AND COALESCE(HX00026, '否') = '是' THEN 'Y'
            -- 冰箱：样机剔除
            WHEN product_line = '冰箱' AND COALESCE(HX00027, '否') = '是' THEN 'Y'
            -- 冰箱：全散件剔除（欧洲大区除俄罗斯直发、美洲大区、东盟区 且 CKD）
            WHEN product_line = '冰箱' AND HX00023 IN ('欧洲大区','美洲大区','东盟区')
                AND COALESCE(HX00024, '') <> '欧洲区销售部-俄罗斯冰冷洗直发'
                AND HX00226 = 'CKD' THEN 'Y'
            -- 冷柜：样机剔除
            WHEN product_line = '冷柜' AND COALESCE(HX00027, '否') = '是' THEN 'Y'
            -- 洗衣机：泰国工厂全散件剔除
            WHEN product_line = '洗衣机' AND PC00025 = '6014-洗衣机泰国工厂' THEN 'Y'
            -- 只选上市且未决策退市的
            WHEN NOT(PG00025 IS NOT NULL AND HX00501 IS NULL) THEN 'Y'
            ELSE 'N'
        END AS is_project_base
    FROM (
        SELECT
            id, PG00061
            ,CASE
                WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冰箱' AND PG00020 = '外销' THEN '冰箱'
                WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冷柜' AND PG00020 = '外销' THEN '冷柜'
                WHEN PG00002 = '清洁卫生器具' AND PG00003 IN ('洗衣机','干衣机') AND PG00020 = '外销' THEN '洗衣机'
                ELSE '其他'
            END AS product_line
            ,PG00020, PG00005, PG00002, PG00003, PG00004
            ,PC00025, HX00026, HX00027, HX00023, HX00024, HX00226, HX00083
            ,HX00501
            ,PG00025
        FROM dim.dim_ipd_productmodel_dd
        WHERE PG00020 = '外销'
    ) t1
    WHERE product_line IN ('冰箱','冷柜','洗衣机')
)
-- GSS实际销量（冰冷洗外销 - 占位，固定输出：产品型号+数量）
-- TODO: 待补充具体GSS协议订单查询逻辑
-- GSS"协议查询"→产品线选"冰箱"/"冷柜"/"洗衣机"，协议状态选"协议已发布"和"工艺BOM已发布"
,gss_sales AS (
--GSS系统协议订单发布量
--冰冷洗外销
SELECT 
  t.product_model as prdct_model, --产品型号
  sum(b.amount) as act_qty  --数量
FROM ods.odsgss_im_order_agreement a
LEFT JOIN ods.odsgss_im_rolling_plan_detail b ON b.roll_plan_number = a.roll_plan_number AND b.enable_flag = 'T'
LEFT JOIN (
    SELECT t1.product_code, t1.product_model FROM ods.odsgss_im_ecc_pln_bd_product_title t1 WHERE t1.enable_flag = 'T'
    UNION
    SELECT t2.product_code, t2.product_model FROM ods.odsgss_im_ecc_pln_bd_lg_product_title t2 WHERE t2.enable_flag = 'T'
    UNION
    SELECT t3.product_code, t3.product_model FROM ods.odsgss_im_ecc_pln_bd_xyj_product_title t3 WHERE t3.enable_flag = 'T'
) t ON t.product_code = b.country_product
LEFT JOIN ods.odsgss_im_grs_dic d ON a.status = d.property_code AND d.dic_code = 'XIEYI_STATUS' AND d.enable_flag = 'T'
WHERE a.enable_flag = 'T'
and d.property_value in ('协议已发布','工艺BOM已发布')
group by  t.product_model
)
-- 外销LX规划量（取上市以来全部累计）
,plan_sales AS (
    SELECT
        t1.prdct_model
        ,SUM(t1.plan_sales_qty) AS plan_sales_qty
    FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd t1
    LEFT JOIN (
        SELECT PG00061
            ,MIN(DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m')) AS min_dtmonth
        FROM all_model
        WHERE PG00025 IS NOT NULL
        GROUP BY PG00061
    ) t2 ON t1.prdct_model = t2.PG00061
    WHERE t1.plan_type = 'LX'
        AND t1.in_out_sale = '外销'
        AND t1.product_big IN ('控温储藏类产品','清洁卫生器具')
        AND t1.model_type = '产品型号口径'
        AND t1.dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND t1.dt_month >= COALESCE(t2.min_dtmonth, '190001')
    GROUP BY t1.prdct_model
)
,fuchan_model AS (
    --本年复产型号（产品型号口径）
    SELECT DISTINCT masterDataName
    FROM dwd.dwd_ipd_ipm_hdrp_delisted_dd
    WHERE formstatus = '发布'
    AND formtype = '再上市'
    AND masterDataType = 'productModel'
    AND SUBSTRING(publishtime,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
)
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m') AS dt_month
    ,'国际营销' AS business_division
    ,t1.product_line
    ,'外销' AS in_out_sale
    ,'4' AS zhibiao_type
    ,t1.PG00061
    ,t1.PG00025
    ,t1.HX00501
    ,COALESCE(t2.act_qty, 0) AS act_sales_qty
    ,t3.plan_sales_qty
    ,COALESCE(COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0), 0) AS sales_qty_rate
    ,t1.PG00005
    ,t1.PG00002
    ,t1.PG00003
    ,t1.PG00004
    ,t1.shangshi_m
    ,CASE WHEN COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0) < 0.8
        THEN 'Y' ELSE 'N' END AS is_dx
    ,CASE
        WHEN t1.shangshi_m >= 13 THEN 'Y'
        WHEN t1.shangshi_m <= 3 THEN 'Y'
        WHEN t_fuchan.masterDataName IS NOT NULL THEN 'Y'  --本年复产不考核
        ELSE t1.is_project_base
    END AS is_project
    ,CASE
        WHEN t1.shangshi_m <= 3 THEN '[0,3]'
        WHEN t1.shangshi_m <= 6 THEN '(3,6]'
        WHEN t1.shangshi_m <= 12 THEN '(6,12]'
        WHEN t1.shangshi_m > 12 THEN '(12,)'
        ELSE '其他'
    END AS model_label_2
    ,NOW()
FROM all_model t1
LEFT JOIN gss_sales t2 ON t1.PG00061 = t2.prdct_model
LEFT JOIN plan_sales t3 ON t1.PG00061 = t3.prdct_model
LEFT JOIN fuchan_model t_fuchan ON t1.PG00061 = t_fuchan.masterDataName;






-- ====================================================================
-- 第二段：家用空调（家空+轻商）外销新品命中率明细
-- GSS排产单实际销量（PUB-009：技术评审通过）
-- 核心转换规则：
--   家空：以整机为主，内机/外机通过HDRP的PC20029/PC20028映射回整机再×0.5
--   轻商：以内机/外机为主，整机通过HDRP的PC20029/PC20028拆到内机和外机
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_dxmodel_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND zhibiao_type = '4'
    AND product_line = '家用空调'
    AND in_out_sale = '外销';

INSERT INTO dws.dws_ipd_ipm_dxmodel_detail_dd(
    dt_month
    ,business_division
    ,product_line
    ,in_out_sale
    ,zhibiao_type
    ,prdct_model
    ,ir_act_time
    ,juece_delistingtime
    ,act_sales_qty
    ,plan_sales_qty
    ,sales_qty_rate
    ,brand
    ,product_big
    ,product_mid
    ,product_sml
    ,shangshi_m
    ,is_dx
    ,is_project
    ,model_label_2
    ,load_dt
)
WITH kt_wx_model AS (
    SELECT
        PG00061
        ,'家用空调' AS product_line
        ,PG00005
        ,PG00002
        ,PG00003
        ,PG00004
        ,PG00025
        ,HX00501
        ,(YEAR('${GP_START_DT}') - YEAR(PG00025)) * 12
            + (MONTH('${GP_START_DT}') - MONTH(PG00025)) AS shangshi_m
        ,hx00290    -- 产品类别
        ,CASE
            -- OEM品牌剔除
            WHEN COALESCE(PG00005, '') in ('OEM品牌','TOSHIBA','REGZA','HITACHI','YORK') THEN 'Y'
            -- 家空：产品类别仅统计"基准机型"
            WHEN pg00003 IN ('家用房间空调','除湿机') AND COALESCE(hx00290, '') NOT IN ('基型产品','') THEN 'Y'
            -- 只选上市且未决策退市的
            WHEN NOT(PG00025 IS NOT NULL AND HX00501 IS NULL) THEN 'Y'
            ELSE 'N'
        END AS is_project_base
    FROM dim.dim_ipd_productmodel_dd
    WHERE PG00002 = '空气调节类产品'
        AND PG00020 = '外销'
        AND (
            -- 家空外销：分体式不取内机外机（只取整机）
            (pg00015 = '空调' AND pg00003 IN ('除湿机','家用房间空调')
                AND pg00004 IN ('除湿机','窗式空调器','移动式空调器','分体式空调器整机'))
            OR
            -- 轻商外销：单元式取内机外机，不取整机
            (pg00015 = '空调' AND pg00003 = '中央空调'
                AND pg00004 IN ('单元式内机','单元式外机','空气源热泵三联供','热泵热水机','屋顶机','一拖多外机'))
        )
)
-- HDRP整机→内外机映射关系（用于GSS销量转换）
-- 家空：整机下有PC20029(内机产品型号)、PC20028(外机产品型号)
-- 轻商：整机的PC20029/PC20028指向对应的内机/外机
,hdrp_mapping AS (
    SELECT distinct
        PG00061 AS zhengji_model    -- 整机产品型号
        ,PC20029 AS neiji_model     -- 内机产品型号
        ,pc20055 AS waiji_model     -- 外机产品型号（注：字段为pc20055）
    FROM dim.dim_ipd_productmodel_dd
    WHERE PG00002 = '空气调节类产品'
        AND PG00020 = '外销'
        AND pg00004 in ('分体式空调器整机','单元式整机')
)
-- GSS排产单原始数据（技术评审通过，不限item_type）
,gss_raw AS (
    SELECT
        oispl.h_spec AS prdct_model    -- 产品型号（原型）
        ,oispl.item_type               -- 产品类型
        ,case when bigc_name in ('家用出口空调','家用房间空调','除湿机') then '家空' 
when bigc_name in ('中央空调','商用出口空调') then '轻商' else '其他' end as productline
        ,SUM(oispl.qty) AS qty
    FROM ods.odsgss_im_sale_prod_header oisph
    LEFT JOIN ods.odsgss_im_sale_prod_line oispl
        ON oisph.prod_id = oispl.prod_id
    LEFT JOIN ods.odsgss_im_sale_prod_kf_line oispkl
        ON oisph.prod_id = oispkl.prod_id
        and oisph.batchno = oispkl.batchno
        AND oispkl.is_zx = 2
    WHERE oisph.sale_stat in (7,9)  -- 技术评审通过 生产评审通过
        AND DATE_FORMAT(oispkl.ps_date, '%Y%m') <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY oispl.h_spec, oispl.item_type,case when bigc_name in ('家用出口空调','家用房间空调','除湿机') then '家空' 
when bigc_name in ('中央空调','商用出口空调') then '轻商' else '其他' end
)
-- GSS实际销量转换
,gss_sales AS (
    SELECT prdct_model, SUM(act_qty) AS act_qty
    FROM (
        -- 1. 整机订单：直接计入整机型号
        SELECT prdct_model, qty AS act_qty
        FROM gss_raw
        WHERE item_type = 1  -- 整机
        and productline = '家空'

        UNION ALL
        -- 2. 对于家空 内机跟外机，由于业务模式就是通过整机下内机外机订单，所以产品型号名称就是整机，不需要关联HDRP  只需要 销量×0.5计入整机
        SELECT prdct_model, qty * 0.5 AS act_qty
        FROM gss_raw
        WHERE item_type in (2,3)
        and productline = '家空'

        UNION ALL
        -- 4. 轻商-整机订单：通过映射拆到内机和外机
        -- 拆到内机
        SELECT hm.neiji_model AS prdct_model, gr.qty AS act_qty
        FROM gss_raw gr
        INNER JOIN hdrp_mapping hm ON gr.prdct_model = hm.zhengji_model
        WHERE gr.item_type = 1
        and productline = '轻商'
            AND hm.neiji_model IN (SELECT PG00061 FROM kt_wx_model WHERE PG00004 = '单元式内机')

        UNION ALL
        -- 拆到外机
        SELECT hm.waiji_model AS prdct_model, gr.qty AS act_qty
        FROM gss_raw gr
        INNER JOIN hdrp_mapping hm ON gr.prdct_model = hm.zhengji_model
        WHERE gr.item_type = 1
        and productline = '轻商'
            AND hm.waiji_model IN (SELECT PG00061 FROM kt_wx_model WHERE PG00004 = '单元式外机')

        UNION ALL
        -- 5. 轻商-内机/外机直接订单：直接计入
        SELECT prdct_model, qty AS act_qty
        FROM gss_raw
        WHERE item_type IN (2, 3)
        and productline = '轻商'
          --AND prdct_model IN (SELECT PG00061 FROM kt_wx_model WHERE PG00004 IN ('单元式内机','单元式外机'))

        UNION ALL
        -- 6. 其他品类（移动空调/窗机/除湿机等）：直接计入
        SELECT prdct_model, qty AS act_qty
        FROM gss_raw
        WHERE item_type NOT IN (1, 2, 3)
    ) t
    GROUP BY prdct_model
)

-- 外销LX规划量（取上市以来全部累计）
,plan_sales AS (
    SELECT
        t1.prdct_model
        ,SUM(t1.plan_sales_qty) AS plan_sales_qty
    FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd t1
    LEFT JOIN (
        SELECT PG00061
            ,MIN(DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m')) AS min_dtmonth
        FROM kt_wx_model
        WHERE PG00025 IS NOT NULL
        GROUP BY PG00061
    ) t2 ON t1.prdct_model = t2.PG00061
    WHERE t1.plan_type = 'LX'
        AND t1.in_out_sale = '外销'
        AND t1.product_big = '空气调节类产品'
        AND t1.model_type = '产品型号口径'
        AND t1.dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND t1.dt_month >= COALESCE(t2.min_dtmonth, '190001')
    GROUP BY t1.prdct_model
)
,fuchan_model AS (
    --本年复产型号（产品型号口径）
    SELECT DISTINCT masterDataName
    FROM dwd.dwd_ipd_ipm_hdrp_delisted_dd
    WHERE formstatus = '发布'
    AND formtype = '再上市'
    AND masterDataType = 'productModel'
    AND SUBSTRING(publishtime,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
)
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m') AS dt_month
    ,'国际营销' AS business_division
    ,'家用空调' AS product_line
    ,'外销' AS in_out_sale
    ,'4' AS zhibiao_type
    ,t1.PG00061
    ,t1.PG00025
    ,t1.HX00501
    ,COALESCE(t2.act_qty, 0) AS act_sales_qty
    ,t3.plan_sales_qty
    ,COALESCE(COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0), 0) AS sales_qty_rate
    ,t1.PG00005
    ,t1.PG00002
    ,t1.PG00003
    ,t1.PG00004
    ,t1.shangshi_m
    ,CASE WHEN COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0) < 0.8
        THEN 'Y' ELSE 'N' END AS is_dx
    ,CASE
        WHEN t1.shangshi_m >= 13 THEN 'Y'
        WHEN t1.shangshi_m <= 3 THEN 'Y'
        WHEN t_fuchan.masterDataName IS NOT NULL THEN 'Y'  --本年复产不考核
        ELSE t1.is_project_base
    END AS is_project
    ,CASE
        WHEN t1.shangshi_m <= 3 THEN '[0,3]'
        WHEN t1.shangshi_m <= 6 THEN '(3,6]'
        WHEN t1.shangshi_m <= 12 THEN '(6,12]'
        WHEN t1.shangshi_m > 12 THEN '(12,)'
        ELSE '其他'
    END AS model_label_2
    ,NOW()
FROM kt_wx_model t1
LEFT JOIN gss_sales t2 ON t1.PG00061 = t2.prdct_model
LEFT JOIN plan_sales t3 ON t1.PG00061 = t3.prdct_model
LEFT JOIN fuchan_model t_fuchan ON t1.PG00061 = t_fuchan.masterDataName
;





-- ====================================================================
-- 第三段：平板电视（显示）外销新品命中率明细
-- 数据源：PLM系统 dim_ipd_jtplm_his_productmodel_dd
-- 品牌限定：Hisense+TOSHIBA+REGZA（品牌字段不取"OEM品牌"值）
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_dxmodel_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND zhibiao_type = '4'
    AND product_line = '平板电视'
    AND in_out_sale = '外销';

INSERT INTO dws.dws_ipd_ipm_dxmodel_detail_dd(
    dt_month
    ,business_division
    ,product_line
    ,in_out_sale
    ,zhibiao_type
    ,prdct_model
    ,ir_act_time
    ,juece_delistingtime
    ,act_sales_qty
    ,plan_sales_qty
    ,sales_qty_rate
    ,brand
    ,product_big
    ,product_mid
    ,product_sml
    ,shangshi_m
    ,is_dx
    ,is_project
    ,model_label_2
    ,load_dt
    ,countries_regions  --立项国家及区域
)
WITH tv_wx_model AS (
    SELECT
        title AS PG00061
        ,his_productbigcategories AS PG00002
        ,his_productmiddlecategories AS PG00003
        ,his_productsmallcategories AS PG00004
        ,his_productsbrand AS brand
        ,'外销' AS PG00020
        ,his_actualtimetomarket AS PG00025
        ,his_actualdelistingtime AS HX00501
        ,(YEAR('${GP_START_DT}') - YEAR(his_actualtimetomarket)) * 12
            + (MONTH('${GP_START_DT}') - MONTH(his_actualtimetomarket)) AS shangshi_m
        ,CASE
            -- 品牌字段不取"OEM品牌"值
            WHEN COALESCE(his_productsbrand, '') = 'OEM品牌' THEN 'Y'
            -- 品牌限定：Hisense + TOSHIBA + REGZA
            WHEN his_productsbrand NOT IN ('Hisense','TOSHIBA','REGZA') THEN 'Y'
            -- 只选上市的
            WHEN COALESCE(his_actualtimetomarket, '') = '' THEN 'Y'
            -- 已退市的排除
            WHEN COALESCE(his_actualdelistingtime, '') != '' THEN 'Y'
            ELSE 'N'
        END AS is_project_base
    FROM dim.dim_ipd_jtplm_his_productmodel_dd
    WHERE his_productbigcategories = '显示类产品'
        AND his_productsmallcategories = '平板电视'
        AND his_domesticsalesorexport = '外销'
)
-- GSS实际销量（显示外销 - 占位）
-- TODO: 待补充GSS协议订单查询逻辑（协议发布订单量）
,gss_sales AS (
--电视
select
sum(t1.ORDER_QTY)act_qty   --数量
,coalesce (t2.model_name,substring_index(t1.PRODUCT_CODE, '(', 1)) prdct_model --产品型号
from (SELECT 
PRODUCT_CODE  --生产版本
,ORDER_QTY   --数量
FROM ods.odsgss_im_sales_order_title 
WHERE ROLL_PLAN_NUMBER NOT LIKE 'R%'
AND ROLL_PLAN_NUMBER NOT LIKE 'B%'
AND ORDER_STATUS_CODE NOT IN ('1002', '1003', '1005', '1006')
AND coalesce (PANEL_CODE,'无') != '无'
and enable_flag = 'T'
) t1 
left join (
select distinct
short_desc_zh,model_name
from dw.dim_product_base_info_dd
where product_type_code='ZZPV'
and delete_flag!='Y'
) t2 
on t1.PRODUCT_CODE = t2.short_desc_zh
group by coalesce (t2.model_name,substring_index(t1.PRODUCT_CODE, '(', 1))
)
-- 外销LX规划量（取上市以来全部累计）
,plan_sales AS (
    SELECT
        t1.prdct_model
        ,SUM(t1.plan_sales_qty) AS plan_sales_qty
    FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd t1
    LEFT JOIN (
        SELECT PG00061
            ,MIN(DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m')) AS min_dtmonth
        FROM tv_wx_model
        WHERE PG00025 IS NOT NULL
        GROUP BY PG00061
    ) t2 ON t1.prdct_model = t2.PG00061
    WHERE t1.plan_type = 'LX'
        AND t1.in_out_sale = '外销'
        AND t1.product_big = '显示类产品'
        AND t1.product_sml = '平板电视'
        AND t1.model_type = '产品型号口径'
        AND t1.dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND t1.dt_month >= COALESCE(t2.min_dtmonth, '190001')
    GROUP BY t1.prdct_model
)
,fuchan_model AS (
    --本年复产型号（产品型号口径）
    SELECT DISTINCT masterDataName
    FROM dwd.dwd_ipd_ipm_hdrp_delisted_dd
    WHERE formstatus = '发布'
    AND formtype = '再上市'
    AND masterDataType = 'productModel'
    AND SUBSTRING(publishtime,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
)
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m') AS dt_month
    ,'国际营销' AS business_division
    ,'平板电视' AS product_line
    ,'外销' AS in_out_sale
    ,'4' AS zhibiao_type
    ,t1.PG00061
    ,t1.PG00025
    ,t1.HX00501
    ,COALESCE(t2.act_qty, 0) AS act_sales_qty
    ,t3.plan_sales_qty
    ,COALESCE(COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0), 0) AS sales_qty_rate
    ,t1.brand
    ,t1.PG00002
    ,t1.PG00003
    ,t1.PG00004
    ,t1.shangshi_m
    ,CASE WHEN COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0) < 0.8
        THEN 'Y' ELSE 'N' END AS is_dx
    ,CASE
        WHEN t1.shangshi_m >= 13 THEN 'Y'
        WHEN t1.shangshi_m <= 3 THEN 'Y'
        WHEN t_fuchan.masterDataName IS NOT NULL THEN 'Y'  --本年复产不考核
        ELSE t1.is_project_base
    END AS is_project
    ,CASE
        WHEN t1.shangshi_m <= 3 THEN '[0,3]'
        WHEN t1.shangshi_m <= 6 THEN '(3,6]'
        WHEN t1.shangshi_m <= 12 THEN '(6,12]'
        WHEN t1.shangshi_m > 12 THEN '(12,)'
        ELSE '其他'
    END AS model_label_2
    ,NOW()
    ,t5.countries_regions  --立项国家及区域
FROM tv_wx_model t1
LEFT JOIN gss_sales t2 ON t1.PG00061 = t2.prdct_model
LEFT JOIN plan_sales t3 ON t1.PG00061 = t3.prdct_model
LEFT JOIN fuchan_model t_fuchan ON t1.PG00061 = t_fuchan.masterDataName
left join (
--生产版本下产品型号对应的【产品线】、【立项国家及区域】
select 
modelname
,group_concat(distinct his_pmdproductlinename)as his_pmdproductlinename  --产品线
,group_concat(distinct countries_regions)as countries_regions  --立项国家及区域
from dim.dim_ipd_jtplm_his_productversion_dd
where his_productsmallcategories = '平板电视'
group by modelname
)t5
on t1.PG00061 = t5.modelname
;


-- ====================================================================
-- 第四段：厨电 外销新品命中率明细
-- 产品线字段HX00223取值：烟机、灶具、洗碗机、电热水器、燃气热水器、烤箱
-- 剔除规则：OEM、散件(洗碗机型号名以"/SKD"结束)、样机(型号名以"YJ"结束)
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_dxmodel_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND zhibiao_type = '4'
    AND product_line = '厨电'
    AND in_out_sale = '外销';

INSERT INTO dws.dws_ipd_ipm_dxmodel_detail_dd(
    dt_month
    ,business_division
    ,product_line
    ,in_out_sale
    ,zhibiao_type
    ,prdct_model
    ,ir_act_time
    ,juece_delistingtime
    ,act_sales_qty
    ,plan_sales_qty
    ,sales_qty_rate
    ,brand
    ,product_big
    ,product_mid
    ,product_sml
    ,shangshi_m
    ,is_dx
    ,is_project
    ,model_label_2
    ,load_dt
)
WITH cd_wx_model AS (
    SELECT
        PG00061
        ,'厨电' AS product_line
        ,PG00005
        ,PG00002
        ,PG00003
        ,PG00004
        ,PG00025
        ,HX00501
        ,(YEAR('${GP_START_DT}') - YEAR(PG00025)) * 12
            + (MONTH('${GP_START_DT}') - MONTH(PG00025)) AS shangshi_m
        ,CASE
            -- OEM品牌剔除
            WHEN COALESCE(PG00005, '') = 'OEM品牌' THEN 'Y'
            -- 散件剔除（仅洗碗机）：产品型号名以"/SKD"结束
            WHEN PG00061 LIKE '%/SKD' THEN 'Y'
            -- 样机剔除：产品型号名以"YJ"结束
            WHEN PG00061 LIKE '%YJ' THEN 'Y'
            -- 只选上市且未决策退市的
            WHEN NOT(PG00025 IS NOT NULL AND HX00501 IS NULL) THEN 'Y'
            ELSE 'N'
        END AS is_project_base
    FROM dim.dim_ipd_productmodel_dd
    WHERE HX00223 IN ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')
        AND PG00020 = '外销'
)
-- GSS实际销量（厨电外销 - 占位）
-- TODO: 待补充GSS协议订单查询逻辑
-- ①GSS"协议查询"→产品线选"洗碗机"，协议状态选"技术协议已发布"和"BOM已发布"
-- ②GSS"协议查询"→产品线选"厨电"，协议状态选"技术协议已发布"和"BOM已发布"
,gss_sales AS (
--GGS 协议查询
--GSS系统协议订单发布量
select 
export_type_no as prdct_model	--出口型号
,sum(qty) as act_qty	--数量
 from ods.odsgss_im_cw_order_ledger oicol 
where agreement_status in ('bom_published','published')
and product_line_name in ('洗碗机','厨电')
group by export_type_no
)
-- 外销LX规划量（取上市以来全部累计）
,plan_sales AS (
    SELECT
        t1.prdct_model
        ,SUM(t1.plan_sales_qty) AS plan_sales_qty
    FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd t1
    LEFT JOIN (
        SELECT PG00061
            ,MIN(DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m')) AS min_dtmonth
        FROM cd_wx_model
        WHERE PG00025 IS NOT NULL
        GROUP BY PG00061
    ) t2 ON t1.prdct_model = t2.PG00061
    WHERE t1.plan_type = 'LX'
        AND t1.in_out_sale = '外销'
        AND t1.product_big = '厨房电器类产品'
        AND t1.model_type = '产品型号口径'
        AND t1.dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND t1.dt_month >= COALESCE(t2.min_dtmonth, '190001')
    GROUP BY t1.prdct_model
)
,fuchan_model AS (
    --本年复产型号（产品型号口径）
    SELECT DISTINCT masterDataName
    FROM dwd.dwd_ipd_ipm_hdrp_delisted_dd
    WHERE formstatus = '发布'
    AND formtype = '再上市'
    AND masterDataType = 'productModel'
    AND SUBSTRING(publishtime,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
)
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m') AS dt_month
    ,'国际营销' AS business_division
    ,'厨电' AS product_line
    ,'外销' AS in_out_sale
    ,'4' AS zhibiao_type
    ,t1.PG00061
    ,t1.PG00025
    ,t1.HX00501
    ,COALESCE(t2.act_qty, 0) AS act_sales_qty
    ,t3.plan_sales_qty
    ,COALESCE(COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0), 0) AS sales_qty_rate
    ,t1.PG00005
    ,t1.PG00002
    ,t1.PG00003
    ,t1.PG00004
    ,t1.shangshi_m
    ,CASE WHEN COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0) < 0.8
        THEN 'Y' ELSE 'N' END AS is_dx
    ,CASE
        WHEN t1.shangshi_m >= 13 THEN 'Y'
        WHEN t1.shangshi_m <= 3 THEN 'Y'
        WHEN t_fuchan.masterDataName IS NOT NULL THEN 'Y'  --本年复产不考核
        ELSE t1.is_project_base
    END AS is_project
    ,CASE
        WHEN t1.shangshi_m <= 3 THEN '[0,3]'
        WHEN t1.shangshi_m <= 6 THEN '(3,6]'
        WHEN t1.shangshi_m <= 12 THEN '(6,12]'
        WHEN t1.shangshi_m > 12 THEN '(12,)'
        ELSE '其他'
    END AS model_label_2
    ,NOW()
FROM cd_wx_model t1
LEFT JOIN gss_sales t2 ON t1.PG00061 = t2.prdct_model
LEFT JOIN plan_sales t3 ON t1.PG00061 = t3.prdct_model
LEFT JOIN fuchan_model t_fuchan ON t1.PG00061 = t_fuchan.masterDataName;



-- ====================================================================
-- 第五段：激光 外销新品命中率明细
-- 数据源：PLM系统 dim_ipd_jtplm_his_productmodel_dd
-- 产品公司="激光显示"，小类"激光电视/家用投影"
-- 剔除规则：品牌字段不取"OEM品牌"值、空壳样机(型号名以"30"结束)
-- ====================================================================
DELETE FROM dws.dws_ipd_ipm_dxmodel_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND zhibiao_type = '4'
    AND product_line = '激光'
    AND in_out_sale = '外销';

INSERT INTO dws.dws_ipd_ipm_dxmodel_detail_dd(
    dt_month
    ,business_division
    ,product_line
    ,in_out_sale
    ,zhibiao_type
    ,prdct_model
    ,ir_act_time
    ,juece_delistingtime
    ,act_sales_qty
    ,plan_sales_qty
    ,sales_qty_rate
    ,brand
    ,product_big
    ,product_mid
    ,product_sml
    ,shangshi_m
    ,is_dx
    ,is_project
    ,model_label_2
    ,load_dt
)
WITH laser_wx_model AS (
    SELECT
        title AS PG00061
        ,his_productbigcategories AS PG00002
        ,his_productmiddlecategories AS PG00003
        ,his_productsmallcategories AS PG00004
        ,his_productsbrand AS brand
        ,'外销' AS PG00020
        ,his_actualtimetomarket AS PG00025
        ,his_actualdelistingtime AS HX00501
        ,(YEAR('${GP_START_DT}') - YEAR(his_actualtimetomarket)) * 12
            + (MONTH('${GP_START_DT}') - MONTH(his_actualtimetomarket)) AS shangshi_m
        ,CASE
            -- 品牌字段不取"OEM品牌"值
            WHEN COALESCE(his_productsbrand, '') = 'OEM品牌' THEN 'Y'
            -- 空壳样机剔除：产品型号名以"30"结束
            WHEN title LIKE '%30' THEN 'Y'
            -- 只选上市的
            WHEN COALESCE(his_actualtimetomarket, '') = '' THEN 'Y'
            -- 已退市的排除
            WHEN COALESCE(his_actualdelistingtime, '') != '' THEN 'Y'
            ELSE 'N'
        END AS is_project_base
    FROM dim.dim_ipd_jtplm_his_productmodel_dd
    WHERE his_pmdproductaffiliatedcompany = '激光显示'
        AND his_domesticsalesorexport = '外销'
        AND his_productsmallcategories IN ('激光电视','家用投影')
)
-- GSS实际销量（激光外销 - 占位）
-- TODO: 待补充GSS协议订单查询逻辑
-- ①GSS"协议查询"→产品线选"激光电视"，协议状态选"技术协议已发布"和"BOM已发布"
-- ②剔除生产版本为"30"结尾的空壳样机和出口方式为"CKD-DK"的订单
,gss_sales AS (
--激光订单表
select
sum(t1.expect_qty) act_qty  --数量
,coalesce (t2.model_name,substring_index(t1.model_code, '(', 1))prdct_model  --产品型号
from (SELECT 
model_code  --生产版本
,expect_qty  --数量
FROM ods.odsgss_im_jg_order
WHERE TURN_STATUS in ('8','9','10','11','12','13')
AND MODEL_CODE NOT LIKE '%(30)%'
AND UPPER(CUSTOMER_MODEL) NOT LIKE '%DUMMY%'
AND EXPORT_PACKING_WAY != 'CKD-DK'
) t1 
left join (
select distinct
short_desc_zh,model_name
from dw.dim_product_base_info_dd
where product_type_code='ZZPV'
and delete_flag!='Y'
) t2 
on t1.model_code = t2.short_desc_zh
group by coalesce (t2.model_name,substring_index(t1.model_code, '(', 1))

)
-- 外销LX规划量（取上市以来全部累计）
,plan_sales AS (
    SELECT
        t1.prdct_model
        ,SUM(t1.plan_sales_qty) AS plan_sales_qty
    FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd t1
    LEFT JOIN (
        SELECT PG00061
            ,MIN(DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m')) AS min_dtmonth
        FROM laser_wx_model
        WHERE PG00025 IS NOT NULL
        GROUP BY PG00061
    ) t2 ON t1.prdct_model = t2.PG00061
    WHERE t1.plan_type = 'LX'
    and t1.product_sml IN ('激光电视','家用投影')
        AND t1.dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
        AND t1.dt_month >= COALESCE(t2.min_dtmonth, '190001')
    GROUP BY t1.prdct_model
)
,fuchan_model AS (
    --本年复产型号（产品型号口径）
    SELECT DISTINCT masterDataName
    FROM dwd.dwd_ipd_ipm_hdrp_delisted_dd
    WHERE formstatus = '发布'
    AND formtype = '再上市'
    AND masterDataType = 'productModel'
    AND SUBSTRING(publishtime,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
)
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m') AS dt_month
    ,'国际营销' AS business_division
    ,'激光' AS product_line
    ,'外销' AS in_out_sale
    ,'4' AS zhibiao_type
    ,t1.PG00061
    ,t1.PG00025
    ,t1.HX00501
    ,COALESCE(t2.act_qty, 0) AS act_sales_qty
    ,t3.plan_sales_qty
    ,COALESCE(COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0), 0) AS sales_qty_rate
    ,t1.brand
    ,t1.PG00002
    ,t1.PG00003
    ,t1.PG00004
    ,t1.shangshi_m
    ,CASE WHEN COALESCE(t2.act_qty, 0) / NULLIF(t3.plan_sales_qty, 0) < 0.8
        THEN 'Y' ELSE 'N' END AS is_dx
    ,CASE
        WHEN t1.shangshi_m >= 13 THEN 'Y'
        WHEN t1.shangshi_m <= 3 THEN 'Y'
        WHEN t_fuchan.masterDataName IS NOT NULL THEN 'Y'  --本年复产不考核
        ELSE t1.is_project_base
    END AS is_project
    ,CASE
        WHEN t1.shangshi_m <= 3 THEN '[0,3]'
        WHEN t1.shangshi_m <= 6 THEN '(3,6]'
        WHEN t1.shangshi_m <= 12 THEN '(6,12]'
        WHEN t1.shangshi_m > 12 THEN '(12,)'
        ELSE '其他'
    END AS model_label_2
    ,NOW()
FROM laser_wx_model t1
LEFT JOIN gss_sales t2 ON t1.PG00061 = t2.prdct_model
LEFT JOIN plan_sales t3 ON t1.PG00061 = t3.prdct_model
LEFT JOIN fuchan_model t_fuchan ON t1.PG00061 = t_fuchan.masterDataName;
