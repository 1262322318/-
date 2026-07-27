/*
 * 脚本名称: dws_ipd_ipm_rili_qdch_m_detail_dd.sql
 * 功能描述: 海信日立签单量&出货量月度汇总明细
 *           包含3次INSERT：型号口径、型号口径-sap编码合计、项目口径
 * 需求编号: 015-rili-xpqd-migration
 * 创建时间: 2026-07-15
 * 依赖关系:
 *   输入: dim.dim_ipd_salemodel_dd（HDRP产品维度）
 *         dw.dim_product_base_info_dd（MDG桥接：sale_model_code→product_code）
 *         dw.dwsd_rilisms_tf_hac_contract（内销签单）
 *         ods.odsemp_sms_hac_hh_gj_contract + _detail（外销签单）
 *         dw.dwsd_rilisms_tf_hac_shipment（内销出货）
 *         ods.odsemp_sms_hac_hh_gj_tr_notice + _detial（外销出货）
 *         ods.odsemp_sms_hac_hise_dept（组织架构）
 *         ods.odsemp_sms_hac_hise_country（国家）
 *   输出: dws.dws_ipd_ipm_rili_qdch_m_detail_dd
 * 调度参数: ${GP_START_DT} = 调度日期（昨天，yyyymmdd）
 */

-- ============================================================
-- 第1次INSERT：data_type = '型号口径'
-- ============================================================
DELETE FROM dws.dws_ipd_ipm_rili_qdch_m_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND data_type = '型号口径';

INSERT INTO dws.dws_ipd_ipm_rili_qdch_m_detail_dd(
    data_type,              -- 数据口径
    dt_month,               -- 月份
    in_out_sale,            -- 内外销
    sap_number,             -- sap编码（物料编码）
    prdct_model,            -- 型号名称
    project_name,           -- 项目名称
    project_id,             -- 项目编码
    shangshi_time,          -- 上市时间
    first_month,            -- 首月
    shangshi_now_m,         -- 统计周期
    marketing_department,   -- 营销部
    branches,               -- 分公司
    daqu,                   -- 大区
    banshichu,              -- 办事处
    country,                -- 国家
    qiandan_m,              -- 本月签单量
    qiandan_lj,             -- 累计签单量
    qiandan_12m,            -- 上市12个月累计签单量
    qiandan_24m,            -- 上市24个月累计签单量
    qiandan_36m,            -- 上市36个月累计签单量
    chuhuo_m,               -- 本月出货量
    chuhuo_lj,              -- 累计出货量
    chuhuo_12m,             -- 上市12个月累计出货量
    chuhuo_24m,             -- 上市24个月累计出货量
    chuhuo_36m,             -- 上市36个月累计出货量
    product_current,        -- 型号生命周期状态
    is_project,             -- 是否保护期
    dimension_1,            -- 维度1（内销/外销）
    load_dt,                -- 加载时间
    shangshi_time_xm,       -- 上市时间（项目）
    shangshi_time_syb,      -- 上市时间（事业部）
    qiandan_12m_xm,         -- 上市12个月累计签单量（项目）
    qiandan_24m_xm,         -- 上市24个月累计签单量（项目）
    qiandan_36m_xm,         -- 上市36个月累计签单量（项目）
    qiandan_12m_syb,         -- 上市12个月累计签单量（事业部）
    qiandan_24m_syb,         -- 上市24个月累计签单量（事业部）
    qiandan_36m_syb,         -- 上市36个月累计签单量（事业部）
    chuhuo_12m_xm,           -- 上市12个月累计出货量（项目）
    chuhuo_24m_xm,           -- 上市24个月累计出货量（项目）
    chuhuo_36m_xm,           -- 上市36个月累计出货量（项目）
    chuhuo_12m_syb,          -- 上市12个月累计出货量（事业部）
    chuhuo_24m_syb,          -- 上市24个月累计出货量（事业部）
    chuhuo_36m_syb,          -- 上市36个月累计出货量（事业部）
    salemodelcode              -- 维度2（销售型号编码）
)

