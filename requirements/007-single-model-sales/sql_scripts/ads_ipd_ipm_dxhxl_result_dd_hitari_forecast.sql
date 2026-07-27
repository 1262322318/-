-- DORIS sql 
-- ******************************************************************** --
-- 脚本名称: ads_ipd_ipm_dxhxl_result_dd_hitari_forecast.sql
-- 功能描述: 日立单型号销量ADS层未来月份预测（v2，对齐原脚本结构）
-- 逻辑说明: 
--   1. 月份序列：上个月 ~ 今年12月
--   2. 保持原脚本结构：明细级数据 → 维度扩展 → 统一COUNT(DISTINCT)+SUM
--   3. 数据源不区分dt_type（DWS层已处理好实际+预测边界）
--   4. 集团口径月度：近3月明细 → COUNT(DISTINCT model) + SUM(sales_qty)
--   5. 内控口径月度：当月明细 → COUNT(DISTINCT model) + SUM(sales_qty)
-- 参数: 无需外部参数
-- 依赖: dws_ipd_ipm_dxhxl_detail_dd_hitari_forecast.sql
-- ******************************************************************** --

DELETE FROM ads.ads_ipd_ipm_dxhxl_result_dd 
WHERE company = '海信日立'
    AND dimension_type = '单型号销量'
    AND dt_month >= DATE_FORMAT(DATE_SUB(DATE_SUB(CURDATE(), INTERVAL 1 DAY), INTERVAL 1 MONTH), '%Y%m')
    AND dt_month <= CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y'), '12');

INSERT INTO ads.ads_ipd_ipm_dxhxl_result_dd(
dt_month, dimension_type, dt_type, company, product_line, in_out_sale,
dimension_1, dimension_2, dimension_3, dimension_4, zhibiao_type, rili_nkjt,
model_num, sum_qty, dxhxl, plan_dxhxl, completion_rate_dxhxl,
sum_amt, dxhxe, plan_dxhxe, completion_rate_dxhxe, load_dt
)
WITH month_seq AS (
    SELECT -1 AS offset UNION ALL SELECT 0 UNION ALL SELECT 1
    UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11
)
,target_months AS (
    SELECT DATE_FORMAT(DATE_ADD(
        STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
        INTERVAL m.offset MONTH
    ), '%Y%m') AS target_month
    FROM month_seq m
    WHERE DATE_FORMAT(DATE_ADD(
        STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m'), '-01'), '%Y-%m-%d'),
        INTERVAL m.offset MONTH
    ), '%Y') = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')
)
,weidu_dt_type AS (
    SELECT '年' AS dt_type UNION ALL SELECT '月' AS dt_type
)
,weidu_dimension_1 AS (
    SELECT '总体' AS dimension_1 UNION ALL SELECT '营销部' AS dimension_1 UNION ALL SELECT '品牌' AS dimension_1
)
,weidu_dimension_2 AS (
    SELECT udp1 AS dimension_2 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '事业部'
    UNION ALL SELECT udp1 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '事业部合计'
    UNION ALL SELECT udp1 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '工程营销部'
)
,weidu_dimension_3 AS (
    SELECT udp1 AS dimension_3 FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '产品小类'
)
,weidu_dimension_4 AS (
    SELECT '合计' AS dimension_4
)
,weidu_brand AS (
    SELECT '海信' AS brand UNION ALL SELECT '约克' AS brand UNION ALL SELECT '日立' AS brand
    UNION ALL SELECT '其他' AS brand UNION ALL SELECT '合计' AS brand
)
,weidu_koujing AS (
    SELECT '集团' AS koujing UNION ALL SELECT '内控' AS koujing
)
,weidu_zhibiao_type AS (
    SELECT '在售' AS zhibiao_type UNION ALL SELECT '退市' AS zhibiao_type UNION ALL SELECT '在产' AS zhibiao_type
)
,weidu_all AS (
    SELECT DISTINCT
        tm.target_month AS dt_month
        ,'空调公司' AS company
        ,'中央空调' AS product_line
        ,dt_type
        ,zhibiao_type
        ,CASE WHEN dimension_1 = '总体' THEN '总体' ELSE dimension_1 END AS dimension_1
        ,CASE WHEN dimension_1 = '营销部' THEN dimension_2
              WHEN dimension_1 = '品牌' THEN brand
              ELSE '总体' END AS dimension_2
        ,dimension_3
        ,dimension_4
        ,koujing
    FROM weidu_dimension_1, weidu_dimension_2, weidu_dt_type, weidu_dimension_3,
         weidu_zhibiao_type, weidu_koujing, weidu_brand, weidu_dimension_4, target_months tm
    WHERE CASE WHEN koujing = '集团' THEN zhibiao_type = '在售' ELSE 1=1 END
        AND CASE WHEN koujing = '集团' THEN dimension_4 = '合计' ELSE 1=1 END
        AND CASE WHEN koujing = '集团' THEN dimension_2 NOT LIKE '%考核%' ELSE 1=1 END
        AND CASE WHEN dimension_1 <> '品牌' THEN brand = '合计' ELSE 1=1 END
)
,weidu_datacopy AS (
    SELECT '正常' AS datacopy UNION ALL SELECT '各营销部' AS datacopy
    UNION ALL SELECT '内销合计' AS datacopy UNION ALL SELECT '内外销' AS datacopy
    UNION ALL SELECT '合计' AS datacopy UNION ALL SELECT '品牌' AS datacopy
    UNION ALL SELECT '品牌合计' AS datacopy UNION ALL SELECT '工程营销部' AS datacopy
)

