
--产品型号对应的项目开发难度
drop table IF EXISTS test.productmodel_xmndxf;
CREATE TABLE test.productmodel_xmndxf
ENGINE=OLAP
-- 表模型（Duplicate/Unique/Aggregate Key，必填）
DUPLICATE KEY(PG00002)
AS 
with xmndxf as ( 
select 
t1.PG00002
,t1.PG00003
,t1.PG00004
,t1.PRODUCTMODEL
,t1.project_name
,t1.project_code 
,t2.develop_diff_segment_cn as new_xmndxf 
,case when t3.develop_diff_segment_cn like 'A1%' then 'A1'
when t3.develop_diff_segment_cn like 'A2%' then 'A2'
when t3.develop_diff_segment_cn like 'A3%' then 'A3'
when t3.develop_diff_segment_cn like 'A4%' then 'A4'
when t3.develop_diff_segment_cn like 'B1%' then 'B1'
when t3.develop_diff_segment_cn like 'B2%' then 'B2'
when t3.develop_diff_segment_cn like 'B3%' then 'B3'
when t3.develop_diff_segment_cn like 'C1%' then 'C1'
when t3.develop_diff_segment_cn like 'C2%' then 'C2'
when t3.develop_diff_segment_cn like 'C3%' then 'C3'
when t3.develop_diff_segment_cn like 'C4%' then 'C4'
when t3.develop_diff_segment_cn like 'C%' then 'C'
when t3.develop_diff_segment_cn like '%D%' then 'D'
else t3.develop_diff_segment_cn end as old_xmndxf
from dim.dim_ipd_productionversion_dd t1 
--通过项目编码映射开发难度细分
left join dim.dim_ipd_hdrp_project_dd t2 
on t1.project_code = t2.objectnumber
--通过产品型号名称映射开发难度细分
left join dim.dim_ipd_hdrp_project_dd t3
on t1.PRODUCTMODEL = t3.objectname
and t1.project_code is null 

)
select 
PG00002
,PG00003
,PG00004
,PRODUCTMODEL
-- ,project_name
-- ,project_code 
-- ,coalesce (new_xmndxf ,old_xmndxf) as xmndxf
,group_concat(distinct coalesce (new_xmndxf ,old_xmndxf)) as xmndxf
from xmndxf
where coalesce (new_xmndxf ,old_xmndxf) is not null  
group by PG00002
,PG00003
,PG00004
,PRODUCTMODEL
;



--销售型号编码对应的项目开发难度
drop table IF EXISTS test.salesmodel_xmndxf;
CREATE TABLE test.salesmodel_xmndxf
ENGINE=OLAP
-- 表模型（Duplicate/Unique/Aggregate Key，必填）
DUPLICATE KEY(PG00002)
AS 

select distinct
t1.PG00002
,t1.PG00003
,t1.PG00004
,t1.PG00068  --销售型号编码
,t1.project_name
,t1.project_code 
,t2.develop_diff_segment_cn as xmndxf 
from dim.dim_ipd_salemodel_dd  t1 
--通过项目编码映射开发难度细分
left join dim.dim_ipd_hdrp_project_dd t2 
on t1.project_code = t2.objectnumber
where t1.project_code is not null 

;



--视像科技产品型号对应的项目开发难度
drop table IF EXISTS test.productmodel_tv_xmndxf;
CREATE TABLE test.productmodel_tv_xmndxf
ENGINE=OLAP
-- 表模型（Duplicate/Unique/Aggregate Key，必填）
DUPLICATE KEY(modelname)
AS 
with xmkfnd as ( 
select 
*
from ( 
select 
projectid  --项目id
,projectcode   --项目编码
,projectname   --项目名称
,case when authenticationtype = '' then null else authenticationtype end as  authenticationtype   --验证类型
,row_number ()over(partition by projectname order by identify) as rn  --优先选新系统
from ods.odsjtplm_his_marketablemachine
)a
where rn=1
)

select 
t1.modelname 
,group_concat(distinct t2.authenticationtype) as xmndxf
from dim.dim_ipd_jtplm_his_productversion_dd t1
left join xmkfnd t2 
on t1.name = t2.projectname
where t1.his_productsmallcategories = '平板电视'
group by t1.modelname 
;




--冰箱 冷柜 洗衣机 内销低效型号数
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line in ('冰箱','冷柜','洗衣机')
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,distribution_channel --销售渠道
,product_positioning --产品定位
,platform   --平台
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,menlei  --门类
,pinleixifen--品类细分
,shangshi_m--上市月份
--,productmodel_life--生命周期状态
,is_odm --是否odm
,is_dx	--是否低效
,is_project	--是否保护期
,model_label_2  --上市周期
,load_dt	--加载日期
,projectdevelopmentdifficulty --项目开发难度
)




