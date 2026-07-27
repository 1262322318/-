-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
/*
 * 脚本名称: dws_ipd_ipm_sale_model_detail_dd_jiguang_draft.sql
 * 功能描述: 在销型号数 - 激光产品线扩展（激光家用/激光商用）
 * 变更类型: CHG-02 产品线扩展
 * 创建时间: 2026-05-29
 * 参考对象: 正式脚本中视像科技段落（第1130~1500行）
 * MCP验证: 
 *   - dim_ipd_jtplm_his_productmodel_dd 确认有 his_focallength, his_plannedsaleschannel
 *   - dim_ipd_jtplm_his_productversion_dd 确认有 modelname, his_pmdproductlinename
 *   - 目标表需 ALTER TABLE 新增 focallength VARCHAR(300) 字段
 *   - 产品线判定：GROUP_CONCAT生产版本产品线后LIKE '%商用%'判定
 */

-- [需ALTER TABLE] 目标表新增焦距字段
-- ALTER TABLE dws.dws_ipd_ipm_sale_model_detail_dd ADD COLUMN focallength VARCHAR(300) COMMENT '焦距';

---------------------------------------------------------在销型号数 激光 内外销 产品型号口径 ----------------------------------------------------

delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光'
and product_line in ('激光家用','激光商用') and dt_type = '月'
and dt_day < CAST('${GP_START_DT}' AS DATE) 
and model_label_10 <> '老品清零'
;
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光'
and product_line in ('激光家用','激光商用') and dt_type = '月'
and dt_day >= CAST('${GP_START_DT}' AS DATE)
;
insert into dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division
,company
,product_line
,in_out_sale
,model
,productmodel
,IR_act_time
,delisted_time
,inventory_qty
,product_big
,product_mid
,product_sml
,brand
,chanpindingwei
,platform
,sale_country
,plan_channel
,act_time_ss
,act_time_tszb
,act_time_tzsc
,productmodel__life
,model_label_16
,model_label_10
,model_label_12
,is_project
,kcql_time
,shangshi_m
,tuishijuece_m
,tingchan_m
,kcqw_m
,dt_day
,load_dt
,focallength
)
with kucun_qingwei as (
-- 激光库存清尾时间
select 
product_line 
,in_out_sale
,coalesce(model, prdct_model) as model
,min(dt_day) as min_kucunqingwei 
from dws.dws_ipd_ipm_sale_model_detail_dd
where product_line in ('激光家用','激光商用')
and company = '激光'
and dt_type = '月'
and (model_label_10 = '老品清零' or (delisted_time is not null and coalesce(inventory_qty,0) = 0))
group by product_line
,coalesce(model, prdct_model), in_out_sale
)
-- 产品线判定：通过生产版本按产品型号聚合产品线（逗号分隔）
,jiguang_productline as (
select 
modelname
,group_concat(distinct his_pmdproductlinename) as his_pmdproductlinename
from dim.dim_ipd_jtplm_his_productversion_dd
where his_productsmallcategories in ('激光电视','家用投影','商用投影')
group by modelname
)
-- 激光型号基础信息
,jiguang_model as (
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
,his_actualtimetomarket
,his_actualdelistingtime
,his_stopproductiontime
,his_focallength
,'Y' as is_zhibiaofanwei
,lifecycle_status
,case when lifecycle_status in ('上市','退市准备') then '在产'
    when lifecycle_status in ('停止服务','停止生产','停止下单') then '退市'
    else '未上市' end as jieduan
from dim.dim_ipd_jtplm_his_productmodel_dd
where his_pmdproductaffiliatedcompany = '激光显示'
and his_productsmallcategories in ('激光电视','家用投影','商用投影')
)
-- 内销库存（同视像逻辑）
,kc_nx as (
select 
coalesce(t2.model, t1.model) as model
,sum(t1.stock_namber) as sm
from test.dwfi_tf_fa_tvp_flfzlmx t1
left join (select distinct model, model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) t2
on t1.model = t2.model_nengxiao
where t1.batch = 'H'
and t1.daymonth_flag = 0
and t1.load_dt = DATE_ADD(cast('${GP_START_DT}' as date), INTERVAL 1 DAY)
AND t1.matkl IN ('1100101','1100112','1100122','1100601')
AND t1.fl in ('ZMM012','ZSD041')
AND substring(t1.model,1,2) != 'TH' 
AND substring(t1.model,length(t1.model)-3) != 'M11P'
AND coalesce(t1.leibie,'0') <> '借机'
group by coalesce(t2.model, t1.model)
)
-- 外销库存（3个源表，无TVS库存）
,kc_wx as (
-- 海外分公司库存（成品库存）
select 
matnr 
,werks 
,charg
,zcusmodel
,zmodel
,zfacmodel
,vtext 
,clabs as kc_sum
,landx
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
where lfgja = DATE_FORMAT('${GP_START_DT}', '%Y') 
and lfmon = DATE_FORMAT('${GP_START_DT}', '%m')
and vtext in ('多媒体-激光影院','多媒体-激光投影')
and case when cast('${GP_START_DT}' as date) <= cast('2024-02-29' as date) then 1=1 else udate = cast('${GP_START_DT}' as date) end
and lgort is not null
and zkwlb = 'A'
and substring(werks,1,2) <> '80'
and quzu_rd in ('国际营销','东盟区')

union all 
-- 基地库存（海外在途）
select 
matnr 
,werks 
,charg 
,null
,null
,null
,gtext 
,menge 
,zywqy
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
where gjahr = DATE_FORMAT('${GP_START_DT}', '%Y')
and monat = DATE_FORMAT('${GP_START_DT}', '%m')
and pdate = cast('${GP_START_DT}' as date) 
and gtext in ('多媒体.激光投影','多媒体.激光电视')
and quzu_rd in ('国际营销','东盟区','东南亚')

union all 
-- 在途库存（海外在库）
select 
matnr 
,bukrs 
,bwtar 
,zcusmodel 
,null as zmodel
,zfacmodel 
,vtext 
,menge as menge
,null 
,related_rd 
,zmodel_rd 
,quzu_rd 
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
where SPART_rd in ('17','24')
and budat = cast('${GP_START_DT}' as date)  
and bukrs not in ('8300','8320','8330','8370','8380','8390','83B0')
and menge >= 1

-- 注意：激光不取TVS库存
)

