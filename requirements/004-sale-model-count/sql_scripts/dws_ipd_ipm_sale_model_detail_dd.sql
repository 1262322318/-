-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/01/13 08:55:50 GMT+08:00
-- ******************************************************************** --

---------------------------------------------------------在销型号数  冰冷洗 内外销 产品型号口径 ----------------------------------------------------
---------------------------------------------------------在销型号数  冰冷洗 内外销 产品型号口径 ----------------------------------------------------
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company in ('冰冷','洗衣机')
and product_line in ('冰箱','冷柜','洗衣机') and dt_type = '月'
and dt_day < CAST('${GP_START_DT}' AS DATE) 
and model_label_10 <> '老品清零'
;
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company in ('冰冷','洗衣机')
and product_line in ('冰箱','冷柜','洗衣机') and dt_type = '月'
and dt_day >= CAST('${GP_START_DT}' AS DATE)
;
insert into dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,prdct_model
,matnr
,IR_act_time
,delisted_time
,inventory_qty
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
,model_label_6
,model_label_7
,model_label_8
,model_label_10
,model_label_16   --在销型号数范围
,dt_day
,is_project 
,kcql_time  --库存清零时间
,shangshi_m  --本月上市
,tuishijuece_m   --本月退市决策
,tingchan_m   --本月停产
,kcqw_m   --本月库存清零
,load_dt 

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
,export_method--出口方式
,is_biaoji--是否标机
,is_yangji--是否样机
,menlei--门类
,plan_channel--规划销售渠道
,pinleixifen--品类细分
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,productmodel_id  --产品型号id
)


--冰冷洗内销外销
with kucun_qingwei as (
--自有库存清尾时间
select 
product_line 
,in_out_sale
,coalesce (model,prdct_model) as model
,min(dt_day) as min_kucunqingwei 
from dws.dws_ipd_ipm_sale_model_detail_dd
where  product_line in ('冰箱','冷柜','洗衣机')
and company in ('冰冷','洗衣机')
and dt_type = '月'
and (model_label_10 = '老品清零' or (delisted_time is not null and coalesce(inventory_qty,0)= 0))
group by product_line 
,coalesce (model,prdct_model),in_out_sale
)
,product_model as (

select 
id
,PG00061	--名称
,product_line  --产品线
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
,HX00226	--出口方式
,HX00027	--是否样机
,HX00026	--是否标机
,HX00025	--出口国家
,HX00024	--销售小区
,HX00023	--销售大区
,PC10050    --门类
,PC00001    --品类细分
,is_zhibiaofanwei
,jieduan
,HX00501 as act_time_tszb  --实际时间-退市准备
,PG00027 as act_time_tzsc  --停止生产时间
,PG00026 as act_time_tzxd  --实际停止下单
,PG00025 as act_time_ss  --实际上市时间
from (
select 
id
,PG00061	--名称
,case
-- 内销：家用冰箱
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 in ('冷藏冷冻箱','冷藏箱') and PG00020 = '内销' then '冰箱'
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 = '冷冻箱' and PC00001 = '冰箱' and PG00020 = '内销' then '冰箱'
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00004 = '冷冻箱' and PG00020 = '内销' then '冷柜'
-- 内销：家用冷柜
when PG00002 = '控温储藏类产品' and PG00003 = '家用冷柜' and PG00020 = '内销' then '冷柜'
-- 内销：家用展示柜（冰吧）
when PG00002 = '控温储藏类产品' and PG00003 = '家用展示柜' and PG00004 = '冰吧' and PG00020 = '内销' then '冷柜'
-- 外销：家用冰箱
when PG00002 = '控温储藏类产品' and PG00003 = '家用冰箱' and PG00020 = '外销' then '冰箱'
-- 外销：家用冷柜
when PG00002 = '控温储藏类产品' and PG00003 = '家用冷柜' and PG00020 = '外销' then '冷柜'
-- 洗衣机
when PG00002 = '清洁卫生器具' and PG00003 in ('洗衣机','干衣机','护理机') then '洗衣机'
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
,HX00226	--出口方式
,HX00027	--是否样机
,HX00026	--是否标机
,HX00025	--出口国家
,HX00024	--销售小区
,HX00023	--销售大区
,PC10050    --门类
,PC00001    --品类细分
,case when PG00020 = '内销' then case
--古洛尼品牌的剔除逻辑
when PG00005 in ('gorenje') then 'N'
else 'Y' end 
when PG00020 = '外销' then case
--需要识别标机、样机，“是否标机”“是否样机”选否
when coalesce (HX00026,'否') = '是' or coalesce (HX00027,'否') = '是' then 'N'
--筛选欧洲和美洲为了发货而重复计入的全散件型号：“销售大区”为欧洲大区、美洲大区，且“出口方式”为CKD）
when HX00023 in ('欧洲大区','美洲大区') and HX00226 = 'CKD' then 'N'
else 'Y' end 
else 'Y' end as  is_zhibiaofanwei
,case when PG00029 in ('上市','退市准备','停止下单') then '在产'
when PG00029 in ('停止服务','停止生产') then '退市'
else '未上市' end as jieduan
/*,case when act_time_ss is not null and act_time_tszb is null then '在产'
when act_time_tszb is not null then '退市'
else '未上市' end as jieduan*/
,PG00027  --停止生产时间
,HX00501  --退市准备时间
,PG00025  --实际上市时间
,PG00026  --实际停止下单时间
from dim.dim_ipd_productmodel_dd t1  --产品型号
)a 
where product_line in ('冰箱','冷柜','洗衣机')

)

,kc_nx as ( 
--库存数量
select 
matnr
,sum(qty) as kc_sum
from ( 
--冰箱-大库龄明细
select
goods_code as matnr
,qty   --库存数量
from dws.dws_fi_mr_bxp_dklmx_di
where invstatus = '正品'
and daymonth_flag = '0'
and load_dt = cast('${GP_START_DT}' as date)

union all 
--冰箱-营销产成品明细
select 
matnr
,occupynumber  --总占有量
from dws.dws_fi_mr_bxp_yxccpmx_all_di
where qbkcfl in ('寄售-线上','寄售-线下')
and daymonth_flag = '0'
and load_dt = cast('${GP_START_DT}' as date)
)t1
group by matnr

)
,kc_wx as (
--海外分公司库存
select 
matnr 
,werks 
,charg
,zcusmodel
,zmodel
,zfacmodel
,vtext 
,clabs as kc_sum --库存数量
,landx
,related_rd
,zmodel_rd
,quzu_rd
,case when vtext = '家电-冰箱' then '冰箱' when vtext = '家电-冷柜' then '冷柜' when vtext = '家电-洗衣机' then '洗衣机' else '其他' end as product_line
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
where lfgja = DATE_FORMAT('${GP_START_DT}', '%Y') 
and lfmon = DATE_FORMAT('${GP_START_DT}', '%m')
and vtext in ('家电-冰箱','家电-冷柜','家电-洗衣机' ) 
and udate = cast('${GP_START_DT}' as date) 
and lgort is not null   --库存地点不为空
and zkwlb = 'A'     --库位类型为A   
and substring(werks,1,2) <> '80'   --海外分公司库存库存
and quzu_rd in ('国际营销','东盟区')

union all 
--基地库存
select 
matnr 
,werks 
,charg 
,null
,null
,null
,gtext 
,menge 
,zywqy
,related_rd
,zmodel_rd
,quzu_rd
,case when gtext = '家电.冰箱' then '冰箱' when gtext = '家电.冷柜' then '冷柜' when gtext = '家电.洗衣机' then '洗衣机' else '其他' end as product_line
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
where gjahr = DATE_FORMAT('${GP_START_DT}', '%Y')
and monat = DATE_FORMAT('${GP_START_DT}', '%m')
and pdate = cast('${GP_START_DT}' as date) 
and gtext in ('家电.冰箱','家电.冷柜','家电.洗衣机')
and quzu_rd in ('国际营销','东盟区')

union all 
--在途库存
select 
matnr 
,bukrs 
,bwtar 
,zcusmodel 
,null as zmodel
,zfacmodel 
,vtext 
,menge 
,null 
,related_rd 
,zmodel_rd 
,quzu_rd 
,case when SPART_rd = '62' then '冰箱' when SPART_rd = '63' then '冷柜' when SPART_rd = '64' then '洗衣机' else '其他' end as product_line
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
where SPART_rd in ('62','63','64')
and budat = cast('${GP_START_DT}' as date) 
and bukrs not in ('8300','8320','8330','8370','8380','8390','83B0')  --不取欧洲8300德国，8320俄罗斯，8330意大利，8370意大利，8380法国，8390捷克，83B0欧研
and menge >=1  --负值跟0不取
)

,kc_all as ( 
--外销库存数量
select 
prouductmodel_rd as productmodel
,'外销' as in_out_sale
,sum(kc_sum) as kc_sum
from kc_wx
group by prouductmodel_rd

union all 

select 
t2.model_name   --产品型号
,'内销' as in_out_sale
,sum(t1.kc_sum) as kc_sum
from kc_nx t1
left join (
select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y'
) t2 
on t1.matnr = t2.product_code
group by t2.model_name   --产品型号
)
,zx_model as ( 
select 
t1.id
,t1.PG00061	--名称
,t1.product_line  --产品线
,t1.PG00029	--产品型号生命周期状态
,t1.PG00021	--规划销售渠道
,t1.PG00020	--内销/外销
,t1.PG00019	--产品定位
,t1.PG00015	--产品公司
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
,t1.HX00226	--出口方式
,t1.HX00027	--是否样机
,t1.HX00026	--是否标机
,t1.HX00025	--出口国家
,t1.HX00024	--销售小区
,t1.HX00023	--销售大区
,t1.PC10050    --门类
,t1.PC00001    --品类细分
,t2.kc_sum  --库存数量
,t1.is_zhibiaofanwei  --指标范围
,case when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) = 0 then '老品清零'
when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) <> 0 then '老品'
else t1.jieduan end as jieduan
,t1.act_time_ss   --实际时间-上市
,t1.act_time_tszb  --实际时间-退市准备
,act_time_tzxd	--实际时间-停止下单
,act_time_tzsc	--实际时间-停止生产
from product_model t1 
left join kc_all t2 
on t1.PG00061 = t2.productmodel
)
select distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,'月' as dt_type
,case when t1.product_line in ('冰箱','冷柜') then '冰冷事业部' when t1.product_line = '洗衣机' then '洗护事业部' end as business_division   --事业部
,case when t1.product_line in ('冰箱','冷柜') then '冰冷' when t1.product_line = '洗衣机' then '洗衣机' end as company
,t1.product_line  --产品线
,t1.PG00020	--内销/外销
,t1.PG00061	--名称
,null as prdct_model
,t4.PG00031 as matnr
,t1.act_time_ss   --实际时间-上市
,t1.act_time_tzsc	--实际时间-停止生产
,t1.kc_sum  --库存数量

