-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/01/19 11:19:09 GMT+08:00
-- ******************************************************************** --
delete from ads.ads_ipd_ipm_zcmodel_result_dd
where company in ('冰冷','洗衣机','空调公司','视像科技','厨电','集团汇总','激光')
and dt_month >= DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and data_type = '在产型号-产品型号口径'
;

insert into ads.ads_ipd_ipm_zcmodel_result_dd(
dt_month	--月份
,dt_type	--日期类型
,data_type	--数据类型
,business_division   --事业部
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,act_num	--实际值
,plan_num  --计划值
,completion_rate   --完成率
,load_dt	--加载时间
)
with weidu_shiyebu as (
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line
,udp4 as in_out_sale
from dim.dim_ipd_td_weidu_nd  
where zhibiao = '在产型号数'
-- and udp1 not in ('集团汇总')
)
,dt_month_weidu as (
select distinct year_mth as dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT('${GP_START_DT}' , '%Y%m')
and cal_year = DATE_FORMAT('${GP_START_DT}' , '%Y')
)
,all_weidu as ( 
select 
t1.business_division
,t1.company
,t1.product_line
,t1.in_out_sale
,t2.dt_month
,'月' as dt_type
from weidu_shiyebu t1 ,dt_month_weidu t2 
)
,weidu_neiwaixiao as (
select '全部' as in_out_sale union all select '内外销' as in_out_sale 
)
,weidu_product_line as (
select '全部' as product_line union all select '非全部' as product_line 
)
,plan_values as (
--在销 在产 单型号销量 单型号销额
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
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.在销型号计划值')as DECIMALV3(20,4)) plan_zxmodel
,cast(get_json_string(record_data,'$.在产型号计划值')as DECIMALV3(20,4)) plan_zcmodel
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblT8dRgmsgrWu9c
)
,act_value as (
select 
t1.dt_month
,'月'as dt_type
,'在产型号-产品型号口径' as data_type
,t1.business_division   --事业部
,t1.company
,case when t3.product_line = '全部' then '全部' else t1.product_line end as product_line
,case when t2.in_out_sale = '全部' then '全部' else t1.in_out_sale end as in_out_sale
,count(distinct t1.model) as act_value
,now()
from dws.dws_ipd_ipm_zcmodel_detail_dd t1 
left join weidu_neiwaixiao t2 on 1=1
left join weidu_product_line t3 on t1.company in  ('冰冷','空调公司','厨电','激光')
where t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and t1.company in ('冰冷','洗衣机','空调公司','视像科技','厨电','激光')
and t1.is_project = 'N'
group by t1.dt_month, t1.company,case when t3.product_line = '全部' then '全部' else t1.product_line end
,case when t2.in_out_sale = '全部' then '全部' else t1.in_out_sale end,t1.business_division
)
select 
t0.dt_month
,t0.dt_type
,'在产型号-产品型号口径' as data_type
,t0.business_division
,t0.company
,t0.product_line
,t0.in_out_sale
,t1.act_value
,t2.plan_zcmodel
,2-(nullif(coalesce (t1.act_value,0.0),0.0)/nullif(coalesce (t2.plan_zcmodel,0.0),0.0))  完成率
,now()
from all_weidu t0
left join act_value t1
on t0.business_division = t1.business_division
and t0.company = t1.company
and t0.product_line = t1.product_line
and t0.in_out_sale = t1.in_out_sale
and t0.dt_month = t1.dt_month
and t0.dt_type = t1.dt_type
left join plan_values t2 
on t0.business_division = t2.shiyebu
and t0.product_line = t2.fenzu 
and t0.in_out_sale = t2.neiwaixiao
and t0.dt_month = t2.dt_month
and t0.dt_type = '月'
;

delete from ads.ads_ipd_ipm_zcmodel_result_dd
where company in ('集团汇总')
and dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and data_type = '在产型号-产品型号口径'
;

