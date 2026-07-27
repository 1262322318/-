-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
/*
 * 脚本名称: dws_ipd_ipm_dxmodel_detail_dd_jiguang_xinpin_draft.sql
 * 功能描述: 新品规划命中率 - 激光产品线扩展（只做内销，zhibiao_type='4'）
 * 变更类型: CHG-02 产品线扩展
 * 创建时间: 2026-05-29
 * 参考对象: 正式脚本中视像科技新品命中率段落（第2206~2410行）
 * MCP验证:
 *   - 目标表同低效型号（dws_ipd_ipm_dxmodel_detail_dd），需 ALTER TABLE 新增 focallength
 *   - BP/LX中间表中激光的product_line值为'激光'
 * 与低效型号的差异:
 *   - zhibiao_type='4'（非'2'）
 *   - 新品期12个月（shangshi_m >= 13 → is_project='Y'）
 *   - 实际销量取全量累计（不限本年，从上市开始累计）
 *   - 规划量只取LX（不走BP/LX选择逻辑）
 */

-- [需ALTER TABLE] 同低效型号草稿，目标表新增焦距字段（如已执行则跳过）
-- ALTER TABLE dws.dws_ipd_ipm_dxmodel_detail_dd ADD COLUMN focallength VARCHAR(300) COMMENT '焦距';

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
;
