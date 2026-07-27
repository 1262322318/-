/*
 * 脚本名称: dws_ipd_ipm_platform_detail_dd_jiguang_draft.sql
 * 功能描述: 产品平台数 - 激光产品线扩展（内外销合并，直接从在产型号表取）
 * 变更类型: CHG-02 产品线扩展
 * 创建时间: 2026-05-29
 * 参考对象: 正式脚本中视像科技出口平台数段落（第398~440行）
 * 逻辑调整: 
 *   - 内外销合并为一段（不再分开写）
 *   - 直接从在产型号明细表取数据，平台名用 platform 字段
 *   - 不再关联生产版本表
 * 依赖: 指标2（在产型号数-激光）必须先执行
 */

---------------------------------------------------------产品平台数 激光 内外销合并 ----------------------------------------------------

delete from dws.dws_ipd_ipm_platform_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '激光'
and dt_type = '月';

insert into dws.dws_ipd_ipm_platform_detail_dd(
dt_month 
,dt_type 
,company 
,product_line 
,in_out_sale 
,platform 
,model 
,prdct_model 
,model_label_10
,is_project 
,load_dt 
,is_productline_jy
,is_nwx_jy
)
select 
dt_month 
,'月' as dt_type 
,company 
,product_line 
,in_out_sale 
,platform
,model 
,productmodel as prdct_model
,brand as model_label_12
,is_project 
,now() as load_dt
,'N' as is_productline_jy
,'N' as is_nwx_jy
from dws.dws_ipd_ipm_zcmodel_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '激光'
and is_project = 'N'
and platform is not null
and platform <> '不涉及'
;
