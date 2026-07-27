-- ============================================================================
-- 脚本名称：dws_ipd_ipm_rili_ajhwcl_detail_dd.sql
-- 功能描述：退市按计划执行率 - DWS明细层
-- 目标表：dws.dws_ipd_ipm_rili_ajhwcl_detail_dd
-- 数据源：
--   dim.dim_ipd_salemodel_dd（销售型号基础信息，含停签/停产/上市/规划上市时间）
--   dim.dim_ipd_productmodel_dd（产品型号，取内外销属性）
--   ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j（飞书退市滚动计划-JSON解析，含营销部/渠道/计划时间）
-- 产品线：海信日立（中央空调）
-- 粒度：一个销售型号 × 一个data_type（停签/停产/上市）
-- 更新策略：DELETE当月 + INSERT
-- 调度参数：${GP_START_DT}（脚本执行日期前一天，yyyymmdd）
-- 业务规则：
--   1. 产品大类 IN ('空气调节类产品','外购产品')
--   2. 产品中类 IN ('中央空调','外购设备','空气调节类配件')
--   3. PC20006 = '标准品'（排除非标准品）
--   4. is_aqwc判定：act_time IS NOT NULL AND plan_time IS NOT NULL
--      AND act_time <= plan_time → 'Y'，否则 → 'N'
--   5. 停产的plan_time不来自飞书，而是：实际停签时间 + 渠道周期
--      渠道周期：家装/电商/全渠道=1月，公建/中小=24月，
--               地产/连锁=12月，Commercial/Residential/JCH=6月
-- 创建时间：2026-07-13

-- ============================================================================

-- 删除当月数据（幂等）
DELETE FROM dws.dws_ipd_ipm_rili_ajhwcl_detail_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

-- 插入当月数据
INSERT INTO dws.dws_ipd_ipm_rili_ajhwcl_detail_dd(
    dt_month                    -- 统计月份YYYYMM
    ,product_line               -- 产品线
    ,data_type                  -- 数据类型（停签/停产/上市）
    ,in_out_sale                -- 内销/外销
    ,prdct_model                -- 产品型号名称
    ,salemodel                  -- 销售型号名称
    ,salemodelcode              -- 销售型号编码
    ,marketing_department       -- 归属营销部
    ,channel                    -- 渠道（地产/公建/家装/电商）
    ,productmanager             -- 所有者/产品经理
    ,plan_time                  -- 计划时间（飞书滚动计划）
    ,act_time                   -- 实际时间（HDRP）
    ,is_aqwc                    -- 是否按时完成（Y/N）
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
        ,t2.PG00020                     AS in_out_sale              -- 内销/外销
        ,t1.HX00339                     AS main_sales_channels      -- 主销渠道
        ,t1.PG00023                     AS plan_shangshi_time       -- 规划上市时间
        ,t1.PG00025                     AS act_shangshi_time        -- 实际上市时间
        ,t1.PG00026                     AS act_tingqian_time        -- 实际停止下单时间
        ,t1.PG00027                     AS act_tingchan_time        -- 实际停止生产时间
    FROM dim.dim_ipd_salemodel_dd t1
    LEFT JOIN dim.dim_ipd_productmodel_dd t2
        ON t1.PRODUCTMODEL_ID = t2.ID
    WHERE t1.PG00002 IN ('空气调节类产品', '外购产品')              -- 产品大类筛选
      AND t1.PG00003 IN ('中央空调', '外购设备', '空气调节类配件')  -- 产品中类筛选
      AND t1.PC20006 = '标准品'                                     -- 排除非标准品
),

-- ============================================================================
-- CTE2: plan_data
-- 用途：获取飞书退市滚动计划中的计划时间（从ODS飞书表JSON解析）
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
        ,FROM_UNIXTIME(CAST(JSON_EXTRACT_STRING(record_data, '$.规划停止下单时间') AS BIGINT) / 1000)
                                        AS plan_tingqian_time       -- 规划停止下单时间
        ,FROM_UNIXTIME(CAST(JSON_EXTRACT_STRING(record_data, '$.规划停止生产时间') AS BIGINT) / 1000)
                                        AS plan_tingchan_time       -- 规划停止生产时间
    FROM ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j
    WHERE JSON_EXTRACT_STRING(record_data, '$.销售型号编码[0].text') IS NOT NULL
),

