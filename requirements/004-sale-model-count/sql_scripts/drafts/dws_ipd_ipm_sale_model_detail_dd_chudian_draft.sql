-- [ARCHIVED] 已合入正式脚本(2026-06-08), 本文件仅供参考回溯
-- DORIS sql 
-- ******************************************************************** --
-- [已合入正式脚本] 2026-05-20 厨电逻辑已合并到 dws_ipd_ipm_sale_model_detail_dd.sql
-- ******************************************************************** --
-- 厨电事业部 - 在销型号数 DWS层明细（副本草稿 v2）
-- 参照：冰冷洗 内外销 产品型号口径 逻辑
-- 说明：业务逻辑等同冰箱产品线，仅筛选范围调整为厨电
-- v2变更：新增生产版本规划生产基地逻辑（model_label_4 + plan_base）
-- 状态：待用户确认后插入正式脚本 dws_ipd_ipm_sale_model_detail_dd.sql
-- ******************************************************************** --

---------------------------------------------------------在销型号数  厨电 内外销 产品型号口径 ----------------------------------------------------
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
