-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2025/12/17 08:18:08 GMT+08:00
-- ******************************************************************** --
--视像科技内销平台数指标
delete from dws.dws_ipd_ipm_platform_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '视像科技'
and in_out_sale = '内销'
and dt_type = '月';

insert into dws.dws_ipd_ipm_platform_detail_dd(
dt_month 
,dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform 
,model 
,prdct_model 
,model_label_2 
,model_label_3
,is_project 
,load_dt 
,is_productline_jy
,is_nwx_jy
) 
with tv_nx_model as ( 
SELECT
COALESCE (t2.newproductname,t1.prototypename) AS prototypename      --原型机
,t1.proudctname      --产品型号
,productline
,brand
,aappraisaltime
,is_daigong
,`recovery`
,case when delistingtime >= coalesce (`recovery`,'1990-01-01') then delistingtime else null end as delistingtime
,in_out_sale
,salecountry
,is_gcj  --是否工程机
,platformtitle
FROM (
select 
name as proudctname --生产版本产品描述（中文）
,modelname as prototypename--产品型号
,his_productbigcategories	--产品大类名称
,his_productmiddlecategories	--产品中类名称
,his_productsmallcategories	--产品小类名称
,platformtitle 	--产品平台名称
,his_productsbrand as brand	--品牌名称
,his_pmdproductlinename as productline --产品线
,case when cast(his_actualtimetomarket as date) >= DATE_ADD(cast('${GP_START_DT}' as date), INTERVAL 1 DAY) then null else his_actualtimetomarket end as aappraisaltime
,case when cast(his_actualdelistingtime as date) >= DATE_ADD(cast('${GP_START_DT}' as date), INTERVAL 1 DAY) then null else his_actualdelistingtime end as delistingtime
,case when cast(recovery_time as date) >= DATE_ADD(cast('${GP_START_DT}' as date), INTERVAL 1 DAY) then null else recovery_time end as `recovery`
,his_domesticsalesorexport as in_out_sale	--内销/外销名称
,is_gcj	--是否工程机
,is_daigong	--是否为代工产品
,his_salescountries as salecountry	--销售国家名称
,data_source  --数据来源
from dim.dim_ipd_jtplm_his_productversion_dd t1 
where his_productsmallcategories = '平板电视'
) t1 
LEFT JOIN dim.dim_ipd_tv_new_oldmodel_nd t2 
ON t1.prototypename = t2.oldproductname
where t1.in_out_sale = '内销'
--and not(aappraisaltime is null and delistingtime is null )  --去除未上市产品
and not(coalesce (aappraisaltime,'') = '' and coalesce (delistingtime,'') = '' )  --去除未上市产品
)
select 
t1.dt_month 
,'月' as dt_type 
,t1.business_division
,t1.company 
,t1.product_line 
,t1.in_out_sale 
,t2.platformtitle --平台名
,t1.model 
,t2.proudctname 
,t2.brand 
,t2.productline 
,t1.is_project 
,now()
,'N' as is_productline_jy
,'N' as is_nwx_jy
from dws.dws_ipd_ipm_zcmodel_detail_dd t1 
left join tv_nx_model t2
on t1.model = t2.prototypename
where t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and t1.company = '视像科技' and t1.in_out_sale = '内销'
and t1.is_project = 'N'
and t2.delistingtime is null   --在产产品
and t2.platformtitle <> '不涉及'
;

--冰冷洗内销平台数
delete from dws.dws_ipd_ipm_platform_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company  in ('冰冷','洗衣机')
and in_out_sale = '内销' and dt_type = '月';

