-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/02/27 14:30:35 GMT+08:00
-- ******************************************************************** --

--月度 单型号销量 单型号销额
delete from ads.ads_ipd_ipm_dxhxl_result_dd
where dt_type = '月'
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '单型号销量'
;
insert into ads.ads_ipd_ipm_dxhxl_result_dd(
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division   --事业部
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,model_num	--型号数
,sum_qty	--销量汇总
,dxhxl	--单型号销量
,plan_dxhxl	--单型号销量计划值
,completion_rate_dxhxl	--单型号销量完成率
,sum_amt	--销额汇总
,dxhxe	--单型号销额
,plan_dxhxe	--单型号销额计划值
,completion_rate_dxhxe	--单型号销额完成率
,load_dt	--加载日期
)

with company_weidu as ( 
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line
,udp4 as in_out_sale
from dim.dim_ipd_td_weidu_nd  
where zhibiao = '单型号销量'
and udp1 not in ('集团汇总')
and udp4 <> '全部'
and udp3 <> '全部'
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
,bingxianggongsi_model as ( 
--提供型号数
select 
business_division   --事业部
,company
,case when company = '厨电' then '厨电' else product_line end product_line
,in_out_sale
,dt_month 
,count(distinct coalesce(prdct_model,model)) as ct
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_type = '月'
and company in ('空调公司','冰冷','洗衣机','视像科技','厨电','激光')
and case when company = '空调公司' then dt_month >= '202601' else 1=1 end 
and is_project = 'N'
group by case when company = '厨电' then '厨电' else product_line end,dt_month,in_out_sale ,company,business_division   --事业部
)
,chukou_sellin as (
--提供销量
--内销取在销型号数销量
select 
business_division   --事业部
,company
,case when company = '厨电' then '厨电' else product_line end product_line 
,in_out_sale
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd
where dt_type = '月'
and company in ('空调公司','冰冷','洗衣机','视像科技','厨电','激光')
and sales_type in ('管报')
and case when company = '空调公司' then dt_month >= '202601' else 1=1 end 
and dt_month in (
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 2 month) , '%Y%m')
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 3 month) , '%Y%m')
)
and is_project = 'N'
group by case when company = '厨电' then '厨电' else product_line end,in_out_sale,company,business_division   --事业部

union all 

--外销取sellin全量数据
select 
case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '厨电' then '厨电事业部'
when company = '激光' then '激光事业部'
else null end as  business_division
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end as company 
,case when product_line = '商用空调' then '家用空调'when company = '激光' then '激光家用' else product_line end as product_line
,'外销' as in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_sales_detail_mid_dd 
where dt_month in (
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 2 month) , '%Y%m')
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 3 month) , '%Y%m')
)
and sales_type = 'sellin'
and product_line in ('冰箱','冷柜','洗衣机','商用空调','家用空调','视像科技','厨电','激光')
and case when product_line in ('家用空调','商用空调') then dt_month >= '202601' else 1=1 end 
group by case when product_line = '商用空调' then '家用空调' when company = '激光' then '激光家用' else product_line end 
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '厨电' then '厨电事业部'
when company = '激光' then '激光事业部'
else null end

)
,dxhxl_mingxi as ( 
select 
business_division   --事业部
,company 
,product_line 
,in_out_sale
,sum(ct) as ct
from bingxianggongsi_model
where dt_month in (
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 2 month) , '%Y%m')
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 3 month) , '%Y%m')
)
group by product_line,company,in_out_sale,business_division   --事业部
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
,cast(get_json_string(record_data,'$.单型号平均销量计划值-三月平均')as DECIMALV3(20,4)) danxinghaoyuede
,cast(get_json_string(record_data,'$.单型号平均销量计划值-累计')as DECIMALV3(20,4)) danxinghaoleiji
,cast(get_json_string(record_data,'$.单型号平均销额计划值-三月平均') * 10000 as DECIMALV3(20,4)) danxinghaoxeyuede
,cast(get_json_string(record_data,'$.单型号平均销额计划值-累计') * 10000 as DECIMALV3(20,4)) danxinghaoxeleiji
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblT8dRgmsgrWu9c
)
select 
t0.dt_month
,'单型号销量' as dimension_type
,'月' as dt_type
,t0.business_division --事业部
,t0.company 
,t0.product_line 
,t0.in_out_sale 
,t1.ct  --型号数
,t2.sales_qty  --销量汇总
,t2.sales_qty/nullif(t1.ct,0.0) as dxhxl
,t3.danxinghaoyuede -- 单型号销量计划值
,(t2.sales_qty/nullif(t1.ct,0.0))/nullif(t3.danxinghaoyuede,0.0) --单型号销量完成率
,t2.sales_amt  --销额汇总
,t2.sales_amt/nullif(t1.ct,0.0) as dxhxe
,t3.danxinghaoxeyuede -- 单型号销额计划值
,(t2.sales_amt/nullif(t1.ct,0.0))/nullif(t3.danxinghaoxeyuede,0.0) --单型号销额完成率
,now()
from all_weidu t0
left join dxhxl_mingxi t1 
on t0.company = t1.company
and t0.product_line = t1.product_line
and t0.in_out_sale = t1.in_out_sale
and t0.business_division =t1.business_division
and t0.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
left join chukou_sellin t2 
on t0.company = t2.company
and t0.product_line = t2.product_line
and t0.in_out_sale = t2.in_out_sale
and t0.business_division =t2.business_division
and t0.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
left join plan_values t3 
on t0.business_division = t3.shiyebu
and t0.product_line = t3.fenzu
and t0.in_out_sale = t3.neiwaixiao
and t0.dt_month = t3.dt_month
;

