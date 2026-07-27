-- ============================================================
-- 建表脚本：奥维数据加工
-- 创建日期：2026-07-01
-- 说明：创建映射表 dim.dim_ipd_ipm_awproduct_dd
--       创建目标表 ads.ads_ipd_ipm_aowei_wd
-- ============================================================

-- 1. 映射表：奥维品线→产品维度映射（三级映射）
CREATE TABLE IF NOT EXISTS dim.dim_ipd_ipm_awproduct_dd
(
    map_level           int           COMMENT '映射级别（1=品线/2=品线+属性/3=品线+属性+属性细分）',
    prdct_line_name     varchar(80)   COMMENT '品线名称',
    prdct_cate          varchar(100)  COMMENT '产品属性',
    prdct_cate_dtl      varchar(100)  COMMENT '产品属性细分',
    business_unit       varchar(300)  COMMENT '事业部',
    product_big_class   varchar(300)  COMMENT '产品大类',
    product_mid_class   varchar(300)  COMMENT '产品中类',
    product_small_class varchar(300)  COMMENT '产品小类',
    category_segment    varchar(300)  COMMENT '品类细分'
)
DISTRIBUTED BY HASH(prdct_line_name) BUCKETS 1
PROPERTIES("replication_num" = "3", "storage_medium" = "HDD");

-- 2. 目标表：奥维数据加工宽表
CREATE TABLE IF NOT EXISTS ads.ads_ipd_ipm_aowei_wd
(
    business_unit       varchar(300)        COMMENT '事业部',
    product_big_class   varchar(300)        COMMENT '产品大类',
    product_mid_class   varchar(300)        COMMENT '产品中类',
    product_small_class varchar(300)        COMMENT '产品小类',
    category_segment    varchar(300)        COMMENT '品类细分',
    dt_wmcode           varchar(6)          COMMENT '日期',
    o2o_type            varchar(2)          COMMENT '线上线下',
    wm_type             varchar(2)          COMMENT '数据维度（周/月）',
    prdct_line_name     varchar(80)         COMMENT '品线名称',
    markt_center        varchar(200)        COMMENT '营销中心',
    province            varchar(200)        COMMENT '省份',
    city_name           varchar(300)        COMMENT '城市名称',
    city_level          varchar(80)         COMMENT '城市级别',
    hisense_city_level  varchar(80)         COMMENT '海信城市级别',
    channel_type        varchar(80)         COMMENT '渠道类型',
    top                 varchar(10)         COMMENT 'TOP客户(奥维定义)',
    hisense_agency      varchar(200)        COMMENT '海信办事处',
    if_top              varchar(20)         COMMENT '是否海信定义TOP客户',
    sale_qty            decimalv3(20, 4)    COMMENT '销量',
    sale_amt            decimalv3(20, 4)    COMMENT '销额',
    prdct_model         varchar(100)        COMMENT '型号名称',
    brand_series        varchar(300)        COMMENT '品牌系列',
    brand_name          varchar(100)        COMMENT '品牌名称',
    sub_brand_name      varchar(100)        COMMENT '子品牌名称',
    core_spec           varchar(300)        COMMENT '核心规格',
    prdct_cate_dtl      varchar(100)        COMMENT '产品属性',
    energy_level        varchar(100)        COMMENT '能效等级',
    freq                varchar(100)        COMMENT '变频定频',
    if_laser            varchar(100)        COMMENT '是否激光（电视）',
    online_week         varchar(20)         COMMENT '上市周',
    online_month        varchar(20)         COMMENT '上市月',
    door_diverse        varchar(100)        COMMENT '门体分类',
    if_fresh_ac         varchar(10)         COMMENT '是否新风空调',
    washing_type        varchar(50)         COMMENT '洗涤类型',
    tec_type1           varchar(50)         COMMENT '屏幕类型',
    product_4_segment   varchar(50)         COMMENT '四分法档次'
)
PARTITION BY RANGE(dt_wmcode) ()
DISTRIBUTED BY HASH(markt_center, prdct_line_name) BUCKETS 3
PROPERTIES("replication_num" = "3", "storage_medium" = "HDD",
           "dynamic_partition.enable" = "true",
           "dynamic_partition.time_unit" = "WEEK",
           "dynamic_partition.start" = "-200",
           "dynamic_partition.end" = "4",
           "dynamic_partition.prefix" = "p");