-- CTE1: rili_model — 新品型号范围
WITH rili_model AS (
    SELECT
        t1.PG00068 AS salemodelcode,                                            -- 销售型号编码
        t1.PG00061 AS prdct_model,                                              -- 型号名称
        t1.project_name AS project_mingcheng,                                   -- 项目名称
        t1.project_code AS project_id,                                          -- 项目编码
        t1.PG00025 AS ha_pclmarkettime,                                         -- 上市时间
        DATE_FORMAT(DATE_ADD(t1.PG00025, INTERVAL 1 MONTH), '%Y%m') AS first_month, -- 首月
        DATE_FORMAT(DATE_ADD(t1.PG00025, INTERVAL 12 MONTH), '%Y%m') AS shangshi_12m, -- 上市+12月
        DATE_FORMAT(DATE_ADD(t1.PG00025, INTERVAL 24 MONTH), '%Y%m') AS shangshi_24m, -- 上市+24月
        DATE_FORMAT(DATE_ADD(t1.PG00025, INTERVAL 36 MONTH), '%Y%m') AS shangshi_36m, -- 上市+36月
        TIMESTAMPDIFF(MONTH, t1.PG00025, CAST('${GP_START_DT}' AS DATE)) AS shangshi_now_m, -- 上市月数
        t1.PC20080 AS marketing_department,                                     -- 事业部
        t1.PG00069 AS brand,                                                    -- 品牌
        t1.PG00009 AS product_series,                                           -- 产品系列
        t1.PG00057 AS product_current,                                          -- 生命周期状态
        t1.HX00379,                                                             -- 是否模块组合
        t1.PC20006,                                                             -- 标准品/定制产品
        t1.HX00327 AS productmanager,                                           -- 产品经理
        -- MDG桥接：获取对应的SAP物料编码
        t2.product_code AS sap_number                                           -- SAP物料编码（用于关联签单/出货表）
    FROM dim.dim_ipd_salemodel_dd t1
    LEFT JOIN (
        SELECT sale_model_code, product_code
        FROM dw.dim_product_base_info_dd
        WHERE product_type_code IN ('FERT', 'ZTAO')
            AND delete_flag != 'Y'
    ) t2 ON t1.PG00068 = t2.sale_model_code
    WHERE t1.PG00002 IN ('空气调节类产品', '外购产品')
        AND t1.PG00003 IN ('中央空调', '外购设备', '空气调节类配件')
        AND t1.PG00004 IN ('单元式内机', '单元式外机', '多联机内机', '多联机外机',
                           '空气源热泵两联供', '空气源热泵三联供', '新风换气机', '热泵热水机')
        AND t1.PG00057 IN ('上市', '预停签')
        AND t1.PG00025 IS NOT NULL
        AND TIMESTAMPDIFF(MONTH, t1.PG00025, CAST('${GP_START_DT}' AS DATE)) >= 1
        AND TIMESTAMPDIFF(MONTH, t1.PG00025, CAST('${GP_START_DT}' AS DATE)) <= 36
        -- [待确认] 模块组合排除：AND t1.HX00379 != '是'
        -- [待确认] 非标排除：AND t1.PC20006 = '标准品'
)

-- CTE2: shangshitime_xm — 项目口径上市时间
,shangshitime_xm AS (
    SELECT
        project_id,                                                             -- 项目编码
        marketing_department,                                                   -- 事业部
        MIN(ha_pclmarkettime) AS ha_pclmarkettime_xm,                           -- 项目口径上市时间
        DATE_FORMAT(DATE_ADD(MIN(ha_pclmarkettime), INTERVAL 12 MONTH), '%Y%m') AS shangshi_12m_xm,
        DATE_FORMAT(DATE_ADD(MIN(ha_pclmarkettime), INTERVAL 24 MONTH), '%Y%m') AS shangshi_24m_xm,
        DATE_FORMAT(DATE_ADD(MIN(ha_pclmarkettime), INTERVAL 36 MONTH), '%Y%m') AS shangshi_36m_xm
    FROM rili_model
    GROUP BY project_id, marketing_department
)

-- CTE3: shangshitime_syb — 事业部口径上市时间
,shangshitime_syb AS (
    SELECT
        marketing_department,                                                   -- 事业部
        MIN(ha_pclmarkettime) AS ha_pclmarkettime_syb,                          -- 事业部口径上市时间
        DATE_FORMAT(DATE_ADD(MIN(ha_pclmarkettime), INTERVAL 12 MONTH), '%Y%m') AS shangshi_12m_syb,
        DATE_FORMAT(DATE_ADD(MIN(ha_pclmarkettime), INTERVAL 24 MONTH), '%Y%m') AS shangshi_24m_syb,
        DATE_FORMAT(DATE_ADD(MIN(ha_pclmarkettime), INTERVAL 36 MONTH), '%Y%m') AS shangshi_36m_syb
    FROM rili_model
    GROUP BY marketing_department
)

-- CTE4: rili_fenjieduan — 每个型号的三种口径时间边界
,rili_fenjieduan AS (
    SELECT
        t1.sap_number,                                                          -- SAP物料编码
        t1.salemodelcode,                                                       -- 销售型号编码
        t1.first_month,
        t1.shangshi_12m,
        t1.shangshi_24m,
        t1.shangshi_36m,
        t2.ha_pclmarkettime_xm,
        t2.shangshi_12m_xm,
        t2.shangshi_24m_xm,
        t2.shangshi_36m_xm,
        t3.ha_pclmarkettime_syb,
        t3.shangshi_12m_syb,
        t3.shangshi_24m_syb,
        t3.shangshi_36m_syb
    FROM rili_model t1
    LEFT JOIN shangshitime_xm t2
        ON t1.project_id = t2.project_id
        AND t1.marketing_department = t2.marketing_department
    LEFT JOIN shangshitime_syb t3
        ON t1.marketing_department = t3.marketing_department
)

-- 承接第一段CTE：rili_model, shangshitime_xm, shangshitime_syb, rili_fenjieduan