-- sales_all：明细级取数，CROSS JOIN目标月+口径（对齐原脚本结构）
,sales_all AS (
    --月度：先按源月分别COUNT(DISTINCT)，再外层SUM得到近3月型号数之和
    SELECT
        dt_month
        ,company
        ,product_line
        ,'月' AS dt_type
        ,dimension_2
        ,dimension_3
        ,zhibiao_type
        ,biaozhun_dingzhi
        ,brand
        ,koujing
        ,SUM(ct) AS ct              --近3月型号数之和（每月去重后再相加）
        ,SUM(sales_qty) AS sales_qty
        ,SUM(sales_amt) AS sales_amt
    FROM (
        --内层：按源月独立COUNT(DISTINCT)
        SELECT
            tm.target_month AS dt_month
            ,company
            ,product_line
            ,COALESCE(PC20080, '其他') AS dimension_2
            ,COALESCE(product_sml, '其他') AS dimension_3
            ,CASE WHEN koujing = '集团' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
            WHEN koujing = '内控' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                     WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
            ELSE '其他' END AS zhibiao_type
            ,'合计' AS biaozhun_dingzhi
            ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
                  WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END AS brand
            ,koujing
            ,COUNT(DISTINCT model) AS ct  --每个源月独立去重
            ,SUM(sales_qty) AS sales_qty
            ,SUM(sales_amt) AS sales_amt
        FROM dws.dws_ipd_ipm_dxhxl_detail_dd dws, weidu_koujing, target_months tm
        WHERE CASE
                WHEN koujing = '集团' THEN
                    dws.dt_month IN (
                        tm.target_month,
                        DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(tm.target_month, '01'), '%Y%m%d'), INTERVAL 1 MONTH), '%Y%m'),
                        DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(tm.target_month, '01'), '%Y%m%d'), INTERVAL 2 MONTH), '%Y%m')
                    )
                WHEN koujing = '内控' THEN
                    dws.dt_month = tm.target_month
                ELSE 1=2
            END
            AND product_line = '中央空调'
            AND CASE WHEN koujing = '集团' THEN is_project = 'N'
                     WHEN koujing = '内控' THEN is_project_nk = 'N'
                     ELSE 1=2 END
        GROUP BY tm.target_month
            ,dws.dt_month  --按源月分组，保证每月独立去重
            ,company
            ,product_line
            ,COALESCE(PC20080, '其他')
            ,COALESCE(product_sml, '其他')
            ,CASE WHEN koujing = '集团' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
            WHEN koujing = '内控' THEN
                CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                     WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
            ELSE '其他' END
            ,koujing
            ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
                  WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END
    ) a
    GROUP BY dt_month, company, product_line, dimension_2, dimension_3,
        zhibiao_type, biaozhun_dingzhi, brand, koujing

    UNION ALL

    --年：集团取全年跨月去重COUNT(DISTINCT)，内控取当月
    SELECT
        tm.target_month AS dt_month
        ,company
        ,product_line
        ,'年' AS dt_type
        ,COALESCE(PC20080, '其他') AS dimension_2
        ,COALESCE(product_sml, '其他') AS dimension_3
        ,CASE WHEN koujing = '集团' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
        WHEN koujing = '内控' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                 WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
        ELSE '其他' END AS zhibiao_type
        ,'合计' AS biaozhun_dingzhi
        ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
              WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END AS brand
        ,koujing
        ,COUNT(DISTINCT model) AS ct
        ,CASE WHEN koujing = '集团' THEN SUM(sales_qty)
              WHEN koujing = '内控' THEN SUM(sales_qty_y)
              ELSE NULL END AS sales_qty
        ,CASE WHEN koujing = '集团' THEN SUM(sales_amt)
              WHEN koujing = '内控' THEN SUM(sales_amt_y)
              ELSE NULL END AS sales_amt
    FROM dws.dws_ipd_ipm_dxhxl_detail_dd dws, weidu_koujing, target_months tm
    WHERE CASE
            WHEN koujing = '集团' THEN
                dws.dt_month <= tm.target_month
                AND SUBSTRING(dws.dt_month, 1, 4) = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y')
            WHEN koujing = '内控' THEN
                dws.dt_month = tm.target_month
            ELSE 1=2
        END
        AND product_line = '中央空调'
        AND CASE WHEN koujing = '集团' THEN is_project = 'N'
                 WHEN koujing = '内控' THEN is_project_nk = 'N'
                 ELSE 1=2 END
    GROUP BY tm.target_month
        ,company
        ,product_line
        ,COALESCE(PC20080, '其他')
        ,COALESCE(product_sml, '其他')
        ,CASE WHEN koujing = '集团' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备','停止下单') THEN '在售' ELSE '其他' END
        WHEN koujing = '内控' THEN
            CASE WHEN COALESCE(productmodel__life, '上市') IN ('上市','退市准备') THEN '在售'
                 WHEN COALESCE(productmodel__life, '上市') IN ('停止下单') THEN '退市' ELSE '其他' END
        ELSE '其他' END
        ,koujing
        ,CASE WHEN brand = 'YORK' THEN '约克' WHEN brand = 'Hisense' THEN '海信'
              WHEN brand = 'HITACHI' THEN '日立' ELSE '其他' END
)

