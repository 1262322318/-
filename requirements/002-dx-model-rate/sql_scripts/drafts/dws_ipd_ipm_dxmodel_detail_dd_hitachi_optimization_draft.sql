/*
 * ============================================================
 * 草稿：海信日立产品效率看板优化（合并版）
 * 【状态：✅ 已合入正式脚本  合入日期：2026-06-11】
 * ============================================================
 * 目标脚本：dws_ipd_ipm_dxmodel_detail_dd.sql
 * 变更概述：
 *   Part 1：型号口径-低效型号数(zhibiao_type='2') —— 替换原约932~1188行
 *   Part 2：型号口径-新品命中率(zhibiao_type='4') —— 替换原约1806~2042行
 *   Part 3：项目口径二级维度(zhibiao_type='2-1'/'2-2'/'2-3'/'4-1'/'4-2') —— 新增段落
 *
 * 变更要点：
 *   - sale_model CTE：外销品牌WHERE扩展、新增is_project_nk（含品牌控制）、新增6个字段
 *   - is_project集团逻辑：新增外销品牌排除
 *   - INSERT字段列表+SELECT：新增10个字段
 *   - zhibiao_type='4'专属：新增is_db_qty/is_db_amt/is_db_margin达标判定
 *   - 项目口径：新增5个二级维度段落（仅中央空调）
 * ============================================================
 */