insert into dws.dws_ipd_ipm_platform_detail_dd(
dt_month 
,dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform 
,model 
,prdct_model 
,matnr 
,is_project 
,load_dt 
,model_label_1 
,model_label_3
,is_productline_jy
,is_nwx_jy
)
select 
t1.dt_month 
,'月' as dt_type 
,t1.business_division
,t1.company 
,t1.product_line 
,t1.in_out_sale 
,t1.platform --平台名
,t1.model 
,t1.prdct_model 
,t1.matnr 
,(case when t2.is_exclusive_only = '是' then 'Y' else t1.is_project end) as is_project
,now()
,t1.model_label_13
,t1.model_label_3 --品牌
,case when t1.product_line in ('冰箱','冷柜') and t1.product_line <> t2.product_line then 'Y'  
else 'N'end as is_productline_jy
,case when t1.in_out_sale = '内销' and t2.shiyongquyu = '外销专用' then 'Y'
else 'N' end as is_nwx_jy
from dws.dws_ipd_ipm_zcmodel_detail_dd t1
left join (select * from dws.dws_ipd_ipm_platform_library_detail_dd
where platform is not null
and dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m'))t2 
on t1.platform = t2.platform
where t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and t1.company in ('冰冷','洗衣机') 
and t1.in_out_sale = '内销'
and t1.is_project = 'N'
and case when t1.product_line = '洗衣机' then coalesce (t1.platform,'正常') <> '其他' else 1=1 end   --20240807新增规则   支架和底座产品立项的时候会选平台为 其他
;

--冰冷洗出口平台数
delete from dws.dws_ipd_ipm_platform_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company in ('冰冷','洗衣机') 
and in_out_sale = '外销' and dt_type = '月';

insert into dws.dws_ipd_ipm_platform_detail_dd(
dt_month 
,dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform 
,model 
,prdct_model 
,matnr 
,model_label_10 
,is_project 
,load_dt 
,is_productline_jy
,is_nwx_jy
)
select 
t1.dt_month 
,'月' as dt_type 
,t1.business_division
,t1.company 
,t1.product_line 
,t1.in_out_sale 
,t1.platform --平台名
,t1.model 
,t1.prdct_model 
,t1.matnr 
,t1.model_label_12
,(case when t2.is_exclusive_only = '是' or t2.is_eurp_product = '是' then 'Y' 
when coalesce (t2.platform_state,'发布') not in ('发布','禁选') then 'Y'  --20250514  剔除未发布且被引用的平台
else t1.is_project end) as is_project  --20250328加
,now()
,case when t1.product_line in ('冰箱','冷柜') and t1.product_line <> t2.product_line then 'Y'  
else 'N'end as is_productline_jy
,case when t1.in_out_sale = '外销' and t2.shiyongquyu = '内销专用' then 'Y'
else 'N' end as is_nwx_jy
from dws.dws_ipd_ipm_zcmodel_detail_dd t1 
left join (select * from dws.dws_ipd_ipm_platform_library_detail_dd
where platform is not null
and dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m'))t2 
on t1.platform = t2.platform
where t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and t1.company in ('冰冷','洗衣机') 
and t1.in_out_sale = '外销'
and t1.is_project = 'N'
;

--视像科技外销平台数
delete from dws.dws_ipd_ipm_platform_detail_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '视像科技'
and in_out_sale = '外销' and dt_type = '月';

insert into dws.dws_ipd_ipm_platform_detail_dd(
dt_month 
,dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform 
,model 
,prdct_model 
,matnr 
,model_label_10 
,is_project 
,load_dt 
,is_productline_jy
,is_nwx_jy
)
select 
dt_month 
,'月' as dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform --平台名
,model 
,prdct_model 
,matnr 
,model_label_12
,is_project 
,now()
,'N' as is_productline_jy
,'N' as is_nwx_jy
from dws.dws_ipd_ipm_zcmodel_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '视像科技' and in_out_sale = '外销'
and is_project = 'N'
and platform <> '不涉及'
and platform not in ('HE315L1','HE426L7','HE425X3','HE550X3','HE500X3')   --CBG部门确定 剔除OEM定制平台
;

---------------------------------------------------------产品平台数 激光 内外销合并 ----------------------------------------------------
delete from dws.dws_ipd_ipm_platform_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '激光'
and dt_type = '月';

insert into dws.dws_ipd_ipm_platform_detail_dd(
dt_month 
,dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform 
,model 
,prdct_model 
,model_label_10
,is_project 
,load_dt 
,is_productline_jy
,is_nwx_jy
)
select 
dt_month 
,'月' as dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform
,model 
,productmodel as prdct_model
,brand as model_label_12
,is_project 
,now() as load_dt
,'N' as is_productline_jy
,'N' as is_nwx_jy
from dws.dws_ipd_ipm_zcmodel_detail_dd 
where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
and company = '激光'
and is_project = 'N'
and platform is not null
and platform <> '不涉及'
;

--海信日立
--日立公司产品平台数明细表
DELETE FROM dws.dws_ipd_ipm_platform_detail_dd WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') and company = '日立公司';

INSERT INTO dws.dws_ipd_ipm_platform_detail_dd (
dt_month
,dt_type
,business_division
,company
,product_line
,in_out_sale
,platform
,prdct_model
,matnr
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
,model_label_6
,model_label_7
,is_project
,load_dt
,is_productline_jy
,is_nwx_jy
,platform_classify 
,model_label_8  --非标标识
)
select 
DATE_FORMAT(t1.dt, '%Y%m') as dt_month1
,'月' --日期维度
,'空气事业部' as business_division
,'日立公司' as company1
,'日立公司' as product_line1
,t1.ha_prosaleregion   --内外销
--,t1.project_number 
--,t1.project_name
,t1.hhattrbasicproductinfo  --基础产品平台
,t1.product_name --产品名称
,t1.sap_number 
,t2.big_class_name
,t2.mid_class_name
,t2.sml_class_name
,t1.hhwhethercombinationmodules  --是否模块组合
,t1.product_current   --型号生命周期状态
,hhproductpurchasetype  --采购类型
,t1.sap_type_info
,case when t2.big_class_name = '产成品'
--and t2.mid_class_name in ('日立内销产成品','日立外销产成品')
and t1.ha_prosaleregion in ('内销','外销')
and t2.sml_class_name in ('室内机','室外机','新风换气机')
and product_current IN ('上市','预停签','退市','合同预留')
and hhwhethercombinationmodules = 'NO'
and hhproductpurchasetype = '自制'
and coalesce(t3.is_exclusive_only,'否') = '否'
then 'N' else 'Y' end as is_project
,now()
,'N' as is_productline_jy
,'N' as is_nwx_jy
,t3.platform_classify
,t1.ha_isstandardornonstandard  --非标标识
from dwd.dwd_ipd_ipm_rlxhyptgx_dd t1 
left join (select mdmid ,big_class_name ,mid_class_name ,sml_class_name from ods.odsmdm_mat_bi_base_info) t2 
on t1.sap_number = t2.mdmid
left join (select * from dws.dws_ipd_ipm_platform_library_detail_dd
where platform is not null
and product_line = '海信日立'
and dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m'))t3 
on t1.hhattrbasicproductinfo = t3.platform
where DATE_FORMAT(t1.dt, '%Y%m%d') =  DATE_FORMAT('${GP_START_DT}', '%Y%m%d')
;

--插入平台数年逻辑
DELETE FROM dws.dws_ipd_ipm_platform_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m') 
and company in ('冰冷','洗衣机','空调公司','视像科技','日立公司','激光')
and dt_type = '年'
;

insert into dws.dws_ipd_ipm_platform_detail_dd(
dt_month 
,dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform 
,model_label_10
,is_project
,load_dt 
)
select distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m')
,'年' as dt_type 
,business_division
,company 
,product_line 
,in_out_sale 
,platform 
,case when in_out_sale in ('出口','外销') and model_label_10 in ('国际营销','东盟区','东南亚','TVS') then model_label_10 else null end 
,is_project
,now()
from dws.dws_ipd_ipm_platform_detail_dd
where dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')
and substring(dt_month,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y')
and company in ('冰冷','洗衣机','空调公司','视像科技','日立公司','激光')
and dt_type = '月'
and is_project = 'N'
and is_productline_jy = 'N'
and is_nwx_jy = 'N'
;

DELETE FROM dws.dws_ipd_ipm_platform_detail_dd WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')and company = '宽带公司1';

INSERT INTO dws.dws_ipd_ipm_platform_detail_dd (
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,model
,prdct_model
,matnr
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
,model_label_6
,model_label_7
,model_label_8
,model_label_9
,model_label_10
,is_project
,load_dt
,model_label11
)
select 
distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month1
,'月'
,'宽带公司1' as company1
,wb.cplx --大产品线
,'全部' as in_out_sale1
,trim(pt.hbmtplatformname) as platform1
,cp.hbmtbasemodel --基本型号
,cp.hbmtcustomermodel --客户型号
,cp.hbmtmaterialcode --物料编码
,pt.hbmtplatformclassification --平台分类
,pt.hbmtplatformstatus --平台状态
,pt.hbmtproductline --产品线原始
,cast(pt.hbmtlaunchdate as date) --发布时间
,cast(pt.hbmtwithdrawaldate as date) --退市时间
,cast(cp.hbmtbasemodellaunchdate as date) --基本型号立项时间
,cast(cp.hbmtobsoletedate as date) --客户型号退市时间
,wb.syb  --事业部
,wb.cpx  --子产品线
,pt.hbmtplatformno --平台序号
--20250120 杨冉需求 终端平台改变和光模块一样 如果平台下面有型号 并且平台的状态是活着的就算活着的平台
--,case WHEN(pt.hbmtplatformclassification = 'market' AND pt.hbmtplatformstatus != 'Obsolete' and wb.cplx = '终端') THEN 'N'
--      WHEN('{START_DATE}'::date  >= cp.hbmtbasemodellaunchdate AND pt.hbmtplatformstatus != 'Obsolete' and wb.cplx = '光模块' AND pt.hbmtplatformclassification = 'market') THEN 'N'
,case WHEN(cast('${GP_START_DT}' as date)  >= cp.hbmtbasemodellaunchdate AND pt.hbmtplatformstatus != 'Obsolete' AND pt.hbmtplatformclassification = 'market') THEN 'N'
 ELSE
 'Y' end as is_project
,now() as load_dt
,pt.hbmtplatformcategory
from
ods.odsplm_bm_hbmtplatform pt
left join
ods.odsplm_bm_hbmtMODELPLATFORM cp
ON
cp.hbmtplatformno = pt.hbmtplatformno
left join
dim.dim_ipd_kdwb_nd wb
ON
pt.hbmtproductline = wb.cpx1
;

--年累的平台明细数据 主要是给单平台收入用的 方便计算
INSERT INTO dws.dws_ipd_ipm_platform_detail_dd (
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,model
,prdct_model
,matnr
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
,model_label_6
,model_label_7
,model_label_8
,model_label_9
,model_label_10
,is_project
,load_dt
,model_label11
)
--找到年累参与计算的平台序号
with tba as (
SELECT
distinct
model_label_10 --平台序号
FROM
dws.dws_ipd_ipm_platform_detail_dd
where 
company = '宽带公司1' 
AND
substring(dt_month,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y') --年份是当年
AND
dt_month <= DATE_FORMAT('${GP_START_DT}', '%Y%m')--月份小于等于当前月份
AND
is_project = 'N'
AND
dt_type = '月'
)
--关联当前月份的平台明细,和产品产生关联
SELECT
distinct
tb.dt_month 
,'年' 
,tb.company 
,tb.product_line 
,tb.in_out_sale 
,tb.platform 
,tb.model 
,tb.prdct_model 
,tb.matnr
,tb.model_label_1 
,tb.model_label_2
,tb.model_label_3
,tb.model_label_4
,tb.model_label_5
,tb.model_label_6
,tb.model_label_7
,tb.model_label_8
,tb.model_label_9
,tb.model_label_10
,case when tba.model_label_10 is not null then 'N' else 'Y' end as is_project1
,now()
,tb.model_label11
FROM
dws.dws_ipd_ipm_platform_detail_dd tb
left join
tba
ON
tb.model_label_10 = tba.model_label_10 --平台序号相同
WHERE
tb.dt_type = '月' --时间维度为月维度
AND
tb.company = '宽带公司1'
AND
tb.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')--月份为当前月份
;

INSERT INTO dws.dws_ipd_ipm_platform_detail_dd (
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,model
,prdct_model
,matnr
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
,model_label_6
,model_label_7
,model_label_8
,model_label_9
,model_label_10
,protect_notes
,is_project
,load_dt
,model_label11
)
--当月新增平台数
--这个月比上个月多了的平台
SELECT
distinct
tba.dt_month
,tba.dt_type
,tba.company
,tba.product_line
,tba.in_out_sale
,tba.platform
,tba.model
,tba.prdct_model
,tba.matnr
,tba.model_label_1
,tba.model_label_2
,tba.model_label_3 --子产品线
,tba.model_label_4
,tba.model_label_5
,tba.model_label_6
,tba.model_label_7
,tba.model_label_8
,tba.model_label_9
,tba.model_label_10 --平台序号
,'当月新增'
,tba.is_project
,tba.load_dt
,tba.model_label11
FROM
dws.dws_ipd_ipm_platform_detail_dd tba
left join
dws.dws_ipd_ipm_platform_detail_dd tbb
ON
tba.model_label_10 = tbb.model_label_10  and  tba.model_label_10 is not null and tbb.model_label_10 is not null--平台序号相同
and 
DATE_FORMAT(DATE_SUB(STR_TO_DATE(tba.dt_month, '%Y%m'), INTERVAL 1 month), '%Y%m') = tbb.dt_month --a表的上个月月份等于b表的月份
AND
tba.company = tbb.company --公司名称相同
AND
tba.dt_type = tbb.dt_type --日期维度相同
AND
tba.is_project = 'N' and tbb.is_project = 'N' --限制都是当月参与了平台数计算的平台
AND
tba.protect_notes is null and tbb.protect_notes is null
WHERE
tba.company = '宽带公司1' --限制公司为宽带公司
AND
tba.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')--限制月份为当月
AND
tbb.model_label_10 is NULL --限制b表的平台序号为空,也就是关联不上的,这就是当月新增的
AND
tba.model_label_10 is not NULL
AND
tba.dt_type = '月' --限制日期维度为月份
AND
tba.is_project = 'N' --限制计算完成后,结果是N的
AND
tba.protect_notes is null
;

INSERT INTO dws.dws_ipd_ipm_platform_detail_dd (
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,model
,prdct_model
,matnr
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
,model_label_6
,model_label_7
,model_label_8
,model_label_9
,model_label_10
,protect_notes
,is_project
,load_dt
,model_label11
)
--当月减少平台数
--这个月比上个月少了的平台,也就是上个月比这个月多的平台
SELECT
distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m')
,tba.dt_type
,tba.company
,tba.product_line
,tba.in_out_sale
,tba.platform
,tba.model
,tba.prdct_model
,tba.matnr
,tba.model_label_1
,tba.model_label_2
,tba.model_label_3 --子产品线
,tba.model_label_4
,tba.model_label_5
,tba.model_label_6
,tba.model_label_7
,tba.model_label_8
,tba.model_label_9
,tba.model_label_10 --平台序号
,'当月减少'
,tba.is_project
,tba.load_dt
,tba.model_label11
FROM
dws.dws_ipd_ipm_platform_detail_dd tba
left join
dws.dws_ipd_ipm_platform_detail_dd tbb
ON
tba.model_label_10 = tbb.model_label_10 and  tba.model_label_10 is not null and tbb.model_label_10 is not null--平台序号相同
and 
DATE_FORMAT(DATE_ADD(STR_TO_DATE(tba.dt_month, '%Y%m'), INTERVAL 1 month), '%Y%m') = tbb.dt_month --a表的下个月月份等于b表的月份
AND
tba.company = tbb.company --公司名称相同
AND
tba.dt_type = tbb.dt_type --日期维度相同
AND
tba.is_project = 'N' and tbb.is_project = 'N' --限制都是当月参与了平台数计算的平台
AND
tba.protect_notes is null and tbb.protect_notes is null
WHERE
tba.company = '宽带公司1' --限制公司为宽带公司
AND
tba.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')--限制月份为上个月
AND
tbb.model_label_10 is NULL --限制b表的平台序号为空,也就是关联不上的,这就是当月减少的
AND
tba.model_label_10 is  not NULL
AND
tba.dt_type = '月' --限制日期维度为月份
AND
tba.is_project = 'N' --限制计算完成后,结果是N的
AND
tba.protect_notes is null
;

delete from ads.ads_ipd_ipm_kdzbmid_dd where dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

--由于宽带公司维度不同,需要新创建一张表,用于存储宽带公司的结果值,可以使用
insert into ads.ads_ipd_ipm_kdzbmid_dd (
dt_month
,dt_type
,company
,product_line
,syb
,z_product_line
,in_out_sale
,ptzs --平台总数
,ptzs_plan
,ptxzs  --平台数新增
,ptxzs_plan
,pttss   --平台数减少
,pttss_plan
,load_dt
)
with tb as (
SELECT
DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month
,'宽带公司' as company
,cplx
,syb
,cpx
,'全部' as in_out_sale
FROM
dim.dim_ipd_kdwb_nd
union all
SELECT
distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month
,'宽带公司' as company
,cplx
,syb
,'全部' as cpx
,'全部' as in_out_sale
FROM
dim.dim_ipd_kdwb_nd
union all
SELECT
distinct
DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month
,'宽带公司' as company
,cplx
,'全部' as syb
,'全部' as cpx
,'全部' as in_out_sale
FROM
dim.dim_ipd_kdwb_nd
),
tb1 as (
select '年' as dt_type
union all
select '月' as dt_type
)
,weidu_all as ( 
SELECT
tb.dt_month
,tb1.dt_type
,tb.company
,tb.cplx
,tb.syb
,tb.cpx
,tb.in_out_sale
,now()
FROM
tb
join
tb1
ON
1=1
)
,data_yue as (
		SELECT
		DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month1
		,'月' as dt_type1
		,'宽带公司' as company1
		,COALESCE(product_line,'全部') as product_line1
		,COALESCE(model_label_8,'全部') as syb1
		,COALESCE(model_label_9,'全部') as cpx
		,'全部' as in_out_sale1
		,count(DISTINCT model_label_10) as cnt 
		FROM
		dws.dws_ipd_ipm_platform_detail_dd
		where 
		is_project = 'N' 
		and 
		dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')--月份
		AND
		dt_type = '月'
		and 
		company = '宽带公司1' --公司
		and 
		protect_notes is null --计算全部的需要限制该字段为空
		group by rollup
		(product_line,model_label_8,model_label_9)
)
,data_nian as (
SELECT
		DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month1
		,'年' as dt_type1
		,'宽带公司' as company1
		,COALESCE(product_line,'全部') as product_line1
		,COALESCE(model_label_8,'全部') as syb1
		,COALESCE(model_label_9,'全部') as cpx
		,'全部' as in_out_sale1
		,count(DISTINCT model_label_10) as cnt 
		FROM
		dws.dws_ipd_ipm_platform_detail_dd
		where 
		is_project = 'N' 
		and 
		substring(dt_month,1,4) = DATE_FORMAT('${GP_START_DT}', '%Y') --年份
		AND
		dt_type = '月'
		and 
		company = '宽带公司1' --公司
		and 
		protect_notes is null --计算全部的需要限制该字段为空
		group by rollup
		(product_line,model_label_8,model_label_9)
)
,add_yue as (
SELECT
		DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month1
		,'月' as dt_type1
		,'宽带公司' as company1
		,COALESCE(product_line,'全部') as product_line1
		,COALESCE(model_label_8,'全部') as syb1
		,COALESCE(model_label_9,'全部') as cpx
		,'全部' as in_out_sale1
		,count(DISTINCT model_label_10) as cnt 
		FROM
		dws.dws_ipd_ipm_platform_detail_dd
		where 
		is_project = 'N' 
		and 
		dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')--月份
		AND
		dt_type = '月'
		and 
		company = '宽带公司1' --公司
		and 
		protect_notes  = '当月新增' --计算全部的需要限制该字段为 当月新增
		group by rollup
		(product_line,model_label_8,model_label_9)
)
,sub_yue as (
		SELECT
		DATE_FORMAT('${GP_START_DT}', '%Y%m')as dt_month1
		,'月' as dt_type1
		,'宽带公司' as company1
		,COALESCE(product_line,'全部') as product_line1
		,COALESCE(model_label_8,'全部') as syb1
		,COALESCE(model_label_9,'全部') as cpx
		,'全部' as in_out_sale1
		,count(DISTINCT model_label_10) as cnt 
		FROM
		dws.dws_ipd_ipm_platform_detail_dd
		where 
		is_project = 'N' 
		and 
		dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')--月份
		AND
		dt_type = '月'
		and 
		company = '宽带公司1' --公司
		and 
		protect_notes  = '当月减少' --计算全部的需要限制该字段为 当月减少
		group by rollup
		(product_line,model_label_8,model_label_9)
)
select 
t1.dt_month
,t1.dt_type
,t1.company
,t1.cplx
,t1.syb
,t1.cpx
,t1.in_out_sale
,nvl(t2.cnt,t3.cnt)  平台总数
,t6.col_dangyuejihuapingtaizongshu  平台总数计划值
,t4.cnt  当月新增平台数
,t6.col_dangyuejihuaxinzengpingtaishu  当月新增计划值
,t5.cnt  当月退市平台数
,t6.col_dangyuejihuatuishipingtaishu  当月退市计划值 
,now()
from weidu_all t1 
left join data_yue t2 
on t1.dt_month = t2.dt_month1
and t1.dt_type = t2.dt_type1
and t1.company = t2.company1
and t1.cplx = t2.product_line1
and t1.syb = t2.syb1
and t1.cpx = t2.cpx
and t1.in_out_sale = t2.in_out_sale1
left join data_nian t3
on t1.dt_month = t3.dt_month1
and t1.dt_type = t3.dt_type1
and t1.company = t3.company1
and t1.cplx = t3.product_line1
and t1.syb = t3.syb1
and t1.cpx = t3.cpx
and t1.in_out_sale = t3.in_out_sale1
left join add_yue t4
on t1.dt_month = t4.dt_month1
and t1.dt_type = t4.dt_type1
and t1.company = t4.company1
and t1.cplx = t4.product_line1
and t1.syb = t4.syb1
and t1.cpx = t4.cpx
and t1.in_out_sale = t4.in_out_sale1
left join sub_yue t5
on t1.dt_month = t5.dt_month1
and t1.dt_type = t5.dt_type1
and t1.company = t5.company1
and t1.cplx = t5.product_line1
and t1.syb = t5.syb1
and t1.cpx = t5.cpx
and t1.in_out_sale = t5.in_out_sale1
left join ods.odsmf_cm_tab21214 t6 
on t1.dt_month = t6.col_nianyue
and t1.dt_type = '月'
and t1.company = t6.col_gongsi
and t1.cplx = t6.col_chanpinxian
and t1.syb = t6.col_shiyebu
and t1.cpx = t6.col_zichanpinxian
and t1.in_out_sale = t6.col_neiwaixiao
;