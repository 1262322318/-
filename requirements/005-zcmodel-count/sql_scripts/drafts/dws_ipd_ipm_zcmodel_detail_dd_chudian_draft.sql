-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
-- DORIS sql 
-- ******************************************************************** --
-- [已合入正式脚本] 2026-05-20 厨电逻辑已合并到 dws_ipd_ipm_zcmodel_detail_dd.sql
-- ******************************************************************** --
-- 厨电事业部 - 在产型号数 DWS层明细（副本草稿）
-- 参照：冰冷洗 在产型号逻辑
-- 说明：从在销型号明细中筛选 model_label_10='在产' 的厨电型号
--       内销：剔除非自制生产型号（生产基地以生产版本PC00025为准）
--       外销：剔除OEM品牌、散件、样机、外协
-- 状态：已合入正式脚本（2026-05-20）
-- ******************************************************************** --

------------------------------------在产型号-产品型号口径  厨电-------------------------------
------------------------------------在产型号-产品型号口径  厨电-------------------------------
delete from dws.dws_ipd_ipm_zcmodel_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '厨电';
insert into dws.dws_ipd_ipm_zcmodel_detail_dd(
dt_month
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,plan_base--规划生产基地
,brand--品牌
,productmodel__life--产品生命周期状态
,salesarea_big--销售大区
,salesarea_sml--销售小区
,is_biaoji--是否标机
,is_yangji--是否样机
,menlei--门类
,plan_channel--规划销售渠道
,pinleixifen--品类细分
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,act_time_tzfw--停止服务
,shangshi_m  --本月上市
,tingchan_m   --本月停产
,is_project
,load_dt 
,productmodel_id --产品型号id
)
select
dt_month
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,plan_base--规划生产基地（已在在销层通过生产版本合并去重）
,brand--品牌
,productmodel__life--产品生命周期状态
,salesarea_big--销售大区
,salesarea_sml--销售小区
,is_biaoji--是否标机
,is_yangji--是否样机
,menlei--门类
,plan_channel--规划销售渠道
,pinleixifen--品类细分
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,act_time_tzfw--停止服务
,shangshi_m  --本月上市
,tingchan_m   --本月停产
--厨电在产型号代工剔除逻辑：
--自制判定：规划生产基地包含"6516-黄岛厨电工厂"为自制，其他均为非自制
--内销：非自制（外购/ODM）不纳入统计
--外销：剔除OEM品牌、非自制（外协）
,case 
--内销：规划生产基地不包含"6516-黄岛厨电工厂" → 非自制，不纳入统计
when in_out_sale = '内销' and (plan_base is null or plan_base not like '%6516-黄岛厨电工厂%') then 'Y'
--外销：品牌为OEM品牌的剔除
when in_out_sale = '外销' and brand = 'OEM品牌' then 'Y'
--外销：规划生产基地不包含"6516-黄岛厨电工厂" → 非自制（外协），不纳入统计
when in_out_sale = '外销' and (plan_base is null or plan_base not like '%6516-黄岛厨电工厂%') then 'Y'
else is_project end as is_project
,now()
,productmodel_id --产品型号id
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '厨电'
and dt_type = '月'
and model_label_10 = '在产'
;
