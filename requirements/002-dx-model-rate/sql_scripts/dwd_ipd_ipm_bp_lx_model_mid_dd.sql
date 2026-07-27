-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/02/03 08:41:18 GMT+08:00
-- ******************************************************************** --
delete from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX' 
and product_big in ('空气调节类产品','控温储藏类产品','清洁卫生器具','供热采暖类产品','厨房电器类产品')
and model_type = '产品型号口径'
and in_out_sale = '内销'
;

insert into dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
prdct_model
,plan_type 
,product_big
,product_mid
,product_sml
,model_label_6 
,dt_month 
,plan_sales_qty
,load_dt 
,model_type
,in_out_sale 
)
with hdrp_product as ( 
select 
PG00061   --名称
,PG00004
,PG00003
,PG00002
,PG00020  --内外销
,PG00025    --实际上市时间
,concat( DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 2 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 3 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 4 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 5 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 6 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 7 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 8 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 9 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 10 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 11 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 12 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 13 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 14 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 15 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 16 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 17 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 18 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 19 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 20 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 21 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 22 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 23 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 24 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 25 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 26 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 27 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 28 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 29 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 30 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 31 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 32 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 33 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 34 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 35 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 36 month) , '%Y%m')
) as dt_month
,concat(COALESCE(HX00506,0.0)	,','--第一个月规划销量
,COALESCE(HX00507	,0.0),','--第二个月规划销量
,COALESCE(HX00508	,0.0),','--第三个月规划销量
,COALESCE(HX00509	,0.0),','--第四个月规划销量
,COALESCE(HX005010	,0.0),','--第五个月规划销量
,COALESCE(HX00511	,0.0),','--第六个月规划销量
,COALESCE(HX005012	,0.0),','--第七个月规划销量
,COALESCE(HX00513	,0.0),','--第八个月规划销量
,COALESCE(HX00514	,0.0),','--第九个月规划销量
,COALESCE(HX00515	,0.0),','--第十个月规划销量
,COALESCE(HX00516	,0.0),','--第十一个月规划销量
,COALESCE(HX00517	,0.0),','--第十二个月规划销量
,COALESCE(HX00518	,0.0),','--第十三个月规划销量
,COALESCE(HX00519	,0.0),','--第十四个月规划销量
,COALESCE(HX00520	,0.0),','--第十五个月规划销量
,COALESCE(HX00521	,0.0),','--第十六个月规划销量
,COALESCE(HX00522	,0.0),','--第十七个月规划销量
,COALESCE(HX00523	,0.0),','--第十八个月规划销量
,COALESCE(HX00524	,0.0),','--第十九个月规划销量
,COALESCE(HX00525	,0.0),','--第二十个月规划销量
,COALESCE(HX00526	,0.0),','--第二十一个月规划销量
,COALESCE(HX00527	,0.0),','--第二十二个月规划销量
,COALESCE(HX00528	,0.0),','--第二十三个月规划销量
,COALESCE(HX00529	,0.0),','--第二十四个月规划销量
,COALESCE(HX00530	,0.0),','--第二十五个月规划销量
,COALESCE(HX00531	,0.0),','--第二十六个月规划销量
,COALESCE(HX00532	,0.0),','--第二十七个月规划销量
,COALESCE(HX00533	,0.0),','--第二十八个月规划销量
,COALESCE(HX00534	,0.0),','--第二十九个月规划销量
,COALESCE(HX00535	,0.0),','--第三十个月规划销量
,COALESCE(HX00536	,0.0),','--第三十一个月规划销量
,COALESCE(HX00537	,0.0),','--第三十二个月规划销量
,COALESCE(HX00538	,0.0),','--第三十三个月规划销量
,COALESCE(HX00539	,0.0),','--第三十四个月规划销量
,COALESCE(HX00540	,0.0),','--第三十五个月规划销量
,COALESCE(HX00541	,0.0)--第三十六个月规划销量
) as plan_sales
from dim.dim_ipd_productmodel_dd 
where PG00020 = '内销'
and HX00506 is not null 
and PG00025 is not null 
and PG00002 in ('空气调节类产品','控温储藏类产品','清洁卫生器具','供热采暖类产品','厨房电器类产品')
)
select
PG00061   --名称
,'LX'  as plan_type
,PG00002  --产品大类
,PG00003  --产品中类
,PG00004  --产品小类
,PG00020  --内外销
,element_at(sbs_dt_month, idx) AS dt_month
,element_at(sbs_plan_sales, idx) AS plan_sales
,now()
,'产品型号口径' as model_type
,PG00020 as in_out_sale
from (
select PG00061   --名称
,PG00002  --产品大类
,PG00003  --产品中类
,PG00004  --产品小类
,PG00020  --内外销
,PG00025    --实际上市时间
,SPLIT_BY_STRING(dt_month, ',') as sbs_dt_month
,SPLIT_BY_STRING(plan_sales, ',') as sbs_plan_sales
,sequence(1, cardinality(SPLIT_BY_STRING(dt_month, ','))+1) AS idx_array
from hdrp_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;

DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big IN ('控温储藏类产品','清洁卫生器具','供热采暖类产品','厨房电器类产品')
    AND model_type = '产品型号口径'
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_product AS (
    SELECT
        PG00061        -- 产品型号名称
        ,PG00002       -- 产品大类
        ,PG00003       -- 产品中类
        ,PG00004       -- 产品小类
        ,PG00020       -- 内外销
        ,PG00025       -- 实际上市时间
        ,HX00020       -- 第一年规划销量
        -- 按实际上市时间生成12个月的月份序列
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 前6月各占40%/6，后6月各占60%/6
        ,CONCAT(
            CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.4 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) * 0.6 / 6 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_productmodel_dd
    WHERE PG00020 = '外销'
        AND HX00020 IS NOT NULL
        AND PG00025 IS NOT NULL
        AND PG00002 IN ('控温储藏类产品','清洁卫生器具','供热采暖类产品','厨房电器类产品')
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061
        ,PG00002
        ,PG00003
        ,PG00004
        ,PG00020
        ,PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;

delete from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'LX' 
and product_big in ('空气调节类产品')
and model_type = '销售型号编码口径'
;

insert into dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
prdct_model
,salemodelcode
,plan_type 
,product_big
,product_mid
,product_sml
,dt_month 
,plan_sales_qty
,load_dt 
,model_type
)
with hdrp_product as ( 
select 
PG00061   --名称
,PG00068  --销售型号编码
,PG00004
,PG00003
,PG00002
-- ,PG00020  --内外销
,PG00025    --实际上市时间
,concat( DATE_FORMAT(date_add(PG00025,interval 1 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 2 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 3 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 4 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 5 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 6 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 7 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 8 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 9 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 10 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 11 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 12 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 13 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 14 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 15 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 16 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 17 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 18 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 19 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 20 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 21 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 22 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 23 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 24 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 25 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 26 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 27 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 28 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 29 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 30 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 31 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 32 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 33 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 34 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 35 month) , '%Y%m'),','
,DATE_FORMAT(date_add(PG00025,interval 36 month) , '%Y%m')
) as dt_month
,concat(COALESCE(HX00506,0.0)	,','--第一个月规划销量
,COALESCE(HX00507	,0.0),','--第二个月规划销量
,COALESCE(HX00508	,0.0),','--第三个月规划销量
,COALESCE(HX00509	,0.0),','--第四个月规划销量
,COALESCE(HX005010	,0.0),','--第五个月规划销量
,COALESCE(HX00511	,0.0),','--第六个月规划销量
,COALESCE(HX005012	,0.0),','--第七个月规划销量
,COALESCE(HX00513	,0.0),','--第八个月规划销量
,COALESCE(HX00514	,0.0),','--第九个月规划销量
,COALESCE(HX00515	,0.0),','--第十个月规划销量
,COALESCE(HX00516	,0.0),','--第十一个月规划销量
,COALESCE(HX00517	,0.0),','--第十二个月规划销量
,COALESCE(HX00518	,0.0),','--第十三个月规划销量
,COALESCE(HX00519	,0.0),','--第十四个月规划销量
,COALESCE(HX00520	,0.0),','--第十五个月规划销量
,COALESCE(HX00521	,0.0),','--第十六个月规划销量
,COALESCE(HX00522	,0.0),','--第十七个月规划销量
,COALESCE(HX00523	,0.0),','--第十八个月规划销量
,COALESCE(HX00524	,0.0),','--第十九个月规划销量
,COALESCE(HX00525	,0.0),','--第二十个月规划销量
,COALESCE(HX00526	,0.0),','--第二十一个月规划销量
,COALESCE(HX00527	,0.0),','--第二十二个月规划销量
,COALESCE(HX00528	,0.0),','--第二十三个月规划销量
,COALESCE(HX00529	,0.0),','--第二十四个月规划销量
,COALESCE(HX00530	,0.0),','--第二十五个月规划销量
,COALESCE(HX00531	,0.0),','--第二十六个月规划销量
,COALESCE(HX00532	,0.0),','--第二十七个月规划销量
,COALESCE(HX00533	,0.0),','--第二十八个月规划销量
,COALESCE(HX00534	,0.0),','--第二十九个月规划销量
,COALESCE(HX00535	,0.0),','--第三十个月规划销量
,COALESCE(HX00536	,0.0),','--第三十一个月规划销量
,COALESCE(HX00537	,0.0),','--第三十二个月规划销量
,COALESCE(HX00538	,0.0),','--第三十三个月规划销量
,COALESCE(HX00539	,0.0),','--第三十四个月规划销量
,COALESCE(HX00540	,0.0),','--第三十五个月规划销量
,COALESCE(HX00541	,0.0)--第三十六个月规划销量
) as plan_sales
from dim.dim_ipd_salemodel_dd 
where HX00506 is not null 
and PG00025 is not null 
and PG00002 = '空气调节类产品'
)
select
PG00061   --名称
,PG00068  --销售型号编码
,'LX'  as plan_type
,PG00002  --产品大类
,PG00003  --产品中类
,PG00004  --产品小类
-- ,PG00020  --内外销
,element_at(sbs_dt_month, idx) AS dt_month
,element_at(sbs_plan_sales, idx) AS plan_sales
,now()
,'销售型号编码口径' as model_type
from (
select PG00061   --名称
,PG00068  --销售型号编码
,PG00002  --产品大类
,PG00003  --产品中类
,PG00004  --产品小类
-- ,PG00020  --内外销
,PG00025    --实际上市时间
,SPLIT_BY_STRING(dt_month, ',') as sbs_dt_month
,SPLIT_BY_STRING(plan_sales, ',') as sbs_plan_sales
,sequence(1, cardinality(SPLIT_BY_STRING(dt_month, ','))+1) AS idx_array
from hdrp_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;

DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big IN ('空气调节类产品')
    AND model_type = '产品型号口径'
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_kt_product AS (
    SELECT
        PG00061        -- 产品型号名称
        ,PG00002       -- 产品大类
        ,PG00003       -- 产品中类
        ,PG00004       -- 产品小类
        ,PG00020       -- 内外销
        ,PG00025       -- 实际上市时间
        ,HX00020       -- 第一年规划销量
        -- 按实际上市时间生成12个月的月份序列
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 12个月平均
        ,CONCAT(
            CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(HX00020, 0) / 12 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_productmodel_dd
    WHERE PG00020 = '外销'
        AND HX00020 IS NOT NULL
        AND PG00025 IS NOT NULL
        AND PG00002 = '空气调节类产品'
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061
        ,PG00002
        ,PG00003
        ,PG00004
        ,PG00020
        ,PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_kt_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;

delete from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and model_label_1 = 'HDRP'
;

insert into dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
dt_month 
,plan_type 
,model_label_1 
,product_line
,prdct_model
,brand
,plan_sales_qty
,plan_sales_amt
,plan_gross_margin
,load_dt 
,salemodelcode  --销售型号编码
,matnr --物料编码
)
with BP_sales as (
--BP1-12月销量
select 
available	--可用状态(1.可用 0.不可用)
,business_unit	--所属事业部
,brand_code	--品牌编码
,brand_name	--品牌名称
,product_model	--产品型号
,sales_model	--销售型号
,case when product_company_name = '日立' then sales_model else product_model end as model 
,SAP_CODE 
,t2.sale_model_code
,product_company_name
,product_name	--产品名称
,concat(
DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'01',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'02',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'03',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'04',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'05',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'06',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'07',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'08',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'09',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'10',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'11',','
,DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y'),'12'
)as dt_month_array
,concat(coalesce (jan_sales_volume,'0'),','	--1月数据-销量
,coalesce (feb_sales_volume,'0'),','	--2月数据-销量
,coalesce (mar_sales_volume,'0'),','	--3月数据-销量
,coalesce (apr_sales_volume,'0'),','	--4月数据-销量
,coalesce (may_sales_volume,'0'),','	--5月数据-销量
,coalesce (jun_sales_volume,'0'),','	--6月数据-销量
,coalesce (jul_sales_volume,'0'),','	--7月数据-销量
,coalesce (aug_sales_volume,'0'),','	--8月数据-销量
,coalesce (sep_sales_volume,'0'),','	--9月数据-销量
,coalesce (oct_sales_volume,'0'),','	--10月数据-销量
,coalesce (nov_sales_volume,'0'),','	--11月数据-销量
,coalesce (dec_sales_volume,'0')	--12月数据-销量
) as sales_qty_array --销量
,concat(coalesce (jan_average_price,'0'),','	--1月数据-均价
,coalesce (feb_average_price,'0'),','	--2月数据-均价
,coalesce (mar_average_price,'0'),','	--3月数据-均价
,coalesce (apr_average_price,'0'),','	--4月数据-均价
,coalesce (may_average_price,'0'),','	--5月数据-均价
,coalesce (jun_average_price,'0'),','	--6月数据-均价
,coalesce (jul_average_price,'0'),','	--7月数据-均价
,coalesce (aug_average_price,'0'),','	--8月数据-均价
,coalesce (sep_average_price,'0'),','	--9月数据-均价
,coalesce (oct_average_price,'0'),','	--10月数据-均价
,coalesce (nov_average_price,'0'),','	--11月数据-均价
,coalesce (dec_average_price,'0')	--12月数据-均价
)as sales_amt_array  --销额
,concat(coalesce (jan_gross_margin_rate_str,'0'),','	--1月数据-毛利率字符串
,coalesce (feb_gross_margin_rate_str,'0'),','	--2月数据-毛利率字符串
,coalesce (mar_gross_margin_rate_str,'0'),','	--3月数据-毛利率字符串
,coalesce (apr_gross_margin_rate_str,'0'),','	--4月数据-毛利率字符串
,coalesce (may_gross_margin_rate_str,'0'),','	--5月数据-毛利率字符串
,coalesce (jun_gross_margin_rate_str,'0'),','	--6月数据-毛利率字符串
,coalesce (jul_gross_margin_rate_str,'0'),','	--7月数据-毛利率字符串
,coalesce (aug_gross_margin_rate_str,'0'),','	--8月数据-毛利率字符串
,coalesce (sep_gross_margin_rate_str,'0'),','	--9月数据-毛利率字符串
,coalesce (oct_gross_margin_rate_str,'0'),','	--10月数据-毛利率字符串
,coalesce (nov_gross_margin_rate_str,'0'),','	--11月数据-毛利率字符串
,coalesce (dec_gross_margin_rate_str,'0')	--12月数据-毛利率字符串
)as  grossrate_array
from ods.odshdrp_hisense_basis_point_target t1 
left join (
select 
product_code
,sale_model_code
from dw.dim_product_base_info_dd
where product_type_code in ('FERT','ZTAO')
and delete_flag!='Y'
)t2
on t1.SAP_CODE = t2.product_code
and t1.product_company_name = '日立'
)
select 
element_at(sbs_dt_month, idx) AS dt_month
,'BP' as plan_type
,'HDRP' as model_label_1
,product_company_name 
,model
,brand_name
,coalesce (cast(element_at(sbs_plan_sales, idx)as DECIMALV3(20,4)),0.0) AS plan_sales
,coalesce (cast(element_at(sbs_sales_amt, idx)as DECIMALV3(20,4)),0.0) AS sales_amt
,coalesce (cast(element_at(sbs_grossrate, idx)as DECIMALV3(20,4)) /100,0.0)  AS grossrate
,now()
,sale_model_code
,SAP_CODE 
from (
select
product_company_name 
,model
,brand_name
,SAP_CODE 
,sale_model_code
,dt_month_array
,sales_qty_array
,sales_amt_array
,grossrate_array
,SPLIT_BY_STRING(dt_month_array, ',') as sbs_dt_month
,SPLIT_BY_STRING(sales_qty_array, ',') as sbs_plan_sales
,SPLIT_BY_STRING(sales_amt_array, ',') as sbs_sales_amt
,SPLIT_BY_STRING(grossrate_array, ',') as sbs_grossrate
,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_array, ','))+1) AS idx_array
from BP_sales
) t
LATERAL VIEW explode(idx_array) tmp AS idx
;