-- ============================================================================
-- CTE4: detail_unpivot
-- 用途：按data_type展开为3行（停签/停产/上市）
-- 逻辑：每个销售型号生成3条记录，分别对应3种退市节点
--   停签：飞书plan_tingqian_time vs act_tingqian_time（PG00026）
--   停产：实际停签时间+渠道周期 vs act_tingchan_time（PG00027）
--   上市：飞书plan_shangshi_time vs act_shangshi_time（PG00025）
-- ============================================================================
detail_unpivot AS (
    -- 停签：计划停止下单时间 vs 实际停止下单时间
    SELECT
        '停签'                          AS data_type               -- 数据类型
        ,bm.in_out_sale                                            -- 内销/外销
        ,bm.prdct_model                                            -- 产品型号名称
        ,bm.salemodel                                              -- 销售型号名称
        ,bm.salemodelcode                                          -- 销售型号编码
        ,pd.marketing_department                                   -- 归属营销部（飞书）
        ,pd.channel                                                -- 渠道（飞书）
        ,bm.productmanager                                         -- 产品经理
        ,pd.plan_tingqian_time          AS plan_time               -- 计划停签时间
        ,bm.act_tingqian_time           AS act_time                -- 实际停签时间
    FROM base_model bm
    LEFT JOIN plan_data pd
        ON bm.salemodelcode = pd.salemodelcode
    -- 筛选：计划时间不为空 且 计划时间在当年
    WHERE pd.plan_tingqian_time IS NOT NULL
      AND YEAR(pd.plan_tingqian_time) = YEAR('${GP_START_DT}')

    UNION ALL

    -- 停产：计划停产时间（实际停签+渠道周期） vs 实际停止生产时间
    SELECT
        '停产'                          AS data_type               -- 数据类型
        ,bm.in_out_sale                                            -- 内销/外销
        ,bm.prdct_model                                            -- 产品型号名称
        ,bm.salemodel                                              -- 销售型号名称
        ,bm.salemodelcode                                          -- 销售型号编码
        ,pd.marketing_department                                   -- 归属营销部（飞书）
        ,pd.channel                                                -- 渠道（飞书）
        ,bm.productmanager                                         -- 产品经理
        -- 计划停产时间 = 实际停签时间 + 渠道周期
        ,CASE
            WHEN bm.act_tingqian_time IS NULL THEN NULL
            WHEN bm.main_sales_channels IN ('家装','电商','全渠道')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 1 MONTH)
            WHEN bm.main_sales_channels IN ('公建','中小')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 24 MONTH)
            WHEN bm.main_sales_channels IN ('地产','连锁')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 12 MONTH)
            WHEN bm.main_sales_channels IN ('Commercial','Residential','JCH')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 6 MONTH)
            ELSE NULL
         END                            AS plan_time               -- 计划停产时间
        ,bm.act_tingchan_time           AS act_time                -- 实际停产时间
    FROM base_model bm
    LEFT JOIN plan_data pd
        ON bm.salemodelcode = pd.salemodelcode
    -- 筛选：停签时间不为空 且 渠道匹配得上 且 计算出的计划停产时间在当年
    WHERE bm.act_tingqian_time IS NOT NULL
      AND bm.main_sales_channels IN ('家装','电商','全渠道','公建','中小','地产','连锁','Commercial','Residential','JCH')
      AND YEAR(CASE
            WHEN bm.main_sales_channels IN ('家装','电商','全渠道')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 1 MONTH)
            WHEN bm.main_sales_channels IN ('公建','中小')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 24 MONTH)
            WHEN bm.main_sales_channels IN ('地产','连锁')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 12 MONTH)
            WHEN bm.main_sales_channels IN ('Commercial','Residential','JCH')
                THEN DATE_ADD(bm.act_tingqian_time, INTERVAL 6 MONTH)
          END) = YEAR('${GP_START_DT}')

    UNION ALL

    -- 上市：规划上市时间 vs 实际上市时间
    SELECT
        '上市'                          AS data_type               -- 数据类型
        ,bm.in_out_sale                                            -- 内销/外销
        ,bm.prdct_model                                            -- 产品型号名称
        ,bm.salemodel                                              -- 销售型号名称
        ,bm.salemodelcode                                          -- 销售型号编码
        ,bm.marketing_department                                   -- 归属营销部（PC20080）
        ,pd.channel                                                -- 渠道（飞书）
        ,bm.productmanager                                         -- 产品经理
        ,bm.plan_shangshi_time          AS plan_time               -- 规划上市时间（PG00023）
        ,bm.act_shangshi_time           AS act_time                -- 实际上市时间（PG00025）
    FROM base_model bm
    LEFT JOIN plan_data pd
        ON bm.salemodelcode = pd.salemodelcode
    -- 筛选：规划上市时间不为空 且 规划上市时间在当年
    WHERE bm.plan_shangshi_time IS NOT NULL
      AND YEAR(bm.plan_shangshi_time) = YEAR('${GP_START_DT}')
)

-- ============================================================================
-- 最终输出：拼装所有字段，计算is_aqwc
-- is_aqwc判定规则：
--   实际时间不为空 AND 计划时间不为空 AND 实际时间<=计划时间 → 'Y'
--   否则 → 'N'
-- ============================================================================
SELECT
    DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month            -- 统计月份
    ,'中央空调'                              AS product_line        -- 产品线（固定值）
    ,data_type                                                     -- 数据类型（停签/停产/上市）
    ,in_out_sale                                                   -- 内销/外销
    ,prdct_model                                                   -- 产品型号名称
    ,salemodel                                                     -- 销售型号名称
    ,salemodelcode                                                 -- 销售型号编码
    ,marketing_department                                          -- 归属营销部
    ,channel                                                       -- 渠道
    ,productmanager                                                -- 产品经理
    ,plan_time                                                     -- 计划时间
    ,act_time                                                      -- 实际时间
    -- is_aqwc判定
    ,CASE WHEN act_time IS NOT NULL
               AND plan_time IS NOT NULL
               AND act_time <= plan_time
          THEN 'Y'
          ELSE 'N'
     END                                    AS is_aqwc             -- 是否按时完成
    ,NOW()                                  AS load_dt             -- 加载时间
FROM detail_unpivot
;