-- sales_all_jiagong：维度加工（与原脚本结构完全一致）
,sales_all_jiagong AS (
    SELECT
        t1.dt_month
        ,t1.company
        ,t1.product_line
        ,t1.dt_type
        ,CASE WHEN t4.datacopy IN ('正常') THEN '总体'
              WHEN t4.datacopy IN ('品牌','品牌合计') THEN '品牌'
              ELSE '营销部' END AS dimension_1
        ,CASE WHEN t4.datacopy IN ('正常') THEN '总体'
              WHEN t4.datacopy IN ('品牌') THEN brand
              WHEN t4.datacopy IN ('合计','品牌合计') THEN '合计'
              WHEN t4.datacopy IN ('内销合计') THEN '内销'
              WHEN t4.datacopy IN ('内外销') THEN COALESCE(t2.udp2, '其他')
              WHEN t4.datacopy LIKE '%工程营销部%' THEN CONCAT(COALESCE(t2.udp1, '其他'), '-', brand)
              ELSE COALESCE(t2.udp1, '其他') END AS dimension_2
        ,CASE WHEN t7.chanpinpinlei LIKE '%产品小类%' THEN COALESCE(t3.udp1, '其他')
              ELSE '合计' END AS dimension_3
        ,CASE WHEN t6.bzp_dzp = '正常' THEN biaozhun_dingzhi
              ELSE '合计' END AS dimension_4
        ,CASE WHEN t5.zhibiao_type IN ('在产','合计') THEN t5.zhibiao_type
              ELSE t1.zhibiao_type END AS zhibiao_type
        ,t1.koujing
        ,t1.ct
        ,t1.sales_qty
        ,t1.sales_amt
        ,t4.datacopy
    FROM sales_all t1
    LEFT JOIN (SELECT * FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '事业部') t2
        ON t1.dimension_2 = t2.udp1
    LEFT JOIN (SELECT * FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao = '产品小类') t3
        ON t1.dimension_3 = t3.udp1
    FULL JOIN weidu_datacopy t4 ON 1=1
    FULL JOIN (SELECT '在产' AS zhibiao_type UNION ALL SELECT '在售' AS zhibiao_type ) t5 ON 1=1
    FULL JOIN (SELECT '合计' AS bzp_dzp ) t6 ON 1=1
    FULL JOIN (SELECT '合计' AS chanpinpinlei UNION ALL SELECT '产品小类' AS chanpinpinlei) t7 ON 1=1
    WHERE CASE WHEN t4.datacopy LIKE '%内销合计%' THEN t2.udp2 IN ('内销TOC','内销TOB')
               WHEN t4.datacopy LIKE '%内外销%' THEN t2.udp2 IN ('内销TOC','内销TOB','外销')
               WHEN t4.datacopy LIKE '%工程营销部%' THEN COALESCE(t2.udp1, '其他') = '工程营销部'
               WHEN t5.zhibiao_type = '在产' THEN t1.zhibiao_type IN ('在售','退市')
               ELSE 1=1 END
        AND CASE WHEN t1.koujing = '内控' AND t4.datacopy LIKE '%考核%'
                 THEN t2.udp1 IN ('大客户部','工程营销部','日立家装营销部','海信家装营销部','约克家装营销部','海外技术支持部')
                 ELSE 1=1 END
)