--视像科技BP效率
--临时通过信魔方传递数据
delete from dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
where plan_type = 'BP'
and product_line in ('视像科技','激光')
;

insert into dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
dt_month 
,plan_type 
,product_line
,brand
,prdct_model
,plan_listingdate
,distribution_channel
,product_positioning
,is_gcj
,plan_sales_qty
,load_dt 
)
with BP_sales as (
--BP1-12月销量
select 
concat(
cast(col_bpnianfen as decimalv3(20,0)),'01',','
,cast(col_bpnianfen as decimalv3(20,0)),'02',','
,cast(col_bpnianfen as decimalv3(20,0)),'03',','
,cast(col_bpnianfen as decimalv3(20,0)),'04',','
,cast(col_bpnianfen as decimalv3(20,0)),'05',','
,cast(col_bpnianfen as decimalv3(20,0)),'06',','
,cast(col_bpnianfen as decimalv3(20,0)),'07',','
,cast(col_bpnianfen as decimalv3(20,0)),'08',','
,cast(col_bpnianfen as decimalv3(20,0)),'09',','
,cast(col_bpnianfen as decimalv3(20,0)),'10',','
,cast(col_bpnianfen as decimalv3(20,0)),'11',','
,cast(col_bpnianfen as decimalv3(20,0)),'12'
)as dt_month_array
,col_chanpinxian	--产品线
,col_pinpai	--品牌
,col_xinghaomingcheng	--型号名称
,col_shangshishijian	--上市时间
,col_xianxiadianshang	--线下电商
,col_chanpindangci	--产品档次
,col_shifougongchengji	--是否工程机
,col_f1yuexiaoliang	--1月销量
,concat(
coalesce(col_f1yuexiaoliang,0.0),','
,coalesce(col_f2yuexiaoliang,0.0),','
,coalesce(col_f3yuexiaoliang,0.0),','
,coalesce(col_f4yuexiaoliang,0.0),','
,coalesce(col_f5yuexiaoliang,0.0),','
,coalesce(col_f6yuexiaoliang,0.0),','
,coalesce(col_f7yuexiaoliang,0.0),','
,coalesce(col_f8yuexiaoliang,0.0),','
,coalesce(col_f9yuexiaoliang,0.0),','
,coalesce(col_f10yuexiaoliang,0.0),','
,coalesce(col_f11yuexiaoliang,0.0),','
,coalesce(col_f12yuexiaoliang,'')
) as sales_qty_array --销量
from ods.odsmf_cm_tab27333
)
select
element_at(sbs_dt_month, idx) AS dt_month
,'BP' as plan_type
,case when col_chanpinxian = '激光' then '激光' else '视像科技' end as product_line
,col_pinpai   --品牌
,col_xinghaomingcheng
,col_shangshishijian  --规划上市时间
,col_xianxiadianshang   --线上线下
,col_chanpindangci   --产品档次
,col_shifougongchengji    --是否工程机
,cast(element_at(sbs_plan_sales, idx)as DECIMALV3(20,4)) AS plan_sales
,now()
from (
select 
col_chanpinxian    --产品线
,col_pinpai   --品牌
,col_xinghaomingcheng  --型号
,col_shangshishijian  --规划上市时间
,col_xianxiadianshang   --线上线下
,col_chanpindangci   --产品档次
,col_shifougongchengji    --是否工程机
,SPLIT_BY_STRING(dt_month_array, ',') as sbs_dt_month
,SPLIT_BY_STRING(sales_qty_array, ',') as sbs_plan_sales
,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_array, ','))+1) AS idx_array
from BP_sales
) t
LATERAL VIEW explode(idx_array) tmp AS idx
;

