-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: create_tables.sql
-- 功能描述: 企划命中率（央空内销/日立）目标表DDL
--           包含DWS明细表和ADS结果表的建表语句
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-04-24
-- ******************************************************************** --


-- ====================================================================
-- DWS层：企划命中率明细表
-- 说明：同时存储型号口径（基础数据）和项目口径（阶段判定）两种数据
--       通过 data_type 字段区分
-- ====================================================================
CREATE TABLE IF NOT EXISTS dws.dws_ipd_ipm_qihua_hit_detail_dd (
    dt_month              VARCHAR(6)       COMMENT '统计月份（YYYYMM格式）'
    ,data_type            VARCHAR(20)      COMMENT '数据类型（型号口径/项目口径）'
    ,salemodel_code       VARCHAR(300)     COMMENT '销售型号编码（型号口径使用）'
    ,salemodel_name       VARCHAR(300)     COMMENT '销售型号名称（型号口径使用）'
    ,project_code         VARCHAR(300)     COMMENT '项目编码'
    ,project_name         VARCHAR(300)     COMMENT '项目名称'
    ,sku_count            INT              COMMENT '项目下SKU数量（项目口径使用）'
    ,pc20080              VARCHAR(1000)    COMMENT '归属营销部（项目口径为去重合并文本）'
    ,product_big          VARCHAR(200)     COMMENT '产品大类（型号口径使用）'
    ,product_mid          VARCHAR(200)     COMMENT '产品中类（型号口径使用）'
    ,product_sml          VARCHAR(200)     COMMENT '产品小类（型号口径使用）'
    ,sale_brand           VARCHAR(200)     COMMENT '销售品牌（型号口径使用）'
    ,listing_date         DATETIMEV2(0)    COMMENT '上市时间（型号口径=SKU上市时间，项目口径=项目最早上市时间）'
    ,stop_production_date DATETIMEV2(0)    COMMENT '停产时间（PG00027，项目口径=所有SKU都停产才有值）'
    ,shangshi_month       INT              COMMENT '上市月份数'
    ,cum_sales_qty        DECIMALV3(20,4)  COMMENT '累计销量'
    ,max_rolling_12m_qty  DECIMALV3(20,4)  COMMENT '累计连续12个月最大销量（项目口径使用）'
    ,plan_first_year_qty  DECIMALV3(20,4)  COMMENT '首年规划量（HX00020）'
    ,sales_progress       DECIMALV3(10,4)  COMMENT '销量进度（项目口径使用）'
    ,time_progress        DECIMALV3(10,4)  COMMENT '时间进度（项目口径使用）'
    ,stage                INT              COMMENT '阶段（1-6，项目口径使用）'
    ,stage_label          VARCHAR(50)      COMMENT '阶段标签（项目口径使用）'
    ,is_hit               VARCHAR(2)       COMMENT '是否达标（Y/N，项目口径使用）'
    ,hit_type             VARCHAR(50)      COMMENT '达标类型（项目口径使用）'
    ,is_stopped           VARCHAR(2)       COMMENT '是否停产（Y/N）'
    ,load_dt              DATETIMEV2(0)    COMMENT '加载时间'
)
COMMENT '企划命中率明细表（央空内销/日立）- DWS层'
PARTITION BY RANGE(dt_month) ()
DISTRIBUTED BY HASH(dt_month) BUCKETS 4
PROPERTIES (
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "MONTH",
    "dynamic_partition.start" = "-24",
    "dynamic_partition.end" = "3",
    "dynamic_partition.prefix" = "p",
    "dynamic_partition.buckets" = "4",
    "replication_num" = "3"
);


-- ====================================================================
-- ADS层：企划命中率结果表
-- 说明：按归属营销部+阶段维度汇总不达标项目数/SKU数/达标率
--       stage=1~6为各阶段明细，stage=99为不达标合计行
-- ====================================================================
CREATE TABLE IF NOT EXISTS ads.ads_ipd_ipm_qihua_hit_result_dd (
    dt_month              VARCHAR(6)       COMMENT '统计月份（YYYYMM格式）'
    ,pc20080              VARCHAR(1000)    COMMENT '归属营销部'
    ,stage                INT              COMMENT '阶段（1-6为各阶段，99为不达标合计）'
    ,stage_label          VARCHAR(50)      COMMENT '阶段标签（stage=99时为"不达标合计"）'
    ,hit_type             VARCHAR(50)      COMMENT '达标类型（stage=99时为"合计"）'
    ,total_project_cnt    INT              COMMENT '该阶段/营销部总项目数'
    ,total_sku_cnt        INT              COMMENT '该阶段/营销部总SKU数'
    ,fail_project_cnt     INT              COMMENT '不达标项目数'
    ,fail_sku_cnt         INT              COMMENT '不达标SKU数'
    ,hit_rate             DECIMALV3(10,4)  COMMENT '达标率（1 - 不达标项目数/总项目数）'
    ,load_dt              DATETIMEV2(0)    COMMENT '加载时间'
)
COMMENT '企划命中率结果表（央空内销/日立）- ADS层，用于红黑榜展示'
PARTITION BY RANGE(dt_month) ()
DISTRIBUTED BY HASH(dt_month) BUCKETS 4
PROPERTIES (
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "MONTH",
    "dynamic_partition.start" = "-24",
    "dynamic_partition.end" = "3",
    "dynamic_partition.prefix" = "p",
    "dynamic_partition.buckets" = "4",
    "replication_num" = "3"
);
