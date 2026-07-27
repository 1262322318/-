-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2025/12/17 08:19:25 GMT+08:00
-- ******************************************************************** --

delete from ads.ads_ipd_ipm_platform_result_dd
where dt_month >= DATE_FORMAT('${GP_START_DT}', '%Y%m')
and in_out_sale <> '无型号引用'
and dimension_1 = '总体'
;
insert into ads.ads_ipd_ipm_platform_result_dd(
dt_month 
,business_division
,company 
,product_line 
,in_out_sale 
,date_type 
,dimension_1
,act_value 
,plan_value 
,completion_rate 
,data_sources 
,load_dt 
)
with weidu_1 as  (
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line 
,udp4 as in_out_sale 
from dim.dim_ipd_td_weidu_nd
where zhibiao = '平台数'
and case when udp2 = '空调公司' then udp3 = '全部' and udp4 = '全部' else 1=1 end

)
,weidu_dt_type as (
select '年' as dt_type union all select '月' as dt_type
)
,dt_month_weidu as (
select distinct year_mth as dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT('${GP_START_DT}', '%Y%m')
and cal_year = DATE_FORMAT('${GP_START_DT}', '%Y')
)

,weidu_all as (
select *  from weidu_1,weidu_dt_type,dt_month_weidu
)
,platform_all as (
--型号 内外销
select 
business_division
,company  
,product_line
,in_out_sale 
,dt_type
,count(distinct platform) as ct
,'型号' as laiyuan
from dws.dws_ipd_ipm_platform_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰冷','洗衣机','视像科技') 
and in_out_sale in ('内销','出口','外销')
and is_project = 'N'
and platform <> ''
and platform <> '/'
and platform <> '附件'
and coalesce(is_productline_jy,'N') = 'N'
and coalesce(is_nwx_jy,'N') = 'N'
group by company
,product_line
,in_out_sale
,dt_type
,business_division

union all 
--空调 全部 内销外销
select 
business_division
,company  
,'全部'as product_line
,in_out_sale 
,dt_type
,count(distinct platform) as ct
,'型号' as laiyuan
from dws.dws_ipd_ipm_platform_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰冷') 
and in_out_sale in ('内销','出口','外销')
and is_project = 'N'
and platform <> ''
and platform <> '/'
and platform <> '附件'
and coalesce(is_productline_jy,'N') = 'N'
and coalesce(is_nwx_jy,'N') = 'N'
group by company
,in_out_sale
,dt_type
,business_division


union all 

--平台库 全部

select 
business_division
,company 
,product_line 
,'全部' as in_out_sale
,dt_type 
,act_value 
,'平台库' as laiyuan
from ads.ads_ipd_ipm_platform_library_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','视像科技')
and coalesce (dimension_1,'总体') = '总体'

 union all 

--平台库 全部

select 
'集团汇总' as business_division
,'集团汇总' as company 
,'全部' as product_line 
,'全部' as in_out_sale
,dt_type 
,sum(act_value ) as act_value
,'平台库' as laiyuan
from ads.ads_ipd_ipm_platform_library_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','视像科技')
and coalesce (dimension_1,'总体') = '总体'
and case when company in ('冰箱公司','空调公司') then product_line = '全部' 
when company in ('视像科技') then product_line = '视像科技' 
when company in ('洗衣机') then product_line = '洗衣机'
else 1=2 end
group by dt_type
)
,platform_all_jiagong as ( 
select 
business_division
,case when company = '冰冷' then '冰箱公司'else company end as company
,product_line
,case when in_out_sale = '出口' then '外销' else in_out_sale end as  in_out_sale
,dt_type
,ct
,laiyuan
,DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
from platform_all
)
,plan_value as (
--平台数  单平台销量
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
,'月' as dt_type
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平台数计划值-月度')as DECIMALV3(20,4)) pingtaishujihuazhi
,cast(get_json_string(record_data,'$.本月发布计划')as DECIMALV3(20,4)) fabujihua
,cast(get_json_string(record_data,'$.本月停产计划')as DECIMALV3(20,4)) tingchanjihua
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
,'年' as dt_type
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平台数计划值-累计')as DECIMALV3(20,4)) pingtaishujihuazhi
,cast(get_json_string(record_data,'$.累计发布计划')as DECIMALV3(20,4)) fabujihua
,cast(get_json_string(record_data,'$.累计停产计划')as DECIMALV3(20,4)) tingchanjihua
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU


)

