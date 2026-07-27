-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
/*
 * 脚本名称: dws_ipd_ipm_dxhxl_detail_dd_jiguang_draft.sql
 * 功能描述: 单型号平均销量/销额 - 激光产品线扩展（内销管报 + 外销sellin）
 * 变更类型: CHG-02 产品线扩展
 * 创建时间: 2026-05-29
 * 参考对象: 正式脚本中视像科技内销段落（第104~200行）
 * MCP验证:
 *   - 目标表 dws_ipd_ipm_dxhxl_detail_dd 需确认是否有 focallength 字段
 *   - 内销销量：管报数据（能效机转换）
 *   - 外销销量：dws.dws_ipd_ipm_sales_detail_mid_dd（sellin全量）
 * 依赖: 指标1（在销型号数-激光）提供型号范围
 */

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


---------------------------------------------------------单型号销量 激光 外销 sellin ----------------------------------------------------

delete from dws.dws_ipd_ipm_dxhxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' and company = '激光' and in_out_sale = '外销' and sales_type = 'sellin';

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
)
with zx_model_wx as ( 
select 
*
from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '激光'
and in_out_sale = '外销'
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_day = date_sub(STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d'),interval 1 day)
and dt_type = '月'
)
,sale_amt_wx as (
-- 外销sellin销量
select 
model as zzprdmodel
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt
,sum(cost_amt) as chengben 
,sum(rev_amt) - sum(cost_amt) as maolie 
from dws.dws_ipd_ipm_sales_detail_mid_dd
where yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and product_line in ('激光家用','激光商用')
and in_out_sale = '外销'
group by model
)

select distinct
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'月' as dt_type 
,'激光事业部' as business_division
,'激光' as company
,t1.product_line
,'外销' as in_out_sale
,t1.model as prdct_model
,t2.sale_qty
,t2.rev_amt
,'sellin' as sales_type
,t1.platform as model_label_1
,t1.model_label_10
,coalesce(t1.is_project,'Y') as is_project
,now() as load_dt
,t2.chengben as act_cost
,t2.maolie as act_gross_profit
,case when t3.platform is not null then 'Y' else 'N' end as is_platformsalemodel
from zx_model_wx t1 
left join sale_amt_wx t2 
on t1.model = t2.zzprdmodel
left join (select distinct platform from dws.dws_ipd_ipm_platform_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y%m')
and company = '激光'
and in_out_sale in ('外销')
and is_project = 'N'
and platform not in ('','/')
and coalesce(is_productline_jy,'N') = 'N'
and coalesce(is_nwx_jy,'N') = 'N') t3 
on t1.platform = t3.platform
;
