-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/03/04 16:02:35 GMT+08:00
-- [CHANGE] 新增厨电产品线（CHG-02 产品线扩展）
-- ******************************************************************** --
delete from ads.ads_ipd_ipm_dxmodel_result_dd
where product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','中央空调','厨电')
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '低效型号数' 
and dimension_1 = '总体'
and zhibiao_type = '2'
;
insert into ads.ads_ipd_ipm_dxmodel_result_dd(
dt_month 
,dimension_type 
,business_division
,product_line 
,in_out_sale 
,zhibiao_type 
,dimension_1
,act_value 
,all_num 
,dxmodel_rate 
,plan_dxmodel_rate
,completion_dxmodel_rate
,load_dt 
)
with product_line_weidu as ( 
select 
udp1 as business_division
,udp2 as product_line
,udp3 as in_out_sale
from dim.dim_ipd_td_weidu_nd
where zhibiao = '低效型号数'
and udp2 in ('冰箱','冷柜','洗衣机','平板电视','家用空调','中央空调','厨电')
)
,dt_month_weidu as (
select distinct year_mth as  dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,all_weidu as ( 
select 
t1.business_division
,t1.product_line
,t1.in_out_sale
,t2.dt_month
,'2' as zhibiao_type
from product_line_weidu t1 ,dt_month_weidu t2 
)
,dxmodel_ct as ( 
select 
dt_month 
,business_division
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end as in_out_sale
,zhibiao_type 
,count(distinct coalesce (prdct_model,project_code)) as act_vale 
from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and case when product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','厨电') then in_out_sale = '内销'
when product_line in ('中央空调') then 1=1
else 1=0 end
and is_project = 'N'
and is_dx = 'Y'
and coalesce (model_label_23,'Y') = 'Y' --空气是否指标考核口径
group by dt_month 
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end
,zhibiao_type 
,business_division
)
,model as (
select 
dt_month 
,business_division
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end as in_out_sale
,zhibiao_type 
,count(distinct coalesce (prdct_model,project_code)) as act_vale 
from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') 
and zhibiao_type = '2'
and case when product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','厨电') then in_out_sale = '内销'
when product_line in ('中央空调') then 1=1
else 1=0 end
and is_project = 'N'
and coalesce (model_label_23,'Y') = 'Y' --空气是否指标考核口径
group by dt_month 
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end 
,zhibiao_type 
,business_division
) 
,plan_value as (
--低效型号数计划值
select distinct
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.低效型号数[0].text')as DECIMALV3(20,4)) dixiaoxinghaoshu
,cast(get_json_string(record_data,'$.总型号数[0].text')as DECIMALV3(20,4)) zongxinghaoshu
,cast(get_json_string(record_data,'$.低效型号占比计划值.value[0]')as DECIMALV3(20,4)) dixiaoxinghaozhanbijihuazhi
,cast(get_json_string(record_data,'$.规划命中新品数')as DECIMALV3(20,4)) guihuamingzhongxinpinshu
,cast(get_json_string(record_data,'$.新品期总型号数')as DECIMALV3(20,4)) xinpinqizongxinghaoshu
,cast(get_json_string(record_data,'$.新品命中率计划值.value[0]')as DECIMALV3(20,4)) xinpinmingzhonglvjihuazhi
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tbl8PBYKby97MVvy

)
select
t0.dt_month
,'低效型号数' as dimension_type
,t0.business_division
,t0.product_line
,t0.in_out_sale
,t0.zhibiao_type
,'总体' as dimension_1
,t2.act_vale  --实际值
,t1.act_vale  --全部值
,t2.act_vale/nullif(t1.act_vale,0.0)   --低效型号数占比
,t3.dixiaoxinghaozhanbijihuazhi  --低效型号数占比计划值
,((1-(t2.act_vale/nullif(t1.act_vale,0.0)))/nullif(1-t3.dixiaoxinghaozhanbijihuazhi,0))   --低效型号数占比完成率
,now()
from all_weidu t0 
left join model t1 
on t0.product_line = t1.product_line
and t0.business_division = t1.business_division
and t0.dt_month = t1.dt_month
and t0.in_out_sale = t1.in_out_sale
and t0.zhibiao_type = t1.zhibiao_type
left join dxmodel_ct t2 
on t1.dt_month = t2.dt_month
and t1.business_division = t2.business_division
and t1.product_line = t2.product_line
and t1.in_out_sale = t2.in_out_sale
and t1.zhibiao_type = t2.zhibiao_type
left join plan_value t3 
on t0.product_line = t3.fenzu
and t0.business_division = t3.shiyebu
and t0.in_out_sale = t3.neiwaixiao
and t0.dt_month = t3.dt_month
;


--总体
delete from ads.ads_ipd_ipm_dxmodel_result_dd
where business_division in ('空气事业部','集团汇总','冰冷事业部')
and product_line = '全部'
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '低效型号数'
and dimension_1 = '总体'
and zhibiao_type = '2'
;
insert into ads.ads_ipd_ipm_dxmodel_result_dd(
dt_month 
,dimension_type 
,business_division
,product_line 
,in_out_sale
,zhibiao_type 
,dimension_1
,act_value 
,all_num 
,dxmodel_rate 
,plan_dxmodel_rate
,completion_dxmodel_rate
,load_dt 
)
with product_line_weidu as ( 
select 
udp1 as business_division
,udp2 as product_line
,udp3 as in_out_sale
from dim.dim_ipd_td_weidu_nd
where zhibiao = '低效型号数'
and case when udp1 in ('空气事业部','冰冷事业部') then udp2 = '全部' 
when udp1 in ('集团汇总') then 1=1
else 1=0 end 
)
,dt_month_weidu as (
select distinct year_mth as  dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,all_weidu as ( 
select 
t1.business_division
,t1.product_line 
,t1.in_out_sale
,t2.dt_month
,'2' as zhibiao_type
from product_line_weidu t1 ,dt_month_weidu t2 
)
,plan_value as  (
--低效型号数计划值

select distinct 
get_json_string(record_data,'$.事业部[0].text') shiyebu
,get_json_string(record_data,'$.分组[0].text') fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.低效型号数[0].text')as DECIMALV3(20,4)) dixiaoxinghaoshu
,cast(get_json_string(record_data,'$.总型号数[0].text')as DECIMALV3(20,4)) zongxinghaoshu
,cast(get_json_string(record_data,'$.低效型号占比计划值.value[0]')as DECIMALV3(20,4)) dixiaoxinghaozhanbijihuazhi
,cast(get_json_string(record_data,'$.规划命中新品数')as DECIMALV3(20,4)) guihuamingzhongxinpinshu
,cast(get_json_string(record_data,'$.新品期总型号数')as DECIMALV3(20,4)) xinpinqizongxinghaoshu
,cast(get_json_string(record_data,'$.新品命中率计划值.value[0]')as DECIMALV3(20,4)) xinpinmingzhonglvjihuazhi
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tbl8PBYKby97MVvy

)
,all_values as ( 
select 
dt_month 
,dimension_type 
,'集团汇总' as business_division
,'全部' as product_line 
,null as in_out_sale
,zhibiao_type 
,dimension_1
,sum(act_value) as  act_value
,sum(all_num) as  all_num
,sum(act_value)/nullif(sum(all_num),0.0) as dxmodel_rate 
--,null as plan_dxmodel_rate
--,completion_dxmodel_rate
from ads.ads_ipd_ipm_dxmodel_result_dd  
where product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','中央空调','厨电')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '低效型号数' 
and coalesce (dimension_1,'总体') = '总体'
and coalesce (dimension_2,'总体') = '总体'
and coalesce (dimension_3,'总体') = '总体'
group by dt_month 
,dimension_type 
,zhibiao_type 
,dimension_1

union all

select 
dt_month 
,dimension_type 
,business_division
,'全部' as product_line
,null as in_out_sale
,zhibiao_type 
,dimension_1
,sum(act_value) as  act_value
,sum(all_num) as  all_num
,sum(act_value)/nullif(sum(all_num),0.0) as dxmodel_rate 
from ads.ads_ipd_ipm_dxmodel_result_dd  
where product_line in ('家用空调','中央空调')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '低效型号数' 
and coalesce (dimension_1,'总体') = '总体'
and coalesce (dimension_2,'总体') = '总体'
and coalesce (dimension_3,'总体') = '总体'
group by dt_month 
,dimension_type 
,zhibiao_type 
,dimension_1
,business_division


union all

select 
dt_month 
,dimension_type 
,business_division
,'全部' as product_line
,in_out_sale
,zhibiao_type 
,dimension_1
,sum(act_value) as  act_value
,sum(all_num) as  all_num
,sum(act_value)/nullif(sum(all_num),0.0) as dxmodel_rate 
from ads.ads_ipd_ipm_dxmodel_result_dd  
where product_line in ('冰箱','冷柜')
and in_out_sale = '内销'
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '低效型号数' 
and coalesce (dimension_1,'总体') = '总体'
and coalesce (dimension_2,'总体') = '总体'
and coalesce (dimension_3,'总体') = '总体'
group by dt_month 
,dimension_type 
,zhibiao_type 
,dimension_1
,business_division
,in_out_sale
)
select 
t0.dt_month 
,'低效型号数' as dimension_type 
,t0.business_division
,t0.product_line 
,t0.in_out_sale
,t0.zhibiao_type 
,coalesce (t1.dimension_1,'总体')
,t1.act_value
,t1.all_num
,t1.dxmodel_rate 
,t2.dixiaoxinghaozhanbijihuazhi
,(1-t1.dxmodel_rate)/nullif(1-t2.dixiaoxinghaozhanbijihuazhi,0) --低效型号数占比完成率
,now()
from all_weidu t0
left join all_values t1 
on t0.dt_month = t1.dt_month
and t0.product_line = t1.product_line
and t0.business_division = t1.business_division
and t0.zhibiao_type = t1.zhibiao_type
left join plan_value t2 
on t0.product_line = t2.fenzu
and t0.dt_month = t2.dt_month
and t0.business_division = t2.shiyebu
;









------------------------------------------------------------------------新品规划命中率------------------------------------------------------------------

delete from ads.ads_ipd_ipm_dxmodel_result_dd
where product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','中央空调','厨电')
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '新品规划命中率' 
and dimension_1 = '总体'
and zhibiao_type = '4'
;
insert into ads.ads_ipd_ipm_dxmodel_result_dd(
dt_month 
,dimension_type 
,business_division
,product_line 
,in_out_sale 
,zhibiao_type 
,dimension_1
,act_value 
,all_num 
,dxmodel_rate 
,plan_dxmodel_rate
,completion_dxmodel_rate
,load_dt 
)
with product_line_weidu as ( 
select 
udp1 as business_division
,udp2 as product_line
,udp3 as in_out_sale
from dim.dim_ipd_td_weidu_nd
where zhibiao = '新品规划命中率'
and udp2 in ('冰箱','冷柜','洗衣机','平板电视','家用空调','中央空调','厨电')
)
,dt_month_weidu as (
select distinct year_mth as  dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,all_weidu as ( 
select 
t1.business_division
,t1.product_line
,t1.in_out_sale
,t2.dt_month
,'4' as zhibiao_type
from product_line_weidu t1 ,dt_month_weidu t2 
)
,dxmodel_ct as ( 
select 
dt_month 
,business_division
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end as in_out_sale
,zhibiao_type 
,count(distinct coalesce (prdct_model,project_code)) as act_vale 
from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and case when product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','厨电') then in_out_sale = '内销'
when product_line in ('中央空调') then 1=1
else 1=0 end
and is_project = 'N'
and is_dx = 'N'
and coalesce (model_label_23,'Y') = 'Y' --空气是否指标考核口径
group by dt_month 
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end
,zhibiao_type 
,business_division
)
,model as (
select 
dt_month 
,business_division
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end as in_out_sale
,zhibiao_type 
,count(distinct coalesce (prdct_model,project_code)) as act_vale 
from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') 
and zhibiao_type = '4'
and case when product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','厨电') then in_out_sale = '内销'
when product_line in ('中央空调') then 1=1
else 1=0 end
and is_project = 'N'
and coalesce (model_label_23,'Y') = 'Y' --空气是否指标考核口径
group by dt_month 
,product_line 
,case when product_line ='中央空调' then '全部' else in_out_sale end 
,zhibiao_type 
,business_division
) 
,plan_value as (
--低效型号数计划值
select distinct
get_json_string(record_data,'$.事业部[0].text') shiyebu
,case when get_json_string(record_data,'$.事业部[0].text') = '洗护事业部' and get_json_string(record_data,'$.分组[0].text') = '全部' then '洗衣机'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '央空' then '中央空调'
when get_json_string(record_data,'$.事业部[0].text') = '空气事业部' and get_json_string(record_data,'$.分组[0].text') = '家空' then '家用空调'
else get_json_string(record_data,'$.分组[0].text') end fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.低效型号数[0].text')as DECIMALV3(20,4)) dixiaoxinghaoshu
,cast(get_json_string(record_data,'$.总型号数[0].text')as DECIMALV3(20,4)) zongxinghaoshu
,cast(get_json_string(record_data,'$.低效型号占比计划值.value[0]')as DECIMALV3(20,4)) dixiaoxinghaozhanbijihuazhi
,cast(get_json_string(record_data,'$.规划命中新品数')as DECIMALV3(20,4)) guihuamingzhongxinpinshu
,cast(get_json_string(record_data,'$.新品期总型号数')as DECIMALV3(20,4)) xinpinqizongxinghaoshu
,cast(get_json_string(record_data,'$.新品命中率计划值.value[0]')as DECIMALV3(20,4)) xinpinmingzhonglvjihuazhi
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tbl8PBYKby97MVvy
)
select
t0.dt_month
,'新品规划命中率' as dimension_type
,t0.business_division
,t0.product_line
,t0.in_out_sale
,t0.zhibiao_type
,'总体' as dimension_1
,t2.act_vale  --实际值
,t1.act_vale  --全部值
,t2.act_vale/nullif(t1.act_vale,0.0)   --新品规划命中率占比
,t3.xinpinmingzhonglvjihuazhi  --新品规划命中率占比计划值
,((t2.act_vale/nullif(t1.act_vale,0.0))/nullif(t3.xinpinmingzhonglvjihuazhi,0))   --新品规划命中率占比完成率
,now()
from all_weidu t0 
left join model t1 
on t0.product_line = t1.product_line
and t0.business_division = t1.business_division
and t0.dt_month = t1.dt_month
and t0.in_out_sale = t1.in_out_sale
and t0.zhibiao_type = t1.zhibiao_type
left join dxmodel_ct t2 
on t1.dt_month = t2.dt_month
and t1.business_division = t2.business_division
and t1.product_line = t2.product_line
and t1.in_out_sale = t2.in_out_sale
and t1.zhibiao_type = t2.zhibiao_type
left join plan_value t3 
on t0.product_line = t3.fenzu
and t0.business_division = t3.shiyebu
and t0.in_out_sale = t3.neiwaixiao
and t0.dt_month = t3.dt_month

;


--总体
delete from ads.ads_ipd_ipm_dxmodel_result_dd
where business_division in ('空气事业部','集团汇总','冰冷事业部')
and product_line = '全部'
and dt_month >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '新品规划命中率'
and dimension_1 = '总体'
and zhibiao_type = '4'
;
insert into ads.ads_ipd_ipm_dxmodel_result_dd(
dt_month 
,dimension_type 
,business_division
,product_line 
,in_out_sale
,zhibiao_type 
,dimension_1
,act_value 
,all_num 
,dxmodel_rate 
,plan_dxmodel_rate
,completion_dxmodel_rate
,load_dt 
)
with product_line_weidu as ( 
select 
udp1 as business_division
,udp2 as product_line
,udp3 as in_out_sale
from dim.dim_ipd_td_weidu_nd
where zhibiao = '新品规划命中率'
and case when udp1 in ('空气事业部','冰冷事业部') then udp2 = '全部' 
when udp1 in ('集团汇总') then 1=1
else 1=0 end 
)
,dt_month_weidu as (
select distinct year_mth as  dt_month  from dw.dim_date_nd
where year_mth >= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and cal_year = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)
,all_weidu as ( 
select 
t1.business_division
,t1.product_line 
,t1.in_out_sale
,t2.dt_month
,'4' as zhibiao_type
from product_line_weidu t1 ,dt_month_weidu t2 
)
,plan_value as  (
--低效型号数计划值

select distinct
get_json_string(record_data,'$.事业部[0].text') shiyebu
,get_json_string(record_data,'$.分组[0].text') fenzu
,get_json_string(record_data,'$.内/外销[0].text') neiwaixiao
,get_json_string(record_data,'$.年份[0].text') nianfen
,lpad(get_json_string(record_data,'$.月份[0].text'),2,0) yuefen
,concat(get_json_string(record_data,'$.年份[0].text'),lpad(get_json_string(record_data,'$.月份[0].text'),2,0)) dt_month
,cast(get_json_string(record_data,'$.低效型号数[0].text')as DECIMALV3(20,4)) dixiaoxinghaoshu
,cast(get_json_string(record_data,'$.总型号数[0].text')as DECIMALV3(20,4)) zongxinghaoshu
,cast(get_json_string(record_data,'$.低效型号占比计划值.value[0]')as DECIMALV3(20,4)) dixiaoxinghaozhanbijihuazhi
,cast(get_json_string(record_data,'$.规划命中新品数')as DECIMALV3(20,4)) guihuamingzhongxinpinshu
,cast(get_json_string(record_data,'$.新品期总型号数')as DECIMALV3(20,4)) xinpinqizongxinghaoshu
,cast(get_json_string(record_data,'$.新品命中率计划值.value[0]')as DECIMALV3(20,4)) xinpinmingzhonglvjihuazhi
from ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tbl8PBYKby97MVvy
)
,all_values as ( 
select 
dt_month 
,dimension_type 
,'集团汇总' as business_division
,'全部' as product_line 
,null as in_out_sale
,zhibiao_type 
,dimension_1
,sum(act_value) as  act_value
,sum(all_num) as  all_num
,sum(act_value)/nullif(sum(all_num),0.0) as dxmodel_rate 
--,null as plan_dxmodel_rate
--,completion_dxmodel_rate
from ads.ads_ipd_ipm_dxmodel_result_dd  
where product_line in ('冰箱','冷柜','洗衣机','家用空调','平板电视','中央空调','厨电')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '新品规划命中率' 
and coalesce (dimension_1,'总体') = '总体'
and coalesce (dimension_2,'总体') = '总体'
and coalesce (dimension_3,'总体') = '总体'
group by dt_month 
,dimension_type 
,zhibiao_type 
,dimension_1

union all

select 
dt_month 
,dimension_type 
,business_division
,'全部' as product_line
,null as in_out_sale
,zhibiao_type 
,dimension_1
,sum(act_value) as  act_value
,sum(all_num) as  all_num
,sum(act_value)/nullif(sum(all_num),0.0) as dxmodel_rate 
from ads.ads_ipd_ipm_dxmodel_result_dd  
where product_line in ('家用空调','中央空调')
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '新品规划命中率' 
and coalesce (dimension_1,'总体') = '总体'
and coalesce (dimension_2,'总体') = '总体'
and coalesce (dimension_3,'总体') = '总体'
group by dt_month 
,dimension_type 
,zhibiao_type 
,dimension_1
,business_division


union all

select 
dt_month 
,dimension_type 
,business_division
,'全部' as product_line
,in_out_sale
,zhibiao_type 
,dimension_1
,sum(act_value) as  act_value
,sum(all_num) as  all_num
,sum(act_value)/nullif(sum(all_num),0.0) as dxmodel_rate 
from ads.ads_ipd_ipm_dxmodel_result_dd  
where product_line in ('冰箱','冷柜')
and in_out_sale = '内销'
and dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dimension_type = '新品规划命中率' 
and coalesce (dimension_1,'总体') = '总体'
and coalesce (dimension_2,'总体') = '总体'
and coalesce (dimension_3,'总体') = '总体'
group by dt_month 
,dimension_type 
,zhibiao_type 
,dimension_1
,business_division
,in_out_sale
)
select 
t0.dt_month 
,'新品规划命中率' as dimension_type 
,t0.business_division
,t0.product_line 
,t0.in_out_sale
,t0.zhibiao_type 
,coalesce (t1.dimension_1,'总体')
,t1.act_value
,t1.all_num
,t1.dxmodel_rate 
,t2.xinpinmingzhonglvjihuazhi
,t1.dxmodel_rate/nullif(t2.xinpinmingzhonglvjihuazhi,0) --新品规划命中率占比完成率
,now()
from all_weidu t0
left join all_values t1 
on t0.dt_month = t1.dt_month
and t0.product_line = t1.product_line
and t0.business_division = t1.business_division
and t0.zhibiao_type = t1.zhibiao_type
left join plan_value t2 
on t0.product_line = t2.fenzu
and t0.dt_month = t2.dt_month
and t0.business_division = t2.shiyebu
;