with all_model as (
select 
product_line  --产品线
,PG00061 --名称
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,PG00025  --实际上市时间
,HX00501  --实际退市时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(PG00025)) as shangshi_m
,PG00029	--产品型号生命周期状态
,case when coalesce(PG00005,'0') IN ('Hisense','Ronshen') AND not(PC00025 LIKE '%海信%' or PC00025 LIKE '%平度%') then 'Y' else 'N' end as  is_odm
,case 
--古洛尼品牌的剔除逻辑
when PG00005 in ('gorenje') then 'Y'
--只选上市状态的
when not(PG00025 is not null and HX00501 is null)  then 'Y'
else 'N' end as is_project
from ( 
select 
id
,PG00061	--名称
,case
-- 内销：家用冰箱
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 in ('冷藏冷冻箱','冷藏箱') and PG00020 = '内销' then '冰箱'
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 = '冷冻箱' and PC00001 = '冰箱' and PG00020 = '内销' then '冰箱'
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 = '冷冻箱' and PG00020 = '内销' then '冷柜'
-- 内销：家用冷柜
when PG00002 = '控温储藏类产品' and PG00003 = '家用冷柜' and PG00020 = '内销' then '冷柜'
-- 内销：家用展示柜（冰吧）
when PG00002 = '控温储藏类产品' and PG00003 = '家用展示柜' and PG00004 = '冰吧' and PG00020 = '内销' then '冷柜'
-- 外销：家用冰箱
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00020 = '外销' then '冰箱'
-- 外销：家用冷柜
when PG00002 = '控温储藏类产品' and PG00003 = '家用冷柜' and PG00020 = '外销' then '冷柜'
-- 洗衣机
when PG00002 = '清洁卫生器具' and PG00003 in ('洗衣机','干衣机','护理机') then '洗衣机'
else '其他' end as product_line
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,HX00024	--销售小区
,HX00023	--销售大区
,PC10050    --门类
,PC00001    --品类细分
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间
,PG00026  --实际停止下单时间
,PG00027  --停止生产时间
from dim.dim_ipd_productmodel_dd t1  --产品型号
)t1 
where product_line in ('冰箱','冷柜','洗衣机')
and PG00020 = '内销'
)
,guanbao_sales as ( 
select 
matnr 
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt
,sum(cost_amt) as chengben 
,sum(rev_amt) - sum(cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata ovafis 
where substring(yearmonth,1,4) =  DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
-- and matkl in ('1300101','1300201','1320201','1320101','1320100','1310101')
group by matnr

) 
,guanbao_sales_2 as (
select t2.model_name as productmodel
,sum(t1.sale_qty) sale_qty --实际销量
,sum(t1.rev_amt) rev_amt  --实际销额
,sum(t1.chengben) chengben --实际成本
,sum(t1.maolie) maolie  --毛利额
from guanbao_sales t1 
left join (select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y') t2 
on t1.matnr = t2.product_code
group by t2.model_name

)
,plan_sales as (
--取本年规划销量
--BP销量与规划销量处理
select 
coalesce (t1.prdct_model ,t2.prdct_model) as prdct_model
-- ,coalesce (t1.product_line ,t2.product_line) as product_line
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_qty else t1.plan_sales_qty end ) as plan_sales_qty
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_amt else t1.plan_sales_amt end ) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit

from (
select 
prdct_model 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and model_label_1 = 'HDRP'
group by prdct_model 
,product_line 
,dt_month 

) t1 
full join (
--RDM数据中可能 会存在一个型号多条记录的情况   默认取最大值
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
,max(plan_gross_margin ) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('控温储藏类产品','清洁卫生器具')
group by prdct_model 
,product_line 
,dt_month 
)t2
on t1.prdct_model = t2.prdct_model
and t1.dt_month = t2.dt_month
left join  (
--最小的立项规划销量月份作为首次上市月份
select 
PG00061
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from all_model
group by PG00061
,product_line 
) t3
on coalesce (t1.prdct_model ,t2.prdct_model) = t3.PG00061
where substring(coalesce (t1.dt_month ,t2.dt_month),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') --限制取出本年的数据
and coalesce (t1.dt_month ,t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')  --限制取出本年内本月之前的数据
--新增滞后上市以实际上市时间开始算累计BP目标销量
and coalesce (t1.dt_month ,t2.dt_month) >=  coalesce (t3.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by coalesce (t1.prdct_model ,t2.prdct_model)
-- ,coalesce (t1.product_line ,t2.product_line)
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,case when t1.product_line = '洗衣机' then '洗护事业部' when t1.product_line in ('冰箱','冷柜') then '冰冷事业部' else '其他' end as business_division   --事业部
,t1.product_line  --产品线
,t1.PG00020	--内销/外销
,'2' as zhibiao_type -- 1:本月;2:本年累;3:生命周期累
,t1.PG00061 --名称
,t1.PG00025  --实际上市时间
,t1.HX00501  --实际退市准备时间
,t2.sale_qty  --实际销量
,t3.plan_sales_qty   --计划销量
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)   --销量完成率
,t2.rev_amt   --实际销额
,t3.plan_sales_amt  --计划销额
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)   --销额完成率
--,t2.chengben  --实际成本
,t2.maolie   --毛利额
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,t1.PG00021	--规划销售渠道
,t1.PG00019	--产品定位
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
,t1.PC10050    --门类
,t1.PC00001    --品类细分
,t1.shangshi_m  --上市月份
--,t1.PG00029	--产品型号生命周期状态
,t1.is_odm
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project  --是否保护期
,case when t1.shangshi_m <= 3 then '[0,3]'
when t1.shangshi_m <= 6 then '(3,6]'
when t1.shangshi_m <= 12 then '(6,12]'
when t1.shangshi_m > 12 then '(12,)'
else '其他' end model_label_2  --上市周期
,now()
,xmndxf
from all_model t1 
left join guanbao_sales_2 t2 
on t1.PG00061 = t2.productmodel
left join plan_sales t3 
on t1.PG00061 = t3.prdct_model
left join test.productmodel_xmndxf t4 
on t1.PG00061 = t4.PRODUCTMODEL
left join fuchan_model t_fuchan 
on t1.PG00061 = t_fuchan.masterDataName
;




--视像科技 内销低效型号数   产品型号口径
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') 
and zhibiao_type = '2'
and product_line = '平板电视'
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
--,is_bp_plan	--是否年度BP规划
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_margin  --实际毛利率
,is_dx	--是否低效
,is_project	--是否保护期
,model_label_1	--型号标签1
,load_dt	--加载日期
,brand  --品牌
,act_gross_profit --实际毛利额
,plan_gross_profit
,gross_profit_rate
,model_label_12
,shangshi_m--上市月份
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
,countries_regions  --立项国家及区域
,productline_tv  --产品线（电视）
)

with tv_model as (
select 
title	--产品型号产品描述（中文）
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,his_productsbrand as brand	--品牌名称
,his_oembrand	--OEM品牌名称
,his_domesticsalesorexport 	--内销/外销名称
,his_prdplatform	--产品平台名称
,his_salescountries	--销售国家名称
,his_plannedsaleschannel	--规划销售渠道
,his_pmdproductpositioning	--产品定位名称
,his_actualtimetomarket--实际上市时间
,his_actualdelistingtime--实际退市时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(his_actualtimetomarket)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(his_actualtimetomarket)) as shangshi_m
from (
select 
title	--产品型号产品描述（中文）
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,his_productsbrand	--品牌名称
,his_oembrand	--OEM品牌名称
,his_pmdproductpositioning	--产品定位名称
,his_domesticsalesorexport 	--内销/外销名称
,his_prdplatform	--产品平台名称
,his_salescountries	--销售国家名称
,his_plannedsaleschannel	--规划销售渠道
,case when cast(his_actualtimetomarket as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualtimetomarket end as his_actualtimetomarket--实际上市时间
,case when cast(his_actualdelistingtime as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualdelistingtime end as his_actualdelistingtime--实际退市时间
,case when cast(his_stopproductiontime as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_stopproductiontime end as his_stopproductiontime--停止生产时间	
,data_source
from dim.dim_ipd_jtplm_his_productmodel_dd
where his_productbigcategories = '显示类产品'
and his_productsmallcategories = '平板电视'
) t1
where t1.his_domesticsalesorexport = '内销'
and (coalesce (his_actualtimetomarket,'') <> '' and coalesce (his_actualdelistingtime,'') = '')  --只取上市且未决策退市的
)
,guanbao_sales as ( 
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
where substring(t1.yearmonth,1,4) =  DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and t1.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
-- and t1.matkl in ('1100101','1100112','1100601')
group by coalesce (t3.model,t2.model_name)
)
,plan_sales as (
--取本年规划销量
--BP销量与规划销量处理
select 
coalesce (t1.prdct_model ,t2.prdct_model) as prdct_model
,coalesce (t1.product_line ,t2.product_line) as product_line
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_qty else t1.plan_sales_qty end ) as plan_sales_qty
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_amt else t1.plan_sales_amt end ) as plan_sales_amt
,sum(t1.plan_gross_profit) as plan_gross_profit
from (
select 
coalesce (t2.model,t1.prdct_model) as prdct_model
,product_line 
,dt_month 
,sum(plan_sales_qty)plan_sales_qty
,sum(plan_sales_amt )plan_sales_amt
,max(plan_gross_margin )plan_gross_margin
,sum(plan_gross_profit)plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd t1 
left join (select distinct model,model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) t2 
on t1.prdct_model = t2.model_nengxiao 
where plan_type = 'BP'
and product_line = '视像科技'
group by coalesce (t2.model,t1.prdct_model) 
,product_line 
,dt_month 
) t1 
full join (
--RDM数据中可能 会存在一个型号多条记录的情况   默认取最大值
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
,max(plan_gross_margin ) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_line = '视像科技'
group by prdct_model 
,product_line 
,dt_month 
)t2
on t1.prdct_model = t2.prdct_model
and t1.dt_month = t2.dt_month
left join  (
--鉴定评审次月为最小上市时间
select 
title as prdct_model
,'视像科技' as product_line
,min(DATE_FORMAT(date_add(his_actualtimetomarket,interval 1 month) , '%Y%m')) as min_dtmonth
from tv_model
group by title
) t3
on coalesce (t1.prdct_model ,t2.prdct_model) = t3.prdct_model
where substring(coalesce (t1.dt_month ,t2.dt_month),1,4) =  DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and coalesce (t1.dt_month ,t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
--新增滞后上市以实际上市时间开始算累计BP目标销量
and coalesce (t1.dt_month ,t2.dt_month) >=  coalesce (t3.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by coalesce (t1.prdct_model ,t2.prdct_model)
,coalesce (t1.product_line ,t2.product_line)
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'显示事业部' as business_division   --事业部
,'平板电视' as productline
,'内销' as  in_out_sale
,'2' as zhibiao_type 
,t1.title 
,t1.his_actualtimetomarket 
,t1.his_actualdelistingtime 
,coalesce (t2.sale_qty,0)
,coalesce (t3.plan_sales_qty,0)
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)
,t2.rev_amt
,t3.plan_sales_amt
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx
,case 
when t1.his_actualtimetomarket >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.title  in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'  --能效机 不考核
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when coalesce(t1.brand,'0')  = 'OEM品牌' then 'Y' --不统计OEM品牌
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else 'N' end as is_project
,case when coalesce (t1.his_actualdelistingtime,'') <> ''  then '决策退市'
when coalesce (t1.his_actualtimetomarket,'') = '' and coalesce (t1.his_actualdelistingtime,'') = '' then '未上市'
when coalesce (t1.his_actualtimetomarket,'') <> '' and coalesce (t1.his_actualdelistingtime,'') = '' then '上市且未决策退市'
else '其他' end as jieduan
,now()
,t1.brand
,t2.maolie  --实际毛利额
-- ,t1.is_gcj   --是否工程机
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,case /*when coalesce (t1.is_gcj,'No') = 'Yes' then '工程机'*/
when coalesce(t1.brand,'0')  = 'OEM品牌' then 'OEM'
when coalesce(t1.brand,'0')  = 'Hisense' then '海信'
when coalesce(t1.brand,'0')  = 'TOSHIBA'  then '东芝'
when coalesce(t1.brand,'0')  = 'Vidda'  then 'Vidda'
else '其他' end 
,shangshi_m  --上市月份
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,his_plannedsaleschannel	--规划销售渠道
,his_pmdproductpositioning	--产品定位名称
,t4.xmndxf
,t5.countries_regions  --立项国家及区域
,t5.his_pmdproductlinename  --产品线
from tv_model t1 
left join guanbao_sales t2 
on t1.title = t2.zzprdmodel
left join plan_sales t3 
on t1.title = t3.prdct_model
left join test.productmodel_tv_xmndxf t4 
on t1.title = t4.modelname
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
on t1.title = t5.modelname
left join fuchan_model t_fuchan 
on t1.title = t_fuchan.masterDataName
;






--空气事业部 低效型号数
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line in ('中央空调','家用空调')
;
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,data_type
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,product_positioning --产品定位
,pg00015	--产品公司
,platform   --平台
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
--,productmodel_life--生命周期状态
,distribution_channel --销售渠道
,shangshi_m--上市月份
,model_label_2  --上市周期
,is_dx	--是否低效
,is_project	--是否保护期
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,project_code  --项目编码
,project_name --项目名称
,model_label_23   --空气是否指标考核口径
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
)
--空气事业部
with product_model as (

select 
id --产品型号id
,PG00061	--名称
,PG00015	--产品公司
,case when kt_nbzz in ('家空内销','家空外销','轻商内销','轻商外销') then '家用空调'
when kt_nbzz in ('央空内销日立','央空外销日立','央空内销科龙') then '中央空调'
else '其他' end product_line
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,pc20029    --内机产品型号
,pc20055    --外机产品型号
,hx00290    --产品类别
,PG00025  --实际上市时间
,HX00501  --实际退市准备时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(PG00025)) as shangshi_m
,kt_nbzz  --空气事业部内部组织
,project_code--项目编码
,project_name--项目名称
from (
select 
id --产品型号id
,PG00061	--名称
,case 
--家用空调
when PG00061= 'KFR-120LW/SEA-X1' then '轻商内销'
when t1.pg00003 in ('除湿机') then '家空外销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and t1.pg00004 in ('分体式空调器整机') then '家空内销'
when t1.pg00015 = '空调' and t1.PG00020 = '外销' and t1.pg00003 = '家用房间空调' and t1.pg00004 in ('分体式空调器整机','移动式空调器','窗式空调器') then '家空外销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (PG00005,'Hisense') <> 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','单元式整机','多联机内机','多联机外机','风机盘管','空气源热泵两联供','热泵热水机','涡旋式冷水(热泵)机组','新风换气机','一拖多外机') then '轻商内销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and coalesce (PG00005,'Hisense') <> 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('热风机整机','热风机内机','热风机外机') then '轻商内销'
when t1.pg00015 = '空调' and t1.PG00020 = '外销' and t1.pg00003 = '中央空调' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','一拖多外机','屋顶机','空气源热泵三联供','热泵热水机') then '轻商外销' 
--中央空调
when t1.pg00015 = '日立' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (PG00005,'Hisense') = 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','风机盘管','空气源热泵两联供','热泵热水机','涡旋式冷水(热泵)机组','新风换气机','一拖多外机') then '央空内销科龙'
when t1.pg00015 = '日立' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and coalesce (PG00005,'Hisense') = 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('热风机内机','热风机外机') then '央空内销科龙'
when t1.pg00015 = '日立' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (hx00427,'否') = '否' 
and t1.pg00004 in ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') then '央空内销日立'  
when t1.pg00015 = '日立' and t1.PG00020 = '外销' and t1.pg00003 = '中央空调' and coalesce (hx00427,'否') = '否' 
and t1.pg00004 in ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') then '央空外销日立'  
else '其他' end as kt_nbzz
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,pc20029    --内机产品型号
,pc20055    --外机产品型号
,hx00290    --产品类别
,hx00427  --是否重复型号
,project_code--项目编码
,project_name--项目名称
-- ,HX00501  --实际退市准备时间
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间
-- ,PG00025  --实际上市时间
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间
from dim.dim_ipd_productmodel_dd t1  --产品型号
where t1.pg00002 = '空气调节类产品'
--排除环境电器产品
and coalesce (t1.productline_syb ,'填空') <> '环境电器'
)a 
where kt_nbzz in ('家空内销','家空外销','轻商内销','轻商外销')
and PG00020 = '内销'
)
,danyuanji_tichu as ( 
select PG00061 from product_model
where pg00004 in ('单元式内机','热风机内机') 
and PG00061 in (
select distinct pc20029 from product_model
where pg00004 in ('单元式整机','热风机整机') 
and pc20029 is not null
)
union all 

select PG00061 from product_model
where pg00004 in ('单元式外机','热风机外机') 
and PG00061 in (
select distinct pc20055 from product_model
where pg00004 in ('单元式整机','热风机整机') 
and pc20055 is not null
)
)
,sales as (
select 
matnr
,'空调' product_line
,sum(sale_qty)sale_qty
,sum(rev_amt)rev_amt
,sum(cost_amt)cost_amt
,sum(rev_amt) - sum(cost_amt) as maolie  --毛利额
from ods.ods_mr_v_app_fm_imat_saledata ovafis 
where /*matkl in ('1200101','1200301','1209901')
and */substring(yearmonth,1,4) =  DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by matnr


)
,all_sales as (
select 
t2.model_name as productmodel
,sum(t1.sale_qty) as sale_qty--实际销量
,sum(t1.rev_amt) as rev_amt--实际销额
,sum(t1.cost_amt) as chengben --实际成本
,sum(t1.maolie) as maolie --毛利额
from sales t1 
left join (
select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO')
and delete_flag!='Y'
) t2 
on t1.matnr = t2.product_code
group by t2.model_name

)

,plan_sales as (
--取本年规划销量
--BP销量与规划销量处理
select 
coalesce (t1.prdct_model ,t2.prdct_model) as prdct_model
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_qty else t1.plan_sales_qty end ) as plan_sales_qty
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_amt else t1.plan_sales_amt end ) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit

