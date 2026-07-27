delete from ads.ads_ipd_ipm_platform_library_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','海信日立','视像科技')
and dt_type = '月'
and dimension_1 = '总体'
;
insert into ads.ads_ipd_ipm_platform_library_result_dd(
dt_month
,dt_type 
,company 
,product_line 
,dimension_1
,act_value 
,load_dt 
,act_cj	--实际值-创建状态
,act_lx	--实际值-立项状态
,act_kf	--实际值-开发状态
,act_qy	--实际值-迁移状态
,act_fb	--实际值-发布状态
,act_jx	--实际值-禁选状态
,act_tc	--实际值-停止生产
,act_zf	--实际值-作废
)

with company_product_line as (
select '冰箱公司' as company , '全部' as product_line union all 
select '冰箱公司' as company , '冰箱' as product_line union all 
select '冰箱公司' as company , '冷柜' as product_line union all 
select '洗衣机' as company , '洗衣机' as product_line union all 
select '海信日立' as company , '海信日立' as product_line union all 
select '空调公司' as company , '全部' as product_line union all 
select '空调公司' as company , '商用空调' as product_line union all 
select '空调公司' as company , '家用空调' as product_line union all 
select '视像科技' as company , '视像科技' as product_line 
)
,act_values as (
select 
dt_month
,company
,product_line
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and product_line in ('冰箱','冷柜','洗衣机','家用空调','商用空调','海信日立','视像科技')
and is_project = 'N'
group by dt_month
,product_line,company

union all 

select 
dt_month
,company
,case when company in ('空调公司','冰箱公司') then '全部' else product_line end as product_line
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and product_line in ('冰箱','冷柜','家用空调','商用空调')
and is_project = 'N'
group by dt_month
,case when company in ('空调公司','冰箱公司') then '全部' else product_line end
,company

)
,platform_state_values as (
select 
dt_month
,company
,product_line
,platform_state 
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and product_line in ('冰箱','冷柜','洗衣机','家用空调','商用空调','海信日立','视像科技')
and case when plan_product_line = '冰箱'  then coalesce (is_eurp_product,'否') <> '是'
else 1=1 end 
and coalesce (is_exclusive_only,'否') <> '是'
group by dt_month
,product_line,company,platform_state 

union all 

select 
dt_month
,company
,case when company in ('空调公司','冰箱公司') then '全部' else product_line end as product_line
,platform_state 
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and product_line in ('冰箱','冷柜','家用空调','商用空调')
and case when plan_product_line = '冰箱'  then coalesce (is_eurp_product,'否') <> '是'
else 1=1 end 
and coalesce (is_exclusive_only,'否') <> '是'
group by dt_month
,case when company in ('空调公司','冰箱公司') then '全部' else product_line end
,company,platform_state 
)
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,'月' as dt_type 
,t1.company
,t1.product_line
,'总体' as dimension_1
,t2.ct    --实际值
,now()
,t3.ct    --实际值-创建
,t4.ct    --实际值-立项
,t5.ct    --实际值-开发
,t6.ct    --实际值-迁移
,t7.ct    --实际值-发布
,t8.ct    --实际值-禁选
,t9.ct    --实际值-停产
,t10.ct   --实际值-作废
from company_product_line t1
left join act_values t2
on t1.company = t2.company
and t1.product_line = t2.product_line
--创建 立项 开发 迁移 发布 禁选 停产 作废
left join platform_state_values t3 
on t1.company = t3.company
and t1.product_line = t3.product_line
and t3.platform_state = '创建'
left join platform_state_values t4 
on t1.company = t4.company
and t1.product_line = t4.product_line
and t4.platform_state = '立项'
left join platform_state_values t5
on t1.company = t5.company
and t1.product_line = t5.product_line
and t5.platform_state = '开发'
left join platform_state_values t6 
on t1.company = t6.company
and t1.product_line = t6.product_line
and t6.platform_state = '迁移'
left join platform_state_values t7 
on t1.company = t7.company
and t1.product_line = t7.product_line
and t7.platform_state = '发布'
left join platform_state_values t8 
on t1.company = t8.company
and t1.product_line = t8.product_line
and t8.platform_state = '禁选'
left join platform_state_values t9 
on t1.company = t9.company
and t1.product_line = t9.product_line
and t9.platform_state = '停产'
left join platform_state_values t10 
on t1.company = t10.company
and t1.product_line = t10.product_line
and t10.platform_state = '作废'
;





delete from ads.ads_ipd_ipm_platform_library_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰箱公司','洗衣机','空调公司','海信日立','视像科技')
and dt_type = '年'
and dimension_1 = '总体'
;
insert into ads.ads_ipd_ipm_platform_library_result_dd(
dt_month
,dt_type 
,company 
,product_line 
,dimension_1 
,act_value 
,load_dt 
)