-- CTE5: qiandan_m — 本月签单量（内销+外销）
,qiandan_m AS (
    -- 内销签单（本月）
    SELECT
        T.ORGNAME AS fengongsi,                                                 -- 分公司
        NULL AS daqu,                                                           -- 大区（内销无）
        NULL AS banshichu,                                                      -- 办事处（内销无）
        NULL AS guojia,                                                         -- 国家（内销无）
        T.PRODUCTID,                                                            -- 产品编码（物料编码）
        '内销' AS fenlei,                                                       -- 分类
        SUM(T.QTY) AS qty                                                       -- 签单数量
    FROM dw.dwsd_rilisms_tf_hac_contract T
    WHERE T.CODENAME NOT LIKE '%国际%'
        AND DATE_FORMAT(T.csigndate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY T.ORGNAME, T.PRODUCTID

    UNION ALL

    -- 外销签单（本月）
    SELECT
        NULL AS fengongsi,                                                      -- 分公司（外销无）
        t3.ORGNAME AS daqu,                                                     -- 大区
        t4.ORGNAME AS banshichu,                                                -- 办事处
        t5.COUNTRY_NAME AS guojia,                                              -- 国家
        t2.PRODUCTID,                                                           -- 产品编码
        '外销' AS fenlei,                                                       -- 分类
        SUM(t2.QTY) AS qty                                                      -- 签单数量
    FROM ods.odsemp_sms_hac_hh_gj_contract t1
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_contract_detail t2
        ON t1.row_id = t2.CONTRACTID
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t3
        ON t1.AREAID = t3.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t4
        ON t1.BID = t4.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_country WHERE active_flag = '1') t5
        ON t1.COUNTRY_CODE = t5.COUNTRY_CODE
    WHERE DATE_FORMAT(t1.SIGN_TIME, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY t3.ORGNAME, t4.ORGNAME, t5.COUNTRY_NAME, t2.PRODUCTID
)

-- CTE6: qiandan_lj — 累计签单量（内销+外销，不限时间）
,qiandan_lj AS (
    -- 内销签单（累计）
    SELECT
        T.ORGNAME AS fengongsi,
        NULL AS daqu,
        NULL AS banshichu,
        NULL AS guojia,
        T.PRODUCTID,
        '内销' AS fenlei,
        SUM(T.QTY) AS qty
    FROM dw.dwsd_rilisms_tf_hac_contract T
    WHERE T.CODENAME NOT LIKE '%国际%'
    GROUP BY T.ORGNAME, T.PRODUCTID

    UNION ALL

    -- 外销签单（累计）
    SELECT
        NULL AS fengongsi,
        t3.ORGNAME AS daqu,
        t4.ORGNAME AS banshichu,
        t5.COUNTRY_NAME AS guojia,
        t2.PRODUCTID,
        '外销' AS fenlei,
        SUM(t2.QTY) AS qty
    FROM ods.odsemp_sms_hac_hh_gj_contract t1
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_contract_detail t2
        ON t1.row_id = t2.CONTRACTID
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t3
        ON t1.AREAID = t3.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t4
        ON t1.BID = t4.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_country WHERE active_flag = '1') t5
        ON t1.COUNTRY_CODE = t5.COUNTRY_CODE
    GROUP BY t3.ORGNAME, t4.ORGNAME, t5.COUNTRY_NAME, t2.PRODUCTID
)

-- CTE7: qiandan_fjd — 分阶段签单量（上市12/24/36月，三种口径）
,qiandan_fjd AS (
    -- 内销签单（分阶段）
    SELECT
        t1.ORGNAME AS fengongsi,
        NULL AS daqu,
        NULL AS banshichu,
        NULL AS guojia,
        t1.PRODUCTID,
        '内销' AS fenlei,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_12m THEN t1.QTY ELSE 0 END) AS sum_12,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_24m THEN t1.QTY ELSE 0 END) AS sum_24,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_36m THEN t1.QTY ELSE 0 END) AS sum_36,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_12m_xm THEN t1.QTY ELSE 0 END) AS sum_12_xm,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_24m_xm THEN t1.QTY ELSE 0 END) AS sum_24_xm,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_36m_xm THEN t1.QTY ELSE 0 END) AS sum_36_xm,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_12m_syb THEN t1.QTY ELSE 0 END) AS sum_12_syb,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_24m_syb THEN t1.QTY ELSE 0 END) AS sum_24_syb,
        SUM(CASE WHEN DATE_FORMAT(t1.csigndate, '%Y%m') <= t2.shangshi_36m_syb THEN t1.QTY ELSE 0 END) AS sum_36_syb
    FROM dw.dwsd_rilisms_tf_hac_contract t1
    INNER JOIN rili_fenjieduan t2 ON t1.PRODUCTID = t2.sap_number
    WHERE t1.CODENAME NOT LIKE '%国际%'
    GROUP BY t1.ORGNAME, t1.PRODUCTID

    UNION ALL

    -- 外销签单（分阶段）
    SELECT
        NULL AS fengongsi,
        t3.ORGNAME AS daqu,
        t4.ORGNAME AS banshichu,
        t5.COUNTRY_NAME AS guojia,
        t2.PRODUCTID,
        '外销' AS fenlei,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_12m THEN t2.QTY ELSE 0 END) AS sum_12,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_24m THEN t2.QTY ELSE 0 END) AS sum_24,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_36m THEN t2.QTY ELSE 0 END) AS sum_36,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_12m_xm THEN t2.QTY ELSE 0 END) AS sum_12_xm,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_24m_xm THEN t2.QTY ELSE 0 END) AS sum_24_xm,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_36m_xm THEN t2.QTY ELSE 0 END) AS sum_36_xm,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_12m_syb THEN t2.QTY ELSE 0 END) AS sum_12_syb,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_24m_syb THEN t2.QTY ELSE 0 END) AS sum_24_syb,
        SUM(CASE WHEN DATE_FORMAT(t1.SIGN_TIME, '%Y%m') <= t6.shangshi_36m_syb THEN t2.QTY ELSE 0 END) AS sum_36_syb
    FROM ods.odsemp_sms_hac_hh_gj_contract t1
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_contract_detail t2
        ON t1.row_id = t2.CONTRACTID
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t3
        ON t1.AREAID = t3.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t4
        ON t1.BID = t4.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_country WHERE active_flag = '1') t5
        ON t1.COUNTRY_CODE = t5.COUNTRY_CODE
    INNER JOIN rili_fenjieduan t6 ON t2.PRODUCTID = t6.sap_number
    GROUP BY t3.ORGNAME, t4.ORGNAME, t5.COUNTRY_NAME, t2.PRODUCTID
)