-- ====================================================================
-- 第三段：显示(平板电视) 外销LX规划量
-- 规划量×50%为年目标，累计比例：0/0/0/16/28/38/53/60/70/74/80/100
-- 差值（各月占比%）：0/0/0/16/12/10/15/7/10/4/6/20
-- ====================================================================
DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big = '显示类产品'
    AND model_type = '产品型号口径'
    AND product_sml IN ('平板电视')
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_tv_product AS (
    SELECT
        title AS PG00061                    -- 产品型号描述
        ,his_productbigcategories AS PG00002  -- 产品大类
        ,his_productmiddlecategories AS PG00003  -- 产品中类
        ,his_productsmallcategories AS PG00004  -- 产品小类
        ,'外销' AS PG00020
        ,his_actualtimetomarket AS PG00025  -- 实际上市时间
        ,CAST(his_plannedsalesvolume AS DECIMALV3(20,4)) AS HX00020  -- 规划销量
        -- 按实际上市时间生成12个月的月份序列
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 规划量×50%，按差值比例拆分：0/0/0/16/12/10/15/7/10/4/6/20
        ,CONCAT(
            CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.00 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.00 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.00 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.16 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.15 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.07 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.04 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.06 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.20 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_jtplm_his_productmodel_dd
    WHERE his_productbigcategories = '显示类产品'
        AND his_productsmallcategories = '平板电视'
        AND his_domesticsalesorexport = '外销'
        AND his_plannedsalesvolume IS NOT NULL
        AND his_actualtimetomarket IS NOT NULL
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061, PG00002, PG00003, PG00004, PG00020, PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_tv_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;

-- ====================================================================
-- 第四段：激光 外销LX规划量
-- 规划量×50%为年目标，按 5/10/10/10/10/12/10/10/8/5/5/5 拆分
-- ====================================================================
DELETE FROM dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
WHERE plan_type = 'LX'
    AND product_big = '显示类产品'
    AND product_sml IN ('激光电视','家用投影')
    AND model_type = '产品型号口径'
    AND in_out_sale = '外销';

INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd(
    prdct_model
    ,plan_type
    ,product_big
    ,product_mid
    ,product_sml
    ,in_out_sale
    ,dt_month
    ,plan_sales_qty
    ,load_dt
    ,model_type
)
WITH wx_laser_product AS (
    SELECT
        title AS PG00061
        ,his_productbigcategories AS PG00002
        ,his_productmiddlecategories AS PG00003
        ,his_productsmallcategories AS PG00004
        ,'外销' AS PG00020
        ,his_actualtimetomarket AS PG00025
        ,CAST(his_plannedsalesvolume AS DECIMALV3(20,4)) AS HX00020
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 2 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 3 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 4 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 5 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 6 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 7 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 8 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 9 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 10 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 11 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(his_actualtimetomarket, INTERVAL 12 MONTH), '%Y%m')
        ) AS dt_month_str
        -- 规划量×50%，按 5/10/10/10/10/12/10/10/8/5/5/5 拆分
        ,CONCAT(
            CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.12 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.10 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.08 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4)), ','
            ,CAST(COALESCE(CAST(his_plannedsalesvolume AS DECIMALV3(20,4)), 0) * 0.5 * 0.05 AS DECIMALV3(20,4))
        ) AS plan_sales_str
    FROM dim.dim_ipd_jtplm_his_productmodel_dd
    WHERE his_pmdproductaffiliatedcompany = '激光显示'
        AND his_domesticsalesorexport = '外销'
        AND his_productsmallcategories IN ('激光电视','家用投影')
        AND his_plannedsalesvolume IS NOT NULL
        AND his_actualtimetomarket IS NOT NULL
)
SELECT
    PG00061
    ,'LX' AS plan_type
    ,PG00002
    ,PG00003
    ,PG00004
    ,PG00020
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,CAST(element_at(sbs_plan_sales, idx) AS DECIMALV3(20,4)) AS plan_sales_qty
    ,NOW()
    ,'产品型号口径' AS model_type
FROM (
    SELECT
        PG00061, PG00002, PG00003, PG00004, PG00020, PG00025
        ,SPLIT_BY_STRING(dt_month_str, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales_str, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month_str, ',')) + 1) AS idx_array
    FROM wx_laser_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;