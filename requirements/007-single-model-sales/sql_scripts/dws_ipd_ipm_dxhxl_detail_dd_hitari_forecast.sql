-- DORIS sql 
-- ******************************************************************** --
-- 脚本名称: dws_ipd_ipm_dxhxl_detail_dd_hitari_forecast.sql
-- 功能描述: 日立单型号销量未来月份预测（纯SQL版，一次性生成所有未来月份）
-- 逻辑说明: 
--   1. 生成月份序列：从当前月到今年12月（实际销量只到上月，当前月起需预测）
--   2. 当前月型号范围从实际在销数据取，未来月从在销型号数预测表取
--   3. 从BP/LX规划量表取每月规划量作为预测销量
--   4. 年累销量 = 上月实际年累 + 从当前月起逐月规划量累加
-- 参数: 无需外部参数，全部基于CURDATE()动态计算
-- 依赖: dws_ipd_ipm_sale_model_detail_dd_hitari_forecast.sql（需先执行在销型号数预测）
-- ******************************************************************** --

-- 删除今年所有中央空调单型号销量预测数据（幂等）
-- 注意：单型号销量实际数据是上月的，预测从当前月开始
DELETE FROM dws.dws_ipd_ipm_dxhxl_detail_dd 
WHERE company = '空调公司'
    AND product_line = '中央空调'
    AND dt_type = '月'
    and sales_type = '规划'
    AND dt_month >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')
    AND dt_month <= CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y'), '12');