-- ============================================================
-- Part 1：型号口径 低效型号数 (zhibiao_type='2')
-- 合入位置：替换原"空气事业部 低效型号数 海信日立"段落
-- 注意：原有的DELETE语句保持不变，本草稿只包含INSERT部分
-- ============================================================
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line in ('中央空调')
;
--空气事业部 低效型号数  海信日立
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,data_type  
,prdct_model	--型号名
,salemodel_code
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
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
,pg00015--产品公司
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,shangshi_m--上市月份
,project_code  --项目编码
,project_name --项目名称
,salemodel	--销售型号名称
,pc20080	--归属营销部
,hx00379	--是否模块组合
,is_dx	--是否低效
,is_project	--是否保护期
,is_project_nk  --是否保护期-内控口径【新增】
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,model_label_23   --空气是否指标考核口径
,PC20006    --标准品/定制产品
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
,HX00327    --所有者【新增】
,PG00039    --营销定位【新增】
,HX00339    --主要销售渠道【新增】
,productmodel_life  --销售型号生命周期状态【新增】
,PG00009    --产品系列【新增】
,shangshi_y --上市年数【新增】
,is_db_qty  --销量是否达标【低效型号数填NULL】
,is_db_amt  --销额是否达标【低效型号数填NULL】
,is_db_margin --毛利率是否达标【低效型号数填NULL】
)
--空气事业部  海信日立
with sale_model as (
select 
'中央空调' as product_line
,t1.kt_nbzz  --空调内部组织
,t2.PG00020	--内销/外销
,t1.PG00025    --实际上市时间
,t1.HX00501    --实际退市准备时间
,t1.PG00026    --停止下单时间
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.productmodel  --产品型号名称
,t1.PG00072    --产品档次
,t1.PC00025	--规划生产基地
,t1.PG00069    --销售品牌
,t2.PG00015   --产品公司
,t1.productmodel_id --产品型号id
,t1.PG00061    --销售型号名称
,t1.PG00068    --销售型号编码
,t1.PC20080   --归属营销部
,t1.HX00379   --是否模块组合
,t1.PC20006    --标准品/定制产品
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(t1.PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(t1.PG00025)) as shangshi_m
,t1.project_code --项目编码
,t1.project_name--项目名称
--集团逻辑 is_project（新增外销品牌控制）
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense') then 'Y'
else 'N' end as is_project
--【新增】内控逻辑 is_project_nk（营销部扩展+外销品牌扩展）
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部','海外业务部(大客户)','水机营销部','海外业务部(水系统)') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense','HITACHI','YORK') then 'Y'
else 'N' end as is_project_nk
,t2.PG00021	--规划销售渠道
,t2.PG00019	--产品定位
--【新增】5个字段
,t1.HX00327    --所有者
,t1.PG00039    --营销定位
,t1.HX00339    --主要销售渠道
,t1.PG00057    --销售型号生命周期状态
,t1.PG00009    --产品系列
from (
select 
PG00061    --名称
,id
,productmodel_id --产品型号id
,productmodel --产品型号名称
,PG00068    --销售型号编码
,PG00072    --产品档次
,'中央空调'  as kt_nbzz
,PG00069    --销售品牌
,PG00057    --销售型号生命周期状态
,PG00042    --销售渠道
,PG00041    --销售国家及地区
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501 --实际退市准备时间
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025 --实际上市时间
,PG00027    --停止生产时间
,case when PG00026 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00026 end as PG00026    --停止下单时间
,HX00378    --实际停止下单时间
,PG00004    --产品小类
,PG00003    --产品中类
,PG00002    --产品大类
,PG00015    --产品公司
,PG00014    --产品平台
,PC20080    --归属营销部
,HX00379    --是否模块组合
,HX00370    --内机箱体
,PC20085    --整机产品平台
,PC20006    --标准品/定制产品
,project_code --项目编码
,project_name --项目名称
,PC00025	--规划生产基地
--【新增】取5个字段
,HX00327    --所有者
,PG00039    --营销定位
,HX00339    --主要销售渠道
,PG00009    --产品系列
from dim.dim_ipd_salemodel_dd t1 
where pg00002 = '空气调节类产品'
and pg00003 = '中央空调'
and pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机')
) t1
left join dim.dim_ipd_productmodel_dd t2 
on t1.productmodel_id = t2.id
where t1.kt_nbzz in ('中央空调')
--【修改】外销品牌扩展（品牌控制已在is_project/is_project_nk的CASE中处理）
and case when t2.PG00020 = '内销' then t1.PG00069 in ('Hisense','HITACHI','YORK','KELON') when t2.PG00020 = '外销' then t1.PG00069 in ('Hisense','HITACHI','YORK') else 1=2 end 
)
,all_sales as (
--日立实际销量（年累）
select 
t2.sale_model_code
,sum(sale_qty ) as sale_qty
,sum(rev_amt ) as rev_amt
,sum(cost_amt) as chengben
,sum(rev_amt ) - sum(cost_amt) as maolie
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (
select 
product_code
,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO')
and delete_flag!='Y'
) t2 
on t1.matnr = t2.product_code
where substring(yearmonth,1,4) =  DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by t2.sale_model_code
)
,plan_sales as (
--BP销量与规划销量处理
select 
coalesce (t1.salemodelcode ,t2.salemodelcode) as salemodelcode
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_qty else t1.plan_sales_qty end ) as plan_sales_qty
,sum(case when substring(coalesce (t3.min_dtmonth ,'190001'),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y') then 
t2.plan_sales_amt else t1.plan_sales_amt end ) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select 
salemodelcode 
,product_line 
,dt_month 
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt ) as plan_sales_amt
,sum(plan_gross_margin ) as plan_gross_margin
,sum(plan_gross_profit ) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and model_label_1 = 'HDRP'
group by salemodelcode 
,product_line 
,dt_month 
) t1 
full join (
select 
salemodelcode
,product_line 
,dt_month 
,max(plan_sales_qty) as plan_sales_qty
,max(plan_sales_amt ) as plan_sales_amt
,max(plan_gross_margin ) as plan_gross_margin
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('空气调节类产品')
and model_type = '销售型号编码口径'
group by product_line 
,dt_month ,salemodelcode
)t2
on t1.salemodelcode = t2.salemodelcode
and t1.dt_month = t2.dt_month
left join  (
select 
PG00068
,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from sale_model
group by PG00068
,product_line 
) t3
on coalesce (t1.salemodelcode ,t2.salemodelcode) = t3.PG00068
where substring(coalesce (t1.dt_month ,t2.dt_month),1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
and coalesce (t1.dt_month ,t2.dt_month) <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and coalesce (t1.dt_month ,t2.dt_month) >=  coalesce (t3.min_dtmonth ,'190001')
group by coalesce (t1.salemodelcode ,t2.salemodelcode)
)
select
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'空气事业部' as business_division
,t1.product_line
,t1.PG00020
,'2' as zhibiao_type
,'型号口径' as data_type
,t1.PG00061
,t1.PG00068
,t1.PG00025
,coalesce (t1.HX00501,t1.PG00026)
,t2.sale_qty
,t3.plan_sales_qty
,coalesce (coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)
,t2.rev_amt
,t3.plan_sales_amt
,coalesce (t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)
,t2.maolie
,t3.plan_gross_profit
,t2.maolie/nullif(t3.plan_gross_profit,0.0)
,t2.maolie/nullif(t2.rev_amt,0.0)
,t1.PG00015
,t1.PG00069
,t1.PG00002
,t1.PG00003
,t1.PG00004
,t1.PC00025
,t1.shangshi_m
,t1.project_code
,t1.project_name
,t1.PG00061
,t1.PC20080
,t1.HX00379
,case when coalesce (t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
--集团逻辑 is_project
,case 
when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m <= 3 then 'Y'
else t1.is_project end as is_project
--【新增】内控逻辑 is_project_nk
,case 
when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m <= 3 then 'Y'
else t1.is_project_nk end as is_project_nk
,t1.kt_nbzz
,now()
,'N' as model_label_23
,t1.PC20006
,t1.PG00021
,t1.PG00019
,t4.xmndxf
--【新增】字段
,t1.HX00327
,t1.PG00039
,t1.HX00339
,t1.PG00057 as productmodel_life
,t1.PG00009
,CEIL(t1.shangshi_m / 12) as shangshi_y
--低效型号数不需要达标判定
,null as is_db_qty
,null as is_db_amt
,null as is_db_margin
from sale_model t1
left join all_sales t2 on t1.PG00068 = t2.sale_model_code
left join plan_sales t3 on t1.PG00068 = t3.salemodelcode
left join test.salesmodel_xmndxf t4 on t1.PG00068 = t4.PG00068
;


-- ============================================================
-- Part 2：型号口径 新品规划命中率 (zhibiao_type='4')
-- 合入位置：替换原"空气事业部 新品规划命中率 海信日立"段落
-- 与Part 1的区别：实际销量取全生命周期累计、规划量只用LX、多shangshi_m>=37条件、新增is_db_*
-- ============================================================

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line in ('中央空调')
;
--空气事业部 新品规划命中率  海信日立
insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month	--月份
,business_division   --事业部
,product_line	--产品线
,in_out_sale	--内外销
,zhibiao_type	--指标口径
,data_type  
,prdct_model	--型号名
,salemodel_code
,ir_act_time	--鉴定评审时间
,juece_delistingtime	--下市时间
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
,pg00015--产品公司
,brand  --品牌
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,plan_base   --规划生产基地
,shangshi_m--上市月份
,project_code  --项目编码
,project_name --项目名称
,salemodel	--销售型号名称
,pc20080	--归属营销部
,hx00379	--是否模块组合
,is_dx	--是否低效
,is_project	--是否保护期
,is_project_nk  --是否保护期-内控口径【新增】
,kt_nbzz  --空气事业部内部组织
,load_dt	--加载日期
,model_label_23   --空气是否指标考核口径
,PC20006    --标准品/定制产品
,distribution_channel --销售渠道
,product_positioning --产品定位
,projectdevelopmentdifficulty --项目开发难度
,HX00327    --所有者【新增】
,PG00039    --营销定位【新增】
,HX00339    --主要销售渠道【新增】
,productmodel_life  --销售型号生命周期状态【新增】
,PG00009    --产品系列【新增】
,shangshi_y --上市年数【新增】
,is_db_qty  --销量是否达标【新增】
,is_db_amt  --销额是否达标【新增】
,is_db_margin --毛利率是否达标【新增】
)
--空气事业部  海信日立
with sale_model as (
select 
'中央空调' as product_line
,t1.kt_nbzz  --空调内部组织
,t2.PG00020	--内销/外销
,t1.PG00025    --实际上市时间
,t1.HX00501    --实际退市准备时间
,t1.PG00026    --停止下单时间
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.productmodel  --产品型号名称
,t1.PG00072    --产品档次
,t1.PC00025	--规划生产基地
,t1.PG00069    --销售品牌
,t2.PG00015   --产品公司
,t1.productmodel_id --产品型号id
,t1.PG00061    --销售型号名称
,t1.PG00068    --销售型号编码
,t1.PC20080   --归属营销部
,t1.HX00379   --是否模块组合
,t1.PC20006    --标准品/定制产品
,(YEAR(date_sub('${GP_START_DT}',interval 1 month)) - YEAR(t1.PG00025)) * 12 + (MONTH(date_sub('${GP_START_DT}',interval 1 month)) - MONTH(t1.PG00025)) as shangshi_m
,t1.project_code --项目编码
,t1.project_name--项目名称
--集团逻辑 is_project（含品牌控制）
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense') then 'Y'
else 'N' end as is_project
--【新增】内控逻辑 is_project_nk
,case when coalesce(t1.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
when t1.PC20080 not in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','科龙商空营销部','海外业务部(大客户)','水机营销部','海外业务部(水系统)') then 'Y'
when t2.PG00020 = '外销' and t1.PG00069 not in ('Hisense','HITACHI','YORK') then 'Y'
else 'N' end as is_project_nk
,t2.PG00021	--规划销售渠道
,t2.PG00019	--产品定位
,t1.HX00327    --所有者
,t1.PG00039    --营销定位
,t1.HX00339    --主要销售渠道
,t1.PG00057    --销售型号生命周期状态
,t1.PG00009    --产品系列
from (
select 
PG00061 ,id ,productmodel_id ,productmodel ,PG00068 ,PG00072
,'中央空调' as kt_nbzz
,PG00069 ,PG00057 ,PG00042 ,PG00041
,case when HX00501 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else HX00501 end as HX00501
,case when PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00025 end as PG00025
,PG00027
,case when PG00026 >= STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d') then null else PG00026 end as PG00026
,HX00378 ,PG00004 ,PG00003 ,PG00002 ,PG00015 ,PG00014
,PC20080 ,HX00379 ,HX00370 ,PC20085 ,PC20006
,project_code ,project_name ,PC00025
,HX00327 ,PG00039 ,HX00339 ,PG00009
from dim.dim_ipd_salemodel_dd t1 
where pg00002 = '空气调节类产品'
and pg00003 = '中央空调'
and pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机')
) t1
left join dim.dim_ipd_productmodel_dd t2 on t1.productmodel_id = t2.id
where t1.kt_nbzz in ('中央空调')
and case when t2.PG00020 = '内销' then t1.PG00069 in ('Hisense','HITACHI','YORK','KELON') when t2.PG00020 = '外销' then t1.PG00069 in ('Hisense','HITACHI','YORK') else 1=2 end 
)
,all_sales as (
--日立实际销量（全生命周期累计，不限本年）
select 
t2.sale_model_code
,sum(sale_qty ) as sale_qty
,sum(rev_amt ) as rev_amt
,sum(cost_amt) as chengben
,sum(rev_amt ) - sum(cost_amt) as maolie
from ods.ods_mr_v_app_fm_imat_saledata t1 
left join (
select product_code ,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO') and delete_flag!='Y'
) t2 on t1.matnr = t2.product_code
where yearmonth <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
group by t2.sale_model_code 
)
,plan_sales as (
--新品命中率只用LX规划量（全生命周期累计）
select 
t1.salemodelcode
,t1.product_line
,sum(t1.plan_sales_qty) as plan_sales_qty
,sum(t1.plan_sales_amt) as plan_sales_amt
,sum(plan_gross_profit) as plan_gross_profit
from (
select salemodelcode ,product_line ,dt_month
,sum(plan_sales_qty) as plan_sales_qty
,sum(plan_sales_amt) as plan_sales_amt
,sum(plan_gross_margin) as plan_gross_margin
,sum(plan_gross_profit) as plan_gross_profit
from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX'
and product_big in ('空气调节类产品')
and model_type = '销售型号编码口径'
group by product_line ,dt_month ,salemodelcode
) t1 
left join (
select PG00068 ,product_line 
,min(DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m')) as min_dtmonth
from sale_model
group by PG00068 ,product_line 
) t2 on t1.salemodelcode = t2.PG00068
where t1.dt_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.dt_month >= coalesce(t2.min_dtmonth,'190001')
group by t1.salemodelcode ,t1.product_line
)
select
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,'空气事业部' as business_division
,t1.product_line
,t1.PG00020
,'4' as zhibiao_type
,'型号口径' as data_type
,t1.PG00061
,t1.PG00068
,t1.PG00025
,coalesce(t1.HX00501,t1.PG00026)
,t2.sale_qty
,t3.plan_sales_qty
,coalesce(coalesce(t2.sale_qty,0)/nullif(t3.plan_sales_qty,0),0)
,t2.rev_amt
,t3.plan_sales_amt
,coalesce(t2.rev_amt,0.0)/nullif(t3.plan_sales_amt,0.0)
,t2.maolie
,t3.plan_gross_profit
,t2.maolie/nullif(t3.plan_gross_profit,0.0)
,t2.maolie/nullif(t2.rev_amt,0.0)
,t1.PG00015
,t1.PG00069
,t1.PG00002
,t1.PG00003
,t1.PG00004
,t1.PC00025
,t1.shangshi_m
,t1.project_code
,t1.project_name
,t1.PG00061
,t1.PC20080
,t1.HX00379
,case when coalesce(t2.sale_qty,0)/nullif(t3.plan_sales_qty,0) < 0.8 then 'Y' else 'N' end is_dx   
--集团逻辑 is_project（含新品期限制）
,case 
when not(PG00025 is not null and coalesce(t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 37 then 'Y'  --超过36个月不算新品
when t1.shangshi_m <= 3 then 'Y'
else t1.is_project end as is_project
--【新增】内控逻辑 is_project_nk（含新品期限制）
,case 
when not(PG00025 is not null and coalesce(t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 37 then 'Y'
when t1.shangshi_m <= 3 then 'Y'
else t1.is_project_nk end as is_project_nk
,t1.kt_nbzz
,now()
,'N' as model_label_23
,t1.PC20006
,t1.PG00021
,t1.PG00019
,t4.xmndxf
,t1.HX00327
,t1.PG00039
,t1.HX00339
,t1.PG00057 as productmodel_life
,t1.PG00009
,CEIL(t1.shangshi_m / 12) as shangshi_y
--【新增】新品命中率达标判定（0.8为边界）
,case when coalesce(t3.plan_sales_qty,0) = 0 then 'Y' when coalesce(t2.sale_qty,0)/t3.plan_sales_qty >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(t3.plan_sales_amt,0.0) = 0 then 'Y' when coalesce(t2.rev_amt,0.0)/t3.plan_sales_amt >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(t3.plan_gross_profit,0.0) = 0 then 'Y' when t2.maolie/t3.plan_gross_profit >= 0.8 then 'Y' else 'N' end as is_db_margin
from sale_model t1
left join all_sales t2 on t1.PG00068 = t2.sale_model_code
left join plan_sales t3 on t1.PG00068 = t3.salemodelcode
left join test.salesmodel_xmndxf t4 on t1.PG00068 = t4.PG00068
;


-- ============================================================
-- Part 3：项目口径（含原有'2'/'4' + 二级维度'2-1'~'2-3'/'4-1'/'4-2'）
-- 全部重写，新增：shangshi_y、rili_nkjt（CROSS JOIN weidu_koujing）、is_db_*（仅4系列）
-- 合入位置：替换原项目口径zhibiao_type='2'段落（约1190~1269行）+ 之后追加二级维度
-- ============================================================

-- ----------------------------------------
-- 3.0 低效型号数 项目口径 (zhibiao_type='2') —— 替换原有段落
-- 新增：shangshi_y、rili_nkjt（通过CROSS JOIN区分集团/内控）
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,GROUP_CONCAT(distinct t1.pc20080,',') as pc20080
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t2.koujing
;

-- ----------------------------------------
-- 3.1 低效型号数 营销部项目口径 (zhibiao_type='2-1')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-1'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.pc20080  --二级维度：归属营销部
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.pc20080 ,t2.koujing
;


delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-1'
and product_line = '中央空调'
and data_type = '项目口径'
and pc20080 in ('工程营销部-海信','工程营销部-日立','工程营销部-约克','工程营销部-其他')
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) as pc20080  --二级维度：归属营销部
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.pc20080 = '工程营销部'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) ,t2.koujing
;

-- ----------------------------------------
-- 3.2 低效型号数 所有者项目口径 (zhibiao_type='2-2')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-2'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,HX00327
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-2' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.HX00327  --二级维度：所有者
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.HX00327 ,t2.koujing
;

-- ----------------------------------------
-- 3.3 低效型号数 产品小类项目口径 (zhibiao_type='2-3')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '2-3'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,product_sml
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'2-3' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.product_sml  --二级维度：产品小类
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '2'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.product_sml ,t2.koujing
;

-- ----------------------------------------
-- 3.4 新品规划命中率 项目口径 (zhibiao_type='4') —— 替换原有段落
-- 新增：shangshi_y、rili_nkjt、is_db_qty/is_db_amt/is_db_margin
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,GROUP_CONCAT(distinct t1.pc20080,',') as pc20080
,t2.koujing as rili_nkjt
--达标判定（0.8为边界）
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t2.koujing
;

-- ----------------------------------------
-- 3.5 新品规划命中率 营销部项目口径 (zhibiao_type='4-1')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4-1'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.pc20080 --二级维度：归属营销部-品牌
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.pc20080 ,t2.koujing
;

delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4-1'
and product_line = '中央空调'
and data_type = '项目口径'
and pc20080 in ('工程营销部-海信','工程营销部-日立','工程营销部-约克','工程营销部-其他')
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,pc20080
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4-1' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) as pc20080  --二级维度：归属营销部-品牌
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.pc20080 = '工程营销部'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,CONCAT(t1.pc20080, '-', CASE WHEN t1.brand = 'Hisense' THEN '海信' WHEN t1.brand = 'HITACHI' THEN '日立' WHEN t1.brand = 'YORK' THEN '约克' ELSE '其他' END) ,t2.koujing
;

-- ----------------------------------------
-- 3.6 新品规划命中率 所有者项目口径 (zhibiao_type='4-2')
-- ----------------------------------------
delete from dws.dws_ipd_ipm_dxmodel_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and zhibiao_type = '4-2'
and product_line = '中央空调'
and data_type = '项目口径'
;

insert into dws.dws_ipd_ipm_dxmodel_detail_dd(
dt_month
,business_division
,product_line
,in_out_sale
,zhibiao_type
,data_type  
,ir_act_time
,act_sales_qty
,plan_sales_qty
,sales_qty_rate
,act_sales_amt
,plan_sales_amt
,sales_amt_rate
,act_gross_profit
,plan_gross_profit
,gross_profit_rate
,act_gross_margin
,shangshi_m
,shangshi_y
,project_code
,project_name
,is_dx
,is_project
,kt_nbzz
,load_dt
,model_label_23
,HX00327
,rili_nkjt
,is_db_qty
,is_db_amt
,is_db_margin
)
with weidu_koujing as (
    select '集团' as koujing union all select '内控' as koujing
)
select 
t1.dt_month
,'空气事业部' as business_division
,t1.product_line
,null as in_out_sale
,'4-2' as zhibiao_type
,'项目口径' as data_type  
,min(t1.ir_act_time)
,sum(coalesce(t1.act_sales_qty,0.0)) as act_sales_qty
,sum(coalesce(t1.plan_sales_qty,0.0)) as plan_sales_qty
,sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) as sales_qty_rate
,sum(coalesce(t1.act_sales_amt,0.0)) as act_sales_amt
,sum(coalesce(t1.plan_sales_amt,0.0)) as plan_sales_amt
,sum(coalesce(t1.act_sales_amt,0.0))/nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0) as sales_amt_rate
,sum(coalesce(t1.act_gross_profit,0.0)) as act_gross_profit
,sum(coalesce(t1.plan_gross_profit,0.0)) as plan_gross_profit
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0) as gross_profit_rate
,sum(coalesce(t1.act_gross_profit,0.0))/nullif(sum(coalesce(t1.act_sales_amt,0.0)),0.0) as act_gross_margin
,max(t1.shangshi_m)
,max(t1.shangshi_y)
,t1.project_code
,t1.project_name
,case when sum(coalesce(t1.act_sales_qty,0.0))/nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0) < 0.8 then 'Y' else 'N' end as is_dx
,'N' as is_project
,t1.kt_nbzz
,now()
,'Y' as model_label_23
,t1.HX00327  --二级维度：所有者
,t2.koujing as rili_nkjt
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_qty,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_qty,0.0))/sum(coalesce(t1.plan_sales_qty,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_qty
,case when coalesce(nullif(sum(coalesce(t1.plan_sales_amt,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_sales_amt,0.0))/sum(coalesce(t1.plan_sales_amt,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_amt
,case when coalesce(nullif(sum(coalesce(t1.plan_gross_profit,0.0)),0.0),0) = 0 then 'Y' when sum(coalesce(t1.act_gross_profit,0.0))/sum(coalesce(t1.plan_gross_profit,0.0)) >= 0.8 then 'Y' else 'N' end as is_db_margin
from dws.dws_ipd_ipm_dxmodel_detail_dd t1
cross join weidu_koujing t2
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and t1.zhibiao_type = '4'
and t1.product_line = '中央空调'
and t1.data_type = '型号口径'
and t1.project_code is not null 
and case when t2.koujing = '集团' then t1.is_project = 'N'
         when t2.koujing = '内控' then t1.is_project_nk = 'N' end
group by t1.dt_month ,t1.product_line ,t1.project_code ,t1.project_name ,t1.kt_nbzz ,t1.HX00327 ,t2.koujing
;