--年累  单型号销量  单型号销额
delete from ads.ads_ipd_ipm_dxhxl_result_dd
where dt_type = '年'
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '单型号销量'
;
insert into ads.ads_ipd_ipm_dxhxl_result_dd(
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division   --事业部
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,model_num	--型号数
,sum_qty	--销量汇总
,dxhxl	--单型号销量
,plan_dxhxl	--单型号销量计划值
,completion_rate_dxhxl	--单型号销量完成率
,sum_amt	--销额汇总
,dxhxe	--单型号销额
,plan_dxhxe	--单型号销额计划值
,completion_rate_dxhxe	--单型号销额完成率
,load_dt	--加载日期
)



with company_weidu as ( 
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line
,udp4 as in_out_sale
from dim.dim_ipd_td_weidu_nd  
where zhibiao = '单型号销量'
and udp1 not in ('集团汇总')
and udp4 <> '全部'
and udp3 <> '全部'
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
, bingxianggongsi_model as ( 
--提供型号数
select 
business_division   --事业部
,company
,case when company = '厨电' then '厨电' else product_line end product_line 
,in_out_sale
,count(distinct coalesce(prdct_model,model)) as ct
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_type = '月'
and company in ('空调公司','冰冷','洗衣机','视像科技','厨电','激光')
and company not like '%商家库存%'
and is_project = 'N'
and substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by case when company = '厨电' then '厨电' else product_line end,in_out_sale ,company,business_division 
)
,chukou_sellin as (
--提供销量
--内销取在销型号数销量
select 
business_division   --事业部
,company
,case when company = '厨电' then '厨电' else product_line end product_line 
,in_out_sale
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_dxhxl_detail_dd
where dt_type = '月'
and company in ('空调公司','冰冷','洗衣机','视像科技','厨电','激光')
and sales_type in ('管报')
and company not like '%商家库存%'
and substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and is_project = 'N'
group by case when company = '厨电' then '厨电' else product_line end,in_out_sale,company,business_division   --事业部

union all 

--外销取sellin全量数据
select 
case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '厨电' then '厨电事业部'
when company = '激光' then '激光事业部'
else null end as  business_division
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end as company 
,case when product_line = '商用空调' then '家用空调' when company = '激光' then '激光家用' else product_line end as product_line
,'外销' as in_out_sale 
,sum(sales_qty) as sales_qty
,sum(sales_amt) as sales_amt
from dws.dws_ipd_ipm_sales_detail_mid_dd 
where substring(dt_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and sales_type = 'sellin'
and product_line in ('冰箱','冷柜','洗衣机','商用空调','家用空调','视像科技','厨电','激光')
group by case when product_line = '商用空调' then '家用空调' when company = '激光' then '激光家用' else product_line end
,case when product_line in ('冰箱','冷柜') then '冰冷'
else company end
,case when product_line in ('冰箱','冷柜') then '冰冷事业部'
when company = '洗衣机' then '洗护事业部'
when company = '空调公司' then '空气事业部'
when company = '视像科技' then '显示事业部'
when company = '厨电' then '厨电事业部'
when company = '激光' then '激光事业部'
else null end

)
,dxhxl_mingxi as ( 
select 
business_division   --事业部
,company 
,product_line 
,in_out_sale
,sum(ct) as ct
from bingxianggongsi_model
group by product_line,company,in_out_sale,business_division   --事业部
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
,cast(get_json_string(record_data,'$.单型号平均销量计划值-三月平均')as DECIMALV3(20,4)) danxinghaoyuede
,cast(get_json_string(record_data,'$.单型号平均销量计划值-累计')as DECIMALV3(20,4)) danxinghaoleiji
,cast(get_json_string(record_data,'$.单型号平均销额计划值-三月平均') * 10000 as DECIMALV3(20,4)) danxinghaoxeyuede
,cast(get_json_string(record_data,'$.单型号平均销额计划值-累计') * 10000 as DECIMALV3(20,4)) danxinghaoxeleiji
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblT8dRgmsgrWu9c
)
select 
t0.dt_month
,'单型号销量' as dimension_type
,'年' as dt_type
,t0.business_division
,t0.company 
,t0.product_line 
,t0.in_out_sale 
,t1.ct  --型号数
,t2.sales_qty  --销量汇总
,t2.sales_qty/nullif(t1.ct,0.0) as dxhxl
,t3.danxinghaoleiji -- 单型号销量计划值
,(t2.sales_qty/nullif(t1.ct,0.0))/nullif(t3.danxinghaoleiji,0.0) --单型号销量完成率
,t2.sales_amt  --销额汇总
,t2.sales_amt/nullif(t1.ct,0.0) as dxhxe
,t3.danxinghaoxeleiji -- 单型号销额计划值
,(t2.sales_amt/nullif(t1.ct,0.0))/nullif(t3.danxinghaoxeleiji,0.0) --单型号销额完成率
,now()
from all_weidu t0
left join dxhxl_mingxi t1 
on t0.company = t1.company
and t0.product_line = t1.product_line
and t0.in_out_sale = t1.in_out_sale
and t0.business_division =t1.business_division
and t0.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
left join chukou_sellin t2 
on t0.company = t2.company
and t0.product_line = t2.product_line
and t0.in_out_sale = t2.in_out_sale
and t0.business_division =t2.business_division
and t0.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
left join plan_values t3 
on t0.business_division = t3.shiyebu
and t0.product_line = t3.fenzu
and t0.in_out_sale = t3.neiwaixiao
and t0.dt_month = t3.dt_month
;




---集团汇总  缺失厨电的逻辑  等着数据完善 新增厨电

insert into ads.ads_ipd_ipm_dxhxl_result_dd(
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division   --事业部
,company	--公司
,product_line	--产品线
,in_out_sale	--内外销
,model_num	--型号数
,sum_qty	--销量汇总
,dxhxl	--单型号销量
,plan_dxhxl	--单型号销量计划值
,completion_rate_dxhxl	--单型号销量完成率
,sum_amt	--销额汇总
,dxhxe	--单型号销额
,plan_dxhxe	--单型号销额计划值
,completion_rate_dxhxe	--单型号销额完成率
,load_dt	--加载日期
)
with company_weidu as ( 
select 
udp1 as business_division
,udp2 as company
,udp3 as product_line
,udp4 as in_out_sale
from dim.dim_ipd_td_weidu_nd  
where zhibiao = '单型号销量'
and case when udp1 = '冰冷事业部' and udp3 = '全部' then 1=1 
when udp1 = '冰冷事业部' and udp3 in ('冰箱','冷柜') then udp4 = '全部'
else udp4 = '全部' end  
)
,dt_month_weidu as (
select distinct year_mth as dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,dt_type_weidu as (
select '年' as dt_type union all select '月' as dt_type
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
, plan_value as (
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
,cast(get_json_string(record_data,'$.单型号平均销量计划值-三月平均')as DECIMALV3(20,4)) danxinghao
,cast(get_json_string(record_data,'$.单型号平均销额计划值-三月平均') * 10000 as DECIMALV3(20,4)) danxinghaoxe
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblT8dRgmsgrWu9c

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
,cast(get_json_string(record_data,'$.单型号平均销量计划值-累计')as DECIMALV3(20,4)) danxinghao
,cast(get_json_string(record_data,'$.单型号平均销额计划值-累计') * 10000 as DECIMALV3(20,4)) danxinghaoxe
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblT8dRgmsgrWu9c
)
,act_value as ( 
--集团汇总
select 
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,'集团汇总' as business_division   --事业部
,'集团汇总' as company	--公司
,'全部' as product_line	--产品线
,'全部' as  in_out_sale 
,sum(model_num)	model_num--型号数
,sum(sum_qty)	sum_qty--销量汇总
,sum(sum_qty)/nullif(sum(model_num),0.0) as dxhxl	--单型号销量
,null as plan_dxhxl	--单型号销量计划值
,null as completion_rate_dxhxl	--单型号销量完成率
,sum(sum_amt)	sum_amt--销额汇总
,sum(sum_amt)/nullif(sum(model_num),0.0) as dxhxe	--单型号销额
,null as plan_dxhxe	--单型号销额计划值
,null as completion_rate_dxhxe	--单型号销额完成率
,now()
from ads.ads_ipd_ipm_dxhxl_result_dd
where company in ('空调公司','冰冷','洗衣机','视像科技')
and dt_type in ('月','年')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '单型号销量'
and in_out_sale <> '全部'
group by dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型


union all 

select 
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division   --事业部
,company	--公司
,'全部' as product_line	--产品线
,'全部' as  in_out_sale 
,sum(model_num)	model_num--型号数
,sum(sum_qty)	sum_qty--销量汇总
,sum(sum_qty)/nullif(sum(model_num),0.0) as dxhxl	--单型号销量
,null as plan_dxhxl	--单型号销量计划值
,null as completion_rate_dxhxl	--单型号销量完成率
,sum(sum_amt)	sum_amt--销额汇总
,sum(sum_amt)/nullif(sum(model_num),0.0) as dxhxe	--单型号销额
,null as plan_dxhxe	--单型号销额计划值
,null as completion_rate_dxhxe	--单型号销额完成率
,now()
from ads.ads_ipd_ipm_dxhxl_result_dd
where company in ('空调公司','冰冷','激光')
and dt_type in ('月','年')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '单型号销量'
and in_out_sale <> '全部'
group by dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,company
,business_division   --事业部

union all 

select 
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division   --事业部
,company	--公司
,'全部' as product_line	--产品线
,in_out_sale 
,sum(model_num)	model_num--型号数
,sum(sum_qty)	sum_qty--销量汇总
,sum(sum_qty)/nullif(sum(model_num),0.0) as dxhxl	--单型号销量
,null as plan_dxhxl	--单型号销量计划值
,null as completion_rate_dxhxl	--单型号销量完成率
,sum(sum_amt)	sum_amt--销额汇总
,sum(sum_amt)/nullif(sum(model_num),0.0) as dxhxe	--单型号销额
,null as plan_dxhxe	--单型号销额计划值
,null as completion_rate_dxhxe	--单型号销额完成率
,now()
from ads.ads_ipd_ipm_dxhxl_result_dd
where company in ('冰冷','激光')
and dt_type in ('月','年')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '单型号销量'
and in_out_sale <> '全部'
group by dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,company
,business_division   --事业部
,in_out_sale 

union all 

select 
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division   --事业部
,company	--公司
,product_line	--产品线
,'全部' as in_out_sale 
,sum(model_num)	model_num--型号数
,sum(sum_qty)	sum_qty--销量汇总
,sum(sum_qty)/nullif(sum(model_num),0.0) as dxhxl	--单型号销量
,null as plan_dxhxl	--单型号销量计划值
,null as completion_rate_dxhxl	--单型号销量完成率
,sum(sum_amt)	sum_amt--销额汇总
,sum(sum_amt)/nullif(sum(model_num),0.0) as dxhxe	--单型号销额
,null as plan_dxhxe	--单型号销额计划值
,null as completion_rate_dxhxe	--单型号销额完成率
,now()
from ads.ads_ipd_ipm_dxhxl_result_dd
where company in ('冰冷','激光') and product_line <> '全部'
and dt_type in ('月','年')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '单型号销量'
and in_out_sale <> '全部'
group by dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,company
,business_division   --事业部
,product_line 

union all 

select 
dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,business_division   --事业部
,company	--公司
,product_line	--产品线
,'全部' as  in_out_sale 
,sum(model_num)	model_num--型号数
,sum(sum_qty)	sum_qty--销量汇总
,sum(sum_qty)/nullif(sum(model_num),0.0) as dxhxl	--单型号销量
,null as plan_dxhxl	--单型号销量计划值
,null as completion_rate_dxhxl	--单型号销量完成率
,sum(sum_amt)	sum_amt--销额汇总
,sum(sum_amt)/nullif(sum(model_num),0.0) as dxhxe	--单型号销额
,null as plan_dxhxe	--单型号销额计划值
,null as completion_rate_dxhxe	--单型号销额完成率
,now()
from ads.ads_ipd_ipm_dxhxl_result_dd
where company in ('视像科技','洗衣机')
and dt_type in ('月','年')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '单型号销量'
and in_out_sale <> '全部'
group by dt_month	--月份
,dimension_type	--数据类型
,dt_type	--日期类型
,company
,business_division   --事业部
,product_line
)
select
t0.dt_month	--月份
,'单型号销量'as dimension_type	--数据类型
,t0.dt_type	--日期类型
,t0.business_division   --事业部
,t0.company	--公司
,t0.product_line	--产品线
,t0.in_out_sale 
,t1.model_num--型号数
,t1.sum_qty--销量汇总
,t1.dxhxl	--单型号销量
,t2.danxinghao	--单型号销量计划值
,t1.dxhxl/nullif(t2.danxinghao,0.0) as  completion_rate_dxhxl	--单型号销量完成率
,t1.sum_amt--销额汇总
,t1.dxhxe	--单型号销额
,t2.danxinghaoxe	--单型号销额计划值
,t1.dxhxe/nullif(t2.danxinghaoxe,0.0) as completion_rate_dxhxe	--单型号销额完成率
,now()
from all_weidu t0 
left join act_value t1
on t0.business_division = t1.business_division 
and t0.product_line = t1.product_line
and t0.in_out_sale = t1.in_out_sale
and t0.dt_month = t1.dt_month
and t0.dt_type = t1.dt_type
left join plan_value t2 
on t0.business_division = t2.shiyebu 
and t0.product_line = t2.fenzu
and t0.in_out_sale = t2.neiwaixiao
and t0.dt_month = t2.dt_month
and t0.dt_type = t2.dt_type
;




DELETE FROM ads.ads_ipd_ipm_dxhxl_result_dd 
WHERE company = '海信日立'
    AND dimension_type = '单型号销量'
    AND dt_month >= DATE_FORMAT(DATE_SUB(DATE_SUB(CURDATE(), INTERVAL 1 DAY), INTERVAL 1 MONTH), '%Y%m')
    AND dt_month <= CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y'), '12');

INSERT INTO ads.ads_ipd_ipm_dxhxl_result_dd(
dt_month, dimension_type, dt_type, company, product_line, in_out_sale,
dimension_1, dimension_2, dimension_3, dimension_4, zhibiao_type, rili_nkjt,
model_num, sum_qty, dxhxl, plan_dxhxl, completion_rate_dxhxl,
sum_amt, dxhxe, plan_dxhxe, completion_rate_dxhxe, load_dt
)
WITH month_seq AS (
    SELECT -1 AS offset UNION ALL SELECT 0 UNION ALL SELECT 1
    UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11
)
,target_months AS (
    SELECT DATE_FORMAT(DATE_ADD(
        STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
        INTERVAL m.offset MONTH
    ), '%Y%m') AS target_month
    FROM month_seq m
    WHERE DATE_FORMAT(DATE_ADD(
        STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
        INTERVAL m.offset MONTH
    ), '%Y') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')
)
,weidu_dt_type AS (
    SELECT '年' AS dt_type UNION ALL SELECT '月' AS dt_type
)
,weidu_dimension_1 AS (
    SELECT '总体' AS dimension_1 UNION ALL SELECT '营销部' AS dimension_1 UNION ALL SELECT '品牌' AS dimension_1
)
,weidu_dimension_2 AS (
    SELECT udp1 AS dimension_2 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '事业部'
    UNION ALL SELECT udp1 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '事业部合计'
    UNION ALL SELECT udp1 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '工程营销部'
)
,weidu_dimension_3 AS (
    SELECT udp1 AS dimension_3 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '产品小类'
)
,weidu_dimension_4 AS (
    SELECT '合计' AS dimension_4
)
,weidu_brand AS (
    SELECT '海信' AS brand UNION ALL SELECT '约克' AS brand UNION ALL SELECT '日立' AS brand
    UNION ALL SELECT '其他' AS brand UNION ALL SELECT '合计' AS brand
)
,weidu_koujing AS (
    SELECT '集团' AS koujing UNION ALL SELECT '内控' AS koujing
)
,weidu_zhibiao_type AS (
    SELECT '在售' AS zhibiao_type UNION ALL SELECT '退市' AS zhibiao_type UNION ALL SELECT '在产' AS zhibiao_type
)
,weidu_all AS (
    SELECT DISTINCT
        tm.target_month AS dt_month
        ,'空调公司' AS company
        ,'中央空调' AS product_line
        ,dt_type
        ,zhibiao_type
        ,CASE WHEN dimension_1 = '总体' THEN '总体' ELSE dimension_1 END AS dimension_1
        ,CASE WHEN dimension_1 = '营销部' THEN dimension_2
              WHEN dimension_1 = '品牌' THEN brand
              ELSE '总体' END AS dimension_2
        ,dimension_3
        ,dimension_4
        ,koujing
    FROM weidu_dimension_1, weidu_dimension_2, weidu_dt_type, weidu_dimension_3,
         weidu_zhibiao_type, weidu_koujing, weidu_brand, weidu_dimension_4, target_months tm
    WHERE CASE WHEN koujing = '集团' THEN zhibiao_type = '在售' ELSE 1=1 END
        AND CASE WHEN koujing = '集团' THEN dimension_4 = '合计' ELSE 1=1 END
        AND CASE WHEN koujing = '集团' THEN dimension_2 NOT LIKE '%考核%' ELSE 1=1 END
        AND CASE WHEN dimension_1 <> '品牌' THEN brand = '合计' ELSE 1=1 END
)
,weidu_datacopy AS (
    SELECT '正常' AS datacopy UNION ALL SELECT '各营销部' AS datacopy
    UNION ALL SELECT '内销合计' AS datacopy UNION ALL SELECT '内外销' AS datacopy
    UNION ALL SELECT '合计' AS datacopy UNION ALL SELECT '品牌' AS datacopy
    UNION ALL SELECT '品牌合计' AS datacopy UNION ALL SELECT '工程营销部' AS datacopy
)

-- sales_all：明细级取数，CROSS JOIN目标月+口径（对齐原脚本结构）
,sales_all AS (
    --月度：先按源月分别COUNT(DISTINCT)，再外层SUM得到近3月型号数之和
    SELECT
        dt_month
        ,company
        ,product_line
        ,'月' AS dt_type
        ,dimension_2
        ,dimension_3
        ,zhibiao_type
        ,biaozhun_dingzhi
        ,brand
        ,koujing
        ,SUM(ct) AS ct              --近3月型号数之和（每月去重后再相加）
        ,SUM(sales_qty) AS sales_qty
        ,SUM(sales_amt) AS sales_amt
    FROM (
        --内层：按源月独立COUNT(DISTINCT)
        SELECT
            tm.target_month AS dt_month
            ,company
            ,product_line
            ,COALESCE(PC20080, '其他') AS dimension_2
            ,COALESCE(product_sml, '其他') AS dimension_3
            ,CASE WHEN koujing = '集团' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
            WHEN koujing = '内控' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                     WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
            ELSE '其他' END AS zhibiao_type
            ,'合计' AS biaozhun_dingzhi
            ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
                  WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END AS brand
            ,koujing
            ,COUNT(DISTINCT model) AS ct  --每个源月独立去重
            ,SUM(sales_qty) AS sales_qty
            ,SUM(sales_amt) AS sales_amt
        FROM dws.dws_ipd_ipm_dxhxl_detail_dd dws, weidu_koujing, target_months tm
        WHERE CASE
                WHEN koujing = '集团' THEN
                    dws.dt_month IN (
                        tm.target_month,
                        DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(tm.target_month, '01'), '%Y%m%d'), INTERVAL 1 MONTH), '%Y%m'),
                        DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(tm.target_month, '01'), '%Y%m%d'), INTERVAL 2 MONTH), '%Y%m')
                    )
                WHEN koujing = '内控' THEN
                    dws.dt_month = tm.target_month
                ELSE 1=2
            END
            AND product_line = '中央空调'
            AND CASE WHEN koujing = '集团' THEN is_project = 'N'
                     WHEN koujing = '内控' THEN is_project_nk = 'N'
                     ELSE 1=2 END
        GROUP BY tm.target_month
            ,dws.dt_month  --按源月分组，保证每月独立去重
            ,company
            ,product_line
            ,COALESCE(PC20080, '其他')
            ,COALESCE(product_sml, '其他')
            ,CASE WHEN koujing = '集团' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
            WHEN koujing = '内控' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                     WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
            ELSE '其他' END
            ,koujing
            ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
                  WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END
    ) a
    GROUP BY dt_month, company, product_line, dimension_2, dimension_3,
        zhibiao_type, biaozhun_dingzhi, brand, koujing

    UNION ALL

    --年：集团取全年跨月去重COUNT(DISTINCT)，内控取当月
    SELECT
        tm.target_month AS dt_month
        ,company
        ,product_line
        ,'年' AS dt_type
        ,COALESCE(PC20080, '其他') AS dimension_2
        ,COALESCE(product_sml, '其他') AS dimension_3
        ,CASE WHEN koujing = '集团' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
        WHEN koujing = '内控' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                 WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
        ELSE '其他' END AS zhibiao_type
        ,'合计' AS biaozhun_dingzhi
        ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
              WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END AS brand
        ,koujing
        ,COUNT(DISTINCT model) AS ct
        ,CASE WHEN koujing = '集团' THEN SUM(sales_qty)
              WHEN koujing = '内控' THEN SUM(sales_qty_y)
              ELSE NULL END AS sales_qty
        ,CASE WHEN koujing = '集团' THEN SUM(sales_amt)
              WHEN koujing = '内控' THEN SUM(sales_amt_y)
              ELSE NULL END AS sales_amt
    FROM dws.dws_ipd_ipm_dxhxl_detail_dd dws, weidu_koujing, target_months tm
    WHERE CASE
            WHEN koujing = '集团' THEN
                dws.dt_month <= tm.target_month
                AND SUBSTRING(dws.dt_month, 1, 4) = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')
            WHEN koujing = '内控' THEN
                dws.dt_month = tm.target_month
            ELSE 1=2
        END
        AND product_line = '中央空调'
        AND CASE WHEN koujing = '集团' THEN is_project = 'N'
                 WHEN koujing = '内控' THEN is_project_nk = 'N'
                 ELSE 1=2 END
    GROUP BY tm.target_month
        ,company
        ,product_line
        ,COALESCE(PC20080, '其他')
        ,COALESCE(product_sml, '其他')
        ,CASE WHEN koujing = '集团' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
        WHEN koujing = '内控' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                 WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
        ELSE '其他' END
        ,koujing
        ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
              WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END
)

