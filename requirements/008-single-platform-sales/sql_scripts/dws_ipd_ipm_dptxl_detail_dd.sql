--内销冰冷洗
delete from dws.dws_ipd_ipm_dptxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and product_line in ('冰箱','冷柜','洗衣机') 
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dptxl_detail_dd(
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform --平台名
,prdct_model
,matnr 
,sales_qty
,sales_amt
,is_project
,load_dt 
)
with dptxl as (
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,matnr 
,prdct_model 
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_3
,model_label_4
,model_label_10
--同在产型号数指标以及平台数指标逻辑，如果这两个指标逻辑发生调整需要单平台销量逻辑同步
,case when model_label_4 not like '%海信%' then 'Y' --在产型号数逻辑
when model_label_10 <> '在产' then 'Y'  --在产型号数逻辑
else is_project end as is_project    --去掉别人给海信代工的产品，只要海信自己工厂生产的
,protect_notes 
,load_dt 
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and product_line in ('冰箱','冷柜','洗衣机') 
and company not like '%商家库存%'
and in_out_sale = '内销'
and sales_type = '管报'
and case when product_line = '洗衣机' then coalesce (model_label_1,'正常') <> '其他' else 1=1 end   --20240807新增规则   支架和底座产品立项的时候会选平台为 其他
)
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,model_label_1 --平台名
,prdct_model
,matnr
,sales_qty
,sales_amt
,is_project
,now()
from dptxl
where is_project ='N'
;





--内销空调电视
delete from dws.dws_ipd_ipm_dptxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and product_line in ('家用空调','视像科技') 
and in_out_sale = '内销';
insert into dws.dws_ipd_ipm_dptxl_detail_dd(
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform --平台名
,prdct_model
,matnr 
,sales_qty
,sales_amt
,is_project
,load_dt 
)
with dptxl as (
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,matnr 
,model 
,prdct_model 
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_3
,model_label_4
,model_label_9
,model_label_10
--同在产型号数指标以及平台数指标逻辑，如果这两个指标逻辑发生调整需要单平台销量逻辑同步
,case when model_label_10 <> '在产' then 'Y'  --在产型号数逻辑
when product_line = '视像科技' and coalesce (model_label_1,'其他') = '不涉及' then 'Y'  --平台数逻辑
else is_project end as is_project    --去掉别人给海信代工的产品，只要海信自己工厂生产的
,protect_notes 
,load_dt 
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and product_line in ('家用空调','视像科技') 
and in_out_sale = '内销'
and sales_type = '管报'
)
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,model_label_1 --平台名
,model
,matnr
,sales_qty
,sales_amt
,is_project
,now()
from dptxl
where is_project ='N'
;




--日立单平台销量
delete from dws.dws_ipd_ipm_dptxl_detail_dd
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and company = '日立公司'
and sales_type = '管报'
;
insert into dws.dws_ipd_ipm_dptxl_detail_dd(
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform --平台名
,prdct_model
,matnr 
,sales_qty
,sales_amt
,sales_type 
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
,model_label_6
,is_project
,load_dt 
,platform_classify
,model_label_8   --非标标识
,sales_cost  --实际成本
,sales_mll  --实际毛利率
,sales_qty_y   --本年累计销量
,sales_amt_y    --本年累计销额
,sales_cost_y   --本年累计成本
,sales_mll_y    --本年累计毛利率
)