,t1.PG00014	--产品平台
,t1.PG00021	--规划销售渠道
,t1.PG00005	--品牌
,t1.PC00025	--规划生产基地
,t1.PG00019	--产品定位
,null as is_gcj  --工程机
,null as 品类  --品类
,t1.PG00029	--产品型号生命周期状态
,t1.jieduan
,t1.is_zhibiaofanwei  --指标范围
,cast('${GP_START_DT}' as date) 
,case when t1.is_zhibiaofanwei = 'N' then 'Y'
when t1.jieduan in ('未上市','老品清零','其他') then 'Y'  
when t1.jieduan in ('老品') and t2.productmodel is not null then 'Y'   --去除以前清尾库存的型号
else 'N' end  as is_project
,case when t1.jieduan = '老品清零' then coalesce (t3.min_kucunqingwei,cast('${GP_START_DT}' as date) ) else t3.min_kucunqingwei end 库存清尾时间--库存清尾 
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_ss, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月上市' else null end 本月上市 --本月上市标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_tszb, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月退市决策' else null end 退市决策--退市决策标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_tzsc, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停产' else null end 本月停产--本月停产标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(
case when t1.jieduan = '老品清零' then coalesce (t3.min_kucunqingwei,cast('${GP_START_DT}' as date) ) else t3.min_kucunqingwei end 
, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停止销售' else null end 本月停止销售--本月库存清尾完成
,now()

--新增
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PG00014	--产品平台
,t1.PG00061	--产品型号名称
,t1.PG00019	--产品定位
,t1.PC00025	--规划生产基地
,t1.PG00005	--品牌
,t1.PG00029	--产品型号生命周期状态
,t1.HX00023	--销售大区
,t1.HX00024	--销售小区
,t1.HX00226	--出口方式
,t1.HX00026	--是否标机
,t1.HX00027	--是否样机
,t1.PC10050    --门类
,t1.PG00021	--规划销售渠道
,t1.PC00001    --品类细分
,t1.act_time_ss   --实际时间-上市
,t1.act_time_tszb  --实际时间-退市准备
,t1.act_time_tzxd	--实际时间-停止下单
,t1.act_time_tzsc	--实际时间-停止生产
,t1.id
from zx_model t1
left join (select distinct productmodel,in_out_sale from dws.dws_ipd_ipm_sale_model_detail_dd
where product_line in ('冰箱','冷柜','洗衣机')
and model_label_10 = '老品清零'
and company not like '%商家库存%'
and dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
)t2
on t1.PG00061 = t2.productmodel
and t1.PG00020 = t2.in_out_sale
left join kucun_qingwei t3 
on t1.product_line = t3.product_line
and t1.PG00061 = t3.model
and t1.PG00020 = t3.in_out_sale
left join (select distinct  productmodel,max(PG00031)as PG00031 from  dim.dim_ipd_productionversion_dd group by productmodel) t4 
on t1.PG00061 = t4.productmodel
and t1.PG00020 = '内销'
;



