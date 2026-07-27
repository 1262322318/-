-- ============================================================
-- 目标表刷新脚本：奥维数据加工宽表
-- 创建日期：2026-07-01
-- 更新日期：2026-07-02
-- 目标表：ads.ads_ipd_ipm_aowei_wd
-- 源表：dwd.dwd_mrs_mr_avcdtl_wd
-- 映射表：test.dim_ipd_ipm_awproduct_dd（三级映射）
-- 更新策略：全量刷新
-- 映射逻辑：三级覆盖（一级全量填充→二级增量覆盖→三级增量覆盖）
-- ============================================================

-- 全量删除
DELETE FROM ads.ads_ipd_ipm_aowei_wd;

-- 全量插入
INSERT INTO ads.ads_ipd_ipm_aowei_wd
(
    business_unit,        -- 事业部
    product_big_class,    -- 产品大类
    product_mid_class,    -- 产品中类
    product_small_class,  -- 产品小类
    category_segment,     -- 品类细分
    dt_wmcode,            -- 日期
    o2o_type,             -- 线上线下
    wm_type,              -- 数据维度（周/月）
    prdct_line_name,      -- 品线名称
    markt_center,         -- 营销中心
    province,             -- 省份
    city_name,            -- 城市名称
    city_level,           -- 城市级别
    hisense_city_level,   -- 海信城市级别
    channel_type,         -- 渠道类型
    top,                  -- TOP客户(奥维定义)
    hisense_agency,       -- 海信办事处
    if_top,               -- 是否海信定义TOP客户
    sale_qty,             -- 销量
    sale_amt,             -- 销额
    prdct_model,          -- 型号名称
    brand_series,         -- 品牌系列
    brand_name,           -- 品牌名称
    sub_brand_name,       -- 子品牌名称
    core_spec,            -- 核心规格
    prdct_cate_dtl,       -- 产品属性
    energy_level,         -- 能效等级
    freq,                 -- 变频定频
    if_laser,             -- 是否激光（电视）
    online_week,          -- 上市周
    online_month,         -- 上市月
    door_diverse,         -- 门体分类
    if_fresh_ac,          -- 是否新风空调
    washing_type,         -- 洗涤类型
    tec_type1,            -- 屏幕类型
    product_4_segment     -- 四分法档次
)
SELECT
    -- 三级覆盖逻辑：优先三级 > 二级 > 一级
    COALESCE(m3.business_unit, m2.business_unit, m1.business_unit)              事业部,
    COALESCE(m3.product_big_class, m2.product_big_class, m1.product_big_class)  产品大类,
    COALESCE(m3.product_mid_class, m2.product_mid_class, m1.product_mid_class)  产品中类,
    COALESCE(m3.product_small_class, m2.product_small_class)                    产品小类,
    m2.category_segment                                                         品类细分,
    t.dt_wmcode                  日期,
    CASE
        WHEN t.o2o_type = 'XX' THEN '线下'
        WHEN t.o2o_type = 'XS' THEN '线上'
        ELSE t.o2o_type
    END AS o2o_type              线上线下,
    CASE
        WHEN t.wm_type = 'M' THEN '月'
        WHEN t.wm_type = 'W' THEN '周'
        ELSE t.wm_type
    END AS wm_type               数据维度,
    t.prdct_line_name            品线名称,
    t.markt_center               营销中心,
    t.province                   省份,
    t.city_name                  城市名称,
    t.city_level                 城市级别,
    t.hisense_city_level         海信城市级别,
    t.channel_type               渠道类型,
    t.top                        TOP客户,
    t.hisense_agency             海信办事处,
    t.if_top                     是否海信定义TOP客户,
    t.sale_qty                   销量,
    t.sale_amt                   销额,
    t.prdct_model                型号名称,
    CASE
        WHEN t.sub_brand_name LIKE '%海信%' THEN '海信系列'
        WHEN t.sub_brand_name LIKE '%海尔%' THEN '海尔系列'
        WHEN t.sub_brand_name LIKE '%美的%' THEN '美的系列'
        WHEN t.sub_brand_name LIKE '%TCL%' THEN 'TCL系列'
        WHEN t.sub_brand_name LIKE '%小米%' THEN '小米系列'
        WHEN t.sub_brand_name LIKE '%创维%' THEN '创维系列'
        WHEN t.sub_brand_name LIKE '%容声%' THEN '海信系列'
        WHEN t.sub_brand_name LIKE '%科龙%' THEN '海信系列'
        WHEN t.sub_brand_name LIKE '%vidda%' THEN '海信系列'
        ELSE '其他'
    END AS brand_series          品牌系列,
    t.brand_name                 品牌名称,
    t.sub_brand_name             子品牌名称,
    CASE
        WHEN COALESCE(m3.product_mid_class, m2.product_mid_class, m1.product_mid_class) = '家用空调' THEN t.match_size
        ELSE CAST(t.spec_size AS varchar(300))
    END AS core_spec             核心规格,
    t.prdct_cate_dtl             产品属性,
    t.energy_level               能效等级,
    t.freq                       变频定频,
    t.if_laser                   是否激光,
    t.online_week                上市周,
    t.online_month               上市月,
    t.door_diverse               门体分类,
    t.if_fresh_ac                是否新风空调,
    t.washing_type               洗涤类型,
    t.tec_type1                  屏幕类型,
    CASE
        WHEN t.product_4_segment_headquarters = 'H' THEN '高端'
        WHEN t.product_4_segment_headquarters = 'HM' THEN '中高端'
        WHEN t.product_4_segment_headquarters = 'ML' THEN '中低端'
        WHEN t.product_4_segment_headquarters = 'L' THEN '低端'
        ELSE t.product_4_segment_headquarters
    END AS product_4_segment     四分法档次
FROM dwd.dwd_mrs_mr_avcdtl_wd t
-- 一级映射：按品线名称
LEFT JOIN test.dim_ipd_ipm_awproduct_dd m1
    ON m1.map_level = 1
    AND t.prdct_line_name = m1.prdct_line_name
-- 二级映射：按品线名称+产品属性
LEFT JOIN test.dim_ipd_ipm_awproduct_dd m2
    ON m2.map_level = 2
    AND t.prdct_line_name = m2.prdct_line_name
    AND t.prdct_cate = m2.prdct_cate
-- 三级映射：按品线名称+产品属性+产品属性细分
LEFT JOIN test.dim_ipd_ipm_awproduct_dd m3
    ON m3.map_level = 3
    AND t.prdct_line_name = m3.prdct_line_name
    AND t.prdct_cate = m3.prdct_cate
    AND t.prdct_cate_dtl = m3.prdct_cate_dtl;