-- CTE8: chuhuo_m — 本月出货量（内销+外销）
,chuhuo_m AS (
    -- 内销出货（本月）
    SELECT
        T.BRANCH_NAME AS fengongsi,                                             -- 分公司
        NULL AS daqu,
        NULL AS banshichu,
        NULL AS guojia,
        T.MATERIAL_CODE AS PRODUCTID,                                           -- 物料编码
        '内销' AS fenlei,
        SUM(T.SHIPMENT_QTY) AS chuhuo_qty                                       -- 出货数量
    FROM dw.dwsd_rilisms_tf_hac_shipment T
    WHERE DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY T.BRANCH_NAME, T.MATERIAL_CODE

    UNION ALL

    -- 外销出货（本月）
    SELECT
        NULL AS fengongsi,
        t4.ORGNAME AS daqu,
        t5.ORGNAME AS banshichu,
        t6.COUNTRY_NAME AS guojia,
        t2.PRODUCT_ID AS PRODUCTID,
        '外销' AS fenlei,
        SUM(t2.TRAN_AMOUNT) AS chuhuo_qty
    FROM ods.odsemp_sms_hac_hh_gj_tr_notice t1
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_tr_detial t2
        ON t1.ROW_ID = t2.TR_NOTICE_ID
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_contract t3
        ON t1.CONTRACT_ID = t3.ROW_ID
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t4
        ON t3.AREAID = t4.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t5
        ON t3.BID = t5.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_country WHERE active_flag = '1') t6
        ON t3.COUNTRY_CODE = t6.COUNTRY_CODE
    WHERE DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    GROUP BY t4.ORGNAME, t5.ORGNAME, t6.COUNTRY_NAME, t2.PRODUCT_ID
)

-- CTE9: chuhuo_lj — 累计出货量（内销+外销，不限时间）
,chuhuo_lj AS (
    -- 内销出货（累计）
    SELECT
        T.BRANCH_NAME AS fengongsi,
        NULL AS daqu,
        NULL AS banshichu,
        NULL AS guojia,
        T.MATERIAL_CODE AS PRODUCTID,
        '内销' AS fenlei,
        SUM(T.SHIPMENT_QTY) AS chuhuo_qty
    FROM dw.dwsd_rilisms_tf_hac_shipment T
    GROUP BY T.BRANCH_NAME, T.MATERIAL_CODE

    UNION ALL

    -- 外销出货（累计）
    SELECT
        NULL AS fengongsi,
        t4.ORGNAME AS daqu,
        t5.ORGNAME AS banshichu,
        t6.COUNTRY_NAME AS guojia,
        t2.PRODUCT_ID AS PRODUCTID,
        '外销' AS fenlei,
        SUM(t2.TRAN_AMOUNT) AS chuhuo_qty
    FROM ods.odsemp_sms_hac_hh_gj_tr_notice t1
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_tr_detial t2
        ON t1.ROW_ID = t2.TR_NOTICE_ID
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_contract t3
        ON t1.CONTRACT_ID = t3.ROW_ID
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t4
        ON t3.AREAID = t4.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t5
        ON t3.BID = t5.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_country WHERE active_flag = '1') t6
        ON t3.COUNTRY_CODE = t6.COUNTRY_CODE
    GROUP BY t4.ORGNAME, t5.ORGNAME, t6.COUNTRY_NAME, t2.PRODUCT_ID
)