-- 库存汇总
,kc_all as ( 
-- 外销库存数量
select 
prouductmodel_rd as productmodel
,'外销' as in_out_sale
,sum(kc_sum) as kc_sum
from kc_wx
group by prouductmodel_rd

union all 
-- 内销库存数量
select 
model
,'内销' as in_out_sale
,sum(sm) as kc_sum
from kc_nx t1
group by model
)

-- 库存清零判定
,zx_model as (
select 
t1.title
,t1.his_productbigcategories
,t1.his_productmiddlecategories
,t1.his_productsmallcategories
,t1.his_productsbrand
,t1.his_oembrand
,t1.his_pmdproductpositioning
,t1.his_domesticsalesorexport
,t1.his_prdplatform
,t1.his_salescountries
,t1.his_plannedsaleschannel
,t1.his_actualtimetomarket
,t1.his_actualdelistingtime
,t1.his_stopproductiontime
,t1.his_focallength
,t1.is_zhibiaofanwei
,t1.lifecycle_status
,case when t1.jieduan = '退市' and coalesce(t2.kc_sum, 0.0) = 0 then '老品清零'
    when t1.jieduan = '退市' and coalesce(t2.kc_sum, 0.0) <> 0 then '老品'
    else t1.jieduan end as jieduan
,t2.kc_sum
from jiguang_model t1 
left join kc_all t2 
on t1.title = t2.productmodel
and t1.his_domesticsalesorexport = t2.in_out_sale
)

-- 最终SELECT
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,'月' as dt_type
,'激光事业部' as business_division
,'激光' as company
,case when t5.his_pmdproductlinename like '%激光-商用产品线%' then '激光商用' else '激光家用' end as product_line
,t1.his_domesticsalesorexport as in_out_sale
,t1.title as model
,t1.title as productmodel
,t1.his_actualtimetomarket as IR_act_time
,t1.his_actualdelistingtime as delisted_time
,t1.kc_sum as inventory_qty
,t1.his_productbigcategories as product_big
,t1.his_productmiddlecategories as product_mid
,t1.his_productsmallcategories as product_sml
,t1.his_productsbrand as brand
,t1.his_pmdproductpositioning as chanpindingwei
,t1.his_prdplatform as platform
,t1.his_salescountries as sale_country
,t1.his_plannedsaleschannel as plan_channel
,t1.his_actualtimetomarket as act_time_ss
,t1.his_actualdelistingtime as act_time_tszb
,t1.his_stopproductiontime as act_time_tzsc
,t1.lifecycle_status as productmodel__life
,t1.is_zhibiaofanwei as model_label_16
,t1.jieduan as model_label_10
,case when coalesce(t1.his_productsbrand,'0') = 'OEM品牌' then 'OEM'
    when coalesce(t1.his_productsbrand,'0') = 'Hisense' then '海信'
    else t1.his_productsbrand end as model_label_12
,case when t1.is_zhibiaofanwei = 'N' then 'Y'
    when t1.jieduan in ('未上市','老品清零','其他') then 'Y'
    when t1.jieduan in ('老品') and t2.productmodel is not null then 'Y'
    when t3.model_nengxiao is not null then 'Y'
    when t1.his_productsmallcategories = '商用投影' then 'Y'
    when coalesce(t1.his_productsbrand,'0') = 'OEM品牌' then 'Y'
    else 'N' end as is_project
,case when t1.jieduan = '老品清零' then coalesce(t4.min_kucunqingwei, cast('${GP_START_DT}' as date)) else t4.min_kucunqingwei end as kcql_time
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_actualtimetomarket, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月上市' else null end as shangshi_m
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_actualdelistingtime, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月退市决策' else null end as tuishijuece_m
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_stopproductiontime, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停产' else null end as tingchan_m
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(
    case when t1.jieduan = '老品清零' then coalesce(t4.min_kucunqingwei, cast('${GP_START_DT}' as date)) else t4.min_kucunqingwei end
    , '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停止销售' else null end as kcqw_m
,cast('${GP_START_DT}' as date) as dt_day
,now() as load_dt
,t1.his_focallength as focallength
from zx_model t1 
left join (
-- 历史已清零型号
select distinct coalesce(productmodel, model) as productmodel from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '激光'
and model_label_10 = '老品清零'
and company not like '%商家库存%'
and dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
) t2
on t1.title = t2.productmodel
left join (select distinct model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) t3
on t1.title = t3.model_nengxiao
left join kucun_qingwei t4 
on t1.title = t4.model
and t1.his_domesticsalesorexport = t4.in_out_sale
left join jiguang_productline t5
on t1.title = t5.modelname
;