-- 插入预测数据
INSERT INTO dws.dws_ipd_ipm_dxhxl_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line
,in_out_sale
,model
,sales_qty   --销量（月度，用规划量代替）
,sales_amt   --销额（月度，用规划销额代替）
,sales_type
,model_label_1   --产品平台
,model_label_10  --阶段
,is_project   --是否保护期
,load_dt
,kt_nbzz   --空气事业部内部组织
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,platform  --产品平台
,productmodel  --产品型号名称
,chanpindingwei  --产品定位
,plan_base  --规划生产基地
,brand  --品牌
,productmodel__life  --产品生命周期状态
,act_time_ss  --上市时间
,act_time_tszb  --退市准备
,act_time_tzxd  --停止下单
,act_time_tzsc  --停止生产
,PG00015  --产品公司
,productmodel_id  --产品型号id
,salemodel    --销售型号名称
,salemodel_code    --销售型号编码
,salemodel_id  --销售型号id
,PC20080    --归属营销部
,HX00379    --是否模块组合
,PC20006    --标准品/定制产品
,is_project_nk  --内控口径
,matnr  --物料编码
,HX00327    --所有者
,PC20018    --非标对应原型机
,PG00009    --产品系列
,sales_qty_y   --销量-年累（实际年累+规划累加）
,sales_amt_y   --销额-年累
)
-- CTE1: month_seq — 生成预测月份序列（当前月 ~ 今年12月）
-- 单型号销量实际数据是上月的，所以从当前月开始预测（offset从0开始）
WITH month_seq AS (
    SELECT 0 AS offset UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10 UNION ALL SELECT 11
)
,target_months AS (
    SELECT
        DATE_FORMAT(DATE_ADD(
            STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
            INTERVAL m.offset MONTH
        ), '%Y%m') AS target_month
        ,LAST_DAY(DATE_ADD(
            STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
            INTERVAL m.offset MONTH
        )) AS target_month_end
    FROM month_seq m
    WHERE DATE_FORMAT(DATE_ADD(
            STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
            INTERVAL m.offset MONTH
        ), '%Y') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')  -- 限制在今年内
)
-- CTE2: base_model — 取各预测月的中央空调型号范围
-- 当前月：从实际数据表取（dt_type='月'）
-- 未来月：从预测数据表取（dt_type='月'）
,base_model AS (
    -- 当前月：取实际在销数据
    SELECT
        dt_month
        ,business_division   --事业部
        ,company
        ,product_line
        ,kt_nbzz  --空气事业部内部组织
        ,in_out_sale  --内销/外销
        ,model  --销售型号名称（日立管理口径）
        ,model_label_10  --阶段
        ,model_label_16  --指标范围
        ,is_project  --是否保护期
        ,product_big  --产品大类
        ,product_mid  --产品中类
        ,product_sml  --产品小类
        ,platform  --产品平台
        ,productmodel  --产品型号名称
        ,chanpindingwei  --产品定位
        ,plan_base  --规划生产基地
        ,brand  --品牌
        ,productmodel__life  --生命周期
        ,act_time_ss  --上市时间
        ,act_time_tszb  --退市准备
        ,act_time_tzxd  --停止下单
        ,act_time_tzsc  --停止生产
        ,PG00015  --产品公司
        ,productmodel_id  --产品型号id
        ,salemodel  --销售型号名称
        ,salemodel_code  --销售型号编码
        ,salemodel_id  --销售型号id
        ,PC20080  --归属营销部
        ,HX00379  --是否模块组合
        ,PC20006  --标准品/定制产品
        ,is_project_nk  --内控口径
        ,matnr  --物料编码
        ,HX00327  --所有者
        ,PC20018  --非标对应原型机
        ,PG00009  --产品系列
    FROM dws.dws_ipd_ipm_sale_model_detail_dd
    WHERE company = '空调公司'
        AND product_line = '中央空调'
        AND dt_type = '月'
        AND dt_month = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')
        AND model_label_10 != '老品清零'

    UNION ALL

    -- 未来月：取预测数据
    SELECT
        dt_month
        ,business_division   --事业部
        ,company
        ,product_line
        ,kt_nbzz  --空气事业部内部组织
        ,in_out_sale  --内销/外销
        ,model  --销售型号名称（日立管理口径）
        ,model_label_10  --预测后阶段
        ,model_label_16  --指标范围
        ,is_project  --预测后是否保护期
        ,product_big  --产品大类
        ,product_mid  --产品中类
        ,product_sml  --产品小类
        ,platform  --产品平台
        ,productmodel  --产品型号名称
        ,chanpindingwei  --产品定位
        ,plan_base  --规划生产基地
        ,brand  --品牌
        ,productmodel__life  --预测后生命周期
        ,act_time_ss  --上市时间
        ,act_time_tszb  --退市准备
        ,act_time_tzxd  --停止下单
        ,act_time_tzsc  --停止生产
        ,PG00015  --产品公司
        ,productmodel_id  --产品型号id
        ,salemodel  --销售型号名称
        ,salemodel_code  --销售型号编码
        ,salemodel_id  --销售型号id
        ,PC20080  --归属营销部
        ,HX00379  --是否模块组合
        ,PC20006  --标准品/定制产品
        ,is_project_nk  --内控口径
        ,matnr  --物料编码
        ,HX00327  --所有者
        ,PC20018  --非标对应原型机
        ,PG00009  --产品系列
    FROM dws.dws_ipd_ipm_sale_model_detail_dd
    WHERE company = '空调公司'
        AND product_line = '中央空调'
        AND dt_type = '月'
        AND dt_month IN (SELECT target_month FROM target_months)
        AND dt_month > DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')  -- 排除当前月（已从实际数据取）
)
-- CTE3: sale_model_info — 获取销售型号的立项首月（用于BP/LX选择）
,sale_model_info AS (
    SELECT
        PG00068  --销售型号编码
        ,MIN(DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m')) AS min_dtmonth  --立项首月
    FROM dim.dim_ipd_salemodel_dd
    WHERE PG00002 = '空气调节类产品'
        AND PG00025 IS NOT NULL
    GROUP BY PG00068
)
-- CTE4: plan_sales — 从BP/LX规划量表取每月规划量（日立销售型号编码口径）
,plan_sales AS (
    SELECT
        COALESCE(t1.salemodelcode, t2.salemodelcode) AS salemodelcode  --销售型号编码
        ,COALESCE(t1.dt_month, t2.dt_month) AS dt_month  --月份
        ,CASE 
            WHEN SUBSTRING(COALESCE(t3.min_dtmonth, '190001'), 1, 4) = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')
            THEN COALESCE(t2.plan_sales_qty, 0)   -- 立项首月在今年→用LX
            ELSE COALESCE(t1.plan_sales_qty, 0)   -- 否则用BP
        END AS plan_sales_qty  --月度规划销量
        ,CASE 
            WHEN SUBSTRING(COALESCE(t3.min_dtmonth, '190001'), 1, 4) = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')
            THEN COALESCE(t2.plan_sales_amt, 0)   -- 立项首月在今年→用LX
            ELSE COALESCE(t1.plan_sales_amt, 0)   -- 否则用BP
        END AS plan_sales_amt  --月度规划销额
    FROM (
        -- BP规划量
        SELECT
            salemodelcode
            ,dt_month
            ,SUM(plan_sales_qty) AS plan_sales_qty
            ,SUM(plan_sales_amt) AS plan_sales_amt
        FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
        WHERE plan_type = 'BP'
            AND model_label_1 = 'HDRP'
            AND product_big = '空气调节类产品'
        GROUP BY salemodelcode, dt_month
    ) t1
    FULL JOIN (
        -- LX立项规划量（销售型号编码口径）
        SELECT
            salemodelcode
            ,dt_month
            ,MAX(plan_sales_qty) AS plan_sales_qty
            ,MAX(plan_sales_amt) AS plan_sales_amt
        FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
        WHERE plan_type = 'LX'
            AND product_big = '空气调节类产品'
            AND model_type = '销售型号编码口径'
        GROUP BY salemodelcode, dt_month
    ) t2 ON t1.salemodelcode = t2.salemodelcode AND t1.dt_month = t2.dt_month
    LEFT JOIN sale_model_info t3
        ON COALESCE(t1.salemodelcode, t2.salemodelcode) = t3.PG00068
    WHERE COALESCE(t1.dt_month, t2.dt_month) IN (SELECT target_month FROM target_months)
)
-- CTE5: base_year_sales — 上个月的年累实际销量（作为基准，因为实际销量滞后一个月）
,base_year_sales AS (
    SELECT
        salemodel_code  --销售型号编码
        ,COALESCE(sales_qty_y, 0) AS base_year_qty   --上月已有年累销量
        ,COALESCE(sales_amt_y, 0) AS base_year_amt   --上月已有年累销额
    FROM dws.dws_ipd_ipm_dxhxl_detail_dd
    WHERE company = '空调公司'
        AND product_line = '中央空调'
        AND dt_type = '月'
        AND dt_month = DATE_FORMAT(DATE_SUB(DATE_SUB(CURDATE(), INTERVAL 1 DAY), INTERVAL 1 MONTH), '%Y%m')
        AND sales_type = '管报'
)
-- CTE6: plan_cumulative — 计算从当前月到各目标月的规划量逐月累加（用于年累）
-- 基准是上月年累，所以从当前月开始累加规划量
,plan_cumulative AS (
    SELECT
        ps.salemodelcode  --销售型号编码
        ,tm.target_month  --目标月
        ,SUM(ps2.plan_sales_qty) AS cum_plan_qty   --从当前月到目标月的规划量累计
        ,SUM(ps2.plan_sales_amt) AS cum_plan_amt   --从当前月到目标月的规划销额累计
    FROM (SELECT DISTINCT salemodelcode FROM plan_sales) ps
    CROSS JOIN target_months tm
    LEFT JOIN plan_sales ps2
        ON ps.salemodelcode = ps2.salemodelcode
        AND ps2.dt_month >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')  -- 从当前月开始
        AND ps2.dt_month <= tm.target_month  -- 到目标月为止
    GROUP BY ps.salemodelcode, tm.target_month
)
-- 最终SELECT：组合型号范围 + 月度规划量 + 年累销量
SELECT DISTINCT
    bm.dt_month  --目标月
    ,'月' AS dt_type
    ,'空气事业部' AS business_division   --事业部
    ,bm.company
    ,bm.product_line
    ,bm.in_out_sale  --内销/外销
    ,bm.model  --销售型号名称
    ,COALESCE(ps.plan_sales_qty, 0) AS sales_qty   --月度销量（规划量代替）
    ,COALESCE(ps.plan_sales_amt, 0) AS sales_amt   --月度销额（规划销额代替）
    ,'规划' AS sales_type  --标记为规划数据
    ,bm.platform AS model_label_1  --产品平台
    ,bm.model_label_10  --预测后阶段
    ,COALESCE(bm.is_project, 'Y') AS is_project  --预测后是否保护期
    ,NOW() AS load_dt
    ,bm.kt_nbzz  --空气事业部内部组织
    ,bm.product_big  --产品大类
    ,bm.product_mid  --产品中类
    ,bm.product_sml  --产品小类
    ,bm.platform  --产品平台
    ,bm.productmodel  --产品型号名称
    ,bm.chanpindingwei  --产品定位
    ,bm.plan_base  --规划生产基地
    ,bm.brand  --品牌
    ,bm.productmodel__life  --预测后生命周期
    ,bm.act_time_ss  --上市时间
    ,bm.act_time_tszb  --退市准备
    ,bm.act_time_tzxd  --停止下单
    ,bm.act_time_tzsc  --停止生产
    ,bm.PG00015  --产品公司
    ,bm.productmodel_id  --产品型号id
    ,bm.salemodel  --销售型号名称
    ,bm.salemodel_code  --销售型号编码
    ,bm.salemodel_id  --销售型号id
    ,bm.PC20080  --归属营销部
    ,bm.HX00379  --是否模块组合
    ,bm.PC20006  --标准品/定制产品
    ,bm.is_project_nk  --内控口径
    ,bm.matnr  --物料编码
    ,bm.HX00327  --所有者
    ,bm.PC20018  --非标对应原型机
    ,bm.PG00009  --产品系列
    ,COALESCE(bys.base_year_qty, 0) + COALESCE(pc.cum_plan_qty, 0) AS sales_qty_y  --年累销量 = 实际年累 + 规划累加
    ,COALESCE(bys.base_year_amt, 0) + COALESCE(pc.cum_plan_amt, 0) AS sales_amt_y  --年累销额
FROM base_model bm
LEFT JOIN plan_sales ps
    ON bm.salemodel_code = ps.salemodelcode
    AND bm.dt_month = ps.dt_month
LEFT JOIN base_year_sales bys
    ON bm.salemodel_code = bys.salemodel_code
LEFT JOIN plan_cumulative pc
    ON bm.salemodel_code = pc.salemodelcode
    AND bm.dt_month = pc.target_month
;