from (
select 
prdct_model 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and model_label_1 = 'HDRP'
group by prdct_model 
,product_line 
,dt_month 

) t1 
full join (
--RDM数据中可能 会存在一个型号多条记录的情况   默认取最大值
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
,max(plan_gross_margin ) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('空气调节类产品')
and model_type = '产品型号口径'
group by prdct_model 
,product_line 
,dt_month 
)t2
on t1.prdct_model = t2.prdct_model
and t1.dt_month = t2.dt_month
left join  (
--最小的立项规划销量月份作为首次上市月份
select 
PG00061
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from product_model
group by PG00061
,product_line 
) t3
on coalesce (t1.prdct_model ,t2.prdct_model) = t3.PG00061
where substring(coalesce (t1.dt_month ,t2.dt_month),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') --限制取出本年的数据
and coalesce (t1.dt_month ,t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')  --限制取出本年内本月之前的数据
--新增滞后上市以实际上市时间开始算累计BP目标销量
and coalesce (t1.dt_month ,t2.dt_month) >=  coalesce (t3.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by coalesce (t1.prdct_model ,t2.prdct_model)
-- ,coalesce (t1.product_line ,t2.product_line)
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'空气事业部' as business_division   --事业部
,t1.product_line  --产品线
,t1.PG00020	--内销/外销
,'2' as zhibiao_type
,'型号口径' as data_type
,t1.PG00061	--名称
,t1.PG00025  --实际上市时间
,t1.HX00501  --实际退市准备时间
,t2.sale_qty  --实际销量
,t3.plan_sales_qty   --计划销量
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)   --销量完成率
,t2.rev_amt   --实际销额
,t3.plan_sales_amt  --计划销额
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)   --销额完成率
,t2.maolie   --毛利额
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,t1.PG00019	--产品定位
,t1.PG00015	--产品公司
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
--,t1.PG00029	--产品型号生命周期状态
,t1.PG00021	--规划销售渠道
,t1.shangshi_m  --上市月份
,case when t1.shangshi_m <= 3 then '[0,3]'
when t1.shangshi_m <= 6 then '(3,6]'
when t1.shangshi_m <= 12 then '(6,12]'
when t1.shangshi_m > 12 then '(12,)'
else '其他' end model_label_2  --上市周期
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
,case 
--只选上市状态的
-- when coalesce(t1.PG00029,'创建') not in ('上市') then 'Y'
when not(PG00025 is not null and HX00501 is null)  then 'Y'
--去除OEM产品
when PG00005 = 'OEM品牌' then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when t4.PG00061 is not null then 'Y'  --单元式内外机  有整机的不考核内外机
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else 'N' end as is_project
,kt_nbzz  --空气事业部内部组织
,now()
,project_code--项目编码
,project_name--项目名称
,case when kt_nbzz = '轻商内销' and t1.PG00061 in (select productmodel from dim.dim_rule_ipd_product_portfolio_kq_oldproject
where brand = '璀璨') then 'N' else 'Y' end model_label_23   --空气是否指标考核口径
,PG00021	--规划销售渠道
,PG00019	--产品定位
,t5.xmndxf
from product_model t1
left join all_sales t2 
on t1.PG00061 = t2.productmodel
left join plan_sales t3 
on t1.PG00061 = t3.prdct_model
left join danyuanji_tichu t4
on t1.PG00061 = t4.PG00061
left join test.productmodel_xmndxf t5 
on t1.PG00061 = t5.PRODUCTMODEL
left join fuchan_model t_fuchan 
on t1.PG00061 = t_fuchan.masterDataName
;




--空气事业部 低效型号数  海信日立
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line in ('中央空调')
;
--空气事业部 低效型号数  海信日立
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,data_type  
,prdct_model	--型号名
,salemodel_code
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,pg00015--产品公司
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,shangshi_m--上市月份
,project_code  --项目编码
,project_name --项目名称
,salemodel	--销售型号名称
,pc20080	--归属营销部
,hx00379	--是否模块组合
,is_dx	--是否低效
,is_project	--是否保护期
,is_project_nk  --是否保护期-内控口径【新增】
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,model_label_23   --空气是否指标考核口径
,PC20006    --标准品/定制产品
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
,HX00327    --所有者【新增】
,PG00039    --营销定位【新增】
,HX00339    --主要销售渠道【新增】
,productmodel_life  --销售型号生命周期状态【新增】
,PG00009    --产品系列【新增】
,shangshi_y --上市年数【新增】
,is_db_qty  --销量是否达标【低效型号数填NULL】
,is_db_amt  --销额是否达标【低效型号数填NULL】
,is_db_margin --毛利率是否达标【低效型号数填NULL】
)
--空气事业部  海信日立
with sale_model as (
select 
'中央空调' as product_line
,t1.kt_nbzz  --空调内部组织
,t2.PG00020	--内销/外销
,t1.PG00025    --实际上市时间
,t1.HX00501    --实际退市准备时间
,t1.PG00026    --停止下单时间
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.productmodel  --产品型号名称
,t1.PG00072    --产品档次
,t1.PC00025	--规划生产基地
,t1.PG00069    --销售品牌
,t2.PG00015   --产品公司
,t1.productmodel_id --产品型号id
,t1.PG00061    --销售型号名称
,t1.PG00068    --销售型号编码
,t1.PC20080   --归属营销部
,t1.HX00379   --是否模块组合
,t1.PC20006    --标准品/定制产品
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(t1.PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(t1.PG00025)) as shangshi_m
,t1.project_code --项目编码
,t1.project_name--项目名称
--集团逻辑 is_project（新增外销品牌控制）
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense') then 'Y'
else 'N' end as is_project
--【新增】内控逻辑 is_project_nk（营销部扩展+外销品牌扩展）
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部','海外业务部(大客户)','水机营销部','海外业务部(水系统)') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense','HITACHI','YORK') then 'Y'
else 'N' end as is_project_nk
,t2.PG00021	--规划销售渠道
,t2.PG00019	--产品定位
--【新增】5个字段
,t1.HX00327    --所有者
,t1.PG00039    --营销定位
,t1.HX00339    --主要销售渠道
,t1.PG00057    --销售型号生命周期状态
,t1.PG00009    --产品系列
from (
select 
PG00061    --名称
,id
,productmodel_id --产品型号id
,productmodel --产品型号名称
,PG00068    --销售型号编码
,PG00072    --产品档次
,'中央空调'  as kt_nbzz
,PG00069    --销售品牌
,PG00057    --销售型号生命周期状态
,PG00042    --销售渠道
,PG00041    --销售国家及地区
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间
,PG00027    --停止生产时间
,case when PG00026 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00026 end as PG00026    --停止下单时间
,HX00378    --实际停止下单时间
,PG00004    --产品小类
,PG00003    --产品中类
,PG00002    --产品大类
,PG00015    --产品公司
,PG00014    --产品平台
,PC20080    --归属营销部
,HX00379    --是否模块组合
,HX00370    --内机箱体
,PC20085    --整机产品平台
,PC20006    --标准品/定制产品
,project_code --项目编码
,project_name --项目名称
,PC00025	--规划生产基地
--【新增】取5个字段
,HX00327    --所有者
,PG00039    --营销定位
,HX00339    --主要销售渠道
,PG00009    --产品系列
from dim.dim_ipd_salemodel_dd t1 
where pg00002 = '空气调节类产品'
and pg00003 = '中央空调'
and pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机')
) t1
left join dim.dim_ipd_productmodel_dd t2 
on t1.productmodel_id = t2.id
where t1.kt_nbzz in ('中央空调')
--【修改】外销品牌扩展（品牌控制已在is_project/is_project_nk的CASE中处理）
and case when t2.PG00020 = '内销' then t1.PG00069 in ('Hisense','HITACHI','YORK','KELON') when t2.PG00020 = '外销' then t1.PG00069 in ('Hisense','HITACHI','YORK') else 1=2 end 
)
,all_sales as (
--日立实际销量（年累）
select 
t2.sale_model_code
,sum(sale_qty ) as sale_qty
,sum(rev_amt ) as rev_amt
,sum(cost_amt) as chengben
,sum(rev_amt ) - sum(cost_amt) as maolie
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (
select 
product_code
,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO')
and delete_flag!='Y'
) t2 
on t1.matnr = t2.product_code
where substring(yearmonth,1,4) =  DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by t2.sale_model_code
)
,plan_sales as (
--BP销量与规划销量处理
select 
coalesce (t1.salemodelcode ,t2.salemodelcode) as salemodelcode
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_qty else t1.plan_sales_qty end ) as plan_sales_qty
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_amt else t1.plan_sales_amt end ) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select 
salemodelcode 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and model_label_1 = 'HDRP'
group by salemodelcode 
,product_line 
,dt_month 
) t1 
full join (
select 
salemodelcode
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
,max(plan_gross_margin ) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('空气调节类产品')
and model_type = '销售型号编码口径'
group by product_line 
,dt_month ,salemodelcode
)t2
on t1.salemodelcode = t2.salemodelcode
and t1.dt_month = t2.dt_month
left join  (
select 
PG00068
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from sale_model
group by PG00068
,product_line 
) t3
on coalesce (t1.salemodelcode ,t2.salemodelcode) = t3.PG00068
where substring(coalesce (t1.dt_month ,t2.dt_month),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and coalesce (t1.dt_month ,t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and coalesce (t1.dt_month ,t2.dt_month) >=  coalesce (t3.min_dtmonth ,'190001')
group by coalesce (t1.salemodelcode ,t2.salemodelcode)
)
,fuchan_model as (
    --本年复产型号（销售型号编码口径）
    select distinct mdgno
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'salesModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
select
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'空气事业部' as business_division
,t1.product_line
,t1.PG00020
,'2' as zhibiao_type
,'型号口径' as data_type
,t1.PG00061
,t1.PG00068
,t1.PG00025
,coalesce (t1.HX00501,t1.PG00026)
,t2.sale_qty
,t3.plan_sales_qty
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)
,t2.rev_amt
,t3.plan_sales_amt
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)
,t2.maolie
,t3.plan_gross_profit
,t2.maolie/nullif(t3.plan_gross_profit,0.0)
,t2.maolie/nullif(t2.rev_amt,0.0)
,t1.PG00015
,t1.PG00069
,t1.PG00002
,t1.PG00003
,t1.PG00004
,t1.PC00025
,t1.shangshi_m
,t1.project_code
,t1.project_name
,t1.PG00061
,t1.PC20080
,t1.HX00379
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
--集团逻辑 is_project
,case 
when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project
--【新增】内控逻辑 is_project_nk
,case 
when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project_nk end as is_project_nk
,t1.kt_nbzz
,now()
,'N' as model_label_23
,t1.PC20006
,t1.PG00021
,t1.PG00019
,t4.xmndxf
--【新增】字段
,t1.HX00327
,t1.PG00039
,t1.HX00339
,t1.PG00057 as productmodel_life
,t1.PG00009
,CEIL(t1.shangshi_m / 12) as shangshi_y
--低效型号数不需要达标判定
,null as is_db_qty
,null as is_db_amt
,null as is_db_margin
from sale_model t1
left join all_sales t2 on t1.PG00068 = t2.sale_model_code
left join plan_sales t3 on t1.PG00068 = t3.salemodelcode
left join test.salesmodel_xmndxf t4 on t1.PG00068 = t4.PG00068
left join fuchan_model t_fuchan on t1.PG00068 = t_fuchan.mdgno
;

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line in ('家用空调')
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale
,zhibiao_type	--指标口径
,data_type  
,ir_act_time	--鉴定评审时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,shangshi_m--上市月份
,project_code  --项目编码
,project_name --项目名称
,is_dx	--是否低效
,is_project	--是否保护期
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,model_label_23   --空气是否指标考核口径
,pc20080 --归属营销部
)
select 
dt_month	--月份
,'空气事业部' as business_division   --事业部
,product_line	--产品线
,case when kt_nbzz in ('中央空调') then null else in_out_sale end as  in_out_sale
,zhibiao_type	--指标口径
,'项目口径' as data_type  
,min(ir_act_time)	--鉴定评审时间
,sum(coalesce (act_sales_qty,0.0)) as act_sales_qty	--实际销量
,sum(coalesce (plan_sales_qty,0.0)) as plan_sales_qty	--规划销量
,sum(coalesce (act_sales_qty,0.0))/nullif(sum(coalesce (plan_sales_qty,0.0)),0.0)as sales_qty_rate	--销量完成率
,sum(coalesce (act_sales_amt,0.0))	as act_sales_amt--实际销额
,sum(coalesce (plan_sales_amt,0.0))	as plan_sales_amt--规划销额
,sum(coalesce (act_sales_amt,0.0))/nullif(sum(coalesce (plan_sales_amt,0.0)),0.0)  as sales_amt_rate	--销额完成率
,sum(coalesce (act_gross_profit,0.0)) as act_gross_profit--实际毛利额
,sum(coalesce (plan_gross_profit,0.0)) as plan_gross_profit --规划毛利额
,sum(coalesce (act_gross_profit,0.0))/nullif(sum(coalesce (plan_gross_profit,0.0)),0.0) as gross_profit_rate  --毛利额完成率
,sum(coalesce (act_gross_profit,0.0))/nullif(sum(coalesce (act_sales_amt,0.0)),0.0) as act_gross_margin  --实际毛利率
,max(shangshi_m)--上市月份
,project_code  --项目编码
,project_name --项目名称
,case when sum(coalesce (act_sales_qty,0.0))/nullif(sum(coalesce (plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx	--是否低效
,'N' as is_project	--是否保护期
,kt_nbzz  --空气事业部内部组织
,now()
,'Y' as model_label_23  --空气是否指标考核口径
,GROUP_CONCAT(distinct pc20080,',') as pc20080 --归属营销部
from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line in ('家用空调')
and data_type = '型号口径'
and is_project = 'N'
and project_code is not null 
and case when kt_nbzz in ('中央空调') then 1=1
when kt_nbzz in ('轻商内销') then model_label_23 ='N'
else 1=2 end
group by dt_month	--月份
,product_line	--产品线
,zhibiao_type	--指标口径
,project_code  --项目编码
,project_name --项目名称
,kt_nbzz  --空气事业部内部组织
,case when kt_nbzz in ('中央空调') then null else in_out_sale end
;

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,GROUP_CONCAT(distinct t1.pc20080,',') as pc20080
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t2.koujing
;

-- ----------------------------------------
-- 3.1 低效型号数 营销部项目口径 (zhibiao_type='2-1')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-1'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.pc20080  --二级维度：归属营销部
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.pc20080 ,t2.koujing
;


delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-1'
and product_line = '中央空调'
and data_type = '项目口径'
and pc20080 in ('工程营销部-海信','工程营销部-日立','工程营销部-约克','工程营销部-其他')
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) as pc20080  --二级维度：归属营销部
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.pc20080 = '工程营销部'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) ,t2.koujing
;

-- ----------------------------------------
-- 3.2 低效型号数 所有者项目口径 (zhibiao_type='2-2')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-2'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,HX00327
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-2' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.HX00327  --二级维度：所有者
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.HX00327 ,t2.koujing
;

-- ----------------------------------------
-- 3.3 低效型号数 产品小类项目口径 (zhibiao_type='2-3')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-3'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,product_sml
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-3' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.product_sml  --二级维度：产品小类
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.product_sml ,t2.koujing
;



--冰箱 冷柜 洗衣机 内销新品规划命中率
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line in ('冰箱','冷柜','洗衣机')
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,distribution_channel --销售渠道
,product_positioning --产品定位
,platform   --平台
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,menlei  --门类
,pinleixifen--品类细分
,shangshi_m--上市月份
--,productmodel_life--生命周期状态
,is_odm --是否odm
,is_dx	--是否低效
,is_project	--是否保护期
,model_label_2  --上市周期
,load_dt	--加载日期
,projectdevelopmentdifficulty --项目开发难度
)