-- CTE10: chuhuo_fjd — 分阶段出货量（上市12/24/36月，三种口径）
,chuhuo_fjd AS (
    -- 内销出货（分阶段）
    SELECT
        T.BRANCH_NAME AS fengongsi,
        NULL AS daqu,
        NULL AS banshichu,
        NULL AS guojia,
        T.MATERIAL_CODE AS PRODUCTID,
        '内销' AS fenlei,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_12m THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_12,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_24m THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_24,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_36m THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_36,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_12m_xm THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_12_xm,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_24m_xm THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_24_xm,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_36m_xm THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_36_xm,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_12m_syb THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_12_syb,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_24m_syb THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_24_syb,
        SUM(CASE WHEN DATE_FORMAT(CAST(T.SHIPMENT_TIME AS DATE), '%Y%m') <= t2.shangshi_36m_syb THEN T.SHIPMENT_QTY ELSE 0 END) AS chuhuo_36_syb
    FROM dw.dwsd_rilisms_tf_hac_shipment T
    INNER JOIN rili_fenjieduan t2 ON T.MATERIAL_CODE = t2.sap_number
    GROUP BY T.BRANCH_NAME, T.MATERIAL_CODE

    UNION ALL

    -- 外销出货（分阶段）
    SELECT
        NULL AS fengongsi,
        t4.ORGNAME AS daqu,
        t5.ORGNAME AS banshichu,
        t6.COUNTRY_NAME AS guojia,
        t2.PRODUCT_ID AS PRODUCTID,
        '外销' AS fenlei,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_12m THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_12,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_24m THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_24,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_36m THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_36,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_12m_xm THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_12_xm,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_24m_xm THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_24_xm,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_36m_xm THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_36_xm,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_12m_syb THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_12_syb,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_24m_syb THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_24_syb,
        SUM(CASE WHEN DATE_FORMAT(CAST(t1.SHIPDATE AS DATE), '%Y%m') <= t7.shangshi_36m_syb THEN t2.TRAN_AMOUNT ELSE 0 END) AS chuhuo_36_syb
    FROM ods.odsemp_sms_hac_hh_gj_tr_notice t1
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_tr_detial t2
        ON t1.ROW_ID = t2.TR_NOTICE_ID
    LEFT JOIN ods.odsemp_sms_hac_hh_gj_contract t3
        ON t1.CONTRACT_ID = t3.ROW_ID
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t4
        ON t3.AREAID = t4.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_dept WHERE COUNTRY_FLAG = '2') t5
        ON t3.BID = t5.ORGDEPT
    LEFT JOIN (SELECT * FROM ods.odsemp_sms_hac_hise_country WHERE active_flag = '1') t6
        ON t3.COUNTRY_CODE = t6.COUNTRY_CODE
    INNER JOIN rili_fenjieduan t7 ON t2.PRODUCT_ID = t7.sap_number
    GROUP BY t4.ORGNAME, t5.ORGNAME, t6.COUNTRY_NAME, t2.PRODUCT_ID
)

-- 承接第二段CTE：qiandan_m, qiandan_lj, qiandan_fjd, chuhuo_m, chuhuo_lj, chuhuo_fjd

-- 最终SELECT：型号口径明细
SELECT
    '型号口径' AS data_type,                                                    -- 数据口径
    DATE_FORMAT('${GP_START_DT}', '%Y%m') AS dt_month,                          -- 月份
    t2.fenlei AS in_out_sale,                                                   -- 内外销（由签单数据来源决定）
    t1.sap_number,                                                              -- SAP物料编码
    t1.prdct_model,                                                             -- 型号名称
    t1.project_mingcheng AS project_name,                                       -- 项目名称
    t1.project_id,                                                              -- 项目编码
    t1.ha_pclmarkettime AS shangshi_time,                                       -- 上市时间
    t1.first_month,                                                             -- 首月
    t1.shangshi_now_m,                                                          -- 统计周期
    t1.marketing_department,                                                    -- 营销部
    t2.fengongsi AS branches,                                                   -- 分公司
    t2.daqu,                                                                    -- 大区
    t2.banshichu,                                                               -- 办事处
    t2.guojia AS country,                                                       -- 国家
    CASE WHEN t1.shangshi_now_m = 1 THEN t2.qty ELSE t3.qty END AS qiandan_m,  -- 本月签单量（首月=累计）
    t2.qty AS qiandan_lj,                                                       -- 累计签单量
    t4.sum_12 AS qiandan_12m,                                                   -- 上市12个月签单量
    t4.sum_24 AS qiandan_24m,                                                   -- 上市24个月签单量
    t4.sum_36 AS qiandan_36m,                                                   -- 上市36个月签单量
    CASE WHEN t1.shangshi_now_m = 1 THEN t5.chuhuo_qty ELSE t6.chuhuo_qty END AS chuhuo_m, -- 本月出货量（首月=累计）
    t5.chuhuo_qty AS chuhuo_lj,                                                 -- 累计出货量
    t7.chuhuo_12 AS chuhuo_12m,                                                 -- 上市12个月出货量
    t7.chuhuo_24 AS chuhuo_24m,                                                 -- 上市24个月出货量
    t7.chuhuo_36 AS chuhuo_36m,                                                 -- 上市36个月出货量
    t1.product_current,                                                         -- 型号生命周期状态
    'N' AS is_project,                                                          -- 是否保护期
    t2.fenlei AS dimension_1,                                                   -- 维度1（内销/外销）
    NOW() AS load_dt,                                                           -- 加载时间
    t8.ha_pclmarkettime_xm AS shangshi_time_xm,                                 -- 上市时间（项目）
    t8.ha_pclmarkettime_syb AS shangshi_time_syb,                               -- 上市时间（事业部）
    t4.sum_12_xm AS qiandan_12m_xm,                                            -- 上市12个月签单量（项目）
    t4.sum_24_xm AS qiandan_24m_xm,                                            -- 上市24个月签单量（项目）
    t4.sum_36_xm AS qiandan_36m_xm,                                            -- 上市36个月签单量（项目）
    t4.sum_12_syb AS qiandan_12m_syb,                                           -- 上市12个月签单量（事业部）
    t4.sum_24_syb AS qiandan_24m_syb,                                           -- 上市24个月签单量（事业部）
    t4.sum_36_syb AS qiandan_36m_syb,                                           -- 上市36个月签单量（事业部）
    t7.chuhuo_12_xm AS chuhuo_12m_xm,                                          -- 上市12个月出货量（项目）
    t7.chuhuo_24_xm AS chuhuo_24m_xm,                                          -- 上市24个月出货量（项目）
    t7.chuhuo_36_xm AS chuhuo_36m_xm,                                          -- 上市36个月出货量（项目）
    t7.chuhuo_12_syb AS chuhuo_12m_syb,                                         -- 上市12个月出货量（事业部）
    t7.chuhuo_24_syb AS chuhuo_24m_syb,                                         -- 上市24个月出货量（事业部）
    t7.chuhuo_36_syb AS chuhuo_36m_syb,                                         -- 上市36个月出货量（事业部）
    t1.salemodelcode AS salemodelcode                                              -- 维度2（销售型号编码）
