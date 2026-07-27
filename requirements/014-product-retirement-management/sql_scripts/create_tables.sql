-- ============================================================================
-- 脚本名称：create_tables.sql
-- 功能描述：产品退市管理 - 建表脚本
-- 涉及表：
--   1. dws.dws_ipd_ipm_rili_ajhwcl_detail_dd（退市按计划执行率明细表）
--   2. dws.dws_ipd_ipm_rili_gjdsj_detail_dd（退市周期缩减率明细表）
--   3. 飞书退市滚动计划已改为ODS表JSON解析（无需独立建表）
-- 产品线：海信日立（中央空调）
-- 创建时间：2026-07-13
-- ============================================================================

-- 1. 退市按计划执行率明细表
CREATE TABLE IF NOT EXISTS dws.dws_ipd_ipm_rili_ajhwcl_detail_dd
(
    dt_month              VARCHAR(6)       COMMENT '统计月份YYYYMM',
    product_line          VARCHAR(200)     COMMENT '产品线',
    data_type             VARCHAR(200)     COMMENT '数据类型（停签/停产/上市）',
    in_out_sale           VARCHAR(200)     COMMENT '内销/外销',
    prdct_model           VARCHAR(300)     COMMENT '产品型号名称',
    salemodel             VARCHAR(300)     COMMENT '销售型号名称',
    salemodelcode         VARCHAR(300)     COMMENT '销售型号编码',
    marketing_department  VARCHAR(200)     COMMENT '归属营销部',
    channel               VARCHAR(200)     COMMENT '渠道（地产/公建/家装/电商）',
    productmanager        VARCHAR(200)     COMMENT '所有者/产品经理',
    plan_time             DATETIMEV2(0)    COMMENT '计划时间（飞书滚动计划）',
    act_time              DATETIMEV2(0)    COMMENT '实际时间（HDRP）',
    is_aqwc               VARCHAR(2)       COMMENT '是否按时完成（Y/N）',
    load_dt               DATETIMEV2(0)    COMMENT '加载时间'
)
DUPLICATE KEY(dt_month, product_line, data_type)
DISTRIBUTED BY HASH(salemodelcode) BUCKETS 8
PROPERTIES ("replication_allocation" = "tag.location.default: 3");

-- 2. 退市周期缩减率明细表
CREATE TABLE IF NOT EXISTS dws.dws_ipd_ipm_rili_gjdsj_detail_dd
(
    dt_month              VARCHAR(6)       COMMENT '统计月份YYYYMM',
    product_line          VARCHAR(200)     COMMENT '产品线',
    data_type             VARCHAR(200)     COMMENT '数据类型（预停签-停签/停签-停产）',
    in_out_sale           VARCHAR(200)     COMMENT '内销/外销',
    prdct_model           VARCHAR(300)     COMMENT '产品型号名称',
    salemodel             VARCHAR(300)     COMMENT '销售型号名称',
    salemodelcode         VARCHAR(300)     COMMENT '销售型号编码',
    marketing_department  VARCHAR(200)     COMMENT '归属营销部',
    channel               VARCHAR(200)     COMMENT '渠道（地产/公建/家装/电商）',
    productmanager        VARCHAR(200)     COMMENT '所有者/产品经理',
    yutingqian_time       DATETIMEV2(0)    COMMENT '预停签时间（飞书）',
    tingqian_time         DATETIMEV2(0)    COMMENT '实际停止下单时间（HDRP）',
    tingchan_time         DATETIMEV2(0)    COMMENT '实际停止生产时间（HDRP）',
    yutingqian_tingqian_d INT              COMMENT '预停签到停签天数',
    tingqian_tingchan_d   INT              COMMENT '停签到停产天数',
    main_sales_channels   VARCHAR(200)     COMMENT '主销渠道（HX00339）',
    load_dt               DATETIMEV2(0)    COMMENT '加载时间'
)
DUPLICATE KEY(dt_month, product_line, data_type)
DISTRIBUTED BY HASH(salemodelcode) BUCKETS 8
PROPERTIES ("replication_allocation" = "tag.location.default: 3");

-- 3. 飞书退市滚动计划（已改为直接从ODS飞书表JSON解析，不再需要独立DIM表）
-- 数据源：ods.ods_feishu_base_r2ofb6xkcamoljswhssc6eg8nnh_tbl1dlmh21vzcl1j
-- 字段：record_data（JSON格式，含销售型号编码/预停签时间/规划停止下单时间/规划停止生产时间等）
-- 说明：飞书表每日全量覆盖，DWS脚本中通过JSON_EXTRACT_STRING直接解析
