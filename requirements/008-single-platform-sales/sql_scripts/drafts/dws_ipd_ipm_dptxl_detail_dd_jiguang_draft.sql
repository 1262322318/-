-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
/*
 * 脚本名称: dws_ipd_ipm_dptxl_detail_dd_jiguang_draft.sql
 * 功能描述: 单平台平均销量 - 激光产品线扩展（内销管报 + 外销sellin）
 * 变更类型: CHG-02 产品线扩展
 * 创建时间: 2026-05-29
 * 参考对象: 正式脚本中视像科技内销段落（第74~130行）+ 外销段落（第258~350行）
 * 逻辑说明:
 *   - 从单型号销量明细表取数据
 *   - 平台名用 model_label_1 字段
 *   - is_project额外判定：在产 + 平台不为'不涉及'
 * 依赖: 指标6（单型号销量-激光）必须先执行
 */

---------------------------------------------------------单平台销量 激光 内销 管报 ----------------------------------------------------

delete from dws.dws_ipd_ipm_dptxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company = '激光'
and in_out_sale = '内销';

insert into dws.dws_ipd_ipm_dptxl_detail_dd(
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,prdct_model
,matnr 
,sales_qty
,sales_amt
,is_project
,load_dt 
)
with dptxl_nx as (
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,matnr 
,model 
,prdct_model 
,sales_qty
,sales_amt
,model_label_1
,model_label_10
-- 在产型号数逻辑 + 平台数逻辑
,case when model_label_10 <> '在产' then 'Y'
    when coalesce(model_label_1,'其他') = '不涉及' then 'Y'
    else is_project end as is_project
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company = '激光'
and in_out_sale = '内销'
and sales_type = '管报'
)
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,model_label_1 as platform
,model
,matnr
,sales_qty
,sales_amt
,is_project
,now()
from dptxl_nx
where is_project = 'N'
;


---------------------------------------------------------单平台销量 激光 外销 sellin ----------------------------------------------------

delete from dws.dws_ipd_ipm_dptxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company = '激光'
and in_out_sale = '外销';

insert into dws.dws_ipd_ipm_dptxl_detail_dd(
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,prdct_model
,matnr 
,sales_qty
,sales_amt
,is_project
,load_dt 
)
with dptxl_wx as (
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,matnr 
,model 
,prdct_model 
,sales_qty
,sales_amt
,model_label_1
,model_label_10
-- 在产型号数逻辑 + 平台数逻辑
,case when model_label_10 <> '在产' then 'Y'
    when coalesce(model_label_1,'其他') = '不涉及' then 'Y'
    else is_project end as is_project
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company = '激光'
and in_out_sale = '外销'
and sales_type = 'sellin'
)
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,model_label_1 as platform
,model
,matnr
,sales_qty
,sales_amt
,is_project
,now()
from dptxl_wx
where is_project = 'N'
;