FROM rili_model t1
LEFT JOIN qiandan_lj t2
    ON t1.sap_number = t2.PRODUCTID
LEFT JOIN qiandan_m t3
    ON t1.sap_number = t3.PRODUCTID
    AND t2.fenlei = t3.fenlei
    AND COALESCE(t2.fengongsi, '全部') = COALESCE(t3.fengongsi, '全部')
    AND COALESCE(t2.daqu, '全部') = COALESCE(t3.daqu, '全部')
    AND COALESCE(t2.banshichu, '全部') = COALESCE(t3.banshichu, '全部')
    AND COALESCE(t2.guojia, '全部') = COALESCE(t3.guojia, '全部')
LEFT JOIN qiandan_fjd t4
    ON t1.sap_number = t4.PRODUCTID
    AND t2.fenlei = t4.fenlei
    AND COALESCE(t2.fengongsi, '全部') = COALESCE(t4.fengongsi, '全部')
    AND COALESCE(t2.daqu, '全部') = COALESCE(t4.daqu, '全部')
    AND COALESCE(t2.banshichu, '全部') = COALESCE(t4.banshichu, '全部')
    AND COALESCE(t2.guojia, '全部') = COALESCE(t4.guojia, '全部')
LEFT JOIN chuhuo_lj t5
    ON t1.sap_number = t5.PRODUCTID
    AND t2.fenlei = t5.fenlei
    AND COALESCE(t2.fengongsi, '全部') = COALESCE(t5.fengongsi, '全部')
    AND COALESCE(t2.daqu, '全部') = COALESCE(t5.daqu, '全部')
    AND COALESCE(t2.banshichu, '全部') = COALESCE(t5.banshichu, '全部')
    AND COALESCE(t2.guojia, '全部') = COALESCE(t5.guojia, '全部')
LEFT JOIN chuhuo_m t6
    ON t1.sap_number = t6.PRODUCTID
    AND t2.fenlei = t6.fenlei
    AND COALESCE(t2.fengongsi, '全部') = COALESCE(t6.fengongsi, '全部')
    AND COALESCE(t2.daqu, '全部') = COALESCE(t6.daqu, '全部')
    AND COALESCE(t2.banshichu, '全部') = COALESCE(t6.banshichu, '全部')
    AND COALESCE(t2.guojia, '全部') = COALESCE(t6.guojia, '全部')
LEFT JOIN chuhuo_fjd t7
    ON t1.sap_number = t7.PRODUCTID
    AND t2.fenlei = t7.fenlei
    AND COALESCE(t2.fengongsi, '全部') = COALESCE(t7.fengongsi, '全部')
    AND COALESCE(t2.daqu, '全部') = COALESCE(t7.daqu, '全部')
    AND COALESCE(t2.banshichu, '全部') = COALESCE(t7.banshichu, '全部')
    AND COALESCE(t2.guojia, '全部') = COALESCE(t7.guojia, '全部')
LEFT JOIN rili_fenjieduan t8
    ON t1.sap_number = t8.sap_number
;


-- ============================================================
-- 第2次INSERT：data_type = '型号口径-sap编码合计'
-- 从型号口径明细中按sap编码聚合，去掉地理维度
-- ============================================================
DELETE FROM dws.dws_ipd_ipm_rili_qdch_m_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND data_type = '型号口径-sap编码合计';