-- act_value：最终聚合
,act_value AS (
    SELECT
        dt_month
        ,company
        ,product_line
        ,dt_type
        ,dimension_1
        ,dimension_2
        ,dimension_3
        ,dimension_4
        ,zhibiao_type
        ,koujing
        ,datacopy
        ,SUM(ct) AS ct
        ,SUM(sales_qty) AS sales_qty
        ,SUM(sales_amt) AS sales_amt
        ,SUM(sales_qty) / NULLIF(SUM(ct), 0.0) AS dxhxl
        ,SUM(sales_amt) / NULLIF(SUM(ct), 0.0) AS dxhxe
    FROM sales_all_jiagong
    GROUP BY dt_month, company, product_line, dt_type,
        dimension_1, dimension_2, dimension_3, dimension_4,
        zhibiao_type, koujing, datacopy
)

-- 最终SELECT
SELECT
    t1.dt_month
    ,'单型号销量' AS dimension_type
    ,t1.dt_type
    ,'海信日立' AS company
    ,'海信日立' AS product_line
    ,'全部' AS in_out_sale
    ,t1.dimension_1
    ,t1.dimension_2
    ,t1.dimension_3
    ,t1.dimension_4
    ,t1.zhibiao_type
    ,t1.koujing
    ,t2.ct
    ,t2.sales_qty
    ,t2.dxhxl
    ,NULL AS plan_dxhxl
    ,NULL AS completion_rate_dxhxl
    ,t2.sales_amt
    ,t2.dxhxe
    ,NULL AS plan_dxhxe
    ,NULL AS completion_rate_dxhxe
    ,NOW()
FROM weidu_all t1
LEFT JOIN act_value t2
    ON t1.dt_month = t2.dt_month
    AND t1.company = t2.company
    AND t1.product_line = t2.product_line
    AND t1.dt_type = t2.dt_type
    AND t1.dimension_1 = t2.dimension_1
    AND t1.dimension_2 = t2.dimension_2
    AND t1.dimension_3 = t2.dimension_3
    AND t1.zhibiao_type = t2.zhibiao_type
    AND t1.koujing = t2.koujing
;
