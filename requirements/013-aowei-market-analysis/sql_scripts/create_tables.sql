-- ============================================================
-- 需求：013-aowei-market-analysis 奥维中间表（行业市场分析）
-- 类型：DDL建表（2张dim表 + 7张ads目标表）
-- 创建日期：2026-07-08
-- 表结构设计：指标行格式（每行=一个维度组合+一个指标，5个年度值列）
-- ============================================================

-- ============================================================
-- 一、维度表
-- ============================================================

-- 1. 价格段维度表
DROP TABLE IF EXISTS dim.dim_ipd_ipm_aw_price_segment_dd;
CREATE TABLE dim.dim_ipd_ipm_aw_price_segment_dd (
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    price_segment       VARCHAR(50)        COMMENT '价格段名称',
    min_price           DECIMALV3(20,4)    COMMENT '最低均价（含）',
    max_price           DECIMALV3(20,4)    COMMENT '最高均价（不含，最高段为含）',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维价格段维度表'
DISTRIBUTED BY HASH(prdct_line_name) BUCKETS 1
PROPERTIES ("replication_num" = "3");

-- 2. 规格段维度表
DROP TABLE IF EXISTS dim.dim_ipd_ipm_aw_spec_segment_dd;
CREATE TABLE dim.dim_ipd_ipm_aw_spec_segment_dd (
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    spec_segment        VARCHAR(50)        COMMENT '规格段名称',
    min_spec            DECIMALV3(20,4)    COMMENT '规格下限（空调为NULL）',
    max_spec            DECIMALV3(20,4)    COMMENT '规格上限（空调为NULL）',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维规格段维度表'
DISTRIBUTED BY HASH(prdct_line_name) BUCKETS 1
PROPERTIES ("replication_num" = "3");

-- ============================================================
-- 二、ADS目标表（指标行格式）
-- ============================================================
-- metric_name 取值：总销额、总销量、产品均价、额占有率、量占有率
-- 表2-1额外有：销额、销量、产品均价、所属价格段、所属规格段
-- val_y3~val_y1_ytd 为5个年度的指标值

-- 表1-1：行业分渠道数据（全市场）
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_industry_channel_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_industry_channel_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    channel_type_agg    VARCHAR(10)        COMMENT '统计渠道（总体/线上/线下）',
    metric_name         VARCHAR(50)        COMMENT '指标名称',
    val_y3              VARCHAR(50)        COMMENT '3年前值',
    val_y2              VARCHAR(50)        COMMENT '2年前值',
    val_y1              VARCHAR(50)        COMMENT '1年前值',
    val_curr            VARCHAR(50)        COMMENT '当年T值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维行业分渠道数据（全市场，指标行格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表1-2：分渠道分品牌数据
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_channel_brand_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_channel_brand_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下',
    stat_brand          VARCHAR(300)       COMMENT '统计品牌',
    metric_name         VARCHAR(50)        COMMENT '指标名称',
    val_y3              VARCHAR(50)        COMMENT '3年前值',
    val_y2              VARCHAR(50)        COMMENT '2年前值',
    val_y1              VARCHAR(50)        COMMENT '1年前值',
    val_curr            VARCHAR(50)        COMMENT '当年T值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维分渠道分品牌数据（指标行格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表2-1：各型号均价及价格段（筛选品牌）
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_model_price_spec_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_model_price_spec_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下',
    stat_brand          VARCHAR(300)       COMMENT '统计品牌',
    prdct_model         VARCHAR(100)       COMMENT '型号名称',
    metric_name         VARCHAR(50)        COMMENT '指标名称（销额/销量/产品均价/所属价格段/所属规格段）',
    val_y3              VARCHAR(50)        COMMENT '3年前值',
    val_y2              VARCHAR(50)        COMMENT '2年前值',
    val_y1              VARCHAR(50)        COMMENT '1年前值',
    val_curr            VARCHAR(50)        COMMENT '当年T值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维各型号均价及价格段（筛选品牌，指标行格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表2-2：分价格段数据（全市场）
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_price_segment_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_price_segment_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下',
    price_segment       VARCHAR(50)        COMMENT '价格段',
    metric_name         VARCHAR(50)        COMMENT '指标名称',
    val_y3              VARCHAR(50)        COMMENT '3年前值',
    val_y2              VARCHAR(50)        COMMENT '2年前值',
    val_y1              VARCHAR(50)        COMMENT '1年前值',
    val_curr            VARCHAR(50)        COMMENT '当年T值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维分价格段数据（全市场，指标行格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表2-3：分价格段分品牌数据
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_price_brand_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_price_brand_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下',
    price_segment       VARCHAR(50)        COMMENT '价格段',
    stat_brand          VARCHAR(300)       COMMENT '统计品牌',
    metric_name         VARCHAR(50)        COMMENT '指标名称',
    val_y3              VARCHAR(50)        COMMENT '3年前值',
    val_y2              VARCHAR(50)        COMMENT '2年前值',
    val_y1              VARCHAR(50)        COMMENT '1年前值',
    val_curr            VARCHAR(50)        COMMENT '当年T值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维分价格段分品牌数据（指标行格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表2-4：分价格段分规格段数据（全市场）
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_price_spec_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_price_spec_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下',
    price_segment       VARCHAR(50)        COMMENT '价格段',
    spec_segment        VARCHAR(50)        COMMENT '规格段',
    metric_name         VARCHAR(50)        COMMENT '指标名称',
    val_y3              VARCHAR(50)        COMMENT '3年前值',
    val_y2              VARCHAR(50)        COMMENT '2年前值',
    val_y1              VARCHAR(50)        COMMENT '1年前值',
    val_curr            VARCHAR(50)        COMMENT '当年T值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维分价格段分规格段数据（全市场，指标行格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表2-5：分价格段分规格段分品牌数据
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_price_spec_brand_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_price_spec_brand_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下',
    price_segment       VARCHAR(50)        COMMENT '价格段',
    spec_segment        VARCHAR(50)        COMMENT '规格段',
    stat_brand          VARCHAR(300)       COMMENT '统计品牌',
    metric_name         VARCHAR(50)        COMMENT '指标名称',
    val_y3              VARCHAR(50)        COMMENT '3年前值',
    val_y2              VARCHAR(50)        COMMENT '2年前值',
    val_y1              VARCHAR(50)        COMMENT '1年前值',
    val_curr            VARCHAR(50)        COMMENT '当年T值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维分价格段分规格段分品牌数据（指标行格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- ============================================================
-- 三、扩增3张中间表（2026-07-21 龚英需求扩增）
-- ============================================================
-- 单元格拼接格式：val字段存 "额占有率%，产品均价"
-- 无 metric_name 字段，每维度组合只对应1行数据
-- 分隔符：中文全角逗号 "，"（U+FF0C）
-- 空值统一：val 字段=`—，—`（禁止半空态）

-- 表A：行业总体分析（含"总体/线上/线下"渠道虚拟维度 + 筛选品牌）
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_industry_brand_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_industry_brand_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    channel_type_agg    VARCHAR(10)        COMMENT '统计渠道（总体/线上/线下）',
    stat_brand          VARCHAR(300)       COMMENT '统计品牌（含小天鹅/三星；不含总体品牌行）',
    val_y3              VARCHAR(50)        COMMENT '3年前【额占有率，产品均价】拼接值',
    val_y2              VARCHAR(50)        COMMENT '2年前【额占有率，产品均价】拼接值',
    val_y1              VARCHAR(50)        COMMENT '1年前【额占有率，产品均价】拼接值',
    val_curr            VARCHAR(50)        COMMENT '当年T【额占有率，产品均价】拼接值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期【额占有率，产品均价】拼接值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维行业总体分析（单元格拼接格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表B：分价格段分品牌市场分析-线上（含"总体"品牌行 + 筛选品牌）
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_price_spec_brand_online_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_price_spec_brand_online_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下（固定=线上）',
    price_segment       VARCHAR(50)        COMMENT '价格段',
    spec_segment        VARCHAR(50)        COMMENT '规格段',
    stat_brand          VARCHAR(300)       COMMENT '统计品牌（总体/海信系列/海尔系列/…）',
    val_y3              VARCHAR(50)        COMMENT '3年前【额占有率，产品均价】拼接值',
    val_y2              VARCHAR(50)        COMMENT '2年前【额占有率，产品均价】拼接值',
    val_y1              VARCHAR(50)        COMMENT '1年前【额占有率，产品均价】拼接值',
    val_curr            VARCHAR(50)        COMMENT '当年T【额占有率，产品均价】拼接值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期【额占有率，产品均价】拼接值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维分价格段分品牌-线上（单元格拼接格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");

-- 表C：分价格段分品牌市场分析-线下（结构同表B，仅渠道不同）
DROP TABLE IF EXISTS ads.ads_ipd_ipm_aowei_price_spec_brand_offline_dd;
CREATE TABLE ads.ads_ipd_ipm_aowei_price_spec_brand_offline_dd (
    business_unit       VARCHAR(300)       COMMENT '事业部',
    prdct_line_name     VARCHAR(80)        COMMENT '品线名称',
    product_mid_class   VARCHAR(300)       COMMENT '产品中类',
    product_small_class VARCHAR(300)       COMMENT '产品小类',
    category_segment    VARCHAR(300)       COMMENT '品类细分',
    o2o_type            VARCHAR(10)        COMMENT '线上线下（固定=线下）',
    price_segment       VARCHAR(50)        COMMENT '价格段',
    spec_segment        VARCHAR(50)        COMMENT '规格段',
    stat_brand          VARCHAR(300)       COMMENT '统计品牌（总体/海信系列/海尔系列/…）',
    val_y3              VARCHAR(50)        COMMENT '3年前【额占有率，产品均价】拼接值',
    val_y2              VARCHAR(50)        COMMENT '2年前【额占有率，产品均价】拼接值',
    val_y1              VARCHAR(50)        COMMENT '1年前【额占有率，产品均价】拼接值',
    val_curr            VARCHAR(50)        COMMENT '当年T【额占有率，产品均价】拼接值',
    val_y1_ytd          VARCHAR(50)        COMMENT '去年同期【额占有率，产品均价】拼接值',
    load_dt             DATETIMEV2(0)      COMMENT 'ETL加载日期'
) COMMENT '奥维分价格段分品牌-线下（单元格拼接格式）'
DISTRIBUTED BY HASH(business_unit) BUCKETS 3
PROPERTIES ("replication_num" = "3");