INSERT INTO dws.dws_ipd_ipm_rili_qdch_m_detail_dd(
    data_type,              -- 数据口径
    dt_month,               -- 月份
    in_out_sale,            -- 内外销
    sap_number,             -- sap编码
    prdct_model,            -- 型号名称
    project_name,           -- 项目名称
    project_id,             -- 项目编码
    shangshi_time,          -- 上市时间
    first_month,            -- 首月
    shangshi_now_m,         -- 统计周期
    marketing_department,   -- 营销部
    branches,               -- 分公司
    daqu,                   -- 大区
    banshichu,              -- 办事处
    country,                -- 国家
    qiandan_m,              -- 本月签单量
    qiandan_lj,             -- 累计签单量
    qiandan_12m,            -- 上市12个月累计签单量
    qiandan_24m,            -- 上市24个月累计签单量
    qiandan_36m,            -- 上市36个月累计签单量
    chuhuo_m,               -- 本月出货量
    chuhuo_lj,              -- 累计出货量
    chuhuo_12m,             -- 上市12个月累计出货量
    chuhuo_24m,             -- 上市24个月累计出货量
    chuhuo_36m,             -- 上市36个月累计出货量
    product_current,        -- 型号生命周期状态
    is_project,             -- 是否保护期
    dimension_1,            -- 维度1
    load_dt,                -- 加载时间
    shangshi_time_xm,       -- 上市时间（项目）
    shangshi_time_syb,      -- 上市时间（事业部）
    qiandan_12m_xm,         -- 上市12个月累计签单量（项目）
    qiandan_24m_xm,         -- 上市24个月累计签单量（项目）
    qiandan_36m_xm,         -- 上市36个月累计签单量（项目）
    qiandan_12m_syb,         -- 上市12个月累计签单量（事业部）
    qiandan_24m_syb,         -- 上市24个月累计签单量（事业部）
    qiandan_36m_syb,         -- 上市36个月累计签单量（事业部）
    chuhuo_12m_xm,           -- 上市12个月累计出货量（项目）
    chuhuo_24m_xm,           -- 上市24个月累计出货量（项目）
    chuhuo_36m_xm,           -- 上市36个月累计出货量（项目）
    chuhuo_12m_syb,          -- 上市12个月累计出货量（事业部）
    chuhuo_24m_syb,          -- 上市24个月累计出货量（事业部）
    chuhuo_36m_syb,          -- 上市36个月累计出货量（事业部）
    salemodelcode              -- 维度2（销售型号编码）
)
SELECT
    '型号口径-sap编码合计' AS data_type,                                        -- 数据口径
    dt_month,                                                                   -- 月份
    in_out_sale,                                                                -- 内外销
    sap_number,                                                                 -- sap编码
    prdct_model,                                                                -- 型号名称
    project_name,                                                               -- 项目名称
    project_id,                                                                 -- 项目编码
    shangshi_time,                                                              -- 上市时间
    first_month,                                                                -- 首月
    shangshi_now_m,                                                             -- 统计周期
    marketing_department,                                                       -- 营销部
    '全部' AS branches,                                                         -- 分公司（合计）
    '全部' AS daqu,                                                             -- 大区（合计）
    '全部' AS banshichu,                                                        -- 办事处（合计）
    '全部' AS country,                                                          -- 国家（合计）
    SUM(qiandan_m),                                                             -- 本月签单量
    SUM(qiandan_lj),                                                            -- 累计签单量
    SUM(qiandan_12m),                                                           -- 上市12个月累计签单量
    SUM(qiandan_24m),                                                           -- 上市24个月累计签单量
    SUM(qiandan_36m),                                                           -- 上市36个月累计签单量
    SUM(chuhuo_m),                                                              -- 本月出货量
    SUM(chuhuo_lj),                                                             -- 累计出货量
    SUM(chuhuo_12m),                                                            -- 上市12个月累计出货量
    SUM(chuhuo_24m),                                                            -- 上市24个月累计出货量
    SUM(chuhuo_36m),                                                            -- 上市36个月累计出货量
    product_current,                                                            -- 型号生命周期状态
    'N' AS is_project,                                                          -- 是否保护期
    '全部' AS dimension_1,                                                      -- 维度1（合计）
    NOW() AS load_dt,                                                           -- 加载时间
    shangshi_time_xm,                                                           -- 上市时间（项目）
    shangshi_time_syb,                                                          -- 上市时间（事业部）
    SUM(qiandan_12m_xm),                                                        -- 上市12个月累计签单量（项目）
    SUM(qiandan_24m_xm),                                                        -- 上市24个月累计签单量（项目）
    SUM(qiandan_36m_xm),                                                        -- 上市36个月累计签单量（项目）
    SUM(qiandan_12m_syb),                                                       -- 上市12个月累计签单量（事业部）
    SUM(qiandan_24m_syb),                                                       -- 上市24个月累计签单量（事业部）
    SUM(qiandan_36m_syb),                                                       -- 上市36个月累计签单量（事业部）
    SUM(chuhuo_12m_xm),                                                         -- 上市12个月累计出货量（项目）
    SUM(chuhuo_24m_xm),                                                         -- 上市24个月累计出货量（项目）
    SUM(chuhuo_36m_xm),                                                         -- 上市36个月累计出货量（项目）
    SUM(chuhuo_12m_syb),                                                        -- 上市12个月累计出货量（事业部）
    SUM(chuhuo_24m_syb),                                                        -- 上市24个月累计出货量（事业部）
    SUM(chuhuo_36m_syb),                                                        -- 上市36个月累计出货量（事业部）
    salemodelcode                                                                 -- 维度2（销售型号编码）