with all_model as (
select 
product_line  --产品线
,PG00061 --名称
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,PG00025  --实际上市时间
,HX00501  --实际退市准备时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(PG00025)) as shangshi_m
,PG00029	--产品型号生命周期状态
,case when coalesce(PG00005,'0') IN ('Hisense','Ronshen') AND not(PC00025 LIKE '%海信%' or PC00025 LIKE '%平度%') then 'Y' else 'N' end as  is_odm
,case 
--古洛尼品牌的剔除逻辑
when PG00005 in ('gorenje') then 'Y'
--只选上市状态的
when not(PG00025 is not null and HX00501 is null)  then 'Y'
else 'N' end as is_project
from ( 
select 
id
,PG00061	--名称
,case
-- 内销：家用冰箱
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 in ('冷藏冷冻箱','冷藏箱') and PG00020 = '内销' then '冰箱'
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 = '冷冻箱' and PC00001 = '冰箱' and PG00020 = '内销' then '冰箱'
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 = '冷冻箱' and PG00020 = '内销' then '冷柜'
-- 内销：家用冷柜
when PG00002 = '控温储藏类产品' and PG00003 = '家用冷柜' and PG00020 = '内销' then '冷柜'
-- 内销：家用展示柜（冰吧）
when PG00002 = '控温储藏类产品' and PG00003 = '家用展示柜' and PG00004 = '冰吧' and PG00020 = '内销' then '冷柜'
-- 外销：家用冰箱
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00020 = '外销' then '冰箱'
-- 外销：家用冷柜
when PG00002 = '控温储藏类产品' and PG00003 = '家用冷柜' and PG00020 = '外销' then '冷柜'
-- 洗衣机
when PG00002 = '清洁卫生器具' and PG00003 in ('洗衣机','干衣机','护理机') then '洗衣机'
else '其他' end as product_line
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,HX00024	--销售小区
,HX00023	--销售大区
,PC10050    --门类
,PC00001    --品类细分
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间
,PG00026  --实际停止下单时间
,PG00027  --停止生产时间
from dim.dim_ipd_productmodel_dd t1  --产品型号
)t1 
where product_line in ('冰箱','冷柜','洗衣机')
and PG00020 = '内销'
)
,guanbao_sales as ( 
select 
matnr 
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt
,sum(cost_amt) as chengben 
,sum(rev_amt) - sum(cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata ovafis 
where yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
-- and matkl in ('1300101','1300201','1320201','1320101','1320100','1310101')
group by matnr

) 

,guanbao_sales_2 as (
select t2.model_name as productmodel
,sum(t1.sale_qty) sale_qty --实际销量
,sum(t1.rev_amt) rev_amt  --实际销额
,sum(t1.chengben) chengben --实际成本
,sum(t1.maolie) maolie  --毛利额
from guanbao_sales t1 
left join (select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y') t2 
on t1.matnr = t2.product_code
group by t2.model_name
)
,plan_sales as (
--取LX规划销量
select 
t1.prdct_model as prdct_model
,t1.product_line as product_line
,sum(t1.plan_sales_qty) as plan_sales_qty
,sum(t1.plan_sales_amt) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select 
prdct_model 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('控温储藏类产品','清洁卫生器具')
group by prdct_model 
,product_line 
,dt_month 

) t1 
left join  (
--最小的立项规划销量月份作为首次上市月份
select 
PG00061
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from all_model
group by PG00061
,product_line 
) t2
on t1.prdct_model = t2.PG00061
where t1.dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')  --限制取出本年内本月之前的数据
--新增滞后上市以实际上市时间开始算累计BP目标销量
and t1.dt_month>=  coalesce (t2.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by t1.prdct_model
,t1.product_line
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,case when t1.product_line = '洗衣机' then '洗护事业部' when t1.product_line in ('冰箱','冷柜') then '冰冷事业部' else '其他' end as business_division   --事业部
,t1.product_line  --产品线
,t1.PG00020	--内销/外销
,'4' as zhibiao_type 
,t1.PG00061 --名称
,t1.PG00025  --实际上市时间
,t1.HX00501  --实际退市准备时间
,t2.sale_qty  --实际销量
,t3.plan_sales_qty   --计划销量
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)   --销量完成率
,t2.rev_amt   --实际销额
,t3.plan_sales_amt  --计划销额
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)   --销额完成率
--,t2.chengben  --实际成本
,t2.maolie   --毛利额
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,t1.PG00021	--规划销售渠道
,t1.PG00019	--产品定位
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
,t1.PC10050    --门类
,t1.PC00001    --品类细分
,t1.shangshi_m  --上市月份
--,t1.PG00029	--产品型号生命周期状态
,t1.is_odm
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m >= 13 then 'Y'  --去除新品期
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project  --是否保护期
,case when t1.shangshi_m <= 3 then '[0,3]'
when t1.shangshi_m <= 6 then '(3,6]'
when t1.shangshi_m <= 12 then '(6,12]'
when t1.shangshi_m > 12 then '(12,)'
else '其他' end model_label_2  --上市周期
,now()
,xmndxf
from all_model t1 
left join guanbao_sales_2 t2 
on t1.PG00061 = t2.productmodel
left join plan_sales t3 
on t1.PG00061 = t3.prdct_model
left join test.productmodel_xmndxf t4 
on t1.PG00061 = t4.PRODUCTMODEL
left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName
;







--空气事业部 低效型号数
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line in ('中央空调','家用空调')
;
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,data_type
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,product_positioning --产品定位
,pg00015	--产品公司
,platform   --平台
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
--,productmodel_life--生命周期状态
,distribution_channel --销售渠道
,shangshi_m--上市月份
,model_label_2  --上市周期
,is_dx	--是否低效
,is_project	--是否保护期
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,project_code  --项目编码
,project_name --项目名称
,model_label_23   --空气是否指标考核口径
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
)
--空气事业部
with product_model as (

select 
id --产品型号id
,PG00061	--名称
,case when kt_nbzz in ('家空内销','家空外销','轻商内销','轻商外销') then '家用空调'
when kt_nbzz in ('央空内销日立','央空外销日立','央空内销科龙') then '中央空调'
else '其他' end product_line
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,pc20029    --内机产品型号
,pc20055    --外机产品型号
,hx00290    --产品类别
,PG00025  --实际上市时间
,HX00501  --实际退市准备时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(PG00025)) as shangshi_m
,kt_nbzz  --空气事业部内部组织
,project_code  --项目编码
,project_name --项目名称
from (
select 
id --产品型号id
,PG00061	--名称
,case 
--家用空调
when PG00061= 'KFR-120LW/SEA-X1' then '轻商内销'
when t1.pg00003 in ('除湿机') then '家空外销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and t1.pg00004 in ('分体式空调器整机') then '家空内销'
when t1.pg00015 = '空调' and t1.PG00020 = '外销' and t1.pg00003 = '家用房间空调' and t1.pg00004 in ('分体式空调器整机','移动式空调器','窗式空调器') then '家空外销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (PG00005,'Hisense') <> 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','单元式整机','多联机内机','多联机外机','风机盘管','空气源热泵两联供','热泵热水机','涡旋式冷水(热泵)机组','新风换气机','一拖多外机') then '轻商内销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and coalesce (PG00005,'Hisense') <> 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('热风机整机','热风机内机','热风机外机') then '轻商内销'
when t1.pg00015 = '空调' and t1.PG00020 = '外销' and t1.pg00003 = '中央空调' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','一拖多外机','屋顶机','空气源热泵三联供','热泵热水机') then '轻商外销' 
--中央空调
when t1.pg00015 = '日立' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (PG00005,'Hisense') = 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','风机盘管','空气源热泵两联供','热泵热水机','涡旋式冷水(热泵)机组','新风换气机','一拖多外机') then '央空内销科龙'
when t1.pg00015 = '日立' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and coalesce (PG00005,'Hisense') = 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('热风机内机','热风机外机') then '央空内销科龙'
when t1.pg00015 = '日立' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (hx00427,'否') = '否' 
and t1.pg00004 in ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') then '央空内销日立'  
when t1.pg00015 = '日立' and t1.PG00020 = '外销' and t1.pg00003 = '中央空调' and coalesce (hx00427,'否') = '否' 
and t1.pg00004 in ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') then '央空外销日立'  
else '其他' end as kt_nbzz
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,pc20029    --内机产品型号
,pc20055    --外机产品型号
,hx00290    --产品类别
,hx00427  --是否重复型号
,project_code  --项目编码
,project_name --项目名称
-- ,HX00501  --实际退市准备时间
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间
-- ,PG00025  --实际上市时间
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间
from dim.dim_ipd_productmodel_dd t1  --产品型号
where t1.pg00002 = '空气调节类产品'
--排除环境电器产品
and coalesce (t1.productline_syb ,'填空') <> '环境电器'
)a 
where kt_nbzz in ('家空内销','家空外销','轻商内销','轻商外销')
and PG00020 = '内销'
)
,danyuanji_tichu as ( 
select PG00061 from product_model
where pg00004 in ('单元式内机','热风机内机') 
and PG00061 in (
select distinct pc20029 from product_model
where pg00004 in ('单元式整机','热风机整机') 
and pc20029 is not null
)
union all 

select PG00061 from product_model
where pg00004 in ('单元式外机','热风机外机') 
and PG00061 in (
select distinct pc20055 from product_model
where pg00004 in ('单元式整机','热风机整机') 
and pc20055 is not null
)
)
,sales as (
select 
matnr
,'空调' product_line
,sum(sale_qty)sale_qty
,sum(rev_amt)rev_amt
,sum(cost_amt)cost_amt
,sum(rev_amt) - sum(cost_amt) as maolie  --毛利额
from ods.ods_mr_v_app_fm_imat_saledata ovafis 
where /*matkl in ('1200101','1200301','1209901')
and */yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by matnr



)
,all_sales as (
select 
t2.model_name as productmodel
,sum(t1.sale_qty) as sale_qty--实际销量
,sum(t1.rev_amt) as rev_amt--实际销额
,sum(t1.cost_amt) as chengben --实际成本
,sum(t1.maolie) as maolie --毛利额
from sales t1 
left join (
select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO')
and delete_flag!='Y'
) t2 
on t1.matnr = t2.product_code
group by t2.model_name

)