--空气事业部 
--空调内销
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '空调公司' and dt_type = '月'
and dt_day < CAST('${GP_START_DT}' AS DATE) 
and model_label_10 <> '老品清零'
;
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '空调公司' and dt_type = '月'
and dt_day >= CAST('${GP_START_DT}' AS DATE)
;
insert into dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,matnr
,IR_act_time
,delisted_time
,inventory_qty
,model_label_10   --判定老品清零
,model_label_16   --在销型号数范围
,dt_day
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,platform_nj  --内机产品平台
,platform_wj  --外机产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,plan_base--规划生产基地
,brand--品牌
,productmodel__life--产品生命周期状态
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,is_project --是否保护期
,kcql_time  --库存清零时间
,shangshi_m  --本月上市
,tuishijuece_m   --本月退市决策
,tingchan_m   --本月停产
,kcqw_m   --本月库存清零
,load_dt 
,PG00015  --产品公司
,productmodel_id  --产品型号id
,kt_nbzz  --空气事业部内部组织
)
with kucun_qingwei as (
--自有库存清尾时间
select 
product_line 
,coalesce (model,prdct_model) as model
,in_out_sale 
,min(dt_day) as min_kucunqingwei 
from dws.dws_ipd_ipm_sale_model_detail_dd
where  product_line in ('家用空调')
and company not like '%商家库存%'
and dt_type = '月'
and (model_label_10 = '老品清零' or (delisted_time is not null and coalesce(inventory_qty,0)= 0))
group by product_line 
,coalesce (model,prdct_model),in_out_sale 
)
,product_model as (

select 
id --产品型号id
,PG00061	--名称
,case when kt_nbzz in ('家空内销','家空外销','轻商内销','轻商外销') then '家用空调'
when kt_nbzz in ('央空内销日立','央空外销日立','央空内销科龙') then '中央空调'
else '其他' end product_line
,kt_nbzz  --产品线-内部
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PC20028    --内机产品平台
,PC20054    --外机产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,pc20029    --内机产品型号
,pc20055    --外机产品型号
,hx00290    --产品类别
,is_zhibiaofanwei
,jieduan
,HX00501 as act_time_tszb  --实际时间-退市准备
,PG00027 as act_time_tzsc  --停止生产时间
,PG00026 as act_time_tzxd  --实际停止下单
,PG00025 as act_time_ss  --实际上市时间
from (
select 
id --产品型号id
,PG00061	--名称
,case 
--家用空调
when PG00061= 'KFR-120LW/SEA-X1' then '轻商内销'
when t1.pg00003 in ('除湿机') then '家空外销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and t1.pg00004 in ('分体式空调器整机') then '家空内销'
when t1.pg00015 = '空调' and t1.PG00020 = '外销' and t1.pg00003 = '家用房间空调' and t1.pg00004 in ('分体式空调器整机','移动式空调器','窗式空调器') then '家空外销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (PG00005,'Hisense') <> 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','单元式整机','多联机内机','多联机外机','风机盘管','空气源热泵两联供','热泵热水机','涡旋式冷水(热泵)机组','新风换气机','一拖多外机') then '轻商内销'
when t1.pg00015 = '空调' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and coalesce (PG00005,'Hisense') <> 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('热风机整机','热风机内机','热风机外机') then '轻商内销'
when t1.pg00015 = '空调' and t1.PG00020 = '外销' and t1.pg00003 = '中央空调' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','一拖多外机','屋顶机','空气源热泵三联供','热泵热水机') then '轻商外销' 
--中央空调
when t1.pg00015 = '博世' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (PG00005,'Hisense') = 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','风机盘管','空气源热泵两联供','热泵热水机','涡旋式冷水(热泵)机组','新风换气机','一拖多外机') then '央空内销科龙'
when t1.pg00015 = '博世' and t1.PG00020 = '内销' and t1.pg00003 = '家用房间空调' and coalesce (PG00005,'Hisense') = 'KELON' and coalesce (HX00083,'补充') <> 'ODM'
and t1.pg00004 in ('热风机内机','热风机外机') then '央空内销科龙'
when t1.pg00015 = '博世' and t1.PG00020 = '内销' and t1.pg00003 = '中央空调' and coalesce (hx00427,'否') = '否' 
and t1.pg00004 in ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') then '央空内销日立'  
when t1.pg00015 = '博世' and t1.PG00020 = '外销' and t1.pg00003 = '中央空调' and coalesce (hx00427,'否') = '否' 
and t1.pg00004 in ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') then '央空外销日立'  
else '其他' end as kt_nbzz
,PG00029	--产品型号生命周期状态
,PG00021	--规划销售渠道
,PG00020	--内销/外销
,PG00019	--产品定位
,PG00015	--产品公司
,PG00014	--产品平台
,PC20028    --内机产品平台
,PC20054    --外机产品平台
,PG00005	--品牌
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PC00025	--规划生产基地
,pc20029    --内机产品型号
,pc20055    --外机产品型号
,hx00290    --产品类别
,hx00427  --是否重复型号
,HX00083  --研发类型
,'Y' as  is_zhibiaofanwei
,case when PG00029 in ('上市','退市准备','停止下单') then '在产'
when PG00029 in ('停止服务','停止生产') then '退市'
else '未上市' end as jieduan
,PG00027  --停止生产时间
,HX00501  --退市准备时间
,PG00025  --实际上市时间
,PG00026  --实际停止下单时间
from dim.dim_ipd_productmodel_dd t1  --产品型号
where t1.pg00002 = '空气调节类产品'
--排除环境电器产品
and coalesce (t1.productline_syb ,'填空') <> '环境电器'

)a 
where kt_nbzz in ('家空内销','家空外销','轻商内销','轻商外销'/*,'央空内销科龙','央空内销日立','央空外销日立'*/)


)
,productionversion_model as ( 
select distinct
productmodel  --产品型号名称
--,PG00061    --生产版本型号
,PG00031	--BOM编码
from dim.dim_ipd_productionversion_dd   --生产版本
where pg00002 = '空气调节类产品'

)
,oem_kucun as (
select 
yz.werks
,yz.matnr
,length(yz.matnr)
,yz.charg
,yz.lgort
,sum(yz.menge) menge
from (
    select tin.werks,tin.matnr,tin.charg,COALESCE(tin.clabs,0)+COALESCE(tin.cumlm,0)+COALESCE(tin.cspem,0) as menge,
    case when tin.werks = '6211' and tin.lgort = '1017' then '1008'
    else tin.lgort end as lgort
    from(
        select t1.* from(
            select werks,lgort,matnr,charg,clabs,cumlm,cspem,--(t.clabs + t.cumlm + t.cspem) as menge,
            row_number() over(partition by werks,lgort,matnr,charg order by concat(t.lfgja * 100 + t.lfmon, '') desc) as rownum  
            from ods.odss900_mchb t
            where concat(t.lfgja * 100 + t.lfmon, '')<= DATE_FORMAT('${GP_START_DT}', '%Y%m')
            and werks IN ( '6210', '6211', '6220', '6221', '6230', '6231' )
        )t1 where t1.rownum=1
        union all
        select t2.* from(
            select werks,lgort,matnr,charg,clabs,cumlm,cspem,--(t.clabs + t.cumlm + t.cspem) as menge,
            row_number() over(partition by werks,lgort,matnr,charg order by concat(t.lfgja * 100 + t.lfmon, '') desc) as rownum
            from ods.odss900_mchbh t
            where concat(t.lfgja * 100 + t.lfmon, '')<= DATE_FORMAT('${GP_START_DT}', '%Y%m')
            and  werks IN ( '6210', '6211', '6220', '6221', '6230', '6231' )
        )t2 where t2.rownum=1
        and not exists(
            select t1.* from(
            select werks,lgort,matnr,charg,clabs,cumlm,cspem,--(t.clabs + t.cumlm + t.cspem) as menge,
            row_number() over(partition by werks,lgort,matnr,charg order by concat(t.lfgja * 100 + t.lfmon, '') desc) as rownum  
            from ods.odss900_mchb t
            where concat(t.lfgja * 100 + t.lfmon, '')<= DATE_FORMAT('${GP_START_DT}', '%Y%m')
            and werks IN ( '6210', '6211', '6220', '6221', '6230', '6231' )
            )t1 where t1.rownum=1  and t2.werks=t1.werks and t2.lgort=t1.lgort and t2.matnr=t1.matnr  and t1.charg=t2.charg
        )
    )tin where (COALESCE(tin.clabs,0)+COALESCE(tin.cumlm,0)+COALESCE(tin.cspem,0))>0
)yz  where werks='6211' and charg='H' and lgort in('1013'/*,'1007'*/) 
group by yz.werks
,yz.matnr
,yz.charg
,yz.lgort

)
,nx_kc as ( 
--空调在销型号 自有库存
select    
pro_model
,material_code
,sum(qty)  AS sm
from  test.dwfi_fa_tf_acp_prostockdetail  
WHERE branch_node in ('CDC','RDC')  ---这就是自有库存
and spare4=0    --1是月报，=0为日报
and batch='H' --是正品
--AND pro_category in('科龙空调','海信空调')
AND coalesce(is_fittings,'否') = '否'  --是否配件
AND coalesce(branch_node,'是') NOT IN ('借机','样机')
AND load_dt = DATE_ADD(cast('${GP_START_DT}' as date), INTERVAL 1 DAY)
group by pro_model,material_code
--业务是按照日报取得数据，如果取2月28号数据，那就是看load_dt为3月1号的数据
--,如果是取月的数据，就是取load_dt为每个月1号的数据，就是上个月的值

)
,nx_kc_2 as ( 
--根据物料号转换一次对应的型号名称
select 
t1.sm
,coalesce (t2.productmodel,t1.pro_model) as pro_model
from nx_kc t1 
left join productionversion_model t2 on t1.material_code = t2.PG00031
)
,nx_kc_3 as (
--将内机型号转换为对应的整机产品型号
select 
coalesce (t2.PG00061,t1.pro_model) as productmodel
,sum(t1.sm) as sm
from nx_kc_2 t1 
left join (
--将内机型号转换成对应的整机
select distinct pc20029,PG00061 from dim.dim_ipd_productmodel_dd where pg00002 = '空气调节类产品' and pg00004 in ('分体式空调器整机','单元式整机') and PG00020 = '内销'
)t2 
on t1.pro_model = t2.pc20029
group by coalesce (t2.PG00061,t1.pro_model)

union all 
--oem库存
select 
coalesce (t3.pg00061,t2.productmodel) as productmodel
,sum(t1.menge) as sm
from oem_kucun t1 
left join productionversion_model t2
on t1.matnr = t2.pg00031
left join (--将内机型号转换成对应的整机
select distinct pc20029,PG00061 from dim.dim_ipd_productmodel_dd where pg00002 = '空气调节类产品' and pg00004 in ('分体式空调器整机','单元式整机') and PG00020 = '内销'
)t3
on t2.productmodel = t3.pc20029
group by coalesce (t3.pg00061,t2.productmodel)
)
,kc_wx as (
--海外分公司库存
select 
matnr 
,werks 
,charg
,zcusmodel
,zmodel
,zfacmodel
,vtext 
,clabs --库存数量
,landx
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
where  lfgja = DATE_FORMAT('${GP_START_DT}', '%Y') 
and lfmon = DATE_FORMAT('${GP_START_DT}', '%m')
and vtext in ('家电-空调' ,'家电-海信商空') 
and udate = cast('${GP_START_DT}' as date) 
and lgort is not null   --库存地点不为空
and zkwlb = 'A'     --库位类型为A   
and substring(werks,1,2) <> '80'   --海外分公司库存库存
and quzu_rd in ('国际营销','东盟区')

union all 
--基地库存
select 
matnr 
,werks 
,charg 
,null
,null
,null
,gtext 
,menge 
,zywqy
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
where gjahr = DATE_FORMAT('${GP_START_DT}', '%Y')
and monat = DATE_FORMAT('${GP_START_DT}', '%m')
and pdate = cast('${GP_START_DT}' as date) 
and gtext in ('家电.家用空调','家电.海信商空')
and quzu_rd in ('国际营销','东盟区')

union all 
--在途库存
select 
matnr 
,bukrs 
,bwtar 
,zcusmodel 
,null as zmodel
,zfacmodel 
,vtext 
,menge 
,null 
,related_rd 
,zmodel_rd 
,quzu_rd 
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
where SPART_rd in ('61','66')
and budat = cast('${GP_START_DT}' as date) 
and bukrs not in ('8300','8320','8330','8370','8380','8390','83B0')  --不取欧洲8300德国，8320俄罗斯，8330意大利，8370意大利，8380法国，8390捷克，83B0欧研
and menge >=1  --负值跟0不取
)
,kc_all as ( 
--外销库存数量
select 
prouductmodel_rd as productmodel
,'外销' as in_out_sale
,sum(clabs) as kc_sum
from kc_wx
group by prouductmodel_rd

union all 

select 
productmodel
,'内销' as in_out_sale
,sm
from nx_kc_3
)
,zx_model as ( 
select 
t1.id --产品型号id
,t1.PG00061	--名称
,t1.product_line  --产品线
,t1.PG00029	--产品型号生命周期状态
,t1.PG00021	--规划销售渠道
,t1.PG00020	--内销/外销
,t1.PG00019	--产品定位
,t1.PG00015	--产品公司
,t1.PG00014	--产品平台
,t1.PC20028    --内机产品平台
,t1.PC20054    --外机产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地
,t1.pc20029    --内机产品型号
,t1.pc20055    --外机产品型号
,t1.hx00290    --产品类别
,t1.is_zhibiaofanwei
,case when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) = 0 then '老品清零'
when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) <> 0 then '老品'
else t1.jieduan end as jieduan
,t1.act_time_ss  --实际上市时间
,t1.act_time_tszb  --实际时间-退市准备
,t1.act_time_tzxd  --实际退市时间
,t1.act_time_tzsc  --停止生产时间
,t2.kc_sum
,t1.kt_nbzz  --产品线-内部
from product_model t1 
left join kc_all t2 
on t1.PG00061 = t2.productmodel
)
,zx_model_2 as ( 
--轻商内销 处理单元机整机 内机外机 去重的规则
select 
t1.product_line  --产品线
,t1.PG00020	--内销/外销
,t1.PG00061	--名称
,t4.PG00031
,t1.kc_sum  --库存数量
,t1.jieduan
,t1.is_zhibiaofanwei  --指标范围
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PG00014	--产品平台
,t1.PC20028    --内机产品平台
,t1.PC20054    --外机产品平台
,t1.PG00019	--产品定位
,t1.PC00025	--规划生产基地
,t1.PG00005	--品牌
,t1.PG00029	--产品型号生命周期状态
,t1.pc20029    --内机产品型号
,t1.pc20055    --外机产品型号
,t1.act_time_ss  --实际时间-上市
,t1.act_time_tszb  --实际时间-退市准备
,t1.act_time_tzxd	--实际时间-停止下单
,t1.act_time_tzsc	--实际时间-停止生产
,case when t1.is_zhibiaofanwei = 'N' then 'Y'
when t1.jieduan in ('未上市','老品清零','其他') then 'Y'  
when t1.jieduan in ('老品') and t2.productmodel is not null then 'Y'   --去除以前清尾库存的型号
else 'N' end  as is_project
,case when t1.jieduan = '老品清零' then coalesce (t3.min_kucunqingwei,cast('${GP_START_DT}' as date) ) else t3.min_kucunqingwei end 库存清尾时间--库存清尾 
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_ss, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月上市' else null end 本月上市 --本月上市标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_tszb, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月退市决策' else null end 退市决策--退市决策标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_tzsc, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停产' else null end 本月停产--本月停产标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(
case when t1.jieduan = '老品清零' then coalesce (t3.min_kucunqingwei,cast('${GP_START_DT}' as date) ) else t3.min_kucunqingwei end 
, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停止销售' else null end 本月停止销售--本月库存清尾完成
,t1.PG00015  --产品公司
,t1.id --产品型号id
,t1.kt_nbzz  --产品线-内部
from zx_model t1
left join (select distinct productmodel,in_out_sale from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '空调公司'
and model_label_10 = '老品清零'
and company not like '%商家库存%'
and dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m') 
)t2
on t1.PG00061 = t2.productmodel
and t1.PG00020 = t2.in_out_sale
left join kucun_qingwei t3 
on  t1.PG00061 = t3.model
and t1.PG00020 = t3.in_out_sale
left join (select  productmodel,max(PG00031)as PG00031 from  dim.dim_ipd_productionversion_dd group by productmodel) t4 
on t1.PG00061 = t4.productmodel
and t1.PG00020 = '内销'
)
,danyuanji_tichu as ( 
select PG00061 from zx_model_2
where pg00004 in ('单元式内机','热风机内机') 
and is_project = 'N'
and PG00061 in (
select distinct pc20029 from zx_model_2
where pg00004 in ('单元式整机','热风机整机') 
and is_project = 'N'
and pc20029 is not null
)
union all 

select PG00061 from zx_model_2
where pg00004 in ('单元式外机','热风机外机') 
and is_project = 'N'
and PG00061 in (
select distinct pc20055 from zx_model_2
where pg00004 in ('单元式整机','热风机整机') 
and is_project = 'N'
and pc20055 is not null
)
)
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m')  as dt_month
,'月' as dt_type
,'空气事业部' as business_division   --事业部
,'空调公司' as company
,product_line  --产品线
,PG00020	--内销/外销
,t1.PG00061	--名称
,PG00031 as matnr
,act_time_ss   --实际时间-上市
,act_time_tzsc	--实际时间-停止生产
,kc_sum  --库存数量
,jieduan
,is_zhibiaofanwei  --指标范围
,cast('${GP_START_DT}' as date) as day_dt
,PG00002	--产品大类
,PG00003	--产品中类
,PG00004	--产品小类
,PG00014	--产品平台
,PC20028    --内机产品平台
,PC20054    --外机产品平台
,t1.PG00061 as productmodel 	--产品型号名称
,PG00019	--产品定位
,PC00025	--规划生产基地
,PG00005	--品牌
,PG00029	--产品型号生命周期状态
,act_time_ss  --实际时间-上市
,act_time_tszb  --实际时间-退市准备
,act_time_tzxd	--实际时间-停止下单
,act_time_tzsc --实际时间-停止生产
,case when t2.PG00061 is not null then 'Y' else  is_project end as is_project
,库存清尾时间--库存清尾 
,本月上市 --本月上市标识
,退市决策--退市决策标识
,本月停产--本月停产标识
,本月停止销售--本月库存清尾完成
,now()
,PG00015  --产品公司
,id --产品型号id
,kt_nbzz  --产品线-内部
from zx_model_2 t1 
left join danyuanji_tichu t2 
on t1.PG00061 = t2.PG00061
and t1.kt_nbzz = '轻商内销'
;