with company_product_line as (
select '冰箱公司' as company , '全部' as product_line union all 
select '冰箱公司' as company , '冰箱' as product_line union all 
select '冰箱公司' as company , '冷柜' as product_line union all 
select '洗衣机' as company , '洗衣机' as product_line union all 
select '海信日立' as company , '海信日立' as product_line union all 
select '空调公司' as company , '全部' as product_line union all 
select '空调公司' as company , '商用空调' as product_line union all 
select '空调公司' as company , '家用空调' as product_line union all 
select '视像科技' as company , '视像科技' as product_line 
)
,act_values as (
select 
company
,product_line
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
and product_line in ('冰箱','冷柜','洗衣机','家用空调','商用空调','海信日立','视像科技')
and is_project = 'N'
group by product_line,company

union all 

select 
company
,case when company in ('空调公司','冰箱公司') then '全部' else product_line end as product_line
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
and product_line in ('冰箱','冷柜','家用空调','商用空调')
and is_project = 'N'
group by case when company in ('空调公司','冰箱公司') then '全部' else product_line end
,company

)

select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,'年' as dt_type 
,t1.company
,t1.product_line
,'总体' as dimension_1
,t2.ct    --实际值
,now()
from company_product_line t1
left join act_values t2
on t1.company = t2.company
and t1.product_line = t2.product_line

;


delete from ads.ads_ipd_ipm_platform_library_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('海信日立')
and dt_type = '月'
and dimension_1 = '平台类型'
;
insert into ads.ads_ipd_ipm_platform_library_result_dd(
dt_month
,dt_type 
,company 
,product_line 
,dimension_1 
,dimension_2 
,act_value 
,load_dt 
,act_cj	--实际值-创建状态
,act_lx	--实际值-立项状态
,act_kf	--实际值-开发状态
,act_qy	--实际值-迁移状态
,act_fb	--实际值-发布状态
,act_jx	--实际值-禁选状态
,act_tc	--实际值-停止生产
,act_zf	--实际值-作废
)


with company_product_line as (
select '海信日立' as company , '海信日立' as product_line 
)
,act_values as (
select 
dt_month
,company
,product_line
,platform_classify 
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and product_line in ('海信日立')
and is_project = 'N'
group by dt_month
,product_line,company,platform_classify 


)
,platform_state_values as (
select 
dt_month
,company
,product_line
,platform_classify 
,platform_state 
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and product_line in ('海信日立')
group by dt_month
,product_line,company,platform_state ,platform_classify 


)
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,'月' as dt_type 
,t1.company
,t1.product_line
,'平台类型' as dimension_1
,t2.platform_classify
,t2.ct    --实际值
,now()
,t3.ct    --实际值-创建
,t4.ct    --实际值-立项
,t5.ct    --实际值-开发
,t6.ct    --实际值-迁移
,t7.ct    --实际值-发布
,t8.ct    --实际值-禁选
,t9.ct    --实际值-停产
,t10.ct   --实际值-作废
from company_product_line t1
left join act_values t2
on t1.company = t2.company
and t1.product_line = t2.product_line
--创建 立项 开发 迁移 发布 禁选 停产 作废
left join platform_state_values t3 
on t1.company = t3.company
and t1.product_line = t3.product_line
and t2.platform_classify = t3.platform_classify
and t3.platform_state = '创建'
left join platform_state_values t4 
on t1.company = t4.company
and t1.product_line = t4.product_line
and t2.platform_classify = t4.platform_classify
and t4.platform_state = '立项'
left join platform_state_values t5
on t1.company = t5.company
and t1.product_line = t5.product_line
and t2.platform_classify = t5.platform_classify
and t5.platform_state = '开发'
left join platform_state_values t6 
on t1.company = t6.company
and t1.product_line = t6.product_line
and t2.platform_classify = t6.platform_classify
and t6.platform_state = '迁移'
left join platform_state_values t7 
on t1.company = t7.company
and t1.product_line = t7.product_line
and t2.platform_classify = t7.platform_classify
and t7.platform_state = '发布'
left join platform_state_values t8 
on t1.company = t8.company
and t1.product_line = t8.product_line
and t2.platform_classify = t8.platform_classify
and t8.platform_state = '禁选'
left join platform_state_values t9 
on t1.company = t9.company
and t1.product_line = t9.product_line
and t2.platform_classify = t9.platform_classify
and t9.platform_state = '停产'
left join platform_state_values t10 
on t1.company = t10.company
and t1.product_line = t10.product_line
and t2.platform_classify = t10.platform_classify
and t10.platform_state = '作废'
;





delete from ads.ads_ipd_ipm_platform_library_result_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('海信日立')
and dt_type = '年'
and dimension_1 = '平台类型'
;
insert into ads.ads_ipd_ipm_platform_library_result_dd(
dt_month
,dt_type 
,company 
,product_line 
,dimension_1 
,dimension_2 
,act_value 
,load_dt 
)

with company_product_line as (
select '海信日立' as company , '海信日立' as product_line 
)
,act_values as (
select 
company
,product_line
,platform_classify 
,count(distinct platform) as ct
from dws.dws_ipd_ipm_platform_library_detail_dd 
where dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
and product_line in ('海信日立')
and is_project = 'N'
group by product_line,company,platform_classify 

)

select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month 
,'年' as dt_type 
,t1.company
,t1.product_line
,'平台类型' as dimension_1
,t2.platform_classify 
,t2.ct    --实际值
,now()
from company_product_line t1
left join act_values t2
on t1.company = t2.company
and t1.product_line = t2.product_line

;