,plan_sales as (
--取本年规划销量
--BP销量与规划销量处理
select 
t1.prdct_model as prdct_model
,case when t1.product_line = '海信日立' then '日立'
when t1.product_line = '家用空调' then '空调'
else t1.product_line end as product_line
,sum(t1.plan_sales_qty ) as plan_sales_qty
,sum(t1.plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select 
prdct_model 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('空气调节类产品')
and model_type = '产品型号口径'
group by prdct_model 
,product_line 
,dt_month 

) t1 
left join  (
--最小的立项规划销量月份作为首次上市月份
select 
PG00061
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from product_model
group by PG00061
,product_line 
) t2
on t1.prdct_model = t2.PG00061
where t1.dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')  --限制取出本年内本月之前的数据
--新增滞后上市以实际上市时间开始算累计BP目标销量
and t1.dt_month >=  coalesce (t2.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by t1.prdct_model
,t1.product_line
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'空气事业部' as business_division   --事业部
,t1.product_line  --产品线
,t1.PG00020	--内销/外销
,'4' as zhibiao_type
,'型号口径' as data_type
,t1.PG00061	--名称
,t1.PG00025  --实际上市时间
,t1.HX00501  --实际退市准备时间
,t2.sale_qty  --实际销量
,t3.plan_sales_qty   --计划销量
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)   --销量完成率
,t2.rev_amt   --实际销额
,t3.plan_sales_amt  --计划销额
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)   --销额完成率
,t2.maolie   --毛利额
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,t1.PG00019	--产品定位
,t1.PG00015	--产品公司
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
--,t1.PG00029	--产品型号生命周期状态
,t1.PG00021	--规划销售渠道
,t1.shangshi_m  --上市月份
,case when t1.shangshi_m <= 3 then '[0,3]'
when t1.shangshi_m <= 6 then '(3,6]'
when t1.shangshi_m <= 12 then '(6,12]'
when t1.shangshi_m > 12 then '(12,)'
else '其他' end model_label_2  --上市周期
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
,case 
--只选上市状态的
-- when coalesce(t1.PG00029,'创建') not in ('上市') then 'Y'
when not(PG00025 is not null and HX00501 is null)  then 'Y'
--去除OEM产品
when PG00005 = 'OEM品牌' then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m >= 13 then 'Y'  --去除新品期
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when t4.PG00061 is not null then 'Y'  --单元式内外机  有整机的不考核内外机
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else 'N' end as is_project
,kt_nbzz  --空气事业部内部组织
,now()
,project_code  --项目编码
,project_name --项目名称
,case when kt_nbzz = '轻商内销' and t1.PG00061 in (select productmodel from dim.dim_rule_ipd_product_portfolio_kq_oldproject
where brand = '璀璨') then 'N' else 'Y' end model_label_23   --空气是否指标考核口径
,PG00021	--规划销售渠道
,PG00019	--产品定位
,t5.xmndxf
from product_model t1
left join all_sales t2 
on t1.PG00061 = t2.productmodel
left join plan_sales t3 
on t1.PG00061 = t3.prdct_model
left join danyuanji_tichu t4
on t1.PG00061 = t4.PG00061
left join test.productmodel_xmndxf t5 
on t1.PG00061 = t5.PRODUCTMODEL
left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName
;