-- sales_all_jiagong：维度加工（与原脚本结构完全一致）
,sales_all_jiagong AS (
    SELECT
        t1.dt_month
        ,t1.company
        ,t1.product_line
        ,t1.dt_type
        ,CASE WHEN t4.datacopy IN ('正常') THEN '总体'
              WHEN t4.datacopy IN ('品牌','品牌合计') THEN '品牌'
              ELSE '营销部' END AS dimension_1
        ,CASE WHEN t4.datacopy IN ('正常') THEN '总体'
              WHEN t4.datacopy IN ('品牌') THEN brand
              WHEN t4.datacopy IN ('合计','品牌合计') THEN '合计'
              WHEN t4.datacopy IN ('内销合计') THEN '内销'
              WHEN t4.datacopy IN ('内外销') THEN COALESCE(t2.udp2, '其他')
              WHEN t4.datacopy LIKE '%工程营销部%' THEN CONCAT(COALESCE(t2.udp1, '其他'), '-', brand)
              ELSE COALESCE(t2.udp1, '其他') END AS dimension_2
        ,CASE WHEN t7.chanpinpinlei LIKE '%产品小类%' THEN COALESCE(t3.udp1, '其他')
              ELSE '合计' END AS dimension_3
        ,CASE WHEN t6.bzp_dzp = '正常' THEN biaozhun_dingzhi
              ELSE '合计' END AS dimension_4
        ,CASE WHEN t5.zhibiao_type IN ('在产','合计') THEN t5.zhibiao_type
              ELSE t1.zhibiao_type END AS zhibiao_type
        ,t1.koujing
        ,t1.ct
        ,t1.sales_qty
        ,t1.sales_amt
        ,t4.datacopy
    FROM sales_all t1
    LEFT JOIN (SELECT * FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '事业部') t2
        ON t1.dimension_2 = t2.udp1
    LEFT JOIN (SELECT * FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '产品小类') t3
        ON t1.dimension_3 = t3.udp1
    FULL JOIN weidu_datacopy t4 ON 1=1
    FULL JOIN (SELECT '在产' AS zhibiao_type UNION ALL SELECT '在售' AS zhibiao_type ) t5 ON 1=1
    FULL JOIN (SELECT '合计' AS bzp_dzp ) t6 ON 1=1
    FULL JOIN (SELECT '合计' AS chanpinpinlei UNION ALL SELECT '产品小类' AS chanpinpinlei) t7 ON 1=1
    WHERE CASE WHEN t4.datacopy LIKE '%内销合计%' THEN t2.udp2 IN ('内销TOC','内销TOB')
               WHEN t4.datacopy LIKE '%内外销%' THEN t2.udp2 IN ('内销TOC','内销TOB','外销')
               WHEN t4.datacopy LIKE '%工程营销部%' THEN COALESCE(t2.udp1, '其他') = '工程营销部'
               WHEN t5.zhibiao_type = '在产' THEN t1.zhibiao_type IN ('在售','退市')
               ELSE 1=1 END
        AND CASE WHEN t1.koujing = '内控' AND t4.datacopy LIKE '%考核%'
                 THEN t2.udp1 IN ('大客户部','工程营销部','日立家装营销部','海信家装营销部','约克家装营销部','海外技术支持部')
                 ELSE 1=1 END
)

