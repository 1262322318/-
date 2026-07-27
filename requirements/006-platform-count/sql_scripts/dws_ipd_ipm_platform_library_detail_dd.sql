-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2025/12/11 10:51:28 GMT+08:00
-- ******************************************************************** --
delete from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机')
;

insert into dws.dws_ipd_ipm_platform_library_detail_dd (
dt_month    --月份
,business_division  --事业部
,company    --公司
,product_line    --产品线
,platform    --平台名称
,platform_old    --旧平台名称
,platform_state    --平台生命周期状态
,platform_classify    --平台分类
,big_class_name    --产品大类
,mid_class_name    --产品中类
,sml_class_name    --产品小类
,is_exclusive_only    --是否外部代工专用
,shiyongquyu    --平台使用区域
,act_firstmodel    --实际鉴定首机型
,plan_firstmodel    --规划首机型
,plan_product_line    --规划产品线
,is_eurp_product    --是否欧产
,is_outsourcing    --是否外购平台
,plan_sales_qty    --目标销量（万元）
,platform_lixiang_time    --平台立项时间
,platform_qianyi_time    --平台迁移时间
,platform_fabu_time    --平台发布时间
,platform_jinxuan_time    --平台禁选时间
,platform_tzsc_time    --平台停止生产时间
,platform_zuofei_time    --平台作废时间
,is_project    --是否保护期
,load_dt    --加载日期
)
with platform_mingxi as (
select 
PG00002--产品大类
,PG00003--产品中类
,PG00004--产品小类
,PG00061--物料描述(中文)
,PG00015--产品公司
,HX00223--产品线
,case when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and HX00223 = '冰箱' then '冰箱'
when PG00015 = '冰箱公司' and HX00223 = '冰箱' and coalesce (PG00003,'其他') <> '家用冰箱' then '其他'  --去除酒柜等非冰箱但是在冰箱产品线下的
when PG00015 = '冰箱公司' then HX00223
else coalesce (HX00223 ,'其他') end as product_line 
,PC10067--实际首机型
,PC10035--规划首机型
,PG00056--平台生命周期状态
,PG00046--平台使用区域
,HX00273--旧平台名称
,PG00044--平台分类
,PG00047--是否外部代工专用
,HX00272--目标销量(万台)
,PG00049--平台立项时间
,PG00050--平台迁移时间
,HX00274--平台发布时间
,PC20035--平台禁选时间
,HX00421--平台停止生产时间
,PG00051--平台退市时间
,PC10050--门类
,HX00267--是否欧产平台
,hx00268  --是否外购平台
from dim.dim_ipd_productplatform_dd
where pg00015 in ('冰箱公司','洗衣机公司')
)
select
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,case when PG00015 = '冰箱公司' then '冰冷事业部' when PG00015 = '洗衣机公司' then '洗护事业部' else PG00015 end as business_division  --事业部
,case when PG00015 = '冰箱公司' then '冰箱公司' when PG00015 = '洗衣机公司' then '洗衣机' else PG00015 end as company
,product_line  --产品线
,PG00061--物料描述(中文)
,HX00273--旧平台名称
,PG00056--平台生命周期状态
,PG00044--平台分类
,PG00002--产品大类
,PG00003--产品中类
,PG00004--产品小类
,PG00047--是否外部代工专用
,PG00046--平台使用区域
,PC10067--实际首机型
,PC10035--规划首机型
,HX00223--产品线
,HX00267--是否欧产平台
,hx00268  --是否外购平台
,HX00272--目标销量(万台)
,PG00049--平台立项时间
,PG00050--平台迁移时间
,HX00274--平台发布时间
,PC20035--平台禁选时间
,HX00421--平台停止生产时间
,PG00051--平台退市时间
,case when product_line = '冰箱' and HX00267 = '是' then 'Y'
	  when PG00047 = '是' then 'Y' 
	  when hx00268 = '是' then 'Y' 
	  when PG00056 in ('发布','禁选') then 'N' else 'Y' end as is_project
,now()
from platform_mingxi
;

delete from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '视像科技';