FROM dws.dws_ipd_ipm_rili_qdch_m_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND data_type = '型号口径'
    AND is_project = 'N'
GROUP BY dt_month, in_out_sale, sap_number, prdct_model, project_name, project_id,
    shangshi_time, first_month, shangshi_now_m, marketing_department,
    product_current, shangshi_time_xm, shangshi_time_syb, salemodelcode
;


-- ============================================================
-- 第3次INSERT：data_type = '项目口径'
-- 从型号口径明细按项目聚合，签单/出货的12/24/36月取项目口径时间窗口
-- ============================================================
DELETE FROM dws.dws_ipd_ipm_rili_qdch_m_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND data_type = '项目口径';

INSERT INTO dws.dws_ipd_ipm_rili_qdch_m_detail_dd(
    data_type,              -- 数据口径
    dt_month,               -- 月份
    in_out_sale,            -- 内外销
    sap_number,             -- sap编码
    prdct_model,            -- 型号名称
    project_name,           -- 项目名称
    project_id,             -- 项目编码
    shangshi_time,          -- 上市时间
    first_month,            -- 首月
    shangshi_now_m,         -- 统计周期
    marketing_department,   -- 营销部
    branches,               -- 分公司
    daqu,                   -- 大区
    banshichu,              -- 办事处
    country,                -- 国家
    qiandan_m,              -- 本月签单量
    qiandan_lj,             -- 累计签单量
    qiandan_12m,            -- 上市12个月累计签单量
    qiandan_24m,            -- 上市24个月累计签单量
    qiandan_36m,            -- 上市36个月累计签单量
    chuhuo_m,               -- 本月出货量
    chuhuo_lj,              -- 累计出货量
    chuhuo_12m,             -- 上市12个月累计出货量
    chuhuo_24m,             -- 上市24个月累计出货量
    chuhuo_36m,             -- 上市36个月累计出货量
    product_current,        -- 型号生命周期状态
    is_project,             -- 是否保护期
    dimension_1,            -- 维度1
    load_dt                 -- 加载时间
)
WITH weidu_all AS (
    SELECT '全部' AS weidu1 UNION ALL SELECT '细分' AS weidu1
)
SELECT
    '项目口径' AS data_type,                                                    -- 数据口径
    dt_month,                                                                   -- 月份
    NULL AS in_out_sale,                                                        -- 内外销（项目口径不区分）
    NULL AS sap_number,                                                         -- sap编码（项目口径无）
    NULL AS prdct_model,                                                        -- 型号名称（项目口径无）
    project_name,                                                               -- 项目名称
    project_id,                                                                 -- 项目编码
    MIN(shangshi_time) AS shangshi_time,                                         -- 上市时间（取最早）
    MIN(first_month) AS first_month,                                            -- 首月（取最早）
    MAX(shangshi_now_m) AS shangshi_now_m,                                       -- 统计周期（取最大）
    marketing_department,                                                       -- 营销部
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '内销' THEN '全部' ELSE branches END AS branches,     -- 分公司
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '外销' THEN '全部' ELSE daqu END AS daqu,             -- 大区
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '外销' THEN '全部' ELSE banshichu END AS banshichu,   -- 办事处
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '外销' THEN '全部' ELSE country END AS country,       -- 国家
    SUM(qiandan_m) AS qiandan_m,                                                -- 本月签单量
    SUM(qiandan_lj) AS qiandan_lj,                                              -- 累计签单量
    SUM(qiandan_12m_xm) AS qiandan_12m,                                         -- 上市12个月签单量（项目口径）
    SUM(qiandan_24m_xm) AS qiandan_24m,                                         -- 上市24个月签单量（项目口径）
    SUM(qiandan_36m_xm) AS qiandan_36m,                                         -- 上市36个月签单量（项目口径）
    SUM(chuhuo_m) AS chuhuo_m,                                                  -- 本月出货量
    SUM(chuhuo_lj) AS chuhuo_lj,                                                -- 累计出货量
    SUM(chuhuo_12m_xm) AS chuhuo_12m,                                           -- 上市12个月出货量（项目口径）
    SUM(chuhuo_24m_xm) AS chuhuo_24m,                                           -- 上市24个月出货量（项目口径）
    SUM(chuhuo_36m_xm) AS chuhuo_36m,                                           -- 上市36个月出货量（项目口径）
    NULL AS product_current,                                                    -- 型号生命周期状态（项目口径无）
    'N' AS is_project,                                                          -- 是否保护期
    dimension_1,                                                                -- 维度1
    NOW() AS load_dt                                                            -- 加载时间
FROM dws.dws_ipd_ipm_rili_qdch_m_detail_dd t1, weidu_all t2
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND data_type = '型号口径'
    AND is_project = 'N'
GROUP BY dt_month, project_name, project_id, marketing_department,
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '内销' THEN '全部' ELSE branches END,
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '外销' THEN '全部' ELSE daqu END,
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '外销' THEN '全部' ELSE banshichu END,
    CASE WHEN t2.weidu1 = '全部' AND dimension_1 = '外销' THEN '全部' ELSE country END,
    dimension_1
;