--中央空调日立部分   采用销售型号
insert into dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line 
,kt_nbzz  --空气事业部内部组织
,in_out_sale
,model
,IR_act_time
,delisted_time
,model_label_10   --判定老品清零
,model_label_16   --在销型号数范围
,dt_day
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
,is_project --是否保护期
,shangshi_m  --本月上市
,tuishijuece_m   --本月退市决策
,tingchan_m   --本月停产
,PG00015  --产品公司
,productmodel_id  --产品型号id
,salemodel    --销售型号名称
,salemodel_code    --销售型号编码
,salemodel_id  --销售型号id
,PC20080    --归属营销部
,HX00379    --是否模块组合
,PC20006    --标准品/定制产品
,is_project_nk  --内控口径
,load_dt 
,matnr  --物料编码
,HX00327    --所有者
,PC20018    --非标对应原型机
,PG00009    --产品系列
,PG00024--规划停止下单时间
,HX00502--规划停止生产时间
)
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m')  as dt_month
,'月' as dt_type
,'空气事业部' as business_division   --事业部
,'空调公司' as company
,'中央空调' as product_line
,t1.kt_nbzz  --空调内部组织
,t2.PG00020	--内销/外销
,t1.PG00061    --名称
,t1.PG00025    --实际上市时间
,t1.PG00027    --停止生产时间
,t1.jieduan
,case when coalesce(t1.PC20006,'标准品') <> '标准品' then 'N' 
when coalesce(t2.PC00025,'正常') = '1000-海信日立委外工厂' then 'N' 
when coalesce(t1.HX00379,'否') = '是' then 'N' 
else 'Y' end as is_zhibiaofanwei
,cast('${GP_START_DT}' as date) as day_dt
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,case when t1.PG00003 = '空气调节类配件' then '空气调节类配件' else t1.PG00004 end as PG00004	--产品小类
,t2.PG00014	--产品平台
,t1.productmodel  --产品型号名称
,t1.PG00072    --产品档次
,t2.PC00025	--规划生产基地
,t1.PG00069    --销售品牌
,t1.PG00057    --销售型号生命周期状态
,t1.PG00025    --实际上市时间
,t1.HX00501    --实际退市时间
,t1.PG00026    --实际停止下单时间
,t1.PG00027    --停止生产时间
,case when t1.PG00004 not in ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机') then 'Y'
when t1.PG00003 = '空气调节类配件' then 'Y'
when t1.jieduan <> '在产' then 'Y' 
when coalesce(t1.PC20006,'标准品') <> '标准品' then 'Y' 
when coalesce(t2.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
else 'N' end as is_project
,case when DATE_FORMAT(t1.PG00025, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月上市' else null end 本月上市 --本月上市标识
,case when DATE_FORMAT(t1.HX00501, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月退市决策' else null end 退市决策--退市决策标识
,case when DATE_FORMAT(t1.PG00027, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停产' else null end 本月停产--本月停产标识
,t2.PG00015    --产品公司
,t1.productmodel_id --产品型号id
,t1.PG00061    --销售型号名称
,t1.PG00068    --销售型号编码
,t1.id  --销售型号id
,t1.PC20080    --归属营销部
,t1.HX00379    --是否模块组合
,t1.PC20006    --标准品/定制产品
,case when t1.jieduan <> '在产' then 'Y' 
when coalesce(t1.PC20006,'标准品') <> '标准品' then 'Y' 
when coalesce(t2.PC00025,'正常') = '1000-海信日立委外工厂' then 'Y' 
when coalesce(t1.HX00379,'否') = '是' then 'Y' 
else 'N' end as is_project_nk
,now()
,t3.product_code --物料编码
,t1.HX00327    --所有者
,t1.PC20018    --非标对应原型机
,t1.PG00009    --产品系列
,t1.PG00024--规划停止下单时间
,t1.HX00502--规划停止生产时间
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
,PG00025    --实际上市时间
,HX00501    --实际退市时间
,PG00027    --停止生产时间
,PC20084    --停止下单时间
,PG00026    --实际停止下单时间
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
,HX00327    --所有者
,PC20018    --非标对应原型机
,PG00009    --产品系列
,PG00024--规划停止下单时间
,HX00502--规划停止生产时间
,case when PG00057 in ('上市','退市准备','停止下单') then '在产'
when PG00057 in ('停止服务','停止生产') then '退市'
else '未上市' end as jieduan
from dim.dim_ipd_salemodel_dd t1
where pg00002 = '空气调节类产品'
and (
    (pg00003 = '中央空调' and pg00004 in ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机','风机盘管','离心式冷水机组','螺杆式冷水机组','涡旋式冷水机组','热泵热水机','屋顶机','空气处理机组'))
    or (pg00003 = '空气调节类配件')
)
and PC20080 in ('日立家装营销部','海信家装营销部','大客户部','工程营销部','电商事业部','约克家装营销部','海外业务部(氟系统)','海外业务部(大客户)','科龙商空营销部','日立商空营销部','海信商空营销部','约克商空营销部')
) t1
left join dim.dim_ipd_productmodel_dd t2 
on t1.productmodel_id = t2.id
left join (
select  
group_concat(product_code) product_code
,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO')
and delete_flag!='Y'
and create_company = 'RILI'
group by sale_model_code
)t3 
on t1.PG00068 = t3.sale_model_code
where t1.kt_nbzz in ('中央空调')
;



-- 删除今年所有预测数据（幂等）
DELETE FROM dws.dws_ipd_ipm_sale_model_detail_dd 
WHERE company = '空调公司'
    AND product_line = '中央空调'
    AND dt_type = '月'
    AND dt_month > DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')
    AND dt_month <= CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y'), '12');

-- 插入预测数据
INSERT INTO dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line
,kt_nbzz  --空气事业部内部组织
,in_out_sale
,model
,IR_act_time
,delisted_time
,model_label_10   --判定老品清零
,model_label_16   --在销型号数范围
,dt_day
,product_big  --产品大类
,product_mid  --产品中类
,product_sml  --产品小类
,platform  --产品平台
,productmodel  --产品型号名称
,chanpindingwei  --产品定位
,plan_base  --规划生产基地
,brand  --品牌
,productmodel__life  --产品生命周期状态
,act_time_ss  --上市时间
,act_time_tszb  --退市准备
,act_time_tzxd  --停止下单
,act_time_tzsc  --停止生产
,is_project  --是否保护期
,shangshi_m  --本月上市
,tuishijuece_m   --本月退市决策
,tingchan_m   --本月停产
,PG00015  --产品公司
,productmodel_id  --产品型号id
,salemodel    --销售型号名称
,salemodel_code    --销售型号编码
,salemodel_id  --销售型号id
,PC20080    --归属营销部
,HX00379    --是否模块组合
,PC20006    --标准品/定制产品
,is_project_nk  --内控口径
,load_dt
,matnr  --物料编码
,HX00327    --所有者
,PC20018    --非标对应原型机
,PG00009    --产品系列
,PG00024  --规划停止下单时间
,HX00502  --规划停止生产时间
)
-- CTE1: month_seq — 生成未来月份序列（当前月+1 ~ 今年12月）
WITH month_seq AS (
    SELECT 1 AS offset UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
)
,target_months AS (
    SELECT
        DATE_FORMAT(DATE_ADD(
            STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
            INTERVAL m.offset MONTH
        ), '%Y%m') AS target_month
        ,LAST_DAY(DATE_ADD(
            STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
            INTERVAL m.offset MONTH
        )) AS target_month_end
    FROM month_seq m
    WHERE DATE_FORMAT(DATE_ADD(
            STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
            INTERVAL m.offset MONTH
        ), '%Y') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')  -- 限制在今年内
)
-- CTE2: base_data — 获取基准月（昨天所在月）的日立全量数据（含在产+未上市）
,base_data AS (
    SELECT
        business_division   --事业部
        ,company
        ,product_line
        ,kt_nbzz  --空气事业部内部组织
        ,in_out_sale  --内销/外销
        ,model  --销售型号名称（日立管理口径）
        ,IR_act_time  --实际上市时间
        ,delisted_time  --停止生产时间
        ,model_label_10  --阶段（在产/未上市/老品）
        ,model_label_16  --在销型号数范围
        ,product_big  --产品大类
        ,product_mid  --产品中类
        ,product_sml  --产品小类
        ,platform  --产品平台
        ,productmodel  --产品型号名称
        ,chanpindingwei  --产品定位
        ,plan_base  --规划生产基地
        ,brand  --品牌
        ,productmodel__life  --产品生命周期状态
        ,act_time_ss  --上市时间
        ,act_time_tszb  --退市准备
        ,act_time_tzxd  --停止下单
        ,act_time_tzsc  --停止生产
        ,is_project  --是否保护期
        ,PG00015  --产品公司
        ,productmodel_id  --产品型号id
        ,salemodel  --销售型号名称
        ,salemodel_code  --销售型号编码
        ,salemodel_id  --销售型号id
        ,PC20080  --归属营销部
        ,HX00379  --是否模块组合
        ,PC20006  --标准品/定制产品
        ,is_project_nk  --内控口径
        ,matnr  --物料编码
        ,HX00327  --所有者
        ,PC20018  --非标对应原型机
        ,PG00009  --产品系列
        ,PG00024  --规划停止下单时间
        ,HX00502  --规划停止生产时间
    FROM dws.dws_ipd_ipm_sale_model_detail_dd
    WHERE dt_month = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y%m')
        AND company = '空调公司'
        AND product_line = '中央空调'
        AND dt_type = '月'
        AND model_label_10 != '老品清零'  -- 排除已清零（不参与预测）
)
-- CTE3: forecast_lifecycle — base_data × 月份序列，逐月生命周期
,forecast_lifecycle AS (
    SELECT
        tm.target_month
        ,tm.target_month_end
        ,b.business_division   --事业部
        ,b.company
        ,b.product_line
        ,b.kt_nbzz  --空气事业部内部组织
        ,b.in_out_sale  --内销/外销
        ,b.model  --销售型号名称
        ,b.IR_act_time  --实际上市时间
        ,b.delisted_time  --停止生产时间
        ,b.model_label_10  --基准月阶段
        ,b.model_label_16  --在销型号数范围
        ,b.product_big  --产品大类
        ,b.product_mid  --产品中类
        ,b.product_sml  --产品小类
        ,b.platform  --产品平台
        ,b.productmodel  --产品型号名称
        ,b.chanpindingwei  --产品定位
        ,b.plan_base  --规划生产基地
        ,b.brand  --品牌
        ,b.act_time_ss  --上市时间
        ,b.act_time_tszb  --退市准备
        ,b.act_time_tzxd  --停止下单
        ,b.act_time_tzsc  --停止生产
        ,b.PG00015  --产品公司
        ,b.productmodel_id  --产品型号id
        ,b.salemodel  --销售型号名称
        ,b.salemodel_code  --销售型号编码
        ,b.salemodel_id  --销售型号id
        ,b.PC20080  --归属营销部
        ,b.HX00379  --是否模块组合
        ,b.PC20006  --标准品/定制产品
        ,b.matnr  --物料编码
        ,b.HX00327  --所有者
        ,b.PC20018  --非标对应原型机
        ,b.PG00009  --产品系列
        ,b.PG00024  --规划停止下单时间
        ,b.HX00502  --规划停止生产时间
        -- 预测生命周期状态
        ,CASE
            -- 规划停止生产时间 <= 目标月末 → 停止生产（退市）
            WHEN b.HX00502 IS NOT NULL AND b.HX00502 <= tm.target_month_end
                THEN '停止生产'
            -- 规划停止下单时间 <= 目标月末 → 停止下单（仍在产）
            WHEN b.PG00024 IS NOT NULL AND b.PG00024 <= tm.target_month_end
                THEN '停止下单'
            -- 未上市型号：上市时间 <= 目标月末 → 上市
            WHEN b.model_label_10 = '未上市' AND b.act_time_ss IS NOT NULL AND b.act_time_ss <= tm.target_month_end
                THEN '上市'
            -- 其他保持原状态
            ELSE b.productmodel__life
        END AS productmodel__life_forecast
        -- 预测阶段（jieduan）
        ,CASE
            WHEN b.HX00502 IS NOT NULL AND b.HX00502 <= tm.target_month_end
                THEN '退市'
            WHEN b.PG00024 IS NOT NULL AND b.PG00024 <= tm.target_month_end
                THEN '在产'
            WHEN b.model_label_10 = '未上市' AND b.act_time_ss IS NOT NULL AND b.act_time_ss <= tm.target_month_end
                THEN '在产'
            WHEN b.model_label_10 IN ('在产','老品') THEN
                CASE WHEN b.productmodel__life IN ('上市','退市准备','停止下单') THEN '在产'
                     WHEN b.productmodel__life IN ('停止服务','停止生产') THEN '退市'
                     ELSE '未上市'
                END
            WHEN b.model_label_10 = '未上市' THEN '未上市'
            ELSE '未上市'
        END AS jieduan_forecast
    FROM base_data b
    CROSS JOIN target_months tm
)
-- CTE4: forecast_result — 重新判定is_project/is_project_nk
,forecast_result AS (
    SELECT
        t.*
        -- 预测后的model_label_10
        ,CASE
            WHEN jieduan_forecast = '退市' THEN '老品清零'
            WHEN jieduan_forecast = '未上市' THEN '未上市'
            ELSE '在产'
        END AS model_label_10_forecast
        -- 预测后的is_project（集团口径）
        ,CASE
            WHEN product_sml NOT IN ('单元式内机','单元式外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','新风换气机') THEN 'Y'
            WHEN product_mid = '空气调节类配件' THEN 'Y'
            WHEN jieduan_forecast != '在产' THEN 'Y'
            WHEN COALESCE(PC20006, '标准品') != '标准品' THEN 'Y'
            WHEN COALESCE(plan_base, '正常') = '1000-海信日立委外工厂' THEN 'Y'
            WHEN COALESCE(HX00379, '否') = '是' THEN 'Y'
            ELSE 'N'
        END AS is_project_forecast
        -- 预测后的is_project_nk（内控口径）
        ,CASE
            WHEN jieduan_forecast != '在产' THEN 'Y'
            WHEN COALESCE(PC20006, '标准品') != '标准品' THEN 'Y'
            WHEN COALESCE(plan_base, '正常') = '1000-海信日立委外工厂' THEN 'Y'
            WHEN COALESCE(HX00379, '否') = '是' THEN 'Y'
            ELSE 'N'
        END AS is_project_nk_forecast
        -- 预测后的model_label_16（指标范围）
        ,CASE
            WHEN COALESCE(PC20006, '标准品') != '标准品' THEN 'N'
            WHEN COALESCE(plan_base, '正常') = '1000-海信日立委外工厂' THEN 'N'
            WHEN COALESCE(HX00379, '否') = '是' THEN 'N'
            ELSE 'Y'
        END AS model_label_16_forecast
    FROM forecast_lifecycle t
)
-- 最终SELECT：输出所有未来月份的预测数据（排除退市和未上市）
SELECT
    target_month AS dt_month
    ,'月' AS dt_type
    ,business_division   --事业部
    ,company
    ,product_line
    ,kt_nbzz  --空气事业部内部组织
    ,in_out_sale  --内销/外销
    ,model  --销售型号名称
    ,IR_act_time  --实际上市时间
    ,delisted_time  --停止生产时间
    ,model_label_10_forecast AS model_label_10  --预测后阶段
    ,model_label_16_forecast AS model_label_16  --预测后指标范围
    ,target_month_end AS dt_day
    ,product_big  --产品大类
    ,product_mid  --产品中类
    ,product_sml  --产品小类
    ,platform  --产品平台
    ,productmodel  --产品型号名称
    ,chanpindingwei  --产品定位
    ,plan_base  --规划生产基地
    ,brand  --品牌
    ,productmodel__life_forecast AS productmodel__life  --预测后生命周期
    ,act_time_ss  --上市时间
    ,act_time_tszb  --退市准备
    ,act_time_tzxd  --停止下单
    ,act_time_tzsc  --停止生产
    ,is_project_forecast AS is_project  --预测后是否保护期
    ,CASE WHEN DATE_FORMAT(act_time_ss, '%Y%m') = target_month THEN '本月上市' ELSE NULL END AS shangshi_m  --本月上市
    ,NULL AS tuishijuece_m  --本月退市决策
    ,CASE WHEN DATE_FORMAT(HX00502, '%Y%m') = target_month THEN '本月停产' ELSE NULL END AS tingchan_m  --本月停产
    ,PG00015  --产品公司
    ,productmodel_id  --产品型号id
    ,salemodel  --销售型号名称
    ,salemodel_code  --销售型号编码
    ,salemodel_id  --销售型号id
    ,PC20080  --归属营销部
    ,HX00379  --是否模块组合
    ,PC20006  --标准品/定制产品
    ,is_project_nk_forecast AS is_project_nk  --预测后内控口径
    ,NOW() AS load_dt
    ,matnr  --物料编码
    ,HX00327  --所有者
    ,PC20018  --非标对应原型机
    ,PG00009  --产品系列
    ,PG00024  --规划停止下单时间
    ,HX00502  --规划停止生产时间
FROM forecast_result
WHERE jieduan_forecast != '退市'    -- 退市=老品清零，不纳入预测在销范围
    AND jieduan_forecast != '未上市' -- 目标月仍未上市的也不纳入
;





delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '视像科技' and dt_type = '月'
and dt_day < CAST('${GP_START_DT}' AS DATE) 
and model_label_10 <> '老品清零'
;
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '视像科技' and dt_type = '月'
and dt_day >= CAST('${GP_START_DT}' AS DATE)
;
insert into dws.dws_ipd_ipm_sale_model_detail_dd(dt_month
,dt_type
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,productmodel--产品型号名称
,IR_act_time
,delisted_time
,inventory_qty
,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,brand--品牌
,chanpindingwei--产品定位
,platform--产品平台
,sale_country  --销售国家名称
,plan_channel--规划销售渠道
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzsc--停止生产
,productmodel__life--产品生命周期状态
,model_label_16   --在销型号数范围
,model_label_10   --阶段
,model_label_12  --品牌分组
,is_project   --是否保护期
,kcql_time  --库存清零时间
,shangshi_m  --本月上市
,tuishijuece_m   --本月退市决策
,tingchan_m   --本月停产
,kcqw_m   --本月库存清零
,dt_day
,load_dt 
,countries_regions  --立项国家及区域
,productline_tv  --产品线（电视）
)
with kucun_qingwei as (
--自有库存清尾时间
select 
product_line 
,coalesce (model,prdct_model) as model
,min(dt_day) as min_kucunqingwei 
from dws.dws_ipd_ipm_sale_model_detail_dd
where  product_line in ('视像科技')
and company not like '%商家库存%'
and dt_type = '月'
and (model_label_10 = '老品清零' or (delisted_time is not null and coalesce(inventory_qty,0)= 0))
group by product_line 
,coalesce (model,prdct_model)
)

,tv_model as (
select 
title	--产品型号产品描述（中文）
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,his_productsbrand	--品牌名称
,his_oembrand	--OEM品牌名称
,his_pmdproductpositioning	--产品定位名称
,his_domesticsalesorexport	--内销/外销名称
,his_prdplatform	--产品平台名称
,his_salescountries	--销售国家名称
,his_plannedsaleschannel	--规划销售渠道
,his_actualtimetomarket	--实际上市时间
,his_actualdelistingtime	--实际退市时间
,his_stopproductiontime	--停止生产时间
,'Y' as is_zhibiaofanwei
,lifecycle_status	--产品型号生命周期状态名称
,case when lifecycle_status in ('上市','退市准备') then '在产'
when lifecycle_status in ('停止服务','停止生产','停止下单') then '退市'
else '未上市' end as jieduan
,data_source
from dim.dim_ipd_jtplm_his_productmodel_dd
where his_productbigcategories = '显示类产品'
and his_productsmallcategories = '平板电视'

)
,kc_nx as ( 
---视像在销型号
SELECT 
coalesce (t2.model,t1.model) as model
,sum(t1.stock_namber) AS sm
from test.dwfi_tf_fa_tvp_flfzlmx t1
left join (select distinct model, model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) t2
on t1.model = t2.model_nengxiao
where t1.batch ='H'
and t1.daymonth_flag=0
and t1.load_dt = DATE_ADD(cast('${GP_START_DT}' as date), INTERVAL 1 DAY)
AND t1.matkl IN ('1100101','1100112','1100122','1100601')
AND t1.fl in ('ZMM012','ZSD041'/*,'ZRSD005'*/)   --20221209调整   只取012库存     20240604  取消ZRSD005库存
AND substring(t1.model,1,2) != 'TH' 
AND substring(t1.model,length(t1.model)-3) != 'M11P'
AND coalesce(t1.leibie,'0') <> '借机'
GROUP BY coalesce (t2.model,t1.model)
--0是日报，1是月报
--业务是按照日报取得数据，如果取2月28号数据，那就是看load_dt为3月1号的数据
--load_dt为今天，是昨天的数据
--,如果是取月的数据，就是取load_dt为每个月1号的数据，就是上个月的值
--1、类别：选正品、批次选H。2、物料组：选平板电视、VIDDA电视、触控智慧屏。3、分类：去掉ZRSD005的数据（研发库存，新品未下线）。
--4、去掉OEM代工产品（目前根据机型国美（尾缀M11P）、松下（TH开头）机型手工剔除，没有明确区分字段）。
--5、如果还有一些显示器或者其他非平板电视机型，手动删除，如CRF6A89等。
)
,kc_wx as (
--海外分公司库存
select 
matnr 
,werks 
,charg
,zcusmodel
,zmodel
,zfacmodel
,vtext 
,clabs as kc_sum --库存数量
,landx
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
where lfgja = DATE_FORMAT('${GP_START_DT}', '%Y') 
and lfmon = DATE_FORMAT('${GP_START_DT}', '%m')
and vtext = '多媒体-电视(LED)'  
and case when cast('${GP_START_DT}' as date)  <= cast('2024-02-29' as date) then 1=1 else udate = cast('${GP_START_DT}' as date) end   --回滚数据专用
and lgort is not null   --库存地点不为空
and zkwlb = 'A'     --库位类型为A   
and substring(werks,1,2) <> '80'   --海外分公司库存库存
and case when quzu_rd = '东盟区' then matnr not like '1TE%' else 1=1 end --20240419邮件剔除库存明细中的东盟区样机
and quzu_rd in ('国际营销','东盟区')


union all 
--基地库存
select 
matnr 
,werks 
,charg 
,null
,null
,null
,gtext 
,menge 
,zywqy
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
where gjahr = DATE_FORMAT('${GP_START_DT}', '%Y')
and monat = DATE_FORMAT('${GP_START_DT}', '%m')
and pdate = cast('${GP_START_DT}' as date) 
and gtext = '多媒体.LED'
and quzu_rd in ('国际营销','东盟区','东南亚' )

union all 
--在途库存
select 
matnr 
,bukrs 
,bwtar 
,zcusmodel 
,null as zmodel
,zfacmodel 
,vtext 
,menge as menge
,null 
,related_rd 
,zmodel_rd 
,quzu_rd 
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
where SPART_rd = '14'
and budat = cast('${GP_START_DT}' as date)  
and bukrs not in ('8300','8320','8330','8370','8380','8390','83B0')  --不取欧洲8300德国，8320俄罗斯，8330意大利，8370意大利，8380法国，8390捷克，83B0欧研
and menge >=1  --负值跟0不取


union all 

--日本TVS库存数量

select 
null 
,null 
,null 
,null 
,null 
,null 
,null 
,ct
,null 
,related_rd
,null 
,'TVS' as quzu 
,t2.modelname as prouductmodel_rd
,null as salemodel_rd
,null as salemodelid_rd
,null as productionversion_rd
from ( 
select
sum(hisense_cnt) as ct
,related_rd
from test.DWHO_IM_TF_QDKC_GJYX_TVS_SUM 
LATERAL VIEW explode(SPLIT_BY_STRING(zfacmodel, ','))tmp as related_rd 
where dt_day = DATE_FORMAT('${GP_START_DT}', '%Y%m%d')
and zfacmodel IS NOT NULL AND zfacmodel != ''
group by related_rd
) t1 
left join (select distinct
name  --生产版本产品描述（中文）
,modelname --产品型号
from dim.dim_ipd_jtplm_his_productversion_dd
where his_productbigcategories = '显示类产品') t2
on t1.related_rd = t2.name


)


,kc_all as ( 
--外销库存数量
select 
prouductmodel_rd as productmodel
,'外销' as in_out_sale
,sum(kc_sum) as kc_sum
from kc_wx
group by prouductmodel_rd


union all 

select 
model
,'内销' as in_out_sale
,sum(sm) as kc_sum
from kc_nx t1
group by model
)
,zx_model as (
select 
t1.title	--产品型号产品描述（中文）
,t1.his_productbigcategories	--产品大类名称
,t1.his_productmiddlecategories	--产品中类名称
,t1.his_productsmallcategories	--产品小类名称
,t1.his_productsbrand	--品牌名称
,t1.his_oembrand	--OEM品牌名称
,t1.his_pmdproductpositioning	--产品定位名称
,t1.his_domesticsalesorexport	--内销/外销名称
,t1.his_prdplatform	--产品平台名称
,t1.his_salescountries	--销售国家名称
,t1.his_plannedsaleschannel	--规划销售渠道
,t1.his_actualtimetomarket	--实际上市时间
,t1.his_actualdelistingtime	--实际退市时间
,t1.his_stopproductiontime	--停止生产时间
,t1.lifecycle_status	--产品型号生命周期状态名称
,t1.is_zhibiaofanwei
,case when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) = 0 then '老品清零'
when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) <> 0 then '老品'
else t1.jieduan end as jieduan
,t2.kc_sum  --库存数量
from tv_model t1 
left join kc_all t2 
on t1.title = t2.productmodel
)



select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,'月' as dt_type
,'显示事业部' as business_division   --事业部
,'视像科技' as company
,'视像科技' as product_line
,t1.his_domesticsalesorexport	--内销/外销名称
,t1.title	--产品型号产品描述（中文）
,t1.title	--产品型号产品描述（中文）
,t1.his_actualtimetomarket	--实际上市时间
,t1.his_actualdelistingtime	--实际退市时间
,t1.kc_sum  --库存数量
,t1.his_productbigcategories	--产品大类名称
,t1.his_productmiddlecategories	--产品中类名称
,t1.his_productsmallcategories	--产品小类名称
,t1.his_productsbrand	--品牌名称
,t1.his_pmdproductpositioning	--产品定位名称
,t1.his_prdplatform	--产品平台名称
,t1.his_salescountries	--销售国家名称
,t1.his_plannedsaleschannel	--规划销售渠道
,t1.his_actualtimetomarket	--实际上市时间
,t1.his_actualdelistingtime	--实际退市时间
,t1.his_stopproductiontime	--停止生产时间
,t1.lifecycle_status	--产品型号生命周期状态名称
,t1.is_zhibiaofanwei as model_label_16  --指标范围
,t1.jieduan as model_label_10
,case when coalesce(t1.his_productsbrand,'0')  = 'OEM品牌' then 'OEM'
when coalesce(t1.his_productsbrand,'0')  = 'Hisense' then '海信'
when coalesce(t1.his_productsbrand,'0')  = 'TOSHIBA'  then '东芝'
when coalesce(t1.his_productsbrand,'0')  = 'Vidda'  then 'Vidda'
else t1.his_productsbrand end as model_label_12
,case when t1.is_zhibiaofanwei = 'N' then 'Y'    --去掉指标范围外的
 when t1.jieduan  in ('未上市','老品清零','其他') then 'Y'  
 when t1.jieduan in ('老品') and t2.productmodel is not null then 'Y'   --去除以前清尾库存的型号
 when t3.model_nengxiao is not null then 'Y'  --去除能效机型号
 else 'N' end as is_project
,case when t1.jieduan = '老品清零' then coalesce (t4.min_kucunqingwei,cast('${GP_START_DT}' as date)  ) else t4.min_kucunqingwei end 库存清尾时间--库存清尾 
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_actualtimetomarket, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月上市' else null end 本月上市 --本月上市标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_actualdelistingtime, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月退市决策' else null end 退市决策--退市决策标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_stopproductiontime, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停产' else null end 本月停产--本月停产标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(
case when t1.jieduan = '老品清零' then coalesce (t4.min_kucunqingwei,cast('${GP_START_DT}' as date)  ) else t4.min_kucunqingwei end 
, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停止销售' else null end 本月停止销售--本月库存清尾完成
,cast('${GP_START_DT}' as date) as dt_day
,now()
,t5.countries_regions  --立项国家及区域
,t5.his_pmdproductlinename  --产品线
from zx_model t1 
left join (
--临时逻辑  要使用productmodel 字段
select distinct coalesce (productmodel ,model) as  productmodel from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '视像科技'
and in_out_sale = '内销'
and model_label_10 = '老品清零'
and company not like '%商家库存%'
and dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
) t2
on t1.title = t2.productmodel
left join (select distinct model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) t3
on t1.title = t3.model_nengxiao
left join kucun_qingwei t4 
on t1.title = t4.model
left join (
--生产版本下产品型号对应的【产品线】、【立项国家及区域】
select 
modelname
,group_concat(distinct his_pmdproductlinename)as his_pmdproductlinename  --产品线
,group_concat(distinct countries_regions)as countries_regions  --立项国家及区域
from dim.dim_ipd_jtplm_his_productversion_dd
where his_productsmallcategories = '平板电视'
group by modelname
)t5
on t1.title = t5.modelname
;













---------------------------------------------------------在销型号数  厨电 内外销 产品型号口径 ----------------------------------------------------
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '厨电'
and product_line in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱') and dt_type = '月'
and dt_day < CAST('${GP_START_DT}' AS DATE) 
and model_label_10 <> '老品清零'
;
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '厨电'
and product_line in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱') and dt_type = '月'
and dt_day >= CAST('${GP_START_DT}' AS DATE)
;
insert into dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company
,product_line 
,in_out_sale
,model
,prdct_model
,matnr
,IR_act_time
,delisted_time
,inventory_qty
,model_label_1
,model_label_2
,model_label_3
,model_label_4   --规划生产基地（来自生产版本PC00025，合并去重）
,model_label_5
,model_label_6
,model_label_7
,model_label_8
,model_label_10
,model_label_16   --在销型号数范围
,dt_day
,is_project 
,kcql_time  --库存清零时间
,shangshi_m  --本月上市
,tuishijuece_m   --本月退市决策
,tingchan_m   --本月停产
,kcqw_m   --本月库存清零
,load_dt 

,product_big--产品大类
,product_mid--产品中类
,product_sml--产品小类
,platform--产品平台
,productmodel--产品型号名称
,chanpindingwei--产品定位
,plan_base--规划生产基地（来自生产版本PC00025，合并去重）
,brand--品牌
,productmodel__life--产品生命周期状态
,salesarea_big--销售大区
,salesarea_sml--销售小区
,export_method--出口方式
,is_biaoji--是否标机
,is_yangji--是否样机
,menlei--门类
,plan_channel--规划销售渠道
,pinleixifen--品类细分
,act_time_ss--上市时间
,act_time_tszb--退市准备
,act_time_tzxd--停止下单
,act_time_tzsc--停止生产
,productmodel_id  --产品型号id
)