insert into dws.dws_ipd_ipm_platform_library_detail_dd (
dt_month	--月份
,business_division  --事业部
,company	--公司
,product_line	--产品线
,platform	--平台名称
,platform_old	--旧平台名称
,platform_state	--平台生命周期状态
,platform_classify	--平台分类
,big_class_name	--产品大类
,mid_class_name	--产品中类
,sml_class_name	--产品小类
,is_exclusive_only	--是否外部代工专用
,platform_lixiang_time	--平台立项时间
,platform_qianyi_time	--平台迁移时间
,act_firstmodel	--实际鉴定首机型
,plan_sales_amt	--目标销额（万元）
,plan_sales_qty	--目标销量（万元）
,shiyongquyu	--平台使用区域
,is_project	--是否保护期
,load_dt	--加载日期
,platform_fabu_time   --平台发布时间
,platform_jinxuan_time   --平台禁选时间
,platform_tzsc_time   --平台停止生产时间
,platform_zuofei_time  --平台作废时间
)
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,'显示事业部' as business_division  --事业部
,'视像科技' as company
,'视像科技' as product_line
,title	--产品平台产品描述（中文）
,his_oldplatformname	--旧平台名称
,case when lifecycle_status = 'Create' then '创建'
when lifecycle_status = 'ProjectApproval' then '立项'
when lifecycle_status = 'Exploit' then '开发'
when lifecycle_status = 'publish' then '发布'
when lifecycle_status = 'appraise' then '鉴定'
when lifecycle_status = 'ProhibitedSelection' then '禁选'
when lifecycle_status = 'StopProduction' then '停止生产'
else lifecycle_status end  --新品平台生命周期状态名称
,his_platformclassification	--平台分类
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,case when his_pmdwhetherornotoemspecial = 'PG00047001' then '是'
when his_pmdwhetherornotoemspecial = 'PG00047002' then '否'
else his_pmdwhetherornotoemspecial end --是否外部代工专用
,cast(his_platformprojectapprovaltime as date)	--平台立项时间
,cast(his_platformmigrationtime as date)	--平台迁移时间
,his_firstmodelname	--首机型型号名称
,cast(his_targetsalesamount as DECIMALV3(20,4)) 	--目标销额
,cast(his_targetsalesvolume as DECIMALV3(20,4))  	--目标销量
,case when his_platformusagearea = 'PG00046001' then '内外销共用'
when his_platformusagearea = 'PG00046002' then '内销专用'
when his_platformusagearea = 'PG00046003' then '外销专用'
else his_platformusagearea end --平台使用区域
,case when coalesce(his_pmdwhetherornotoemspecial,'否') in ('是','PG00047001') then 'Y'  --去除代工产品
when lifecycle_status in ('发布','禁选','publish','ProhibitedSelection') then 'N' else 'Y' end as is_project
,now()
,cast(publish as date)		--发布时间
,cast(prohibitedselection as date)		--禁选时间
,cast(stopproduction as date)		--停止生产时间
,cast(cancellation as date)		--作废时间
from ods.odsjtplm_his_productplatform ohp 
where his_productsmallcategories = '平板电视'
;

---------------------------------------------------------平台库 激光 不区分内外销 ----------------------------------------------------
delete from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '激光';

