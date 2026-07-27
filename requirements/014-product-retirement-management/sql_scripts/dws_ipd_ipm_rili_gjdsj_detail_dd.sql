-- ============================================================================
-- 脚本名称：dws_ipd_ipm_rili_gjdsj_detail_dd.sql
-- 功能描述：退市周期缩减率 - DWS明细层
-- 目标表：dws.dws_ipd_ipm_rili_gjdsj_detail_dd
-- 数据源：
--   dim.dim_ipd_salemodel_dd（销售型号基础信息，含停签/停产时间）
--   dim.dim_ipd_productmodel_dd（产品型号，取内外销属性）
--   ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j（飞书退市滚动计划-JSON解析，含营销部/渠道/预停签时间）
-- 产品线：海信日立（中央空调）
-- 粒度：一个销售型号 × 一个data_type（预停签-停签 / 停签-停产）
-- 更新策略：DELETE当月 + INSERT
-- 调度参数：${GP_START_DT}（脚本执行日期前一天，yyyymmdd）
-- 业务规则：
--   1. 产品大类 IN ('空气调节类产品','外购产品')
--   2. 产品中类 IN ('中央空调','外购设备','空气调节类配件')
--   3. PC20006 = '标准品'（排除非标准品）
--   4. 预停签-停签：停签时间(PG00026)在当月发生的型号
--      天数 = DATEDIFF(PG00026, 飞书.plan_yutingqian_time)
--   5. 停签-停产：停产时间(PG00027)在当月发生的型号
--      天数 = DATEDIFF(PG00027, PG00026)
-- 参考逻辑：GP旧脚本 dwrd_rdkpi_tf_rili_gjdsj_detail.sql
-- 创建时间：2026-07-13
-- ============================================================================

-- 删除当月数据（幂等）
DELETE FROM dws.dws_ipd_ipm_    _detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

-- 插入当月数据
INSERT INTO dws.dws_ipd_ipm_rili_gjdsj_detail_dd(
    dt_month                    -- 统计月份YYYYMM
    ,product_line               -- 产品线
    ,data_type                  -- 数据类型（预停签-停签/停签-停产）
    ,in_out_sale                -- 内销/外销
    ,prdct_model                -- 产品型号名称
    ,salemodel                  -- 销售型号名称
    ,salemodelcode              -- 销售型号编码
    ,marketing_department       -- 归属营销部
    ,channel                    -- 渠道（地产/公建/家装/电商）
    ,productmanager             -- 所有者/产品经理
    ,yutingqian_time            -- 预停签时间（飞书）
    ,tingqian_time              -- 实际停止下单时间（HDRP）
    ,tingchan_time              -- 实际停止生产时间（HDRP）
    ,yutingqian_tingqian_d      -- 预停签到停签天数
    ,tingqian_tingchan_d        -- 停签到停产天数
    ,main_sales_channels        -- 主销渠道（HX00339）
    ,load_dt                    -- 加载时间
)

WITH
-- ============================================================================
-- CTE1: base_model
-- 用途：筛选中央空调销售型号，获取基础信息和时间字段
-- 数据源：dim.dim_ipd_salemodel_dd LEFT JOIN dim.dim_ipd_productmodel_dd
-- 筛选：产品大类/中类 + 标准品
-- ============================================================================
base_model AS (
    SELECT
        t1.PG00068                      AS salemodelcode            -- 销售型号编码
        ,t1.PG00061                     AS salemodel                -- 销售型号名称
        ,t1.PRODUCTMODEL                AS prdct_model              -- 产品型号名称
        ,t1.PC20080                     AS marketing_department     -- 归属营销部
        ,t1.HX00327                     AS productmanager           -- 所有者/产品经理
        ,t1.HX00339                     AS main_sales_channels      -- 主销渠道
        ,t2.PG00020                     AS in_out_sale              -- 内销/外销
        ,t1.PG00026                     AS tingqian_time            -- 实际停止下单时间
        ,t1.PG00027                     AS tingchan_time            -- 实际停止生产时间
    FROM dim.dim_ipd_salemodel_dd t1
    LEFT JOIN dim.dim_ipd_productmodel_dd t2
        ON t1.PRODUCTMODEL_ID = t2.ID
    WHERE t1.PG00002 IN ('空气调节类产品', '外购产品')              -- 产品大类筛选
      AND t1.PG00003 IN ('中央空调', '外购设备', '空气调节类配件')  -- 产品中类筛选
      AND t1.PC20006 = '标准品'                                     -- 排除非标准品
),

-- ============================================================================
-- CTE2: plan_data
-- 用途：获取飞书退市滚动计划中的预停签时间（从ODS飞书表JSON解析）
-- 数据源：ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j
-- 逻辑：飞书表每日全量覆盖，直接读取，无需版本筛选
-- ============================================================================
plan_data AS (
    SELECT
        JSON_EXTRACT_STRING(record_data, '$.销售型号编码[0].text')
                                        AS salemodelcode            -- 销售型号编码（关联键）
        ,JSON_EXTRACT_STRING(record_data, '$.营销部[0].text')
                                        AS marketing_department     -- 归属营销部（飞书）
        ,JSON_EXTRACT_STRING(record_data, '$.主要销售渠道[0].text')
                                        AS channel                  -- 渠道（飞书）
        ,FROM_UNIXTIME(CAST(JSON_EXTRACT_STRING(record_data, '$.预停签时间') AS BIGINT) / 1000)
                                        AS plan_yutingqian_time     -- 预停签时间
    FROM ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j
    WHERE JSON_EXTRACT_STRING(record_data, '$.销售型号编码[0].text') IS NOT NULL
),