--厨电内销外销
with kucun_qingwei as (
--自有库存清尾时间
select 
product_line 
,in_out_sale
,coalesce (model,prdct_model) as model
,min(dt_day) as min_kucunqingwei 
from dws.dws_ipd_ipm_sale_model_detail_dd
where  product_line in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')
and company = '厨电'
and dt_type = '月'
and (model_label_10 = '老品清零' or (delisted_time is not null and coalesce(inventory_qty,0)= 0))
group by product_line 
,coalesce (model,prdct_model),in_out_sale
)
,productionversion_base as (
--生产版本规划生产基地（按产品型号合并去重，逗号分隔）
select 
productmodel
,GROUP_CONCAT(DISTINCT PC00025 ORDER BY PC00025) as plan_base_merged
from dim.dim_ipd_productionversion_dd
where PC00025 is not null and PC00025 <> ''
group by productmodel
)
,product_model as (

select 
id
,PG00061	--名称
,product_line  --产品线（来自HX00223）
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
,PC00025	--规划生产基地（产品型号表原始值，备用）
,HX00226	--出口方式
,HX00027	--是否样机
,HX00026	--是否标机
,HX00025	--出口国家
,HX00024	--销售小区
,HX00023	--销售大区
,PC10050    --门类
,PC00001    --品类细分
,is_zhibiaofanwei
,jieduan
,HX00501 as act_time_tszb  --实际时间-退市准备
,PG00027 as act_time_tzsc  --停止生产时间
,PG00026 as act_time_tzxd  --实际停止下单
,PG00025 as act_time_ss  --实际上市时间
from (
select 
id
,PG00061	--名称
--厨电产品线：直接使用HX00223字段，仅保留6个目标产品线
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
,HX00226	--出口方式
,HX00027	--是否样机
,HX00026	--是否标机
,HX00025	--出口国家
,HX00024	--销售小区
,HX00023	--销售大区
,PC10050    --门类
,PC00001    --品类细分
--厨电指标范围判定
,case when PG00020 = '内销' then case 
--内销：剔除空壳机（型号名含"空壳机"）
when PG00061 like '%空壳机%' then 'N'
--内销：剔除配件（中类为"吸油烟机配件"）
when PG00003 = '吸油烟机配件' then 'N'
--内销：品牌必须为Hisense
when coalesce(PG00005,'') <> 'Hisense' then 'N'
else 'Y' end 
when PG00020 = '外销' then case 
--外销：剔除散件（型号名以"/SKD"结尾，仅洗碗机有）
when PG00061 like '%/SKD' then 'N'
--外销：剔除样机（型号名以"YJ"结尾）
when PG00061 like '%YJ' then 'N'
else 'Y' end 
else 'Y' end as is_zhibiaofanwei
--生命周期阶段判定（同冰箱）
,case when PG00029 in ('上市','退市准备','停止下单') then '在产'
when PG00029 in ('停止服务','停止生产') then '退市'
else '未上市' end as jieduan
,PG00027  --停止生产时间
,HX00501  --退市准备时间
,PG00025  --实际上市时间
,PG00026  --实际停止下单时间
from dim.dim_ipd_productmodel_dd t1  --产品型号
)a 
where product_line in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')

)