insert into ads.ads_ipd_ipm_zcmodel_result_dd(
dt_month	--月份
,dt_type	--日期类型
,data_type	--数据类型
,business_division   --事业部
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,act_num	--实际值
,plan_num  --计划值
,completion_rate   --完成率
,load_dt	--加载时间
)
with act_value as ( 
select 
dt_month	--月份
,dt_type	--日期类型
,data_type	--数据类型
,'集团汇总' as business_division   --事业部
,'集团汇总' as company	--公司
,'全部' as product_line	--产品线
,'全部' as in_out_sale	--内外销
,sum(act_num) as act_num	--实际值
from ads.ads_ipd_ipm_zcmodel_result_dd
where company in ('冰冷','洗衣机','空调公司','视像科技'/*,'厨电'*/)
and dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and data_type = '在产型号-产品型号口径'
and case when business_division = '冰冷事业部' then product_line = '全部' and in_out_sale = '全部' 
when business_division = '显示事业部' then product_line = '视像科技' and in_out_sale = '全部' 
when business_division = '空气事业部' then product_line = '全部' and in_out_sale = '全部' 
when business_division = '洗护事业部' then product_line = '洗衣机' and in_out_sale = '全部' 
when business_division = '厨电事业部' then product_line = '全部' and in_out_sale = '全部'
else 1=2 end 
group by dt_month	--月份
,dt_type	--日期类型
,data_type	--数据类型
union all 
select 
dt_month	--月份
,dt_type	--日期类型
,data_type	--数据类型
,'集团汇总' as business_division   --事业部
,'集团汇总' as company	--公司
,'全部' as product_line	--产品线
,in_out_sale	--内外销
,sum(act_num) as act_num	--实际值
from ads.ads_ipd_ipm_zcmodel_result_dd
where company in ('冰冷','洗衣机','空调公司','视像科技'/*,'厨电'*/)
and dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and data_type = '在产型号-产品型号口径'
and case when business_division = '冰冷事业部' then product_line = '全部' and in_out_sale in ('内销','外销')
when business_division = '显示事业部' then product_line = '视像科技' and in_out_sale in ('内销','外销')
when business_division = '空气事业部' then product_line = '全部' and in_out_sale in ('内销','外销')
when business_division = '洗护事业部' then product_line = '洗衣机' and in_out_sale in ('内销','外销')
when business_division = '厨电事业部' then product_line = '全部' and in_out_sale in ('内销','外销')
else 1=2 end 
group by dt_month	--月份
,dt_type	--日期类型
,data_type	--数据类型
,in_out_sale	--内外销
)
,plan_values as (
--在销 在产 单型号销量 单型号销额
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
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.在销型号计划值')as DECIMALV3(20,4)) plan_zxmodel
,cast(get_json_string(record_data,'$.在产型号计划值')as DECIMALV3(20,4)) plan_zcmodel
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblT8dRgmsgrWu9c
where get_json_string(record_data,'$.事业部[0].text')  = '集团汇总'
)
select 
t1.dt_month	--月份
,t1.dt_type	--日期类型
,t1.data_type	--数据类型
,t1.business_division   --事业部
,t1.company	--公司
,t1.product_line	--产品线
,t1.in_out_sale	--内外销
,t1.act_num	--实际值
,t2.plan_zcmodel --计划值
,2-(coalesce (t1.act_num,0.0)/nullif(coalesce (t2.plan_zcmodel,0.0),0.0))  完成率
,now()
from act_value t1 
left join plan_values t2 
on t1.dt_month = t2.dt_month
and t1.dt_type = '月'
and t1.business_division = t2.shiyebu 
and t1.in_out_sale = t2.neiwaixiao 
;

--在产型号数  生产版本口径
delete from ads.ads_ipd_ipm_zcmodel_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰冷','洗衣机','空调公司','视像科技')
and data_type = '在产型号-生产版本口径'
;

insert into ads.ads_ipd_ipm_zcmodel_result_dd(
dt_month	--月份
,dt_type	--日期类型
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,data_type	--数据类型
,act_num	--实际值
,load_dt	--加载时间
)
with weidu_neiwaixiao as ( 
select '全部' as weidu_neiwaixiao union all select '内外销' as weidu_neiwaixiao
)
select 
dt_month 
,dt_type 
,company 
,product_line 
,case when t2.weidu_neiwaixiao = '全部' then '全部' else in_out_sale end as in_out_sale
,'在产型号-生产版本口径' as data_type
,count(distinct proversion)  as act_num
,now()
from dws.dws_ipd_ipm_zcproductionversion_dd  t1 
left join weidu_neiwaixiao t2 on 1=1 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰冷','洗衣机','空调公司','视像科技')
and is_project = 'N'
group by dt_month 
,dt_type 
,company 
,product_line 
,case when t2.weidu_neiwaixiao = '全部' then '全部' else in_out_sale end
;