with guanbao as (
select 
data_month 
,product_id 
,sum(order_qty ) as order_qty
,sum(huanyuan_shouru ) as huanyuan_shouru
,sum(cost_sum) as cost_sum  
,(sum(huanyuan_shouru )-sum(cost_sum)) /nullif(sum(huanyuan_shouru ),0.0) as mll
from ods.odsmr_v_hitach_ykfpmxb
where data_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y-%m')
group by data_month 
,product_id 

)
,guanbao_y as (
select 
product_id 
,sum(order_qty ) as order_qty
,sum(huanyuan_shouru ) as huanyuan_shouru
,sum(cost_sum) as cost_sum  
,(sum(huanyuan_shouru )-sum(cost_sum)) /nullif(sum(huanyuan_shouru ),0.0) as mll
from ods.odsmr_v_hitach_ykfpmxb
where data_month <= DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y-%m')
and substring(data_month,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
group by product_id 

)
select 
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,prdct_model
,matnr
,t2.order_qty   --实际销量
,t2.huanyuan_shouru   --实际收入
,'管报' as sales_type
,model_label_1  --物料大类
,model_label_2   --物料中类
,model_label_3   --物料小类
,model_label_4   --是否模块组合
,model_label_5   --型号生命周期状态
,model_label_6   --采购类型
,is_project
,now()
,t1.platform_classify --平台分类
,model_label_8   --非标标识
,t2.cost_sum
,t2.mll
,t3.order_qty  --年累销量
,t3.huanyuan_shouru  --年累销额
,t3.cost_sum  --年累成本
,t3.mll  --年累毛利率
FROM dws.dws_ipd_ipm_platform_detail_dd t1 
left join guanbao t2 
on t1.matnr = t2.product_id
left join guanbao_y t3 
on t1.matnr = t3.product_id
WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') 
and company = '日立公司'
and is_project = 'N'
and dt_type= '月'

;







--出口冰冷洗空电
delete from dws.dws_ipd_ipm_dptxl_detail_dd where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and product_line in ('冰箱','冷柜','洗衣机','家用空调','视像科技') 
and in_out_sale = '出口';
insert into dws.dws_ipd_ipm_dptxl_detail_dd(
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform --平台名
,prdct_model
,sales_qty
,sales_amt
,model_label_12
,is_project
,load_dt 
)
with add_zcluoji as ( 
select 
dt_month
,dt_type
,company
,product_line
,in_out_sale
,model
,prdct_model
,matnr
,sales_qty
,sales_amt
,sales_type
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
,case when product_line = '冰箱' and not(model_label_9 = '在产' and model_label_4 IN ('011', '098', '020', '010', '009','海信（蒙特雷）家电制造有限公司')) then 'Y'
when product_line = '冷柜' and model_label_9 <> '在产' then 'Y'
when product_line = '洗衣机' and not(model_label_9 = '在产' and coalesce(model_label_4,'000') in ('012','020')) then 'Y'
when product_line = '家用空调' and model_label_9 <> '在产' then 'Y'
when product_line = '视像科技' and not(model_label_10 = '在产' and coalesce (model_label_13 ,'正常') <> '借用') then 'Y'
else is_project end as is_project
,protect_notes
,model_label_11
,model_label_12
,model_label_13
,model_label_14
,model_label_15
,model_label_16
from dws.dws_ipd_ipm_dxhxl_detail_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
and dt_type = '月' 
and product_line in ('冰箱','冷柜','洗衣机','家用空调','视像科技') 
and in_out_sale = '出口'
and sales_type = 'sellin'
--and is_project = 'N' 
--and product_line = '视像科技' and model_label_12 = '国际营销'
)
,add_platformluoji as ( 
select 
dt_month
,dt_type
,company
,product_line
,in_out_sale
,model
,prdct_model
,matnr
,sales_qty
,sales_amt
,sales_type
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
,case when product_line in ('冰箱','冷柜') and coalesce (model_label_3,'正常') in ('全散件') then 'Y'
when product_line = '视像科技' and coalesce (model_label_1,'其他') = '不涉及' then 'Y'
else is_project end as is_project
,protect_notes
,model_label_11
,model_label_12
,model_label_13
,model_label_14
,model_label_15
,model_label_16
from add_zcluoji
--where is_project = 'N'
)
select
dt_month
,dt_type
,company
,product_line
,in_out_sale
,model_label_1 --平台名
,prdct_model
,sales_qty
,sales_amt
,model_label_12
,is_project
,now()
from add_platformluoji
where is_project = 'N'
;








DELETE FROM dws.dws_ipd_ipm_dptxl_detail_dd WHERE dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') and company = '宽带公司1';

INSERT INTO dws.dws_ipd_ipm_dptxl_detail_dd (
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,model
,prdct_model
,matnr
,sales_amt
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
,model_label_12
)


--插入月度明细数据 光模块和终端的数据不同,不能放在一起
SELECT
distinct
t1.dt_month
,t1.dt_type
,t1.company
,t1.product_line
,t1.in_out_sale
,t1.platform
,t1.model
,t1.prdct_model
,t1.matnr
,sum(COALESCE(kdsr.mon_re_bvi,0))over(partition by t1.matnr) --按照型号进行分组,计算收入求和
,t1.model_label_1
,t1.model_label_2
,t1.model_label_3
,t1.model_label_4
,t1.model_label_5
,t1.model_label_6
,t1.model_label_7
,t1.model_label_8
,t1.model_label_9
,t1.model_label_10
,t1.is_project
,now()
,t1.model_label11
FROM
dws.dws_ipd_ipm_platform_detail_dd t1
left join
(select matnr,mon_re_bvi,maktx from ods.odsmr_v_sync_4200bvi_income
WHERE
substring(cod_scenario,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
AND
cod_periodo = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%m')
AND
maktx not like '%LSSY%'
and 
ltext IN  ('FTTX-OSA','相干','FTTX','无线产品','DATACOM','TELECOM','光融合','BOX','直播星','高清/标清','IPTV')
)
kdsr
on
kdsr.matnr  = t1.matnr
where 
t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') --上个月的明细数据
AND
t1.dt_type = '月'
AND
company = '宽带公司1'
--AND
--product_line = '光模块' --限制产品线为光模块
AND
protect_notes is null --限制为当月平台数 而不是新增和减少
;



INSERT INTO dws.dws_ipd_ipm_dptxl_detail_dd (
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,model
,prdct_model
,matnr
,sales_amt
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
,model_label_12
)


--插入年累明细数据 光模块和终端的数据不同,不能放在一起
SELECT
distinct
t1.dt_month
,t1.dt_type
,t1.company
,t1.product_line
,t1.in_out_sale
,t1.platform
,t1.model
,t1.prdct_model
,t1.matnr
,sum(COALESCE(kdsr.cum_re,0))over(partition by t1.matnr) --按照型号进行分组,计算收入求和
,t1.model_label_1
,t1.model_label_2
,t1.model_label_3
,t1.model_label_4
,t1.model_label_5
,t1.model_label_6
,t1.model_label_7
,t1.model_label_8
,t1.model_label_9
,t1.model_label_10
,t1.is_project
,now()
,t1.model_label11
FROM
dws.dws_ipd_ipm_platform_detail_dd t1
left join
(select matnr,cum_re,maktx from ods.odsmr_v_sync_4200bvi_income
WHERE
substring(cod_scenario,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
AND
cod_periodo = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%m')
AND
maktx not like '%LSSY%'
and 
ltext IN  ('FTTX-OSA','相干','FTTX','无线产品','DATACOM','TELECOM','光融合','BOX','直播星','高清/标清','IPTV')
)
kdsr
on
kdsr.matnr  = t1.matnr
where 
t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') --上个月的明细数据
AND
t1.dt_type = '年' --限制时间维度为年
AND
company = '宽带公司1'
--AND
--product_line = '光模块' --限制产品线为光模块
AND
protect_notes is null --限制为当月平台数 而不是新增和减少
;



--20241230日 杨冉需求 要计算每个平台的汇总收入 并排序 , 20250120日 进行修改
--聚合到平台的收入
INSERT INTO dws.dws_ipd_ipm_dptxl_detail_dd (
dt_month
,dt_type
,company
,product_line
,in_out_sale
,platform
,model_label_8
,model_label_9
,sales_amt
,model_label_10
,model_label_11
,is_project
,load_dt
,model_label_12
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
)
SELECT
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,dt_type
,'宽带公司1' as company
,product_line as product_line
,'全部' as in_out_sale
,platform
,model_label_8 as syb--事业部
,model_label_9 as zcpx--子产品线
,SUM(sales_amt) as sales_amt
,model_label_10 --平台序号
,'平台' as model_label_11
,is_project
,now()
,model_label_12
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
FROM
dws.dws_ipd_ipm_dptxl_detail_dd
WHERE
dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
AND
company  = '宽带公司1'
group by 
dt_type,product_line,model_label_8,model_label_9,model_label_10,platform,is_project,model_label_12
,model_label_1
,model_label_2
,model_label_3
,model_label_4
,model_label_5
;





--实现更新 dptsr dptsr_plan  功能
drop table test.tmp_kdzbmid;
CREATE TABLE test.tmp_kdzbmid
ENGINE=OLAP
-- 表模型（Duplicate/Unique/Aggregate Key，必填）
DUPLICATE KEY(dt_month)
AS 
--计算单平台平均收入
with sr as(
SELECT
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m') as dt_month
,dt_type
,'全部' as in_out_sale
,COALESCE(product_line,'全部') as product_line
,COALESCE(model_label_8,'全部') as syb--事业部
,COALESCE(model_label_9,'全部') as zcpx--子产品线
,SUM(sales_amt) as sales_amt
FROM
dws.dws_ipd_ipm_dptxl_detail_dd
WHERE
dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
AND
company  = '宽带公司1'
AND
is_project = 'N'
AND
model_label_11 = '平台'
group by rollup
(dt_type,product_line,model_label_8,model_label_9)
)
,dptsr_values as (
SELECT
sr.dt_month as dt_month1
,sr.dt_type as dt_type1
,'宽带公司' as company1
,sr.product_line as product_line1
,sr.in_out_sale as in_out_sale1
,sr.syb as syb1
,sr.zcpx as zcpx1
,CASE when pts.ptzs is not null and pts.ptzs != 0 and sr.sales_amt != 0 then sr.sales_amt/pts.ptzs end as sale_pf1
FROM
sr
join
ads.ads_ipd_ipm_kdzbmid_dd pts
ON
sr.dt_type = pts.dt_type 
AND 
sr.product_line = pts.product_line 
and 
sr.syb = pts.syb
AND 
sr.zcpx = pts.z_product_line 
and 
sr.in_out_sale = pts.in_out_sale 
and 
sr.dt_month = pts.dt_month
)
,plan_values as (
SELECT
col_nianyue
,col_gongsi
,col_neiwaixiao
,col_chanpinxian
,col_shiyebu
,col_zichanpinxian
,cast(col_dangyuejihuadanpingtaishourudanweiwanyuan as DECIMALV3(20,8))  * 10000 as dptsr_plan
,'月' as dt_type
from
ods.odsmf_cm_tab21214
where col_nianleijihuadanpingtaishourudanweiwanyuan not like '%,%'
and col_nianyue = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')

union all 

SELECT
col_nianyue
,col_gongsi
,col_neiwaixiao
,col_chanpinxian
,col_shiyebu
,col_zichanpinxian
,cast(col_nianleijihuadanpingtaishourudanweiwanyuan as DECIMALV3(20,8)) * 10000 as dptsr_plan
,'年' as dt_type
FROM
ods.odsmf_cm_tab21214
where col_nianleijihuadanpingtaishourudanweiwanyuan not like '%,%'
and col_nianyue = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
)
select 
t1.dt_month	--年月
,t1.dt_type	--日期维度
,t1.company	--公司名称
,t1.product_line	--产品线
,t1.syb	--事业部
,t1.z_product_line	--子产品线
,t1.in_out_sale	--内外销
,t1.ptxzs	--平台数新增
,t1.ptxzs_plan	--平台数新增计划
,t1.pttss	--平台数退市
,t1.pttss_plan	--平台数退市计划
,t1.ptzs	--平台总数
,t1.ptzs_plan	--平台总数计划
,coalesce (t2.sale_pf1,t1.dptsr) as dptsr	--单平台收入
,coalesce (t3.dptsr_plan,t1.dptsr_plan) as dptsr_plan	--单平台收入计划
,t1.load_dt	--加载日期
from ads.ads_ipd_ipm_kdzbmid_dd t1
left join dptsr_values t2 
on t1.dt_month = t2.dt_month1
AND t1.dt_type = t2.dt_type1
and t1.product_line = t2.product_line1
and t1.in_out_sale = t2.in_out_sale1
and t1.company = t2.company1
and t1.syb = t2.syb1
and t1.z_product_line = t2.zcpx1
left join plan_values t3 
on t1.dt_month = t3.col_nianyue
and t1.dt_type = t3.dt_type
and t1.company = t3.col_gongsi
and t1.product_line = t3.col_chanpinxian
and t1.syb = t3.col_shiyebu
and t1.z_product_line = t3.col_zichanpinxian
and t1.in_out_sale = t3.col_neiwaixiao
where t1.dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
;


delete from ads.ads_ipd_ipm_kdzbmid_dd 
where dt_month = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y%m')
;
insert into ads.ads_ipd_ipm_kdzbmid_dd (
dt_month	--年月
,dt_type	--日期维度
,company	--公司名称
,product_line	--产品线
,syb	--事业部
,z_product_line	--子产品线
,in_out_sale	--内外销
,ptxzs	--平台数新增
,ptxzs_plan	--平台数新增计划
,pttss	--平台数退市
,pttss_plan	--平台数退市计划
,ptzs	--平台总数
,ptzs_plan	--平台总数计划
,dptsr	--单平台收入
,dptsr_plan	--单平台收入计划
,load_dt	--加载日期
)
select
dt_month	--年月
,dt_type	--日期维度
,company	--公司名称
,product_line	--产品线
,syb	--事业部
,z_product_line	--子产品线
,in_out_sale	--内外销
,ptxzs	--平台数新增
,ptxzs_plan	--平台数新增计划
,pttss	--平台数退市
,pttss_plan	--平台数退市计划
,ptzs	--平台总数
,ptzs_plan	--平台总数计划
,dptsr	--单平台收入
,dptsr_plan	--单平台收入计划
,load_dt	--加载日期
from test.tmp_kdzbmid;