select
t1.dt_month as dt_month
,t1.business_division
,t1.company
,t1.product_line
,t1.in_out_sale
,t1.dt_type
,'总体' as dimension_1
,t2.ct
,t3.pingtaishujihuazhi
,2-t2.ct/nullif(t3.pingtaishujihuazhi,0.0)
,t2.laiyuan
,now()
from weidu_all t1 
left join platform_all_jiagong t2 
on t1.company = t2.company 
and t1.product_line = t2.product_line 
and t1.business_division = t2.business_division 
and t1.in_out_sale = t2.in_out_sale 
and t1.dt_type = t2.dt_type 
and t1.dt_month = t2.dt_month
left join plan_value t3 
on t1.business_division = t3.shiyebu 
and t1.product_line = t3.fenzu 
and t1.in_out_sale = t3.neiwaixiao 
and t1.dt_month = t3.dt_month
and t1.dt_type = t3.dt_type 
;



delete from ads.ads_ipd_ipm_platform_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','海信日立','视像科技')
and in_out_sale = '无型号引用'
and dimension_1 = '总体'
;
insert into ads.ads_ipd_ipm_platform_result_dd(
dt_month 
,business_division
,company 
,product_line 
,in_out_sale 
,dimension_1
,act_value
,data_sources
,date_type
,load_dt 
)
select
dt_month 
,business_division
,company 
,product_line 
,'无型号引用'as in_out_sale
,'总体' as dimension_1
,count(distinct platform)
,'平台库'
,'月'
,now()
from dws.dws_ipd_ipm_platform_library_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','海信日立','视像科技')
and is_project = 'N'
and platform_model is null --无型号引用
group by dt_month 
,company ,product_line 
,business_division
;








delete from ads.ads_ipd_ipm_platform_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '海信日立'
and dimension_1 = '平台类型'
;
insert into ads.ads_ipd_ipm_platform_result_dd(
dt_month 
,company 
,product_line 
,in_out_sale 
,dimension_1 
,dimension_2
,date_type 
,act_value 
,data_sources 
,load_dt 
)
with weidu_1 as  (
select 
udp1 as company
,udp2 as product_line
,udp3 as in_out_sale 
from dim.dim_ipd_td_weidu_nd
where zhibiao = '平台数'
and udp1 = '海信日立'
and udp3 = '全部'
)
,weidu_dt_type as (
select '年' as dt_type union all select '月' as dt_type
)
,dt_month_weidu as (
select distinct year_mth as dt_month  from dw.dim_date_nd
where year_mth = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and cal_year = DATE_FORMAT('${GP_START_DT}', '%Y')
)

,weidu_all as (
select *  from weidu_1,weidu_dt_type,dt_month_weidu
)
,platform_all as (
--平台库 全部

select 
company 
,product_line 
,'全部' as in_out_sale
,dt_type 
,act_value as ct
,'平台库' as laiyuan
,dimension_1 
,dimension_2
from ads.ads_ipd_ipm_platform_library_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('海信日立')
and coalesce (dimension_1,'总体') = '平台类型'
)
,platform_all_jiagong as ( 
select 
case when company = '冰冷' then '冰箱公司'
when company = '日立公司' then '海信日立'else company end as company
,case when company in ('日立公司','海信日立','视像科技') then '全部' else product_line end as product_line
,case when in_out_sale = '出口' then '外销' else in_out_sale end as  in_out_sale
,dt_type
,ct
,laiyuan
,DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,dimension_1 
,dimension_2
from platform_all
)
select
t1.dt_month as dt_month
,t1.company
,t1.product_line
,t1.in_out_sale
,t2.dimension_1 
,t2.dimension_2
,t1.dt_type
,t2.ct
,t2.laiyuan
,now()
from weidu_all t1 
left join platform_all_jiagong t2 
on t1.company = t2.company 
and t1.product_line = t2.product_line 
and t1.in_out_sale = t2.in_out_sale 
and t1.dt_type = t2.dt_type 
and t1.dt_month = t2.dt_month
;