,kc_nx as ( 
--内销库存
select 
matnr
,sum(qty) as kc_sum
from ( 
--山东厨卫产成品明细
select 
wlh as matnr  --物料号
,zzysl as qty    --总站用量
from dws.dws_fi_mr_kbsp_ccpmx_di
where daymonth_flag = '0'
and kcfl = '正品'
and load_dt = date_add(cast('${GP_START_DT}' as date), interval 1 day)
)t1
group by matnr

)
,kc_wx as (
--外销库存（厨电：6A 家电-炉灶具，6B 家电-洗碗机，65 家电-小家电）
--产品线统一写'厨电'占位，暂不做细分映射
--海外分公司库存
select 
matnr 
,werks 
,charg
,zcusmodel
,zmodel
,zfacmodel
,vtext 
,clabs as kc_sum --库存数量
,landx
,related_rd
,zmodel_rd
,quzu_rd
,'厨电' as product_line
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
where lfgja = DATE_FORMAT('${GP_START_DT}', '%Y') 
and lfmon = DATE_FORMAT('${GP_START_DT}', '%m')
and vtext in ('家电-炉灶具','家电-洗碗机','家电-小家电') 
and udate = cast('${GP_START_DT}' as date) 
and lgort is not null   --库存地点不为空
and zkwlb = 'A'     --库位类型为A   
and substring(werks,1,2) <> '80'   --海外分公司库存
and quzu_rd in ('国际营销','东盟区')

union all 
--基地库存
select 
matnr 
,werks 
,charg 
,null
,null
,null
,gtext 
,menge 
,zywqy
,related_rd
,zmodel_rd
,quzu_rd
,'厨电' as product_line
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
where gjahr = DATE_FORMAT('${GP_START_DT}', '%Y')
and monat = DATE_FORMAT('${GP_START_DT}', '%m')
and pdate = cast('${GP_START_DT}' as date) 
and gtext in ('家电.炉灶具','家电.洗碗机','家电.小家电')
and quzu_rd in ('国际营销','东盟区')

union all 
--在途库存
select 
matnr 
,bukrs 
,bwtar 
,zcusmodel 
,null as zmodel
,zfacmodel 
,vtext 
,menge 
,null 
,related_rd 
,zmodel_rd 
,quzu_rd 
,'厨电' as product_line
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
,country_rd
,xiaolei_rd
from dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
where SPART_rd in ('6A','6B','65')
and budat = cast('${GP_START_DT}' as date) 
and bukrs not in ('8300','8320','8330','8370','8380','8390','83B0')  --不取欧洲8300德国，8320俄罗斯，8330意大利，8370意大利，8380法国，8390捷克，83B0欧研
and menge >=1  --负值跟0不取
)