insert into dws.dws_ipd_ipm_platform_library_detail_dd (
dt_month
,business_division
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
,'激光事业部' as business_division  --事业部
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

delete from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('空调公司')
;

insert into dws.dws_ipd_ipm_platform_library_detail_dd (
dt_month    --月份
,business_division  --事业部
,company    --公司
-- ,product_line    --产品线
,platform    --平台名称
,platform_old    --旧平台名称
,platform_state    --平台生命周期状态
,platform_classify    --平台分类
,big_class_name    --产品大类
,mid_class_name    --产品中类
,sml_class_name    --产品小类
,is_exclusive_only    --是否外部代工专用
,shiyongquyu    --平台使用区域
,act_firstmodel    --实际鉴定首机型
,plan_firstmodel    --规划首机型
,plan_product_line    --规划产品线
,is_outsourcing    --是否外购平台
,plan_sales_qty    --目标销量（万元）
,platform_lixiang_time    --平台立项时间
,platform_qianyi_time    --平台迁移时间
,platform_fabu_time    --平台发布时间
,platform_jinxuan_time    --平台禁选时间
,platform_tzsc_time    --平台停止生产时间
,platform_zuofei_time    --平台作废时间
,is_project    --是否保护期
,load_dt    --加载日期
,PG00015
)
with platform_mingxi as (
select 
PG00002--产品大类
,PG00003--产品中类
,PG00004--产品小类
,PG00061--物料描述(中文)
,PG00015--产品公司
,HX00223--产品线
,PC10067--实际首机型
,PC10035--规划首机型
,PG00056--平台生命周期状态
,PG00046--平台使用区域
,HX00273--旧平台名称
,PG00044--平台分类
,PG00047--是否外部代工专用
,HX00272--目标销量(万台)
,PG00049--平台立项时间
,PG00050--平台迁移时间
,HX00274--平台发布时间
,PC20035--平台禁选时间
,HX00421--平台停止生产时间
,PG00051--平台退市时间
,hx00268  --是否外购平台
from dim.dim_ipd_productplatform_dd
where PG00002 = '空气调节类产品'
)
select
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,'空气事业部' as business_division  --事业部
,'空调公司' as company
-- ,product_line  --产品线
,PG00061--物料描述(中文)
,HX00273--旧平台名称
,PG00056--平台生命周期状态
,PG00044--平台分类
,PG00002--产品大类
,PG00003--产品中类
,PG00004--产品小类
,PG00047--是否外部代工专用
,PG00046--平台使用区域
,PC10067--实际首机型
,PC10035--规划首机型
,HX00223--产品线
,hx00268  --是否外购平台
,HX00272--目标销量(万台)
,PG00049--平台立项时间
,PG00050--平台迁移时间
,HX00274--平台发布时间
,PC20035--平台禁选时间
,HX00421--平台停止生产时间
,PG00051--平台退市时间
,case when PG00047 = '是' then 'Y' 
	  when PG00056 in ('发布','禁选') then 'N' else 'Y' end as is_project
,now()
,PG00015
from platform_mingxi
where PG00015 in ('空调','日立')
and HX00223 in ('家用空调','商用空调','中央空调氟机')
;

--平台数月度迁移退市
delete from dws.dws_ipd_ipm_add_reduce_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰冷','洗衣机','空调公司','视像科技','冰箱公司','激光')
and type in ('迁移','退市')
;

insert into dws.dws_ipd_ipm_add_reduce_detail_dd(
dt_month 
,zhibiao_name 
,`type`
,business_division --事业部
,company 
,product_line 
,platform 
,load_dt 
)
--本月迁移平台数
select 
t1.dt_month
,'平台数' as zhibiao_name
,'迁移' as tp
,business_division --事业部
,case when t1.company = '海信日立' then '日立公司' else t1.company end  as company
,case when t1.product_line = '海信日立' then '日立公司' else t1.product_line end as product_line
,t1.platform 
,now()
from dws.dws_ipd_ipm_platform_library_detail_dd t1 
left join (select distinct product_line ,platform 
from dws.dws_ipd_ipm_platform_library_detail_dd t1 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','海信日立','视像科技','激光')
and is_project = 'N')t2 
on t1.platform = t2.platform
where t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and t1.company in ('冰箱公司','洗衣机','空调公司','视像科技','激光')
and t1.is_project = 'N'
and t2.platform is null 
union all
--本月退市平台数
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,'平台数' as zhibiao_name
,'退市' as tp
,business_division --事业部
,case when t1.company = '海信日立' then '日立公司' else t1.company end   as company
,case when t1.product_line = '海信日立' then '日立公司' else t1.product_line end as product_line
,t1.platform 
,now()
from dws.dws_ipd_ipm_platform_library_detail_dd t1 
left join (select distinct product_line ,platform 
from dws.dws_ipd_ipm_platform_library_detail_dd t1 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','海信日立','视像科技','激光')
and is_project = 'N')t2 
on t1.platform = t2.platform
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.company in ('冰箱公司','洗衣机','空调公司','视像科技','激光')
and t1.is_project = 'N'
and t2.platform is null 
;

--平台数迁移退市结果值
delete from ads.ads_ipd_ipm_add_reduce_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and zhibiao_name = '平台数';

insert into ads.ads_ipd_ipm_add_reduce_result_dd(
dt_month
,zhibiao_name
,type
,business_division
,company 
,product_line 
,in_out_sale 
,act_value 
,plan_value 
,completion_rate 
,load_dt 
)
with jihuazhi as (
select 
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
when get_json_string(record_data,'$.事业部[0].text') = '显示事业部' and get_json_string(record_data,'$.分组[0].text') = '平板电视' then '视像科技'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,'迁移' as type_weidu
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平台数计划值-月度')as DECIMALV3(20,4)) pingtaishujihuazhi
,cast(get_json_string(record_data,'$.本月发布计划')as DECIMALV3(20,4)) jihua
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU
union all
select 
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
when get_json_string(record_data,'$.事业部[0].text') = '显示事业部' and get_json_string(record_data,'$.分组[0].text') = '平板电视' then '视像科技'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,'退市' as type_weidu
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平台数计划值-月度')as DECIMALV3(20,4)) pingtaishujihuazhi
,cast(get_json_string(record_data,'$.本月停产计划')as DECIMALV3(20,4)) jihua
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU
)
, type_weidu as (
select '迁移' as type_weidu union all select '退市' as type_weidu
)
,product_line_weidu as (
select '冰冷事业部' as business_division,'冰冷' as company,'冰箱' as product_line,'全部' as in_out_sale union all 
select '冰冷事业部' as business_division,'冰冷' as company,'冷柜' as product_line,'全部' as in_out_sale union all 
select '冰冷事业部' as business_division,'冰冷' as company,'全部' as product_line,'全部' as in_out_sale union all 
select '洗护事业部' as business_division,'洗衣机' as company,'洗衣机' as product_line,'全部' as in_out_sale union all 
select '显示事业部' as business_division,'视像科技' as company,'视像科技' as product_line,'全部' as in_out_sale union all 
select '激光事业部' as business_division,'激光' as company,'激光' as product_line,'全部' as in_out_sale union all 
select '空气事业部' as business_division,'空调公司' as company,'全部' as product_line,'全部' as in_out_sale 
)
,act_value as ( 
select 
type as tp
,business_division
,case when company = '冰箱公司' then '冰冷' else company end as  company
,case when company = '空调公司' then '全部' else product_line end as product_line
,zhibiao_name
,count(distinct platform)as ct
from dws.dws_ipd_ipm_add_reduce_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and zhibiao_name = '平台数'
group by type ,business_division
,case when company = '冰箱公司' then '冰冷' else company end
,case when company = '空调公司' then '全部' else product_line end  ,zhibiao_name
union all 
select 
type as tp
,business_division
,case when company = '冰箱公司' then '冰冷' else company end as  company
,'全部' as product_line
,zhibiao_name
,count(distinct platform)as ct
from dws.dws_ipd_ipm_add_reduce_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and zhibiao_name = '平台数'
and product_line in ('冰箱','冷柜')
group by type ,business_division
,case when company = '冰箱公司' then '冰冷' else company end
,zhibiao_name
)
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,'平台数' as zhibiao_name
,t2.type_weidu
,t1.business_division
,t1.company
,t1.product_line
,t1.in_out_sale
,coalesce (t3.ct,0)
,coalesce (t4.jihua,0)   --计划值
,coalesce (t3.ct,0)/nullif(coalesce (t4.jihua,0),0)  完成率
,now()
from product_line_weidu t1
full join type_weidu t2 on 1=1
left join act_value t3 
on t1.company = t3.company
and t1.product_line = t3.product_line
and t1.business_division = t3.business_division
and t2.type_weidu = t3.tp
left join jihuazhi t4 
on t1.business_division = t4.shiyebu
and t2.type_weidu = t4.type_weidu 
and t1.product_line = t4.fenzu 
and t1.in_out_sale = t4.neiwaixiao 
and t4.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
;