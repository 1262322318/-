-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
-- DORIS sql 
-- ******************************************************************** --
-- 厨电事业部 - 低效型号数占比 DWS层明细（副本草稿）
-- 参照：冰冷洗 内销低效型号数 逻辑（zhibiao_type = '2'）
-- 说明：业务逻辑等同冰箱产品线，仅筛选范围调整为厨电
--       产品线通过HX00223字段判定
--       规划量：本年上市用LX，其他用BP，LX不低于BP
--       实际销量：本年度1月至当前月累计
--       无ODM剔除（所有海信系产品，无剔除）
-- 状态：待用户确认后插入正式脚本 dws_ipd_ipm_dxmodel_detail_dd.sql
-- ******************************************************************** --

--厨电 内销低效型号数
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,prdct_model	--型号名
,ir_act_time	--鉴定评审时间（实际上市时间）
,juece_delistingtime	--下市时间（实际退市准备时间）
,act_sales_qty	--实际销量
,plan_sales_qty	--规划销量
,sales_qty_rate	--销量完成率
,act_sales_amt	--实际销额
,plan_sales_amt	--规划销额
,sales_amt_rate	--销额完成率
,act_gross_profit --实际毛利额
,plan_gross_profit  --规划毛利额
,gross_profit_rate  --毛利额完成率
,act_gross_margin  --实际毛利率
,distribution_channel --销售渠道
,product_positioning --产品定位
,platform   --平台
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,menlei  --门类
,pinleixifen--品类细分
,shangshi_m--上市月份
,is_odm --是否odm
,is_dx	--是否低效
,is_project	--是否保护期
,model_label_2  --上市周期
,load_dt	--加载日期
)




with all_model as (
select 
product_line  --产品线（来自HX00223）
,PG00061 --名称
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,PG00025  --实际上市时间
,HX00501  --实际退市准备时间
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(PG00025)) as shangshi_m
,PG00029	--产品型号生命周期状态
--厨电无ODM剔除
,'N' as is_odm
--厨电保护期判定
,case 
--剔除空壳机
when PG00061 like '%空壳机%' then 'Y'
--剔除配件（中类为吸油烟机配件）
when PG00003 = '吸油烟机配件' then 'Y'
--品牌非Hisense剔除
when coalesce(PG00005,'') <> 'Hisense' then 'Y'
--只选上市且未决策退市的
when not(PG00025 is not null and HX00501 is null) then 'Y'
else 'N' end as is_project
from ( 
select 
id
,PG00061	--名称
--厨电产品线：直接使用HX00223字段
,case when HX00223 in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱') then HX00223
else '其他' end as product_line
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,PC10050    --门类
,PC00001    --品类细分
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间（本月退市置NULL）
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间（本月上市置NULL）
from dim.dim_ipd_productmodel_dd t1  --产品型号
)t1 
where product_line in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')
and PG00020 = '内销'
)
,guanbao_sales as ( 
--管报实际销量（本年度1月至当前月累计）
select 
matnr 
,sum(sale_qty) as sale_qty
,sum(rev_amt) as rev_amt
,sum(cost_amt) as chengben 
,sum(rev_amt) - sum(cost_amt) as maolie 
from ods.ods_mr_v_app_fm_imat_saledata ovafis 
where substring(yearmonth,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by matnr

) 
,guanbao_sales_2 as (
--通过MDG映射到产品型号名称
select t2.model_name as productmodel
,sum(t1.sale_qty) sale_qty --实际销量
,sum(t1.rev_amt) rev_amt  --实际销额
,sum(t1.chengben) chengben --实际成本
,sum(t1.maolie) maolie  --毛利额
from guanbao_sales t1 
left join (select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y') t2 
on t1.matnr = t2.product_code
group by t2.model_name

)
,plan_sales as (
--取本年规划销量（BP+LX处理）
--整体逻辑：①本年度上市产品，取立项目标销量(LX)；②其他产品取本年度BP目标销量；③LX不低于BP
select 
coalesce (t1.prdct_model ,t2.prdct_model) as prdct_model
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_qty else t1.plan_sales_qty end ) as plan_sales_qty
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_amt else t1.plan_sales_amt end ) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit

from (
--BP规划量（HDRP来源）
select 
prdct_model 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and model_label_1 = 'HDRP'
group by prdct_model 
,product_line 
,dt_month 

) t1 
full join (
--LX立项规划量（厨电：product_big IN ('供热采暖类产品','厨房电器类产品')）
select 
prdct_model 
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
,max(plan_gross_margin ) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('供热采暖类产品','厨房电器类产品')
group by prdct_model 
,product_line 
,dt_month 
)t2
on t1.prdct_model = t2.prdct_model
and t1.dt_month = t2.dt_month
left join  (
--最小的立项规划销量月份作为首次上市月份
select 
PG00061
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from all_model
group by PG00061
,product_line 
) t3
on coalesce (t1.prdct_model ,t2.prdct_model) = t3.PG00061
where substring(coalesce (t1.dt_month ,t2.dt_month),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') --限制取出本年的数据
and coalesce (t1.dt_month ,t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')  --限制取出本年内本月之前的数据
--新增滞后上市以实际上市时间开始算累计BP目标销量
and coalesce (t1.dt_month ,t2.dt_month) >= coalesce (t3.min_dtmonth ,'190001')  --防止出现老品没有上市时间 空置异常问题
group by coalesce (t1.prdct_model ,t2.prdct_model)
)

select 
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'厨电事业部' as business_division   --事业部
,t1.product_line  --产品线
,t1.PG00020	--内销/外销
,'2' as zhibiao_type -- 本年累计低效型号数
,t1.PG00061 --名称
,t1.PG00025  --实际上市时间
,t1.HX00501  --实际退市准备时间
,t2.sale_qty  --实际销量（本年累计）
,t3.plan_sales_qty   --计划销量（BP+LX）
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)   --销量完成率
,t2.rev_amt   --实际销额
,t3.plan_sales_amt  --计划销额
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)   --销额完成率
,t2.maolie   --毛利额
,t3.plan_gross_profit   --规划毛利额
,t2.maolie/nullif(t3.plan_gross_profit,0.0)   --毛利额完成率
,t2.maolie/nullif(t2.rev_amt,0.0)  --实际毛利率
,t1.PG00021	--规划销售渠道
,t1.PG00019	--产品定位
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
,t1.PC10050    --门类
,t1.PC00001    --品类细分
,t1.shangshi_m  --上市月份
,t1.is_odm
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   --<0.8为低效
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核（第4个月开始）
else t1.is_project end as is_project  --是否保护期
,case when t1.shangshi_m <= 3 then '[0,3]'
when t1.shangshi_m <= 6 then '(3,6]'
when t1.shangshi_m <= 12 then '(6,12]'
when t1.shangshi_m > 12 then '(12,)'
else '其他' end model_label_2  --上市周期
,now()
from all_model t1 
left join guanbao_sales_2 t2 
on t1.PG00061 = t2.productmodel
left join plan_sales t3 
on t1.PG00061 = t3.prdct_model
;