,kc_all as ( 
--外销库存数量（占位，实际为空）
select 
prouductmodel_rd as productmodel
,'外销' as in_out_sale
,sum(kc_sum) as kc_sum
from kc_wx
group by prouductmodel_rd

union all 
--内销库存（通过MDG主数据 matnr→model_name 映射）
select 
t2.model_name   --产品型号
,'内销' as in_out_sale
,sum(t1.kc_sum) as kc_sum
from kc_nx t1
left join (
select 
product_code
,model_name 
from dw.dim_product_base_info_dd
where product_type_code='FERT'
and delete_flag!='Y'
) t2 
on t1.matnr = t2.product_code
group by t2.model_name   --产品型号
)
,zx_model as ( 
select 
t1.id
,t1.PG00061	--名称
,t1.product_line  --产品线
,t1.PG00029	--产品型号生命周期状态
,t1.PG00021	--规划销售渠道
,t1.PG00020	--内销/外销
,t1.PG00019	--产品定位
,t1.PG00015	--产品公司
,t1.PG00014	--产品平台
,t1.PG00005	--品牌
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PC00025	--规划生产基地（产品型号表）
,t1.HX00226	--出口方式
,t1.HX00027	--是否样机
,t1.HX00026	--是否标机
,t1.HX00025	--出口国家
,t1.HX00024	--销售小区
,t1.HX00023	--销售大区
,t1.PC10050    --门类
,t1.PC00001    --品类细分
,t2.kc_sum  --库存数量
,t1.is_zhibiaofanwei  --指标范围
--库存清零判定（同冰箱）
,case when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) = 0 then '老品清零'
when t1.jieduan = '退市' and coalesce (t2.kc_sum,0.0) <> 0 then '老品'
else t1.jieduan end as jieduan
,t1.act_time_ss   --实际时间-上市
,t1.act_time_tszb  --实际时间-退市准备
,act_time_tzxd	--实际时间-停止下单
,act_time_tzsc	--实际时间-停止生产
from product_model t1 
left join kc_all t2 
on t1.PG00061 = t2.productmodel
and t1.PG00020 = t2.in_out_sale
)
select distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,'月' as dt_type
,'厨电事业部' as business_division   --事业部
,'厨电' as company
,t1.product_line  --产品线
,t1.PG00020	--内销/外销
,t1.PG00061	--名称
,null as prdct_model
,t4.PG00031 as matnr
,t1.act_time_ss   --实际时间-上市
,t1.act_time_tzsc	--实际时间-停止生产
,t1.kc_sum  --库存数量

