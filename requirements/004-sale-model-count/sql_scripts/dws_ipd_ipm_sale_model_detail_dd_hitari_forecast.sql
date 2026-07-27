-- DORIS sql 
-- ******************************************************************** --
-- 脚本名称: dws_ipd_ipm_sale_model_detail_dd_hitari_forecast.sql
-- 功能描述: 日立在销型号数未来月份预测（纯SQL版，一次性生成所有未来月份）
-- 逻辑说明: 
--   1. 生成月份序列：从当前月+1到今年12月
--   2. 以系统当前月（CURDATE()-1天）为基准月，获取日立全量数据
--   3. CROSS JOIN月份序列，逐月生命周期变化
--   4. 重新判定is_project/is_project_nk
-- 参数: 无需外部参数，全部基于CURDATE()动态计算
-- ******************************************************************** --

-- 删除今年所有预测数据（幂等）
DELETE FROM dws.dws_ipd_ipm_sale_model_detail_dd 
WHERE company = '空调公司'
    AND product_line = '中央空调'
    AND dt_type = '月'
    AND dt_month > DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')
    AND dt_month <= CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y'), '12');

-- 插入预测数据
INSERT INTO dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line
,kt_nbzz  --空气事业部内部组织
,in_out_sale
,model
,IR_act_time
,delisted_time
,model_label_10   --判定老品清零
,model_label_16   --在销型号数范围
,dt_day
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
,is_project  --是否保护期
,shangshi_m  --本月上市
,tuishijuece_m   --本月退市决策
,tingchan_m   --本月停产
,PG00015  --产品公司
,productmodel_id  --产品型号id
,salemodel    --销售型号名称
,salemodel_code    --销售型号编码
,salemodel_id  --销售型号id
,PC20080    --归属营销部
,HX00379    --是否模块组合
,PC20006    --标准品/定制产品
,is_project_nk  --内控口径
,load_dt
,matnr  --物料编码
,HX00327    --所有者
,PC20018    --非标对应原型机
,PG00009    --产品系列
,PG00024  --规划停止下单时间
,PC10141  --规划停止生产时间
)
-- CTE1: month_seq — 生成未来月份序列（当前月+1 ~ 今年12月）
WITH month_seq AS (
    SELECT 1 AS offset UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
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
-- CTE2: base_data — 获取基准月（昨天所在月）的日立全量数据（含在产+未上市）
,base_data AS (
    SELECT
        business_division   --事业部
        ,company
        ,product_line
        ,kt_nbzz  --空气事业部内部组织
        ,in_out_sale  --内销/外销
        ,model  --销售型号名称（日立管理口径）
        ,IR_act_time  --实际上市时间
        ,delisted_time  --停止生产时间
        ,model_label_10  --阶段（在产/未上市/老品）
        ,model_label_16  --在销型号数范围
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
        ,is_project  --是否保护期
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
        ,PG00024  --规划停止下单时间
        ,PC10141  --规划停止生产时间
    FROM dws.dws_ipd_ipm_sale_model_detail_dd
    WHERE dt_month = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')
        AND company = '空调公司'
        AND product_line = '中央空调'
        AND dt_type = '月'
        AND model_label_10 != '老品清零'  -- 排除已清零（不参与预测）
)
-- CTE3: forecast_lifecycle — base_data × 月份序列，逐月生命周期
,forecast_lifecycle AS (
    SELECT
        tm.target_month
        ,tm.target_month_end
        ,b.business_division   --事业部
        ,b.company
        ,b.product_line
        ,b.kt_nbzz  --空气事业部内部组织
        ,b.in_out_sale  --内销/外销
        ,b.model  --销售型号名称
        ,b.IR_act_time  --实际上市时间
        ,b.delisted_time  --停止生产时间
        ,b.model_label_10  --基准月阶段
        ,b.model_label_16  --在销型号数范围
        ,b.product_big  --产品大类
        ,b.product_mid  --产品中类
        ,b.product_sml  --产品小类
        ,b.platform  --产品平台
        ,b.productmodel  --产品型号名称
        ,b.chanpindingwei  --产品定位
        ,b.plan_base  --规划生产基地
        ,b.brand  --品牌
        ,b.act_time_ss  --上市时间
        ,b.act_time_tszb  --退市准备
        ,b.act_time_tzxd  --停止下单
        ,b.act_time_tzsc  --停止生产
        ,b.PG00015  --产品公司
        ,b.productmodel_id  --产品型号id
        ,b.salemodel  --销售型号名称
        ,b.salemodel_code  --销售型号编码
        ,b.salemodel_id  --销售型号id
        ,b.PC20080  --归属营销部
        ,b.HX00379  --是否模块组合
        ,b.PC20006  --标准品/定制产品
        ,b.matnr  --物料编码
        ,b.HX00327  --所有者
        ,b.PC20018  --非标对应原型机
        ,b.PG00009  --产品系列
        ,b.PG00024  --规划停止下单时间
        ,b.PC10141  --规划停止生产时间
        -- 预测生命周期状态
        ,CASE
            -- 规划停止生产时间 <= 目标月末 → 停止生产（退市）
            WHEN b.PC10141 IS NOT NULL AND b.PC10141 <= tm.target_month_end
                THEN '停止生产'
            -- 规划停止下单时间 <= 目标月末 → 停止下单（仍在产）
            WHEN b.PG00024 IS NOT NULL AND b.PG00024 <= tm.target_month_end
                THEN '停止下单'
            -- 未上市型号：上市时间 <= 目标月末 → 上市
            WHEN b.model_label_10 = '未上市' AND b.act_time_ss IS NOT NULL AND b.act_time_ss <= tm.target_month_end
                THEN '上市'
            -- 其他保持原状态
            ELSE b.productmodel__life
        END AS productmodel__life_forecast
        -- 预测阶段（jieduan）
        ,CASE
            WHEN b.PC10141 IS NOT NULL AND b.PC10141 <= tm.target_month_end
                THEN '退市'
            WHEN b.PG00024 IS NOT NULL AND b.PG00024 <= tm.target_month_end
                THEN '在产'
            WHEN b.model_label_10 = '未上市' AND b.act_time_ss IS NOT NULL AND b.act_time_ss <= tm.target_month_end
                THEN '在产'
            WHEN b.model_label_10 IN ('在产','老品') THEN
                CASE WHEN b.productmodel__life IN ('上市','退市准备','停止下单') THEN '在产'
                     WHEN b.productmodel__life IN ('停止服务','停止生产') THEN '退市'
                     ELSE '未上市'
                END
            WHEN b.model_label_10 = '未上市' THEN '未上市'
            ELSE '未上市'
        END AS jieduan_forecast
    FROM base_data b
    CROSS JOIN target_months tm
)
-- CTE4: forecast_result — 重新判定is_project/is_project_nk
,forecast_result AS (
    SELECT
        t.*
        -- 预测后的model_label_10
        ,CASE
            WHEN jieduan_forecast = '退市' THEN '老品清零'
            WHEN jieduan_forecast = '未上市' THEN '未上市'
            ELSE '在产'
        END AS model_label_10_forecast
        -- 预测后的is_project（集团口径）
        ,CASE
            WHEN product_sml NOT IN ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机') THEN 'Y'
            WHEN product_mid = '空气调节类配件' THEN 'Y'
            WHEN jieduan_forecast != '在产' THEN 'Y'
            WHEN COALESCE(PC20006, '标准品') != '标准品' THEN 'Y'
            WHEN COALESCE(plan_base, '正常') = '1000-海信日立委外工厂' THEN 'Y'
            WHEN COALESCE(HX00379, '否') = '是' THEN 'Y'
            ELSE 'N'
        END AS is_project_forecast
        -- 预测后的is_project_nk（内控口径）
        ,CASE
            WHEN jieduan_forecast != '在产' THEN 'Y'
            WHEN COALESCE(PC20006, '标准品') != '标准品' THEN 'Y'
            WHEN COALESCE(plan_base, '正常') = '1000-海信日立委外工厂' THEN 'Y'
            WHEN COALESCE(HX00379, '否') = '是' THEN 'Y'
            ELSE 'N'
        END AS is_project_nk_forecast
        -- 预测后的model_label_16（指标范围）
        ,CASE
            WHEN COALESCE(PC20006, '标准品') != '标准品' THEN 'N'
            WHEN COALESCE(plan_base, '正常') = '1000-海信日立委外工厂' THEN 'N'
            WHEN COALESCE(HX00379, '否') = '是' THEN 'N'
            ELSE 'Y'
        END AS model_label_16_forecast
    FROM forecast_lifecycle t
)
-- 最终SELECT：输出所有未来月份的预测数据（排除退市和未上市）
SELECT
    target_month AS dt_month
    ,'月' AS dt_type
    ,business_division   --事业部
    ,company
    ,product_line
    ,kt_nbzz  --空气事业部内部组织
    ,in_out_sale  --内销/外销
    ,model  --销售型号名称
    ,IR_act_time  --实际上市时间
    ,delisted_time  --停止生产时间
    ,model_label_10_forecast AS model_label_10  --预测后阶段
    ,model_label_16_forecast AS model_label_16  --预测后指标范围
    ,target_month_end AS dt_day
    ,product_big  --产品大类
    ,product_mid  --产品中类
    ,product_sml  --产品小类
    ,platform  --产品平台
    ,productmodel  --产品型号名称
    ,chanpindingwei  --产品定位
    ,plan_base  --规划生产基地
    ,brand  --品牌
    ,productmodel__life_forecast AS productmodel__life  --预测后生命周期
    ,act_time_ss  --上市时间
    ,act_time_tszb  --退市准备
    ,act_time_tzxd  --停止下单
    ,act_time_tzsc  --停止生产
    ,is_project_forecast AS is_project  --预测后是否保护期
    ,CASE WHEN DATE_FORMAT(act_time_ss, '%Y%m') = target_month THEN '本月上市' ELSE NULL END AS shangshi_m  --本月上市
    ,NULL AS tuishijuece_m  --本月退市决策
    ,CASE WHEN DATE_FORMAT(PC10141, '%Y%m') = target_month THEN '本月停产' ELSE NULL END AS tingchan_m  --本月停产
    ,PG00015  --产品公司
    ,productmodel_id  --产品型号id
    ,salemodel  --销售型号名称
    ,salemodel_code  --销售型号编码
    ,salemodel_id  --销售型号id
    ,PC20080  --归属营销部
    ,HX00379  --是否模块组合
    ,PC20006  --标准品/定制产品
    ,is_project_nk_forecast AS is_project_nk  --预测后内控口径
    ,NOW() AS load_dt
    ,matnr  --物料编码
    ,HX00327  --所有者
    ,PC20018  --非标对应原型机
    ,PG00009  --产品系列
    ,PG00024  --规划停止下单时间
    ,PC10141  --规划停止生产时间
FROM forecast_result
WHERE jieduan_forecast != '退市'    -- 退市=老品清零，不纳入预测在销范围
    AND jieduan_forecast != '未上市' -- 目标月仍未上市的也不纳入
;
