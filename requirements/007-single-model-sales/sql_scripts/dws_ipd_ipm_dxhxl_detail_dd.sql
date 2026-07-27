
--冰冷洗内销 单型号销量 销额      管报数据
delete from dws.dws_ipd_ipm_dxhxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' and product_line in ('冰箱','冷柜','洗衣机') and in_out_sale = '内销' and sales_type = '管报';
insert into dws.dws_ipd_ipm_dxhxl_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line
,in_out_sale
,prdct_model 
,model
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_3
,model_label_4
,model_label_10
,is_project 
,load_dt 
,act_cost
,act_gross_profit
,chanpindingwei  --产品定位
,brand  --品牌
)


with zx_model as ( 
select 
*
from dws.dws_ipd_ipm_sale_model_detail_dd
where product_line in ('冰箱','冷柜','洗衣机')
and in_out_sale = '内销'
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_day =  date_sub(STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d'),interval 1 day)
and dt_type = '月'
)
,sale_amt as (
select 
t2.model_name 
,sum(t1.sale_qty) as sale_qty
,sum(t1.rev_amt) as rev_amt
,sum(t1.cost_amt) as chengben 
,sum(t1.rev_amt) - sum(t1.cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y') t2 
on t1.matnr = t2.product_code
where t1.yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by t2.model_name
)

select distinct 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'月' as dt_type
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when product_line in ('洗衣机') then '洗护事业部'
else null end as business_division   --事业部
,t1.company
,t1.product_line
,'内销'
,t1.model
,t1.model
,t2.sale_qty
,t2.rev_amt
,'管报' 
,t1.model_label_1
,t1.model_label_3
,t1.model_label_4
,t1.model_label_10
,coalesce (t1.is_project,'Y')  as is_project
,now()
,t2.chengben
,t2.maolie
,t1.chanpindingwei  --产品定位
,t1.brand  --品牌
from zx_model t1 
left join sale_amt t2 
on t1.model = t2.model_name
;



--厨电内销 单型号销量 销额      管报数据
delete from dws.dws_ipd_ipm_dxhxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' and company in ('厨电') and in_out_sale = '内销' and sales_type = '管报';
insert into dws.dws_ipd_ipm_dxhxl_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line
,in_out_sale
,prdct_model 
,model
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_3
,model_label_4
,model_label_10
,is_project 
,load_dt 
,act_cost
,act_gross_profit
,chanpindingwei  --产品定位
,brand  --品牌
)



with zx_model as ( 
select 
*
from dws.dws_ipd_ipm_sale_model_detail_dd
where company in ('厨电')
and in_out_sale = '内销'
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_day =  date_sub(STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d'),interval 1 day)
and dt_type = '月'
)
,sale_amt as (
select 
t2.model_name 
,sum(t1.sale_qty) as sale_qty
,sum(t1.rev_amt) as rev_amt
,sum(t1.cost_amt) as chengben 
,sum(t1.rev_amt) - sum(t1.cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y') t2 
on t1.matnr = t2.product_code
where t1.yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by t2.model_name
)

select distinct 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'月' as dt_type
,t1.business_division   --事业部
,t1.company
,t1.product_line
,'内销'
,t1.model
,t1.model
,t2.sale_qty
,t2.rev_amt
,'管报' 
,t1.model_label_1
,t1.model_label_3
,t1.model_label_4
,t1.model_label_10
,coalesce (t1.is_project,'Y')  as is_project
,now()
,t2.chengben
,t2.maolie
,t1.chanpindingwei  --产品定位
,t1.brand  --品牌
from zx_model t1 
left join sale_amt t2 
on t1.model = t2.model_name
;










--视像科技 内销  单型号销量
delete from dws.dws_ipd_ipm_dxhxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' and company = '视像科技' and in_out_sale = '内销' and sales_type = '管报';
insert into dws.dws_ipd_ipm_dxhxl_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line
,in_out_sale
,model 
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_3
,model_label_9
,model_label_10
,is_project 
,load_dt 
,act_cost
,act_gross_profit
,model_label_2
,brand
,plan_channel
,countries_regions   --立项国家及区域
,productline_tv   --产品线（电视）
,chanpindingwei  --产品定位
)
with zx_model as ( 
select 
*
from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '视像科技'
and in_out_sale = '内销'
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_day = date_sub(STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d'),interval 1 day)
and dt_type = '月'
)
,sale_amt as (

select 
coalesce (t3.model,t2.model_name)as zzprdmodel
,sum(t1.sale_qty) as sale_qty
,sum(t1.rev_amt) as rev_amt
,sum(t1.cost_amt) as chengben 
,sum(t1.rev_amt) - sum(cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (
select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y'
) t2
on t1.matnr = t2.product_code
left join dim.dim_ipd_tv_model_nengxiao_nd t3 --能效机 销量转换成原型机
on t2.model_name = t3.model_nengxiao
where t1.yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
-- and t1.matkl in ('1100101','1100112','1100601')
group by coalesce (t3.model,t2.model_name)
)

select distinct
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'月' as dt_type 
,'显示事业部'as business_division   --事业部
,'视像科技' as company
,'视像科技' as product_line
,'内销'
,t1.model as prdct_model
,t2.sale_qty
,t2.rev_amt
,'管报' 
,platform as model_label_1
,t1.model_label_3
,t1.model_label_9
,t1.model_label_10
,coalesce (t1.is_project,'Y')  as is_project
,now()
,t2.chengben
,t2.maolie
,t1.model_label_2
,t1.brand
,t1.plan_channel
,t1.countries_regions   --立项国家及区域
,t1.productline_tv   --产品线（电视）
,t1.chanpindingwei  --产品定位
from zx_model t1 
left join sale_amt t2 
on t1.model = t2.zzprdmodel
;



--空调公司 单型号销量   单型号销额  管报数据
delete from dws.dws_ipd_ipm_dxhxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' and company = '空调公司' and sales_type = '管报';
insert into dws.dws_ipd_ipm_dxhxl_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line
,in_out_sale
,model 
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_3
,model_label_10
,is_project 
,load_dt 
,act_cost
,act_gross_profit
,kt_nbzz
--${GP_START_DT}新增
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,plan_base--规划生产基地
,brand--品牌
,productmodel__life--产品生命周期状态
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
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
,sales_qty_y   --销量-年累
,sales_amt_y   --销额-年累
)
with zx_model as ( 
select 
*
from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '空调公司'
and case when product_line = '中央空调' then 1=1 else in_out_sale = '内销' end 
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_day = date_sub(STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d'),interval 1 day)
and dt_type = '月'
)
,sales_amt_1 as (
select 
t2.model_name
,matnr 
,sale_qty
,rev_amt   --销额
,cost_amt  --成本
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (select distinct 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO')
and delete_flag!='Y'
)t2
on t1.matnr = t2.product_code
where yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t2.model_name is not null 


)
,sale_amt as (
select 
model_name
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt
,sum(cost_amt) as cost_amt
,sum(rev_amt) - sum(cost_amt) as maolie
from sales_amt_1
group by model_name

)

select distinct
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'月' as dt_type 
,'空气事业部'as business_division   --事业部
,t1.company
,t1.product_line
,t1.in_out_sale
,t1.model
,coalesce (t3.sale_qty,t2.sale_qty) as sale_qty
,coalesce (t3.rev_amt,t2.rev_amt) as rev_amt
,'管报' 
,t1.platform as model_label_1
,t1.model_label_3
,t1.model_label_10
,coalesce (t1.is_project,'Y')  as is_project
,now()
,t2.cost_amt
,t2.maolie
,t1.kt_nbzz
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,plan_base--规划生产基地
,brand--品牌
,productmodel__life--产品生命周期状态
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
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
,t4.sale_qty  --销量-年累
,t4.rev_amt   --销额-年累
from zx_model t1 
left join sale_amt t2 
on t1.model = t2.model_name
left join (
--中央空调取数
select 
t2.sale_model_code
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt   --销额
,sum(cost_amt) as cost_amt  --成本
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (select distinct
product_code
,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y'
and create_company ='RILI'
)t2
on substring(t1.matnr,1,14)  = substring(t2.product_code,1,14)
where yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t2.sale_model_code is not null 
group by t2.sale_model_code
)t3
on t1.salemodel_code = t3.sale_model_code
and t1.product_line = '中央空调'
and t1.PC20006 = '标准品'
left join (
--中央空调取数
select 
t2.sale_model_code
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt   --销额
,sum(cost_amt) as cost_amt  --成本
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (select distinct
product_code
,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y'
and create_company ='RILI'
)t2
on substring(t1.matnr,1,14)  = substring(t2.product_code,1,14)
where yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and substring(yearmonth,1,4) =  DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and t2.sale_model_code is not null 
group by t2.sale_model_code
)t4
on t1.salemodel_code = t4.sale_model_code
and t1.product_line = '中央空调'
and t1.PC20006 = '标准品'
;


-- 删除今年所有中央空调单型号销量预测数据（幂等）
-- 注意：单型号销量实际数据是上月的，预测从当前月开始
DELETE FROM dws.dws_ipd_ipm_dxhxl_detail_dd 
WHERE company = '空调公司'
    AND product_line = '中央空调'
    AND dt_type = '月'
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


---------------------------------------------------------单型号销量 激光 内销 管报 ----------------------------------------------------

delete from dws.dws_ipd_ipm_dxhxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' and company = '激光' and in_out_sale = '内销' and sales_type = '管报';

insert into dws.dws_ipd_ipm_dxhxl_detail_dd(
dt_month
,dt_type
,business_division
,company
,product_line
,in_out_sale
,model 
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_10
,is_project 
,load_dt 
,act_cost
,act_gross_profit
,is_platformsalemodel
,chanpindingwei  --产品定位
,brand  --品牌
)
with zx_model as ( 
select 
*
from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '激光'
and in_out_sale = '内销'
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_day = date_sub(STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d'),interval 1 day)
and dt_type = '月'
)
,sale_amt as (
-- 管报实际销量（能效机转换）
select 
coalesce(t3.model, t2.model_name) as zzprdmodel
,sum(t1.sale_qty) as sale_qty
,sum(t1.rev_amt) as rev_amt
,sum(t1.cost_amt) as chengben 
,sum(t1.rev_amt) - sum(cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (
select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code = 'FERT'
and delete_flag != 'Y'
) t2
on t1.matnr = t2.product_code
left join dim.dim_ipd_tv_model_nengxiao_nd t3
on t2.model_name = t3.model_nengxiao
where t1.yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by coalesce(t3.model, t2.model_name)
)

select distinct
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'月' as dt_type 
,'激光事业部' as business_division
,'激光' as company
,t1.product_line
,'内销' as in_out_sale
,t1.model as prdct_model
,t2.sale_qty
,t2.rev_amt
,'管报' as sales_type
,t1.platform as model_label_1
,t1.model_label_10
,coalesce(t1.is_project,'Y') as is_project
,now() as load_dt
,t2.chengben as act_cost
,t2.maolie as act_gross_profit
,case when t3.platform is not null then 'Y' else 'N' end as is_platformsalemodel
,t1.chanpindingwei  --产品定位
,t1.brand  --品牌
from zx_model t1 
left join sale_amt t2 
on t1.model = t2.zzprdmodel
left join (select distinct platform from dws.dws_ipd_ipm_platform_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y%m')
and company = '激光'
and in_out_sale in ('内销')
and is_project = 'N'
and platform not in ('','/')
and coalesce(is_productline_jy,'N') = 'N'
and coalesce(is_nwx_jy,'N') = 'N') t3 
on t1.platform = t3.platform
;