,t1.PG00014	--产品平台（model_label_1占位）
,t1.PG00021	--规划销售渠道（model_label_2占位）
,t1.PG00005	--品牌（model_label_3占位）
,t5.plan_base_merged  --model_label_4：规划生产基地（来自生产版本，合并去重）
,t1.PG00019	--产品定位（model_label_5占位）
,null as model_label_6
,null as model_label_7
,t1.PG00029	--产品型号生命周期状态（model_label_8占位）
,t1.jieduan  --阶段（model_label_10）
,t1.is_zhibiaofanwei  --指标范围（model_label_16）
,cast('${GP_START_DT}' as date) 
,case when t1.is_zhibiaofanwei = 'N' then 'Y'
when t1.jieduan in ('未上市','老品清零','其他') then 'Y'  
when t1.jieduan in ('老品') and t2.productmodel is not null then 'Y'   --去除以前清尾库存的型号
else 'N' end  as is_project
,case when t1.jieduan = '老品清零' then coalesce (t3.min_kucunqingwei,cast('${GP_START_DT}' as date) ) else t3.min_kucunqingwei end 库存清尾时间--库存清尾 
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_ss, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月上市' else null end 本月上市 --本月上市标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_tszb, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月退市决策' else null end 退市决策--退市决策标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.act_time_tzsc, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停产' else null end 本月停产--本月停产标识
,case when is_zhibiaofanwei = 'Y' and DATE_FORMAT(
case when t1.jieduan = '老品清零' then coalesce (t3.min_kucunqingwei,cast('${GP_START_DT}' as date) ) else t3.min_kucunqingwei end 
, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停止销售' else null end 本月停止销售--本月库存清尾完成
,now()

--新增字段
,t1.PG00002	--产品大类
,t1.PG00003	--产品中类
,t1.PG00004	--产品小类
,t1.PG00014	--产品平台
,t1.PG00061	--产品型号名称
,t1.PG00019	--产品定位
,t5.plan_base_merged  --规划生产基地（来自生产版本，合并去重，与model_label_4一致）
,t1.PG00005	--品牌
,t1.PG00029	--产品型号生命周期状态
,t1.HX00023	--销售大区
,t1.HX00024	--销售小区
,t1.HX00226	--出口方式
,t1.HX00026	--是否标机
,t1.HX00027	--是否样机
,t1.PC10050    --门类
,t1.PG00021	--规划销售渠道
,t1.PC00001    --品类细分
,t1.act_time_ss   --实际时间-上市
,t1.act_time_tszb  --实际时间-退市准备
,t1.act_time_tzxd	--实际时间-停止下单
,t1.act_time_tzsc	--实际时间-停止生产
,t1.id
from zx_model t1
left join (select distinct productmodel,in_out_sale from dws.dws_ipd_ipm_sale_model_detail_dd
where product_line in ('烟机','灶具','洗碗机','电热水器','燃气热水器','烤箱')
and model_label_10 = '老品清零'
and company = '厨电'
and dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
)t2
on t1.PG00061 = t2.productmodel
and t1.PG00020 = t2.in_out_sale
left join kucun_qingwei t3 
on t1.product_line = t3.product_line
and t1.PG00061 = t3.model
and t1.PG00020 = t3.in_out_sale
left join (select distinct productmodel,max(PG00031) as PG00031 from dim.dim_ipd_productionversion_dd group by productmodel) t4 
on t1.PG00061 = t4.productmodel
and t1.PG00020 = '内销'
left join productionversion_base t5
on t1.PG00061 = t5.productmodel
;


---------------------------------------------------------在销型号数 激光 内外销 产品型号口径 ----------------------------------------------------

delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光'
and product_line in ('激光家用','激光商用') and dt_type = '月'
and dt_day < CAST('${GP_START_DT}' AS DATE) 
and model_label_10 <> '老品清零'
;
delete from dws.dws_ipd_ipm_sale_model_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company = '激光'
and product_line in ('激光家用','激光商用') and dt_type = '月'
and dt_day >= CAST('${GP_START_DT}' AS DATE)
;
insert into dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division
,company
,product_line
,in_out_sale
,model
,productmodel
,IR_act_time
,delisted_time
,inventory_qty
,product_big
,product_mid
,product_sml
,brand
,chanpindingwei
,platform
,sale_country
,plan_channel
,act_time_ss
,act_time_tszb
,act_time_tzsc
,productmodel__life
,model_label_16
,model_label_10
,model_label_12
,is_project
,kcql_time
,shangshi_m
,tuishijuece_m
,tingchan_m
,kcqw_m
,dt_day
,load_dt
,focallength
)
with kucun_qingwei as (
-- 激光库存清尾时间
select 
product_line 
,in_out_sale
,coalesce(model, prdct_model) as model
,min(dt_day) as min_kucunqingwei 
from dws.dws_ipd_ipm_sale_model_detail_dd
where product_line in ('激光家用','激光商用')
and company = '激光'
and dt_type = '月'
and (model_label_10 = '老品清零' or (delisted_time is not null and coalesce(inventory_qty,0) = 0))
group by product_line
,coalesce(model, prdct_model), in_out_sale
)
-- 产品线判定：通过生产版本按产品型号聚合产品线（逗号分隔）
,jiguang_productline as (
select 
modelname
,group_concat(distinct his_pmdproductlinename) as his_pmdproductlinename
from dim.dim_ipd_jtplm_his_productversion_dd
where his_productsmallcategories in ('激光电视','家用投影','商用投影')
group by modelname
)
-- 激光型号基础信息
,jiguang_model as (
select 
title
,his_productbigcategories
,his_productmiddlecategories
,his_productsmallcategories
,his_productsbrand
,his_oembrand
,his_pmdproductpositioning
,his_domesticsalesorexport
,his_prdplatform
,his_salescountries
,his_plannedsaleschannel
,his_actualtimetomarket
,his_actualdelistingtime
,his_stopproductiontime
,his_focallength
,'Y' as is_zhibiaofanwei
,lifecycle_status
,case when lifecycle_status in ('上市','退市准备') then '在产'
    when lifecycle_status in ('停止服务','停止生产','停止下单') then '退市'
    else '未上市' end as jieduan
from dim.dim_ipd_jtplm_his_productmodel_dd
where his_pmdproductaffiliatedcompany = '激光显示'
and his_productsmallcategories in ('激光电视','家用投影','商用投影')
)
-- 内销库存（同视像逻辑）
,kc_nx as (

select 
sum(t1.kcsl) as sm --库存数量
,coalesce(t2.model, t1.model) as model --型号
from dws.dws_fi_mr_ldp_flfzlmx_di t1 
left join (select distinct model, model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd where product_line = '激光') t2
on t1.model = t2.model_nengxiao
where t1.load_dt = DATE_ADD(cast('${GP_START_DT}' as date), INTERVAL 1 DAY)  --load_dt = 今天,对应昨天的库存数量 
and t1.daymonth_flag = 0 
and t1.leibie = '正品'
group by coalesce(t2.model, t1.model)
)
-- 外销库存（3个源表，无TVS库存）
,kc_wx as (
-- 海外分公司库存（成品库存）
select 
matnr 
,werks 
,charg
,zcusmodel
,zmodel
,zfacmodel
,vtext 
,clabs as kc_sum
,landx
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
where lfgja = DATE_FORMAT('${GP_START_DT}', '%Y') 
and lfmon = DATE_FORMAT('${GP_START_DT}', '%m')
and vtext in ('多媒体-激光影院','多媒体-激光投影')
and case when cast('${GP_START_DT}' as date) <= cast('2024-02-29' as date) then 1=1 else udate = cast('${GP_START_DT}' as date) end
and lgort is not null
and zkwlb = 'A'
and substring(werks,1,2) <> '80'
and quzu_rd in ('国际营销','东盟区')

union all 
-- 基地库存（海外在途）
select 
matnr 
,werks 
,charg 
,null
,null
,null
,gtext 
,menge 
,zywqy
,related_rd
,zmodel_rd
,quzu_rd
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
where gjahr = DATE_FORMAT('${GP_START_DT}', '%Y')
and monat = DATE_FORMAT('${GP_START_DT}', '%m')
and pdate = cast('${GP_START_DT}' as date) 
and gtext in ('多媒体.激光投影','多媒体.激光电视')
and quzu_rd in ('国际营销','东盟区','东南亚')

union all 
-- 在途库存（海外在库）
select 
matnr 
,bukrs 
,bwtar 
,zcusmodel 
,null as zmodel
,zfacmodel 
,vtext 
,menge as menge
,null 
,related_rd 
,zmodel_rd 
,quzu_rd 
,prouductmodel_rd
,salemodel_rd
,salemodelid_rd
,productionversion_rd
from dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
where SPART_rd in ('17','24')
and budat = cast('${GP_START_DT}' as date)  
and bukrs not in ('8300','8320','8330','8370','8380','8390','83B0')
and menge >= 1

-- 注意：激光不取TVS库存
)

-- 库存汇总
,kc_all as ( 
-- 外销库存数量
select 
prouductmodel_rd as productmodel
,'外销' as in_out_sale
,sum(kc_sum) as kc_sum
from kc_wx
group by prouductmodel_rd

union all 
-- 内销库存数量
select 
model
,'内销' as in_out_sale
,sum(sm) as kc_sum
from kc_nx t1
group by model
)

-- 库存清零判定
,zx_model as (
select 
t1.title
,t1.his_productbigcategories
,t1.his_productmiddlecategories
,t1.his_productsmallcategories
,t1.his_productsbrand
,t1.his_oembrand
,t1.his_pmdproductpositioning
,t1.his_domesticsalesorexport
,t1.his_prdplatform
,t1.his_salescountries
,t1.his_plannedsaleschannel
,t1.his_actualtimetomarket
,t1.his_actualdelistingtime
,t1.his_stopproductiontime
,t1.his_focallength
,t1.is_zhibiaofanwei
,t1.lifecycle_status
,case when t1.jieduan = '退市' and coalesce(t2.kc_sum, 0.0) = 0 then '老品清零'
    when t1.jieduan = '退市' and coalesce(t2.kc_sum, 0.0) <> 0 then '老品'
    else t1.jieduan end as jieduan
,t2.kc_sum
from jiguang_model t1 
left join kc_all t2 
on t1.title = t2.productmodel
and t1.his_domesticsalesorexport = t2.in_out_sale
)

-- 最终SELECT
select 
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month
,'月' as dt_type
,'激光事业部' as business_division
,'激光' as company
,case when t5.his_pmdproductlinename like '%激光-商用产品线%' then '激光商用' else '激光家用' end as product_line
,t1.his_domesticsalesorexport as in_out_sale
,t1.title as model
,t1.title as productmodel
,t1.his_actualtimetomarket as IR_act_time
,t1.his_actualdelistingtime as delisted_time
,t1.kc_sum as inventory_qty
,t1.his_productbigcategories as product_big
,t1.his_productmiddlecategories as product_mid
,t1.his_productsmallcategories as product_sml
,t1.his_productsbrand as brand
,t1.his_pmdproductpositioning as chanpindingwei
,t1.his_prdplatform as platform
,t1.his_salescountries as sale_country
,t1.his_plannedsaleschannel as plan_channel
,t1.his_actualtimetomarket as act_time_ss
,t1.his_actualdelistingtime as act_time_tszb
,t1.his_stopproductiontime as act_time_tzsc
,t1.lifecycle_status as productmodel__life
,t1.is_zhibiaofanwei as model_label_16
,t1.jieduan as model_label_10
,case when coalesce(t1.his_productsbrand,'0') = 'OEM品牌' then 'OEM'
    when coalesce(t1.his_productsbrand,'0') = 'Hisense' then '海信'
    else t1.his_productsbrand end as model_label_12
,case when t1.is_zhibiaofanwei = 'N' then 'Y'
    when t1.jieduan in ('未上市','老品清零','其他') then 'Y'
    when t1.jieduan in ('老品') and t2.productmodel is not null then 'Y'
    when t3.model_nengxiao is not null then 'Y'
    when t1.his_productsmallcategories = '商用投影' then 'Y'
    when coalesce(t1.his_productsbrand,'0') = 'OEM品牌' then 'Y'
    else 'N' end as is_project
,case when t1.jieduan = '老品清零' then coalesce(t4.min_kucunqingwei, cast('${GP_START_DT}' as date)) else t4.min_kucunqingwei end as kcql_time
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_actualtimetomarket, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月上市' else null end as shangshi_m
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_actualdelistingtime, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月退市决策' else null end as tuishijuece_m
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(t1.his_stopproductiontime, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停产' else null end as tingchan_m
,case when t1.is_zhibiaofanwei = 'Y' and DATE_FORMAT(
    case when t1.jieduan = '老品清零' then coalesce(t4.min_kucunqingwei, cast('${GP_START_DT}' as date)) else t4.min_kucunqingwei end
    , '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m') then '本月停止销售' else null end as kcqw_m
,cast('${GP_START_DT}' as date) as dt_day
,now() as load_dt
,t1.his_focallength as focallength
from zx_model t1 
left join (
-- 历史已清零型号
select distinct coalesce(productmodel, model) as productmodel from dws.dws_ipd_ipm_sale_model_detail_dd
where company = '激光'
and model_label_10 = '老品清零'
and company not like '%商家库存%'
and dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
) t2
on t1.title = t2.productmodel
left join (select distinct model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) t3
on t1.title = t3.model_nengxiao
left join kucun_qingwei t4 
on t1.title = t4.model
and t1.his_domesticsalesorexport = t4.in_out_sale
left join jiguang_productline t5
on t1.title = t5.modelname
;



--插入年维度数据
delete from dws.dws_ipd_ipm_sale_model_detail_dd 
where company in ('冰冷','洗衣机','空调公司','视像科技','厨电','激光')
and dt_type = '年'
and dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
;
insert into dws.dws_ipd_ipm_sale_model_detail_dd(
dt_month
,dt_type
,business_division   --事业部
,company  --公司
,product_line  --产品线
,in_out_sale   --内外销
,model
,productmodel  --产品型号
,is_project  --是否保护期
,load_dt 
)
select distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m') as dt_month  --月份
,'年' as dt_type
,business_division   --事业部
,company  --公司
,product_line  --产品线
,in_out_sale   --内外销
,model  --产品型号 日立销售型号
,productmodel  --产品型号
,is_project  --是否保护期
,now()
from dws.dws_ipd_ipm_sale_model_detail_dd 
where substr(dt_month,1,4)  = DATE_FORMAT('${GP_START_DT}', '%Y') 
and dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰冷','洗衣机','空调公司','视像科技','厨电','激光')
and is_project = 'N'
and dt_type = '月'
;
