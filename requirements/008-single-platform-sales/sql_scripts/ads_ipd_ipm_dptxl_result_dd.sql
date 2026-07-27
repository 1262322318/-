-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2025/12/26 09:34:27 GMT+08:00
-- ******************************************************************** --
delete from ads.ads_ipd_ipm_dptxl_result_dd
where dt_type = '月'
and dimension_type = '单平台销量'
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and company not in ('集团汇总')
and dimension_1 = '总体'
;

insert into ads.ads_ipd_ipm_dptxl_result_dd(
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,dimension_1
,platform_num	--平台数
,sum_qty	--销量汇总
,dptxl	--单平台销量
,plan_dptxl	--单平台销量计划值
,completion_rate_dptxl	--单平台销量完成率
,sum_amt	--销额汇总
,dptxe	--单平台销额
,load_dt	--加载日期
)
with company_weidu as ( 
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line
,udp4 as in_out_sale
from dim.dim_ipd_td_weidu_nd  
where zhibiao = '单平台销量'
and udp1 not in ('集团汇总')
and case when  udp2 = '空调公司' then udp3 = '全部' and udp4 = '全部' else 1=1 end 
)
,dt_month_weidu as (
select distinct year_mth as dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,all_weidu as ( 
select 
t1.business_division
,t1.company
,t1.product_line
,t1.in_out_sale
,t2.dt_month
from company_weidu t1 ,dt_month_weidu t2 
)
,month_sales as ( 
--25年口径 内销调整为在销型号数累计销量
select 
dt_month 
,business_division
,company
,case when company = '视像科技'  then '平板电视'
else product_line end  as product_line
,in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company not like '%商家库存%'
and product_line in ('冰箱','冷柜','洗衣机','家用空调','视像科技','中央空调','激光')
and is_project = 'N'
and sales_type = '管报'
and case when product_line in ('冰箱','冷柜') then model_label_4 like '%海信%'
when product_line in ('洗衣机') then (coalesce (model_label_4,'6372-平度洗衣机工厂') = '6372-平度洗衣机工厂' or model_label_4 like '%海信%')  else 1=1 end   --去除ODM产品
group by dt_month 
,company
,case when company = '视像科技'  then '平板电视'
else product_line end  
,in_out_sale ,business_division
union all 
select 
dt_month 
,business_division
,company
,'全部' as product_line
,in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company not like '%商家库存%'
and product_line in ('冰箱','冷柜','激光')
and is_project = 'N'
and in_out_sale = '内销'
and sales_type = '管报'
and case when product_line in ('冰箱','冷柜') then model_label_4 like '%海信%'
when product_line in ('洗衣机') then (coalesce (model_label_4,'6372-平度洗衣机工厂') = '6372-平度洗衣机工厂' or model_label_4 like '%海信%')  else 1=1 end   --去除ODM产品
group by dt_month 
,company
,in_out_sale ,business_division
union all 
select 
dt_month 
,business_division
,company
,'全部' as product_line
,in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company not like '%商家库存%'
and product_line in ('家用空调','中央空调')
and is_project = 'N'
and sales_type = '管报'
group by dt_month 
,company
,in_out_sale ,business_division
union all 
--外销
--sellin全量数据
select 
dt_month
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end as  business_division
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end as company 
,case when product_line = '商用空调' then '家用空调'when product_line in ('视像科技') then '平板电视'
when product_line in ('激光') then '激光家用'else product_line end as product_line
,'外销' as in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_sales_detail_mid_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and sales_type = 'sellin'
and product_line in ('冰箱','冷柜','洗衣机','商用空调','家用空调','视像科技','激光')
group by case when product_line in ('冰箱','冷柜') then '冰冷'
else company end
,case when product_line = '商用空调' then '家用空调'when product_line in ('视像科技') then '平板电视'
when product_line in ('激光') then '激光家用'else product_line end
,in_out_sale 
,dt_month
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end
union all 
--sellin全量数据  空调公司
select 
dt_month
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end as  business_division
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end as company 
,'全部' as product_line
,'外销' as in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_sales_detail_mid_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and sales_type = 'sellin'
and product_line in ('冰箱','冷柜','商用空调','家用空调','激光')
group by case when product_line in ('冰箱','冷柜') then '冰冷'
else company end
,in_out_sale 
,dt_month
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end
)
,month_sales_2 as (
select 
dt_month
,business_division
,company
,product_line
,in_out_sale
,sales_qty
,sales_amt
from month_sales
union all 
--内外销合计
select 
dt_month
,business_division
,company
,product_line
,'全部' as in_out_sale
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from month_sales
where company in ('视像科技','冰冷','洗衣机','空调公司','激光')
and in_out_sale in ('内销','外销')
group by dt_month
,company
,product_line,business_division
)
,platform as ( 
select 
dt_month
,case when company = '冰箱公司' then '冰冷' else  company end as company
,case when company = '视像科技' then '平板电视'when product_line = '商用空调' then '中央空调' else  product_line end as product_line
,case when company <> '海信日立'and  in_out_sale = '外销' then '外销' else in_out_sale end as in_out_sale
,act_value  as ct
from ads.ads_ipd_ipm_platform_result_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and company in ('冰箱公司','空调公司','视像科技','洗衣机','激光')
and date_type = '月'
and coalesce (dimension_1,'总体') = '总体'
)
,plan_values as (
select 
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平台数计划值-月度')as DECIMALV3(20,4)) pingtaishujihuazhiyuedu
,cast(get_json_string(record_data,'$.平台数计划值-累计')as DECIMALV3(20,4)) pingtaishujihuazhileiji
,cast(get_json_string(record_data,'$.平均销量-月度')as DECIMALV3(20,4)) pingjunxiaoliangyuedu
,cast(get_json_string(record_data,'$.平均销量-累计')as DECIMALV3(20,4)) pingjunxiaoliangleiji
,cast(get_json_string(record_data,'$.本月发布计划')as DECIMALV3(20,4)) benyuefabujihua
,cast(get_json_string(record_data,'$.本月停产计划')as DECIMALV3(20,4)) benyuetingchanjihua
,cast(get_json_string(record_data,'$.累计发布计划')as DECIMALV3(20,4)) leijifabujihua
,cast(get_json_string(record_data,'$.累计停产计划')as DECIMALV3(20,4)) leijitingchanjihua
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU
)
select 
t1.dt_month
,'单平台销量' as dimension_type
,'月' as dt_type
,t1.business_division
,t1.company as company1
,t1.product_line as product_line1
,t1.in_out_sale as in_out_sale1
,'总体' as dimension_1
,t2.ct   --平台数
,t3.sales_qty   --销量汇总
,t3.sales_qty/nullif(t2.ct ,0.0) as dptxl  --单平台销量
,t4.pingjunxiaoliangyuedu --单平台销量计划值
,(t3.sales_qty/nullif(t2.ct ,0.0)) / nullif(t4.pingjunxiaoliangyuedu,0.0) --单平台销量完成率 
,t3.sales_amt  --销额汇总
,t3.sales_amt/nullif(t2.ct ,0.0) as dptxe1   --单平台销额
,now()
from all_weidu t1
left join platform t2 
on t1.company = t2.company
and t1.product_line = t2.product_line
and t1.in_out_sale = t2.in_out_sale
and t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
left join month_sales_2 t3 
on t1.company = t3.company
and t1.business_division = t3.business_division
and t1.product_line = t3.product_line
and t1.in_out_sale = t3.in_out_sale
and t1.dt_month = t3.dt_month
left join plan_values t4 
on t1.business_division = t4.shiyebu
and t1.product_line = t4.fenzu
and t1.in_out_sale = t4.neiwaixiao
and t1.dt_month = t4.dt_month
;

delete from ads.ads_ipd_ipm_dptxl_result_dd
where dt_type = '年'
and dimension_type = '单平台销量'
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and company not in ('集团汇总')
and dimension_1 = '总体'
;

insert into ads.ads_ipd_ipm_dptxl_result_dd(
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,dimension_1
,platform_num	--平台数
,sum_qty	--销量汇总
,dptxl	--单平台销量
,plan_dptxl	--单平台销量计划值
,completion_rate_dptxl	--单平台销量完成率
,sum_amt	--销额汇总
,dptxe	--单平台销额
,load_dt	--加载日期
)
--冰冷洗空电 单平台销量 单平台销额逻辑更新
with company_weidu as ( 
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line
,udp4 as in_out_sale
from dim.dim_ipd_td_weidu_nd  
where zhibiao = '单平台销量'
and udp1 not in ('集团汇总')
and case when  udp2 = '空调公司' then udp3 = '全部' and udp4 = '全部' else 1=1 end 
)
,dt_month_weidu as (
select distinct year_mth as dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,all_weidu as ( 
select 
t1.business_division
,t1.company
,t1.product_line
,t1.in_out_sale
,t2.dt_month
from company_weidu t1 ,dt_month_weidu t2 
)
, month_sales as ( 
--25年口径 内销调整为在销型号数累计销量
select 
business_division
,company
,case when company = '视像科技'  then '平板电视'
else product_line end  as product_line
,in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and dt_type = '月' 
and company not like '%商家库存%'
and product_line in ('冰箱','冷柜','洗衣机','家用空调','视像科技','中央空调','激光')
and is_project = 'N'
and sales_type = '管报'
and case when product_line in ('冰箱','冷柜') then model_label_4 like '%海信%'
when product_line in ('洗衣机') then (coalesce (model_label_4,'6372-平度洗衣机工厂') = '6372-平度洗衣机工厂' or model_label_4 like '%海信%')  else 1=1 end   --去除ODM产品
group by company
,case when company = '视像科技'  then '平板电视'
else product_line end  
,in_out_sale ,business_division
union all 
select 
business_division
,company
,'全部' as product_line
,in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and dt_type = '月' 
and company not like '%商家库存%'
and product_line in ('冰箱','冷柜','激光')
and is_project = 'N'
and sales_type = '管报'
and case when product_line in ('冰箱','冷柜') then model_label_4 like '%海信%'
when product_line in ('洗衣机') then (coalesce (model_label_4,'6372-平度洗衣机工厂') = '6372-平度洗衣机工厂' or model_label_4 like '%海信%')  else 1=1 end   --去除ODM产品
group by company
,in_out_sale ,business_division
union all 
select 
business_division
,company
,'全部' as product_line
,in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and dt_type = '月' 
and company not like '%商家库存%'
and product_line in ('家用空调','中央空调')
and is_project = 'N'
and sales_type = '管报'
group by company
,in_out_sale ,business_division
union all 
--外销
--sellin全量数据
select 
case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end as  business_division
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end as company 
,case when product_line = '商用空调' then '家用空调'when product_line in ('视像科技') then '平板电视'
when product_line in ('激光') then '激光家用'else product_line end as product_line
,'外销' as in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_sales_detail_mid_dd 
where dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and sales_type = 'sellin'
and product_line in ('冰箱','冷柜','洗衣机','商用空调','家用空调','视像科技','激光')
group by case when product_line in ('冰箱','冷柜') then '冰冷'
else company end
,case when product_line = '商用空调' then '家用空调'when product_line in ('视像科技') then '平板电视'
when product_line in ('激光') then '激光家用' else product_line end
,in_out_sale 
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end
union all 
--外销
select 
case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end as  business_division
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end as company 
,'全部' as product_line
,'外销' as in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_sales_detail_mid_dd 
where dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and sales_type = 'sellin'
and product_line in ('冰箱','冷柜','商用空调','家用空调','激光')
group by case when product_line in ('冰箱','冷柜') then '冰冷'
else company end
,in_out_sale 
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '激光' then '激光事业部'
else null end
)
,month_sales_2 as (
select 
business_division
,company
,product_line
,in_out_sale
,sales_qty
,sales_amt
from month_sales
union all 
--内外销合计
select 
business_division
,company
,product_line
,'全部' as in_out_sale
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from month_sales
where company in ('视像科技','冰冷','洗衣机','空调公司','激光')
and in_out_sale in ('内销','外销')
group by company
,product_line,business_division
)
,platform as ( 
select 
dt_month
,case when company = '海信日立' then '日立公司'when company = '冰箱公司' then '冰冷' else  company end as company
,case when company = '视像科技' then '平板电视'when product_line = '商用空调' then '中央空调' else  product_line end as product_line
,case when company <> '海信日立'and  in_out_sale = '外销' then '外销' else in_out_sale end as in_out_sale
,act_value  as ct
from ads.ads_ipd_ipm_platform_result_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and company in ('冰箱公司','空调公司','视像科技','洗衣机','激光')
and date_type = '年'
and coalesce (dimension_1,'总体') = '总体'
)
,plan_values as (
select 
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平台数计划值-月度')as DECIMALV3(20,4)) pingtaishujihuazhiyuedu
,cast(get_json_string(record_data,'$.平台数计划值-累计')as DECIMALV3(20,4)) pingtaishujihuazhileiji
,cast(get_json_string(record_data,'$.平均销量-月度')as DECIMALV3(20,4)) pingjunxiaoliangyuedu
,cast(get_json_string(record_data,'$.平均销量-累计')as DECIMALV3(20,4)) pingjunxiaoliangleiji
,cast(get_json_string(record_data,'$.本月发布计划')as DECIMALV3(20,4)) benyuefabujihua
,cast(get_json_string(record_data,'$.本月停产计划')as DECIMALV3(20,4)) benyuetingchanjihua
,cast(get_json_string(record_data,'$.累计发布计划')as DECIMALV3(20,4)) leijifabujihua
,cast(get_json_string(record_data,'$.累计停产计划')as DECIMALV3(20,4)) leijitingchanjihua
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU
)
select 
t1.dt_month
,'单平台销量' as dimension_type
,'年' as dt_type
,t1.business_division
,t1.company as company1
,t1.product_line as product_line1
,t1.in_out_sale as in_out_sale1
,'总体' as dimension_1
,t2.ct   --平台数
,t3.sales_qty   --销量汇总
,t3.sales_qty/nullif(t2.ct ,0.0) as dptxl  --单平台销量
,t4.pingjunxiaoliangleiji --单平台销量计划值
,(t3.sales_qty/nullif(t2.ct ,0.0)) / nullif(t4.pingjunxiaoliangleiji,0.0) --单平台销量完成率 
,t3.sales_amt  --销额汇总
,t3.sales_amt/nullif(t2.ct ,0.0) as dptxe1   --单平台销额
,now()
from all_weidu t1
left join platform t2 
on t1.company = t2.company
and t1.product_line = t2.product_line
and t1.in_out_sale = t2.in_out_sale
and t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
left join month_sales_2 t3 
on t1.company = t3.company
and t1.business_division = t3.business_division
and t1.product_line = t3.product_line
and t1.in_out_sale = t3.in_out_sale
and t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
left join plan_values t4 
on t1.business_division = t4.shiyebu
and t1.product_line = t4.fenzu
and t1.in_out_sale = t4.neiwaixiao
and t1.dt_month = t4.dt_month
;

delete from ads.ads_ipd_ipm_dptxl_result_dd
where dimension_type = '单平台销量'
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and company in ('集团汇总')
and dimension_1 = '总体'
;

insert into ads.ads_ipd_ipm_dptxl_result_dd(
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division
,company	--公司
,product_line 
,in_out_sale 
,dimension_1
,platform_num	--平台数
,sum_qty	--销量汇总
,dptxl	--单平台销量
,plan_dptxl	--单平台销量计划值
,completion_rate_dptxl	--单平台销量完成率
,sum_amt	--销额汇总
,dptxe	--单平台销额
,plan_dptxe	--单平台销额计划值
,completion_rate_dptxe	--单平台销额完成率
,load_dt	--加载日期
)
with company_weidu as ( 
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line
,udp4 as in_out_sale
from dim.dim_ipd_td_weidu_nd  
where zhibiao = '单平台销量'
and udp1 in ('集团汇总')
)
,dt_month_weidu as (
select distinct year_mth as dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,dt_type_weidu as (
select '月' as dt_type union all select '年' as dt_type
)
,all_weidu as ( 
select 
t1.business_division
,t1.company
,t1.product_line
,t1.in_out_sale
,t2.dt_month
,t3.dt_type
from company_weidu t1 ,dt_month_weidu t2 ,dt_type_weidu t3
)
,plan_values as (
select 
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,'月' as dt_type
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平均销量-月度')as DECIMALV3(20,4)) pingjunxiaoliang
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU
union all 
select 
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,'年' as dt_type
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.平均销量-累计')as DECIMALV3(20,4)) pingjunxiaoliang
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU
)
,act_value as ( 
--智慧生活BG
select 
t1.dt_month	--月份
,t1.dimension_type	--数据类型
,t1.dt_type	--日期类型
,'集团汇总' as business_division
,'集团汇总' as company
,t1.in_out_sale 
,sum(t1.platform_num) as platform_num	--平台数
,sum(t1.sum_qty) as sum_qty	--销量汇总
,sum(t1.sum_qty)/nullif(sum(t1.platform_num),0.0) as dptxl	--单平台销量
,sum(t1.sum_amt) as sum_amt	--销额汇总
,sum(t1.sum_amt)/nullif(sum(t1.platform_num),0.0) as dptxe	--单平台销额
from ads.ads_ipd_ipm_dptxl_result_dd t1 
where t1.dimension_type = '单平台销量'
and t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and case when company = '空调公司' then product_line = '全部' and in_out_sale = '全部' else product_line <> '全部' end
and coalesce (dimension_1,'总体') = '总体'
group by t1.dt_month	--月份
,t1.dimension_type	--数据类型
,t1.dt_type	--日期类型
,t1.in_out_sale 
)
select 
t1.dt_month	--月份
,'单平台销量' as dimension_type	--数据类型
,t1.dt_type	--日期类型
,t1.business_division
,t1.company
,t1.product_line
,t1.in_out_sale 
,'总体' as dimension_1
,t2.platform_num	--平台数
,t2.sum_qty--销量汇总
,t2.dptxl	--单平台销量
,t3.pingjunxiaoliang as plan_dptxl	--单平台销量计划值
,t2.dptxl/nullif(t3.pingjunxiaoliang,0.0) as completion_rate_dptxl	--单平台销量完成率
,t2.sum_amt--销额汇总
,t2.dptxe	--单平台销额
,null as plan_dptxe	--单平台销额计划值
,null  as completion_rate_dptxe	--单平台销额完成率
,now()
from all_weidu t1 
left join act_value t2 
on t1.company = t2.company
and t1.business_division = t2.business_division
and t1.in_out_sale = t2.in_out_sale
and t1.dt_month = t2.dt_month
and t1.dt_type = t2.dt_type
left join plan_values t3 
on t1.dt_month = t3.dt_month
and t1.business_division = t3.shiyebu
and t1.dt_type = t3.dt_type
and t1.in_out_sale = t3.neiwaixiao
;