-- act_value：最终聚合
,act_value AS (
    SELECT
        dt_month
        ,company
        ,product_line
        ,dt_type
        ,dimension_1
        ,dimension_2
        ,dimension_3
        ,dimension_4
        ,zhibiao_type
        ,koujing
        ,datacopy
        ,SUM(ct) AS ct
        ,SUM(sales_qty) AS sales_qty
        ,SUM(sales_amt) AS sales_amt
        ,SUM(sales_qty) / NULLIF(SUM(ct), 0.0) AS dxhxl
        ,SUM(sales_amt) / NULLIF(SUM(ct), 0.0) AS dxhxe
    FROM sales_all_jiagong
    GROUP BY dt_month, company, product_line, dt_type,
        dimension_1, dimension_2, dimension_3, dimension_4,
        zhibiao_type, koujing, datacopy
)

-- 最终SELECT
SELECT
    t1.dt_month
    ,'单型号销量' AS dimension_type
    ,t1.dt_type
    ,'海信日立' AS company
    ,'海信日立' AS product_line
    ,'全部' AS in_out_sale
    ,t1.dimension_1
    ,t1.dimension_2
    ,t1.dimension_3
    ,t1.dimension_4
    ,t1.zhibiao_type
    ,t1.koujing
    ,t2.ct
    ,t2.sales_qty
    ,t2.dxhxl
    ,NULL AS plan_dxhxl
    ,NULL AS completion_rate_dxhxl
    ,t2.sales_amt
    ,t2.dxhxe
    ,NULL AS plan_dxhxe
    ,NULL AS completion_rate_dxhxe
    ,NOW()
FROM weidu_all t1
LEFT JOIN act_value t2
    ON t1.dt_month = t2.dt_month
    AND t1.company = t2.company
    AND t1.product_line = t2.product_line
    AND t1.dt_type = t2.dt_type
    AND t1.dimension_1 = t2.dimension_1
    AND t1.dimension_2 = t2.dimension_2
    AND t1.dimension_3 = t2.dimension_3
    AND t1.zhibiao_type = t2.zhibiao_type
    AND t1.koujing = t2.koujing
;
