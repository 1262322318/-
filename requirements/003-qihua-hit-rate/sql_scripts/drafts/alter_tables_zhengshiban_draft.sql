-- DORIS sql
-- ******************************************************************** --
-- 脚本名称: alter_tables_zhengshiban_draft.sql
-- 功能描述: 企划命中率正式版 — test库完整建表DDL（用于测试）
--           包含正式版所有新增字段的完整表结构
-- 作者: ETL智能辅助工具
-- 创建时间: 2026-06-16
-- 变更说明: 配合PRD 2026-06-16_003_央空企划命中率正式版_prd.md
-- 【状态：草稿  创建日期：2026-06-16】
-- ******************************************************************** --


-- ====================================================================
-- test库：企划命中率明细表（完整建表，含正式版所有字段）
-- ====================================================================
DROP TABLE IF EXISTS test.dws_ipd_ipm_qihua_hit_detail_dd;

CREATE TABLE test.dws_ipd_ipm_qihua_hit_detail_dd (
    dt_month              VARCHAR(6)       COMMENT '统计月份（YYYYMM格式）'
    ,data_type            VARCHAR(20)      COMMENT '数据类型（型号口径/项目口径/事业部口径）'
    ,salemodel_code       VARCHAR(300)     COMMENT '销售型号编码（型号口径使用）'
    ,salemodel_name       VARCHAR(300)     COMMENT '销售型号名称（型号口径使用）'
    ,project_code         VARCHAR(300)     COMMENT '项目编码'
    ,project_name         VARCHAR(300)     COMMENT '项目名称'
    ,sku_count            INT              COMMENT '项目下SKU数量（项目口径/事业部口径使用）'
    ,pc20080              VARCHAR(1000)    COMMENT '归属营销部（项目口径为去重合并文本，事业部口径为单个）'
    ,product_big          VARCHAR(200)     COMMENT '产品大类（型号口径使用）'
    ,product_mid          VARCHAR(200)     COMMENT '产品中类（型号口径使用）'
    ,product_sml          VARCHAR(200)     COMMENT '产品小类（型号口径使用）'
    ,sale_brand           VARCHAR(200)     COMMENT '销售品牌（型号口径使用）'
    ,listing_date         DATETIMEV2(0)    COMMENT '上市时间（型号口径=SKU上市时间，项目口径=项目最早上市时间）'
    ,stop_production_date DATETIMEV2(0)    COMMENT '停产时间（PG00027，项目口径=所有SKU都停产才有值）'
    ,stop_order_date      DATETIMEV2(0)    COMMENT '停止下单时间（PG00026，项目口径=所有SKU都停止下单才有值）'
    ,shangshi_month       INT              COMMENT '上市月份数'
    ,cum_sales_qty        DECIMALV3(20,4)  COMMENT '累计销量'
    ,recent_12m_qty      DECIMALV3(20,4)  COMMENT '近12个月销量（阶段5-7使用，型号/项目级别）'
    ,max_rolling_12m_qty  DECIMALV3(20,4)  COMMENT '累计连续12个月最大销量（项目口径/事业部口径使用）'
    ,plan_first_year_qty  DECIMALV3(20,4)  COMMENT '首年规划量（HX00020）'
    ,sales_progress       DECIMALV3(10,4)  COMMENT '销量进度（项目口径/事业部口径使用）'
    ,time_progress        DECIMALV3(10,4)  COMMENT '时间进度（项目口径/事业部口径使用）'
    ,stage                INT              COMMENT '阶段（1/2/3/41/42/43/5/6/7，项目口径/事业部口径使用）'
    ,stage_label          VARCHAR(50)      COMMENT '阶段标签（项目口径/事业部口径使用）'
    ,is_hit               VARCHAR(2)       COMMENT '是否达标（Y/N，项目口径/事业部口径使用）'
    ,hit_type             VARCHAR(50)      COMMENT '达标类型（项目口径/事业部口径使用）'
    ,is_stopped           VARCHAR(2)       COMMENT '是否停产（Y/N）'
    ,is_stop_order        VARCHAR(2)       COMMENT '是否停止下单（Y/N）'
    ,lifecycle_status     VARCHAR(200)     COMMENT '销售型号生命周期状态（PG00057，型号口径使用）'
    ,is_in_hongheibang    VARCHAR(2)       COMMENT '是否上红黑榜（Y=阶段1/2/3/41/42/43，N=阶段5/6/7）'
    ,is_kaohe             VARCHAR(2)       COMMENT '是否考核（Y=阶段41/42/43，N=其余阶段）'
    ,load_dt              DATETIMEV2(0)    COMMENT '加载时间'
)
COMMENT '企划命中率明细表（央空/日立）正式版 - test库测试用'
DISTRIBUTED BY HASH(dt_month) BUCKETS 4
PROPERTIES (
    "replication_num" = "3"
);


-- ====================================================================
-- test库：企划命中率结果表（ADS层，完整建表）
-- ====================================================================
DROP TABLE IF EXISTS test.ads_ipd_ipm_qihua_hit_result_dd;

CREATE TABLE test.ads_ipd_ipm_qihua_hit_result_dd (
    dt_month              VARCHAR(6)       COMMENT '统计月份（YYYYMM格式）'
    ,pc20080              VARCHAR(1000)    COMMENT '归属营销部'
    ,stage                INT              COMMENT '阶段（1/2/3/41/42/43为红黑榜阶段，99为不达标合计）'
    ,stage_label          VARCHAR(50)      COMMENT '阶段标签（stage=99时为"不达标合计"）'
    ,hit_type             VARCHAR(50)      COMMENT '达标类型（stage=99时为"合计"）'
    ,total_project_cnt    INT              COMMENT '该阶段/营销部总项目数'
    ,total_sku_cnt        INT              COMMENT '该阶段/营销部总SKU数'
    ,fail_project_cnt     INT              COMMENT '不达标项目数'
    ,fail_sku_cnt         INT              COMMENT '不达标SKU数'
    ,hit_rate             DECIMALV3(10,4)  COMMENT '达标率（1 - 不达标项目数/总项目数）'
    ,load_dt              DATETIMEV2(0)    COMMENT '加载时间'
)
COMMENT '企划命中率结果表（央空/日立）正式版 - test库测试用，仅含红黑榜阶段(1/2/3/41/42/43)'
DISTRIBUTED BY HASH(dt_month) BUCKETS 4
PROPERTIES (
    "replication_num" = "3"
);