--空气事业部 新品规划命中率  海信日立

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line in ('中央空调')
;
--空气事业部 新品规划命中率  海信日立
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,data_type  
,prdct_model	--型号名
,salemodel_code
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,pg00015--产品公司
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,shangshi_m--上市月份
,project_code  --项目编码
,project_name --项目名称
,salemodel	--销售型号名称
,pc20080	--归属营销部
,hx00379	--是否模块组合
,is_dx	--是否低效
,is_project	--是否保护期
,is_project_nk  --是否保护期-内控口径【新增】
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,model_label_23   --空气是否指标考核口径
,PC20006    --标准品/定制产品
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
,HX00327    --所有者【新增】
,PG00039    --营销定位【新增】
,HX00339    --主要销售渠道【新增】
,productmodel_life  --销售型号生命周期状态【新增】
,PG00009    --产品系列【新增】
,shangshi_y --上市年数【新增】
,is_db_qty  --销量是否达标【新增】
,is_db_amt  --销额是否达标【新增】
,is_db_margin --毛利率是否达标【新增】
)
--空气事业部  海信日立
with sale_model as (
select 
'中央空调' as product_line
,t1.kt_nbzz  --空调内部组织
,t2.PG00020	--内销/外销
,t1.PG00025    --实际上市时间
,t1.HX00501    --实际退市准备时间
,t1.PG00026    --停止下单时间
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.productmodel  --产品型号名称
,t1.PG00072    --产品档次
,t1.PC00025	--规划生产基地
,t1.PG00069    --销售品牌
,t2.PG00015   --产品公司
,t1.productmodel_id --产品型号id
,t1.PG00061    --销售型号名称
,t1.PG00068    --销售型号编码
,t1.PC20080   --归属营销部
,t1.HX00379   --是否模块组合
,t1.PC20006    --标准品/定制产品
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(t1.PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(t1.PG00025)) as shangshi_m
,t1.project_code --项目编码
,t1.project_name--项目名称
--集团逻辑 is_project（含品牌控制）
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense') then 'Y'
else 'N' end as is_project
--【新增】内控逻辑 is_project_nk
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部','海外业务部(大客户)','水机营销部','海外业务部(水系统)') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense','HITACHI','YORK') then 'Y'
else 'N' end as is_project_nk
,t2.PG00021	--规划销售渠道
,t2.PG00019	--产品定位
,t1.HX00327    --所有者
,t1.PG00039    --营销定位
,t1.HX00339    --主要销售渠道
,t1.PG00057    --销售型号生命周期状态
,t1.PG00009    --产品系列
from (
select 
PG00061 ,id ,productmodel_id ,productmodel ,PG00068 ,PG00072
,'中央空调' as kt_nbzz
,PG00069 ,PG00057 ,PG00042 ,PG00041
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025
,PG00027
,case when PG00026 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00026 end as PG00026
,HX00378 ,PG00004 ,PG00003 ,PG00002 ,PG00015 ,PG00014
,PC20080 ,HX00379 ,HX00370 ,PC20085 ,PC20006
,project_code ,project_name ,PC00025
,HX00327 ,PG00039 ,HX00339 ,PG00009
from dim.dim_ipd_salemodel_dd t1 
where pg00002 = '空气调节类产品'
and pg00003 = '中央空调'
and pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机')
) t1
left join dim.dim_ipd_productmodel_dd t2 on t1.productmodel_id = t2.id
where t1.kt_nbzz in ('中央空调')
and case when t2.PG00020 = '内销' then t1.PG00069 in ('Hisense','HITACHI','YORK','KELON') when t2.PG00020 = '外销' then t1.PG00069 in ('Hisense','HITACHI','YORK') else 1=2 end 
)
,all_sales as (
--日立实际销量（全生命周期累计，不限本年）
select 
t2.sale_model_code
,sum(sale_qty ) as sale_qty
,sum(rev_amt ) as rev_amt
,sum(cost_amt) as chengben
,sum(rev_amt ) - sum(cost_amt) as maolie
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (
select product_code ,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO') and delete_flag!='Y'
) t2 on t1.matnr = t2.product_code
where yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by t2.sale_model_code 
)
,plan_sales as (
--新品命中率只用LX规划量（全生命周期累计）
select 
t1.salemodelcode
,t1.product_line
,sum(t1.plan_sales_qty) as plan_sales_qty
,sum(t1.plan_sales_amt) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select salemodelcode ,product_line ,dt_month
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt) as plan_sales_amt
,sum(plan_gross_margin) as plan_gross_margin
,sum(plan_gross_profit) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('空气调节类产品')
and model_type = '销售型号编码口径'
group by product_line ,dt_month ,salemodelcode
) t1 
left join (
select PG00068 ,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from sale_model
group by PG00068 ,product_line 
) t2 on t1.salemodelcode = t2.PG00068
where t1.dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.dt_month >= coalesce(t2.min_dtmonth,'190001')
group by t1.salemodelcode ,t1.product_line
)
,fuchan_model as (
    --本年复产型号（销售型号编码口径）
    select distinct mdgno
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'salesModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
select
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'空气事业部' as business_division
,t1.product_line
,t1.PG00020
,'4' as zhibiao_type
,'型号口径' as data_type
,t1.PG00061
,t1.PG00068
,t1.PG00025
,coalesce(t1.HX00501,t1.PG00026)
,t2.sale_qty
,t3.plan_sales_qty
,coalesce(coalesce(t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)
,t2.rev_amt
,t3.plan_sales_amt
,coalesce(t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)
,t2.maolie
,t3.plan_gross_profit
,t2.maolie/nullif(t3.plan_gross_profit,0.0)
,t2.maolie/nullif(t2.rev_amt,0.0)
,t1.PG00015
,t1.PG00069
,t1.PG00002
,t1.PG00003
,t1.PG00004
,t1.PC00025
,t1.shangshi_m
,t1.project_code
,t1.project_name
,t1.PG00061
,t1.PC20080
,t1.HX00379
,case when coalesce(t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
--集团逻辑 is_project（含新品期限制）
,case 
when not(PG00025 is not null and coalesce(t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 37 then 'Y'  --超过36个月不算新品
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project
--【新增】内控逻辑 is_project_nk（含新品期限制）
,case 
when not(PG00025 is not null and coalesce(t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 37 then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project_nk end as is_project_nk
,t1.kt_nbzz
,now()
,'N' as model_label_23
,t1.PC20006
,t1.PG00021
,t1.PG00019
,t4.xmndxf
,t1.HX00327
,t1.PG00039
,t1.HX00339
,t1.PG00057 as productmodel_life
,t1.PG00009
,CEIL(t1.shangshi_m / 12) as shangshi_y
--【新增】新品命中率达标判定（0.8为边界）
,case when coalesce(t3.plan_sales_qty,0) = 0 then 'Y' when coalesce(t2.sale_qty,0)/t3.plan_sales_qty >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(t3.plan_sales_amt,0.0) = 0 then 'Y' when coalesce(t2.rev_amt,0.0)/t3.plan_sales_amt >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(t3.plan_gross_profit,0.0) = 0 then 'Y' when t2.maolie/t3.plan_gross_profit >= 0.8 then 'Y' else 'N' end as is_db_margin
from sale_model t1
left join all_sales t2 on t1.PG00068 = t2.sale_model_code
left join plan_sales t3 on t1.PG00068 = t3.salemodelcode
left join test.salesmodel_xmndxf t4 on t1.PG00068 = t4.PG00068
left join fuchan_model t_fuchan on t1.PG00068 = t_fuchan.mdgno
;




delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line in ('家用空调')
and data_type = '项目口径'
;
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale
,zhibiao_type	--指标口径
,data_type  
,ir_act_time	--鉴定评审时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,shangshi_m--上市月份
,project_code  --项目编码
,project_name --项目名称
,is_dx	--是否低效
,is_project	--是否保护期
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,model_label_23   --空气是否指标考核口径
,pc20080 --归属营销部
)
select 
dt_month	--月份
,'空气事业部' as business_division   --事业部
,product_line	--产品线
,case when kt_nbzz in ('中央空调') then null else in_out_sale end as  in_out_sale
,zhibiao_type	--指标口径
,'项目口径' as data_type  
,min(ir_act_time)	--鉴定评审时间
,sum(coalesce (act_sales_qty,0.0)) as act_sales_qty	--实际销量
,sum(coalesce (plan_sales_qty,0.0)) as plan_sales_qty	--规划销量
,sum(coalesce (act_sales_qty,0.0))/nullif(sum(coalesce (plan_sales_qty,0.0)),0.0)as sales_qty_rate	--销量完成率
,sum(coalesce (act_sales_amt,0.0))	as act_sales_amt--实际销额
,sum(coalesce (plan_sales_amt,0.0))	as plan_sales_amt--规划销额
,sum(coalesce (act_sales_amt,0.0))/nullif(sum(coalesce (plan_sales_amt,0.0)),0.0)  as sales_amt_rate	--销额完成率
,sum(coalesce (act_gross_profit,0.0)) as act_gross_profit--实际毛利额
,sum(coalesce (plan_gross_profit,0.0)) as plan_gross_profit --规划毛利额
,sum(coalesce (act_gross_profit,0.0))/nullif(sum(coalesce (plan_gross_profit,0.0)),0.0) as gross_profit_rate  --毛利额完成率
,sum(coalesce (act_gross_profit,0.0))/nullif(sum(coalesce (act_sales_amt,0.0)),0.0) as act_gross_margin  --实际毛利率
,max(shangshi_m)--上市月份
,project_code  --项目编码
,project_name --项目名称
,case when sum(coalesce (act_sales_qty,0.0))/nullif(sum(coalesce (plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx	--是否低效
,'N' as is_project	--是否保护期
,kt_nbzz  --空气事业部内部组织
,now()
,'Y' as model_label_23  --空气是否指标考核口径
,GROUP_CONCAT(distinct pc20080,',') as pc20080 --归属营销部
from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line in ('家用空调')
and data_type = '型号口径'
and is_project = 'N'
and project_code is not null 
and case when kt_nbzz in ('中央空调') then 1=1
when kt_nbzz in ('轻商内销') then model_label_23 ='N'
else 1=2 end
group by dt_month	--月份
,product_line	--产品线
,zhibiao_type	--指标口径
,project_code  --项目编码
,project_name --项目名称
,kt_nbzz  --空气事业部内部组织
,case when kt_nbzz in ('中央空调') then null else in_out_sale end 
;




delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,GROUP_CONCAT(distinct t1.pc20080,',') as pc20080
,t2.koujing as rili_nkjt
--达标判定（0.8为边界）
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t2.koujing
;

-- ----------------------------------------
-- 3.5 新品规划命中率 营销部项目口径 (zhibiao_type='4-1')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4-1'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.pc20080 --二级维度：归属营销部-品牌
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.pc20080 ,t2.koujing
;

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4-1'
and product_line = '中央空调'
and data_type = '项目口径'
and pc20080 in ('工程营销部-海信','工程营销部-日立','工程营销部-约克','工程营销部-其他')
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) as pc20080  --二级维度：归属营销部-品牌
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.pc20080 = '工程营销部'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) ,t2.koujing
;

-- ----------------------------------------
-- 3.6 新品规划命中率 所有者项目口径 (zhibiao_type='4-2')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4-2'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,HX00327
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4-2' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.HX00327  --二级维度：所有者
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.HX00327 ,t2.koujing
;








--视像科技 内销低效型号数   产品型号口径
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') 
and zhibiao_type = '4'
and product_line = '平板电视'
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
--,is_bp_plan	--是否年度BP规划
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_margin  --实际毛利率
,is_dx	--是否低效
,is_project	--是否保护期
,model_label_1	--型号标签1
,load_dt	--加载日期
,brand  --品牌
,act_gross_profit --实际毛利额
,model_label_12
,shangshi_m--上市月份
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
,countries_regions  --立项国家及区域
,productline_tv  --产品线（电视）
)

with tv_model as (
select 
title	--产品型号产品描述（中文）
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,his_productsbrand as brand	--品牌名称
,his_oembrand	--OEM品牌名称
,his_pmdproductpositioning	--产品定位名称
,his_domesticsalesorexport 	--内销/外销名称
,his_prdplatform	--产品平台名称
,his_salescountries	--销售国家名称
,his_plannedsaleschannel	--规划销售渠道
,his_actualtimetomarket--实际上市时间
,his_actualdelistingtime--实际退市时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(his_actualtimetomarket)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(his_actualtimetomarket)) as shangshi_m
from (
select 
title	--产品型号产品描述（中文）
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,his_productsbrand	--品牌名称
,his_oembrand	--OEM品牌名称
,his_pmdproductpositioning	--产品定位名称
,his_domesticsalesorexport 	--内销/外销名称
,his_prdplatform	--产品平台名称
,his_salescountries	--销售国家名称
,his_plannedsaleschannel	--规划销售渠道
,case when cast(his_actualtimetomarket as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualtimetomarket end as his_actualtimetomarket--实际上市时间
,case when cast(his_actualdelistingtime as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualdelistingtime end as his_actualdelistingtime--实际退市时间
,case when cast(his_stopproductiontime as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_stopproductiontime end as his_stopproductiontime--停止生产时间	
,data_source
from dim.dim_ipd_jtplm_his_productmodel_dd
where his_productbigcategories = '显示类产品'
and his_productsmallcategories = '平板电视'
) t1
where t1.his_domesticsalesorexport = '内销'
and (coalesce (his_actualtimetomarket,'') <> '' and coalesce (his_actualdelistingtime,'') = '')  --只取上市且未决策退市的
)
,guanbao_sales as ( 
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
where t1.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
-- and t1.matkl in ('1100101','1100112','1100601')
group by coalesce (t3.model,t2.model_name)
)
,plan_sales as (
select 
t1.prdct_model
,t1.product_line
,sum(t1.plan_sales_qty) as plan_sales_qty
,sum(t1.plan_sales_amt) as plan_sales_amt
from (
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_line = '视像科技'
group by prdct_model 
,product_line 
,dt_month 
) t1 
left join  (
--鉴定评审次月为最小上市时间
select 
title as prdct_model
,'视像科技' as product_line
,min(DATE_FORMAT(date_add(his_actualtimetomarket,interval 1 month) , '%Y%m')) as min_dtmonth
from tv_model
group by title
) t2
on t1.prdct_model = t2.prdct_model
where t1.dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
--新增滞后上市以实际上市时间开始算累计BP目标销量
and t1.dt_month >=  coalesce (t2.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by t1.prdct_model
,t1.product_line
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'显示事业部' as business_division   --事业部
,'平板电视' as productline
,'内销' as  in_out_sale
,'4' as zhibiao_type 
,t1.title 
,t1.his_actualtimetomarket 
,t1.his_actualdelistingtime 
,coalesce (t2.sale_qty,0)
,coalesce (t3.plan_sales_qty,0)
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)
,t2.rev_amt
,t3.plan_sales_amt
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx
,case 
when t1.his_actualtimetomarket >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.title  in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'  --能效机 不考核
when t1.shangshi_m >= 13 then 'Y'  --去除新品期
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when coalesce(t1.brand,'0')  = 'OEM品牌' then 'Y' --不统计OEM品牌
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else 'N' end as is_project
,case when coalesce (t1.his_actualdelistingtime,'') <> ''  then '决策退市'
when coalesce (t1.his_actualtimetomarket,'') = '' and coalesce (t1.his_actualdelistingtime,'') = '' then '未上市'
when coalesce (t1.his_actualtimetomarket,'') <> '' and coalesce (t1.his_actualdelistingtime,'') = '' then '上市且未决策退市'
else '其他' end as jieduan
,now()
,t1.brand
,t2.maolie  --实际毛利额
,case /*when coalesce (t1.is_gcj,'No') = 'Yes' then '工程机'*/
when coalesce(t1.brand,'0')  = 'OEM品牌' then 'OEM'
when coalesce(t1.brand,'0')  = 'Hisense' then '海信'
when coalesce(t1.brand,'0')  = 'TOSHIBA'  then '东芝'
when coalesce(t1.brand,'0')  = 'Vidda'  then 'Vidda'
else '其他' end 
,shangshi_m  --上市月份
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,his_plannedsaleschannel	--规划销售渠道
,his_pmdproductpositioning	--产品定位名称
,t4.xmndxf
,t5.countries_regions  --立项国家及区域
,t5.his_pmdproductlinename  --产品线
from tv_model t1 
left join guanbao_sales t2 
on t1.title = t2.zzprdmodel
left join plan_sales t3 
on t1.title = t3.prdct_model
left join test.productmodel_tv_xmndxf t4 
on t1.title = t4.modelname
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
on t1.title = t5.modelname
left join fuchan_model t_fuchan on t1.title = t_fuchan.masterDataName
;




--厨电 内销低效型号数  产品型号口径
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line = '厨电'
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,distribution_channel --销售渠道
,product_positioning --产品定位
,platform   --平台
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,menlei  --门类
,pinleixifen--品类细分
,shangshi_m--上市月份
,is_odm --是否odm
,is_dx	--是否低效
,is_project	--是否保护期
,model_label_2  --上市周期
,load_dt	--加载日期
,projectdevelopmentdifficulty --项目开发难度
)



with all_model as (
select 
'厨电' as product_line  --产品线统一为厨电
,PG00061 --名称
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,PG00025  --实际上市时间
,HX00501  --实际退市准备时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(PG00025)) as shangshi_m
,PG00029	--产品型号生命周期状态
--厨电无ODM剔除
,'N' as is_odm
--厨电保护期判定
,case 
--剔除空壳机
when PG00061 like '%空壳机%' then 'Y'
--剔除配件（中类为吸油烟机配件）
when PG00003 = '吸油烟机配件' then 'Y'
--品牌非Hisense剔除
when coalesce(PG00005,'') <> 'Hisense' then 'Y'
--只选上市且未决策退市的
when not(PG00025 is not null and HX00501 is null) then 'Y'
else 'N' end as is_project
from ( 
select 
id
,PG00061	--名称
,HX00223  --厨电产品线细分（仅用于筛选，不输出）
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间（本月退市置NULL）
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间（本月上市置NULL）
from dim.dim_ipd_productmodel_dd t1  --产品型号
where HX00223 in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')
)t1 
where PG00020 = '内销'
)
,guanbao_sales as ( 
--管报实际销量（本年累计）
select 
matnr 
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt
,sum(cost_amt) as chengben 
,sum(rev_amt) - sum(cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata ovafis 
where substring(yearmonth,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by matnr

) 
,guanbao_sales_2 as (
--通过MDG映射到产品型号名称
select t2.model_name as productmodel
,sum(t1.sale_qty) sale_qty --实际销量
,sum(t1.rev_amt) rev_amt  --实际销额
,sum(t1.chengben) chengben --实际成本
,sum(t1.maolie) maolie  --毛利额
from guanbao_sales t1 
left join (select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y') t2 
on t1.matnr = t2.product_code
group by t2.model_name
)
,plan_sales as (
--取本年规划销量（BP与LX选择，同冰箱逻辑）
select 
coalesce (t1.prdct_model ,t2.prdct_model) as prdct_model
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_qty else t1.plan_sales_qty end ) as plan_sales_qty
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_amt else t1.plan_sales_amt end ) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select 
prdct_model 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and model_label_1 = 'HDRP'
and product_big in ('供热采暖类产品','厨房电器类产品')
group by prdct_model 
,product_line 
,dt_month 
) t1 
full join (
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
,max(plan_gross_margin ) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('供热采暖类产品','厨房电器类产品')
group by prdct_model 
,product_line 
,dt_month 
)t2
on t1.prdct_model = t2.prdct_model
and t1.dt_month = t2.dt_month
left join  (
select 
PG00061
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from all_model
group by PG00061
,product_line 
) t3
on coalesce (t1.prdct_model ,t2.prdct_model) = t3.PG00061
where substring(coalesce (t1.dt_month ,t2.dt_month),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and coalesce (t1.dt_month ,t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and coalesce (t1.dt_month ,t2.dt_month) >= coalesce (t3.min_dtmonth ,'190001')
group by coalesce (t1.prdct_model ,t2.prdct_model)
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'厨电事业部' as business_division   --事业部
,'厨电' as product_line  --产品线统一为厨电
,t1.PG00020	--内销/外销
,'2' as zhibiao_type -- 本年累
,t1.PG00061 --名称
,t1.PG00025  --实际上市时间
,t1.HX00501  --实际退市准备时间
,t2.sale_qty  --实际销量
,t3.plan_sales_qty   --计划销量
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)   --销量完成率
,t2.rev_amt   --实际销额
,t3.plan_sales_amt  --计划销额
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)   --销额完成率
,t2.maolie   --毛利额
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,t1.PG00021	--规划销售渠道
,t1.PG00019	--产品定位
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
,t1.PC10050    --门类
,t1.PC00001    --品类细分
,t1.shangshi_m  --上市月份
,t1.is_odm
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project  --是否保护期
,case when t1.shangshi_m <= 3 then '[0,3]'
when t1.shangshi_m <= 6 then '(3,6]'
when t1.shangshi_m <= 12 then '(6,12]'
when t1.shangshi_m > 12 then '(12,)'
else '其他' end model_label_2  --上市周期
,now()
,t4.xmndxf  --项目开发难度
from all_model t1 
left join guanbao_sales_2 t2 
on t1.PG00061 = t2.productmodel
left join plan_sales t3 
on t1.PG00061 = t3.prdct_model
left join test.productmodel_xmndxf t4 
on t1.PG00061 = t4.PRODUCTMODEL
left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName
;



--厨电 内销新品规划命中率
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line = '厨电'
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间（实际上市时间）
,juece_delistingtime	--下市时间（实际退市准备时间）
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,distribution_channel --销售渠道
,product_positioning --产品定位
,platform   --平台
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,menlei  --门类
,pinleixifen--品类细分
,shangshi_m--上市月份
,is_odm --是否odm
,is_dx	--是否低效（命中率中：<0.8为未命中）
,is_project	--是否保护期
,model_label_2  --上市周期
,load_dt	--加载日期
,projectdevelopmentdifficulty --项目开发难度
)



with all_model as (
select 
'厨电' as product_line  --产品线统一为厨电
,PG00061 --名称
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,PG00025  --实际上市时间
,HX00501  --实际退市准备时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(PG00025)) as shangshi_m
,PG00029	--产品型号生命周期状态
--厨电无ODM剔除
,'N' as is_odm
--厨电保护期判定
,case 
--剔除空壳机
when PG00061 like '%空壳机%' then 'Y'
--剔除配件（中类为吸油烟机配件）
when PG00003 = '吸油烟机配件' then 'Y'
--品牌非Hisense剔除
when coalesce(PG00005,'') <> 'Hisense' then 'Y'
--只选上市且未决策退市的
when not(PG00025 is not null and HX00501 is null) then 'Y'
else 'N' end as is_project
from ( 
select 
id
,PG00061	--名称
,HX00223  --厨电产品线细分（仅用于筛选，不输出）
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间（本月退市置NULL）
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间（本月上市置NULL）
from dim.dim_ipd_productmodel_dd t1  --产品型号
where HX00223 in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')
)t1 
where PG00020 = '内销'
)
,guanbao_sales as ( 
--管报实际销量（上市至今全部累计，不限本年）
select 
matnr 
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt
,sum(cost_amt) as chengben 
,sum(rev_amt) - sum(cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata ovafis 
where yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by matnr

) 
,guanbao_sales_2 as (
--通过MDG映射到产品型号名称
select t2.model_name as productmodel
,sum(t1.sale_qty) sale_qty --实际销量
,sum(t1.rev_amt) rev_amt  --实际销额
,sum(t1.chengben) chengben --实际成本
,sum(t1.maolie) maolie  --毛利额
from guanbao_sales t1 
left join (select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y') t2 
on t1.matnr = t2.product_code
group by t2.model_name
)
,plan_sales as (
--取LX立项规划量（从上市次月累计到当前月）
select 
t1.prdct_model as prdct_model
,t1.product_line as product_line
,sum(t1.plan_sales_qty) as plan_sales_qty
,sum(t1.plan_sales_amt) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select 
prdct_model 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('供热采暖类产品','厨房电器类产品')
group by prdct_model 
,product_line 
,dt_month 

) t1 
left join  (
--最小的立项规划销量月份作为首次上市月份
select 
PG00061
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from all_model
group by PG00061
,product_line 
) t2
on t1.prdct_model = t2.PG00061
where t1.dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')  --限制取出本月之前的数据
--新增滞后上市以实际上市时间开始算累计LX目标销量
and t1.dt_month >= coalesce (t2.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by t1.prdct_model
,t1.product_line
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'厨电事业部' as business_division   --事业部
,'厨电' as product_line  --产品线统一为厨电
,t1.PG00020	--内销/外销
,'4' as zhibiao_type --新品规划命中率
,t1.PG00061 --名称
,t1.PG00025  --实际上市时间
,t1.HX00501  --实际退市准备时间
,t2.sale_qty  --实际销量（上市至今累计）
,t3.plan_sales_qty   --LX立项规划销量（上市至今累计）
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)   --销量完成率
,t2.rev_amt   --实际销额
,t3.plan_sales_amt  --计划销额
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)   --销额完成率
,t2.maolie   --毛利额
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,t1.PG00021	--规划销售渠道
,t1.PG00019	--产品定位
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
,t1.PC10050    --门类
,t1.PC00001    --品类细分
,t1.shangshi_m  --上市月份
,t1.is_odm
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   --<0.8为未命中
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m >= 13 then 'Y'  --超过12个月新品期的不纳入
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核（第4个月开始）
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project  --是否保护期
,case when t1.shangshi_m <= 3 then '[0,3]'
when t1.shangshi_m <= 6 then '(3,6]'
when t1.shangshi_m <= 12 then '(6,12]'
when t1.shangshi_m > 12 then '(12,)'
else '其他' end model_label_2  --上市周期
,now()
,t4.xmndxf  --项目开发难度
from all_model t1 
left join guanbao_sales_2 t2 
on t1.PG00061 = t2.productmodel
left join plan_sales t3 
on t1.PG00061 = t3.prdct_model
left join test.productmodel_xmndxf t4 
on t1.PG00061 = t4.PRODUCTMODEL
left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName
;



---------------------------------------------------------低效型号占比 激光 内销 产品型号口径 zhibiao_type='2' ----------------------------------------------------

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') 
and zhibiao_type = '2'
and product_line in ('激光家用','激光商用')
and in_out_sale = '内销';

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
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
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_margin
,is_dx
,is_project
,model_label_1
,load_dt
,brand
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,model_label_12
,shangshi_m
,product_big
,product_mid
,product_sml
,distribution_channel
,product_positioning
,countries_regions
,productline_tv
,focallength
)

with tv_model as (
select 
title
,his_productbigcategories
,his_productmiddlecategories
,his_productsmallcategories
,his_productsbrand as brand
,his_oembrand
,his_domesticsalesorexport
,his_prdplatform
,his_salescountries
,his_plannedsaleschannel
,his_pmdproductpositioning
,his_actualtimetomarket
,his_actualdelistingtime
,his_focallength
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(his_actualtimetomarket)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(his_actualtimetomarket)) as shangshi_m
from (
select 
title
,his_productbigcategories
,his_productmiddlecategories
,his_productsmallcategories
,his_productsbrand
,his_oembrand
,his_pmdproductpositioning
,his_domesticsalesorexport
,his_prdplatform
,his_salescountries
,his_plannedsaleschannel
,his_focallength
,case when cast(his_actualtimetomarket as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualtimetomarket end as his_actualtimetomarket
,case when cast(his_actualdelistingtime as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualdelistingtime end as his_actualdelistingtime
from dim.dim_ipd_jtplm_his_productmodel_dd
where his_pmdproductaffiliatedcompany = '激光显示'
and his_productsmallcategories in ('激光电视','家用投影','商用投影')
) t1
where t1.his_domesticsalesorexport = '内销'
and (coalesce(his_actualtimetomarket,'') <> '' and coalesce(his_actualdelistingtime,'') = '')
)
-- 管报实际销量（年累，能效机转换）
,guanbao_sales as ( 
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
where substring(t1.yearmonth,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and t1.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by coalesce(t3.model, t2.model_name)
)
-- 规划销量（BP/LX选择逻辑）
,plan_sales as (
select 
coalesce(t1.prdct_model, t2.prdct_model) as prdct_model
,coalesce(t1.product_line, t2.product_line) as product_line
,sum(case when substring(coalesce(t3.min_dtmonth,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
    t2.plan_sales_qty else t1.plan_sales_qty end) as plan_sales_qty
,sum(case when substring(coalesce(t3.min_dtmonth,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
    t2.plan_sales_amt else t1.plan_sales_amt end) as plan_sales_amt
,sum(t1.plan_gross_profit) as plan_gross_profit
from (
-- BP规划量（能效机转换）
select 
coalesce(t2.model, t1.prdct_model) as prdct_model
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd t1 
left join (select distinct model, model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) t2 
on t1.prdct_model = t2.model_nengxiao 
where plan_type = 'BP'
and product_line = '激光'
group by coalesce(t2.model, t1.prdct_model) 
,product_line 
,dt_month 
) t1 
full join (
-- LX立项规划量
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt) as plan_sales_amt
,max(plan_gross_margin) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_line = '激光'
group by prdct_model 
,product_line 
,dt_month 
) t2
on t1.prdct_model = t2.prdct_model
and t1.dt_month = t2.dt_month
left join (
-- 上市次月为最小时间
select 
title as prdct_model
,min(DATE_FORMAT(date_add(his_actualtimetomarket, interval 1 month) , '%Y%m')) as min_dtmonth
from tv_model
group by title
) t3
on coalesce(t1.prdct_model, t2.prdct_model) = t3.prdct_model
where substring(coalesce(t1.dt_month, t2.dt_month),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and coalesce(t1.dt_month, t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and coalesce(t1.dt_month, t2.dt_month) >= coalesce(t3.min_dtmonth,'190001')
group by coalesce(t1.prdct_model, t2.prdct_model)
,coalesce(t1.product_line, t2.product_line)
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

-- 最终SELECT
select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'激光事业部' as business_division
,case when t5.his_pmdproductlinename like '%激光-商用产品线%' then '激光商用' else '激光家用' end as product_line
,'内销' as in_out_sale
,'2' as zhibiao_type 
,t1.title as prdct_model
,t1.his_actualtimetomarket as ir_act_time
,t1.his_actualdelistingtime as juece_delistingtime
,coalesce(t2.sale_qty, 0) as act_sales_qty
,coalesce(t3.plan_sales_qty, 0) as plan_sales_qty
,coalesce(coalesce(t2.sale_qty, 0) / nullif(t3.plan_sales_qty, 0), 0) as sales_qty_rate
,t2.rev_amt as act_sales_amt
,t3.plan_sales_amt as plan_sales_amt
,coalesce(t2.rev_amt, 0.0) / nullif(t3.plan_sales_amt, 0.0) as sales_amt_rate
,t2.maolie / nullif(t2.rev_amt, 0.0) as act_gross_margin
,case when coalesce(t2.sale_qty, 0) / nullif(t3.plan_sales_qty, 0) < 0.8 then 'Y' else 'N' end as is_dx
,case 
    when t1.his_actualtimetomarket >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
    when t1.title in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'
    when t1.shangshi_m <= 3 then 'Y'
    when coalesce(t1.brand,'0') = 'OEM品牌' then 'Y'
    when t1.his_productsmallcategories = '商用投影' then 'Y'
    when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
    else 'N' end as is_project
,case when coalesce(t1.his_actualdelistingtime,'') <> '' then '决策退市'
    when coalesce(t1.his_actualtimetomarket,'') = '' and coalesce(t1.his_actualdelistingtime,'') = '' then '未上市'
    when coalesce(t1.his_actualtimetomarket,'') <> '' and coalesce(t1.his_actualdelistingtime,'') = '' then '上市且未决策退市'
    else '其他' end as model_label_1
,now() as load_dt
,t1.brand
,t2.maolie as act_gross_profit
,t3.plan_gross_profit
,t2.maolie / nullif(t3.plan_gross_profit, 0.0) as gross_profit_rate
,case when coalesce(t1.brand,'0') = 'OEM品牌' then 'OEM'
    when coalesce(t1.brand,'0') = 'Hisense' then '海信'
    else t1.brand end as model_label_12
,t1.shangshi_m
,t1.his_productbigcategories as product_big
,t1.his_productmiddlecategories as product_mid
,t1.his_productsmallcategories as product_sml
,t1.his_plannedsaleschannel as distribution_channel
,t1.his_pmdproductpositioning as product_positioning
,t5.countries_regions
,t5.his_pmdproductlinename as productline_tv
,t1.his_focallength as focallength
from tv_model t1 
left join guanbao_sales t2 
on t1.title = t2.zzprdmodel
left join plan_sales t3 
on t1.title = t3.prdct_model
left join (
-- 生产版本下产品型号对应的【产品线】、【立项国家及区域】
select 
modelname
,group_concat(distinct his_pmdproductlinename) as his_pmdproductlinename
,group_concat(distinct countries_regions) as countries_regions
from dim.dim_ipd_jtplm_his_productversion_dd
where his_productsmallcategories in ('激光电视','家用投影','商用投影')
group by modelname
) t5
on t1.title = t5.modelname
left join fuchan_model t_fuchan on t1.title = t_fuchan.masterDataName
;



---------------------------------------------------------新品规划命中率 激光 内销 产品型号口径 zhibiao_type='4' ----------------------------------------------------

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') 
and zhibiao_type = '4'
and product_line in ('激光家用','激光商用')
and in_out_sale = '内销';

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
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
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_margin
,is_dx
,is_project
,model_label_1
,load_dt
,brand
,act_gross_profit
,model_label_12
,shangshi_m
,product_big
,product_mid
,product_sml
,distribution_channel
,product_positioning
,countries_regions
,productline_tv
,focallength
)

with tv_model as (
select 
title
,his_productbigcategories
,his_productmiddlecategories
,his_productsmallcategories
,his_productsbrand as brand
,his_oembrand
,his_domesticsalesorexport
,his_prdplatform
,his_salescountries
,his_plannedsaleschannel
,his_pmdproductpositioning
,his_actualtimetomarket
,his_actualdelistingtime
,his_focallength
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(his_actualtimetomarket)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(his_actualtimetomarket)) as shangshi_m
from (
select 
title
,his_productbigcategories
,his_productmiddlecategories
,his_productsmallcategories
,his_productsbrand
,his_oembrand
,his_pmdproductpositioning
,his_domesticsalesorexport
,his_prdplatform
,his_salescountries
,his_plannedsaleschannel
,his_focallength
,case when cast(his_actualtimetomarket as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualtimetomarket end as his_actualtimetomarket
,case when cast(his_actualdelistingtime as date) >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else his_actualdelistingtime end as his_actualdelistingtime
from dim.dim_ipd_jtplm_his_productmodel_dd
where his_pmdproductaffiliatedcompany = '激光显示'
and his_productsmallcategories in ('激光电视','家用投影','商用投影')
) t1
where t1.his_domesticsalesorexport = '内销'
and (coalesce(his_actualtimetomarket,'') <> '' and coalesce(his_actualdelistingtime,'') = '')
)
-- 管报实际销量（全量累计，从上市开始，能效机转换）
,guanbao_sales as ( 
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
where t1.yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by coalesce(t3.model, t2.model_name)
)
-- 规划销量（只取LX立项规划量，累计到当月）
,plan_sales as (
select 
t1.prdct_model
,t1.product_line
,sum(t1.plan_sales_qty) as plan_sales_qty
,sum(t1.plan_sales_amt) as plan_sales_amt
from (
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt) as plan_sales_amt
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_line = '激光'
group by prdct_model 
,product_line 
,dt_month 
) t1 
left join (
-- 上市次月为最小时间
select 
title as prdct_model
,min(DATE_FORMAT(date_add(his_actualtimetomarket, interval 1 month) , '%Y%m')) as min_dtmonth
from tv_model
group by title
) t2
on t1.prdct_model = t2.prdct_model
where t1.dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.dt_month >= coalesce(t2.min_dtmonth,'190001')
group by t1.prdct_model
,t1.product_line
)
,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

-- 最终SELECT
select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'激光事业部' as business_division
,case when t5.his_pmdproductlinename like '%激光-商用产品线%' then '激光商用' else '激光家用' end as product_line
,'内销' as in_out_sale
,'4' as zhibiao_type 
,t1.title as prdct_model
,t1.his_actualtimetomarket as ir_act_time
,t1.his_actualdelistingtime as juece_delistingtime
,coalesce(t2.sale_qty, 0) as act_sales_qty
,coalesce(t3.plan_sales_qty, 0) as plan_sales_qty
,coalesce(coalesce(t2.sale_qty, 0) / nullif(t3.plan_sales_qty, 0), 0) as sales_qty_rate
,t2.rev_amt as act_sales_amt
,t3.plan_sales_amt as plan_sales_amt
,coalesce(t2.rev_amt, 0.0) / nullif(t3.plan_sales_amt, 0.0) as sales_amt_rate
,t2.maolie / nullif(t2.rev_amt, 0.0) as act_gross_margin
,case when coalesce(t2.sale_qty, 0) / nullif(t3.plan_sales_qty, 0) < 0.8 then 'Y' else 'N' end as is_dx
,case 
    when t1.his_actualtimetomarket >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
    when t1.title in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'
    when t1.shangshi_m >= 13 then 'Y'
    when t1.shangshi_m <= 3 then 'Y'
    when coalesce(t1.brand,'0') = 'OEM品牌' then 'Y'
    when t1.his_productsmallcategories = '商用投影' then 'Y'
    when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
    else 'N' end as is_project
,case when coalesce(t1.his_actualdelistingtime,'') <> '' then '决策退市'
    when coalesce(t1.his_actualtimetomarket,'') = '' and coalesce(t1.his_actualdelistingtime,'') = '' then '未上市'
    when coalesce(t1.his_actualtimetomarket,'') <> '' and coalesce(t1.his_actualdelistingtime,'') = '' then '上市且未决策退市'
    else '其他' end as model_label_1
,now() as load_dt
,t1.brand
,t2.maolie as act_gross_profit
,case when coalesce(t1.brand,'0') = 'OEM品牌' then 'OEM'
    when coalesce(t1.brand,'0') = 'Hisense' then '海信'
    else t1.brand end as model_label_12
,t1.shangshi_m
,t1.his_productbigcategories as product_big
,t1.his_productmiddlecategories as product_mid
,t1.his_productsmallcategories as product_sml
,t1.his_plannedsaleschannel as distribution_channel
,t1.his_pmdproductpositioning as product_positioning
,t5.countries_regions
,t5.his_pmdproductlinename as productline_tv
,t1.his_focallength as focallength
from tv_model t1 
left join guanbao_sales t2 
on t1.title = t2.zzprdmodel
left join plan_sales t3 
on t1.title = t3.prdct_model
left join (
-- 生产版本下产品型号对应的【产品线】、【立项国家及区域】
select 
modelname
,group_concat(distinct his_pmdproductlinename) as his_pmdproductlinename
,group_concat(distinct countries_regions) as countries_regions
from dim.dim_ipd_jtplm_his_productversion_dd
where his_productsmallcategories in ('激光电视','家用投影','商用投影')
group by modelname
) t5
on t1.title = t5.modelname
left join fuchan_model t_fuchan on t1.title = t_fuchan.masterDataName
;