-- ============================================================================
-- CTE3: detail_unpivot
-- 用途：按data_type展开为2行
--   预停签-停签：停签时间(PG00026)在当月发生的型号
--     天数 = DATEDIFF(停签时间, 预停签时间)
--   停签-停产：停产时间(PG00027)在当月发生的型号
--     天数 = DATEDIFF(停产时间, 停签时间)
-- 注意：旧逻辑按"停签当月"筛选预停签-停签，按"停产当月"筛选停签-停产
-- ============================================================================
detail_unpivot AS (
    -- 预停签-停签：当月完成停签的型号
    SELECT
        '预停签-停签'                   AS data_type               -- 数据类型
        ,bm.in_out_sale                                            -- 内销/外销
        ,bm.prdct_model                                            -- 产品型号名称
        ,bm.salemodel                                              -- 销售型号名称
        ,bm.salemodelcode                                          -- 销售型号编码
        ,pd.marketing_department                                   -- 归属营销部（飞书）
        ,pd.channel                                                -- 渠道（飞书）
        ,bm.productmanager                                         -- 产品经理
        ,pd.plan_yutingqian_time        AS yutingqian_time         -- 预停签时间（飞书）
        ,bm.tingqian_time                                          -- 实际停签时间
        ,bm.tingchan_time                                          -- 实际停产时间
        -- 预停签到停签天数
        ,DATEDIFF(bm.tingqian_time, pd.plan_yutingqian_time)
                                        AS yutingqian_tingqian_d   -- 预停签→停签天数
        -- 停签到停产天数（此data_type下可能为NULL，保留供参考）
        ,DATEDIFF(bm.tingchan_time, bm.tingqian_time)
                                        AS tingqian_tingchan_d     -- 停签→停产天数
        ,bm.main_sales_channels                                    -- 主销渠道
    FROM base_model bm
    LEFT JOIN plan_data pd
        ON bm.salemodelcode = pd.salemodelcode
    -- 筛选：停签时间在当月发生 且 飞书预停签时间不为空
    WHERE DATE_FORMAT(bm.tingqian_time, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
      AND pd.plan_yutingqian_time IS NOT NULL

    UNION ALL

    -- 停签-停产：当月完成停产的型号
    SELECT
        '停签-停产'                     AS data_type               -- 数据类型
        ,bm.in_out_sale                                            -- 内销/外销
        ,bm.prdct_model                                            -- 产品型号名称
        ,bm.salemodel                                              -- 销售型号名称
        ,bm.salemodelcode                                          -- 销售型号编码
        ,pd.marketing_department                                   -- 归属营销部（飞书）
        ,pd.channel                                                -- 渠道（飞书）
        ,bm.productmanager                                         -- 产品经理
        ,pd.plan_yutingqian_time        AS yutingqian_time         -- 预停签时间（飞书）
        ,bm.tingqian_time                                          -- 实际停签时间
        ,bm.tingchan_time                                          -- 实际停产时间
        -- 预停签到停签天数（此data_type下保留供参考）
        ,DATEDIFF(bm.tingqian_time, pd.plan_yutingqian_time)
                                        AS yutingqian_tingqian_d   -- 预停签→停签天数
        -- 停签到停产天数
        ,DATEDIFF(bm.tingchan_time, bm.tingqian_time)
                                        AS tingqian_tingchan_d     -- 停签→停产天数
        ,bm.main_sales_channels                                    -- 主销渠道
    FROM base_model bm
    LEFT JOIN plan_data pd
        ON bm.salemodelcode = pd.salemodelcode
    -- 筛选：停产时间在当月发生
    WHERE DATE_FORMAT(bm.tingchan_time, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
)

-- ============================================================================
-- 最终输出
-- ============================================================================
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month            -- 统计月份
    ,'中央空调'                              AS product_line        -- 产品线（固定值）
    ,data_type                                                     -- 数据类型
    ,in_out_sale                                                   -- 内销/外销
    ,prdct_model                                                   -- 产品型号名称
    ,salemodel                                                     -- 销售型号名称
    ,salemodelcode                                                 -- 销售型号编码
    ,marketing_department                                          -- 归属营销部
    ,channel                                                       -- 渠道
    ,productmanager                                                -- 产品经理
    ,yutingqian_time                                               -- 预停签时间
    ,tingqian_time                                                 -- 实际停签时间
    ,tingchan_time                                                 -- 实际停产时间
    ,yutingqian_tingqian_d                                         -- 预停签→停签天数
    ,tingqian_tingchan_d                                           -- 停签→停产天数
    ,main_sales_channels                                           -- 主销渠道
    ,NOW()                                  AS load_dt             -- 加载时间
FROM detail_unpivot
;
