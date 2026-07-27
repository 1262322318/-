-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
/*
 * 脚本名称: dws_ipd_ipm_platform_library_detail_dd_jiguang_draft.sql
 * 功能描述: 平台库 - 激光产品线扩展（不区分内外销）
 * 变更类型: CHG-02 产品线扩展
 * 创建时间: 2026-05-29
 * 参考对象: 正式脚本中视像科技段落（第220~284行）
 * MCP验证:
 *   - 数据源 ods.odsjtplm_his_productplatform 筛选产品小类
 *   - 平台库状态只取发布和禁选
 *   - 商用投影平台不计入统计（is_project='Y'）
 * 依赖: 无
 */

---------------------------------------------------------平台库 激光 不区分内外销 ----------------------------------------------------

delete from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '激光';

insert into dws.dws_ipd_ipm_platform_library_detail_dd (
dt_month
,company
,product_line
,platform
,platform_old
,platform_state
,platform_classify
,big_class_name
,mid_class_name
,sml_class_name
,is_exclusive_only
,platform_lixiang_time
,platform_qianyi_time
,act_firstmodel
,plan_sales_amt
,plan_sales_qty
,shiyongquyu
,is_project
,load_dt
,platform_fabu_time
,platform_jinxuan_time
,platform_tzsc_time
,platform_zuofei_time
)

select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,'激光' as company
,'激光' as product_line
,title as platform
,his_oldplatformname as platform_old
,case when lifecycle_status = 'Create' then '创建'
    when lifecycle_status = 'ProjectApproval' then '立项'
    when lifecycle_status = 'Exploit' then '开发'
    when lifecycle_status = 'publish' then '发布'
    when lifecycle_status = 'appraise' then '鉴定'
    when lifecycle_status = 'ProhibitedSelection' then '禁选'
    when lifecycle_status = 'StopProduction' then '停止生产'
    else lifecycle_status end as platform_state
,his_platformclassification as platform_classify
,his_productbigcategories as big_class_name
,his_productmiddlecategories as mid_class_name
,his_productsmallcategories as sml_class_name
,his_pmdwhetherornotoemspecial as is_exclusive_only
,cast(his_platformprojectapprovaltime as date) as platform_lixiang_time
,cast(his_platformmigrationtime as date) as platform_qianyi_time
,his_firstmodelname as act_firstmodel
,cast(his_targetsalesamount as DECIMALV3(20,4)) as plan_sales_amt
,cast(his_targetsalesvolume as DECIMALV3(20,4)) as plan_sales_qty
,his_platformusagearea as shiyongquyu
,case when coalesce(his_pmdwhetherornotoemspecial,'否') = '是' then 'Y'
    when his_productsmallcategories = '商用投影' then 'Y'
    when lifecycle_status in ('发布','禁选','publish','ProhibitedSelection') then 'N' 
    else 'Y' end as is_project
,now() as load_dt
,cast(publish as date) as platform_fabu_time
,cast(prohibitedselection as date) as platform_jinxuan_time
,cast(stopproduction as date) as platform_tzsc_time
,cast(cancellation as date) as platform_zuofei_time
from ods.odsjtplm_his_productplatform ohp 
where his_productsmallcategories in ('激光电视','家用投影','商用投影')
;
