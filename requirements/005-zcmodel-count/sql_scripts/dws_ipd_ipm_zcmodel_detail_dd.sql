-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/01/13 10:20:13 GMT+08:00
-- ******************************************************************** --
------------------------------------在产型号-产品型号口径-------------------------------
------------------------------------在产型号-产品型号口径-------------------------------
delete from dws.dws_ipd_ipm_zcmodel_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company in ('冰冷','洗衣机');

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
,export_method  --出口方式
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
,case when product_line = '冰箱'and in_out_sale = '内销' and not(model_label_4 like '%6330-海信冰箱扬州工厂%' or model_label_4 like '%6370-海信冰箱平度工厂%' or model_label_4 like '%6320-海信冰箱成都工厂%' or model_label_4 like '%6300-海信冰箱顺德工厂%')
then 'Y'
when product_line = '冰箱'and in_out_sale = '外销' and model_label_4 in (
'6330-合肥雪祺电气股份有限公司',
'6330-广东奥马冰箱有限公司',
'6330-上海双鹿上菱企业集团电器有限公司',
'6330-土耳其VESTEL伊兹密尔工厂',
'6330-孟加拉FEL达卡冰箱工厂',
'6330-宁波韩电电器有限公司',
'6330-青岛新星家用电器有限公司',
'6360-万宝电器有限公司',
'6360-江苏星星冷链科技有限公司'
) then 'Y'
when product_line = '冷柜' and model_label_4 in (
'6360-万宝电器有限公司',
'6330-创维电器股份有限公司',
'6330-江苏双鹿电器有限公司',
'6360-江苏星星冷链科技有限公司'
) then 'Y'
when product_line = '洗衣机' and model_label_4 not in (
'6372-平度洗衣机工厂'
) then 'Y' else is_project end     --去掉别人给海信代工的产品，只要海信自己工厂生产的
,now()
,productmodel_id --产品型号id
,export_method  --出口方式
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company in ('冰冷','洗衣机')
and dt_type = '月'
and model_label_10 = '在产'
;

------------------------------------在产型号-产品型号口径-------------------------------
delete from dws.dws_ipd_ipm_zcmodel_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '空调公司';

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
,PG00015 --产品公司
,kt_nbzz
,salemodel    --销售型号名称
,salemodel_code    --销售型号编码
,salemodel_id  --销售型号id
,PC20080    --归属营销部
,HX00379    --是否模块组合
,PC20006    --标准品/定制产品
,platform_nj   --内机平台
,platform_wj   --外机平台
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
,plan_base--规划生产基地
,brand--品牌
,productmodel__life--产品生命周期状态
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,act_time_tzfw--停止服务
,shangshi_m  --本月上市
,tingchan_m   --本月停产
,is_project    --去掉别人给海信代工的产品，只要海信自己工厂生产的
,now()
,productmodel_id --产品型号id
,PG00015 --产品公司
,kt_nbzz
,salemodel    --销售型号名称
,salemodel_code    --销售型号编码
,salemodel_id  --销售型号id
,PC20080    --归属营销部
,HX00379    --是否模块组合
,PC20006    --标准品/定制产品
,platform_nj   --内机平台
,platform_wj   --外机平台
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '空调公司'
and dt_type = '月'
and model_label_10 = '在产'
;

delete from dws.dws_ipd_ipm_zcmodel_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '视像科技';

insert into dws.dws_ipd_ipm_zcmodel_detail_dd(
dt_month
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,ir_act_time
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,sale_country--销售国家名称
,brand--品牌
,productmodel__life--产品生命周期状态
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,act_time_tzfw--停止服务
,shangshi_m  --本月上市
,tingchan_m   --本月停产
,is_project
,load_dt 
,plan_channel  --规划销售渠道
,countries_regions  --立项国家及区域
,productline_tv   --产品线
)
select
dt_month
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,ir_act_time 
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,sale_country--销售国家名称
,brand--品牌
,productmodel__life--产品生命周期状态
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,act_time_tzfw--停止服务
,shangshi_m  --本月上市
,tingchan_m   --本月停产
,is_project    --去掉别人给海信代工的产品，只要海信自己工厂生产的
,now()
,plan_channel  --规划销售渠道
,countries_regions  --立项国家及区域
,productline_tv   --产品线
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '视像科技'
and dt_type = '月'
and model_label_10 = '在产'
;

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

------------------------------------在产型号-产品型号口径 激光-------------------------------
delete from dws.dws_ipd_ipm_zcmodel_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光';

insert into dws.dws_ipd_ipm_zcmodel_detail_dd(
dt_month
,business_division
,company
,product_line
,in_out_sale
,model
,ir_act_time
,product_big
,product_mid
,product_sml
,platform
,productmodel
,chanpindingwei
,sale_country
,brand
,productmodel__life
,act_time_ss
,act_time_tszb
,act_time_tzxd
,act_time_tzsc
,shangshi_m
,tingchan_m
,is_project
,plan_channel
,focallength
,load_dt
)
select
dt_month
,business_division
,company
,product_line
,in_out_sale
,model
,ir_act_time
,product_big
,product_mid
,product_sml
,platform
,productmodel
,chanpindingwei
,sale_country
,brand
,productmodel__life
,act_time_ss
,act_time_tszb
,act_time_tzxd
,act_time_tzsc
,shangshi_m
,tingchan_m
,is_project
,plan_channel
,focallength
,now()
from dws.dws_ipd_ipm_sale_model_detail_dd
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光'
and dt_type = '月'
and model_label_10 = '在产'
;