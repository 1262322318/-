-- =====================================================================
-- 脚本名称：create_tables.sql
-- 功能说明：应市项目按计划实施率 - 建表语句（DWS + ADS）
-- =====================================================================

-- =========================
-- DWS层：项目按计划实施率明细表
-- =========================
DROP TABLE IF EXISTS dws.dws_ipd_itd_project_impl_rate_dd;

CREATE TABLE dws.dws_ipd_itd_project_impl_rate_dd (
    dt_month                       VARCHAR(6)        COMMENT '统计月份（YYYYMM）',
    projectname                    VARCHAR(200)      COMMENT '项目名称',
    hbmtpproductline               VARCHAR(200)      COMMENT '产品线原值（A1/BOX等）',
    business_division              VARCHAR(50)       COMMENT '事业部（光模块/终端）',
    product_line_display           VARCHAR(100)      COMMENT '产品线展示名（TELECOM/BOX等）',
    hbmtpderivetype                VARCHAR(200)      COMMENT '项目分类原值（PS1/PA2等）',
    derive_type_group              VARCHAR(10)       COMMENT '项目分类分组（PS/PA/PB/PC1/PC2/HW/FH）',
    projectcurrent                 VARCHAR(60)       COMMENT '项目状态原值（Active/Hold/Cancel等）',
    hbmtpprojecttype               VARCHAR(200)      COMMENT '项目类型',
    productowner                   VARCHAR(200)      COMMENT '项目经理',
    hbmtpdesignestimatededate      DATETIMEV2(0)     COMMENT '开发计划完成时间（市场因素变更后）',
    hbmtpdesignactualedate         DATETIMEV2(0)     COMMENT '开发实际完成时间',
    hbmtpproductionestimatededate  DATETIMEV2(0)     COMMENT '鉴定计划完成时间（市场因素变更后）',
    hbmtpproductionactualedate     DATETIMEV2(0)     COMMENT '鉴定实际完成时间',
    is_design_delay                VARCHAR(2)        COMMENT '开发阶段延期标记（Y/N）',
    design_deadline_date           DATETIMEV2(0)     COMMENT '开发计划+3工作日截止日期',
    is_production_delay            VARCHAR(2)        COMMENT '鉴定阶段延期标记（Y/N）',
    production_deadline_date       DATETIMEV2(0)     COMMENT '鉴定计划+3工作日截止日期',
    project_situation              VARCHAR(20)       COMMENT '项目情况（结题/延期/暂停/终止/正常）',
    in_total_flag                  VARCHAR(2)        COMMENT '是否纳入合计分母（Y/N，终止为N）',
    load_dt                        DATETIMEV2(0)     COMMENT '加载时间'
)
ENGINE = OLAP
DUPLICATE KEY(dt_month, projectname)
COMMENT '应市项目按计划实施率明细表'
DISTRIBUTED BY HASH(projectname) BUCKETS 4
PROPERTIES ("replication_allocation" = "tag.location.default: 3");


-- =========================
-- ADS层：项目按计划实施率汇总表
-- =========================
DROP TABLE IF EXISTS ads.ads_ipd_itd_project_impl_rate_result_dd;

CREATE TABLE ads.ads_ipd_itd_project_impl_rate_result_dd (
    dt_month                       VARCHAR(6)        COMMENT '统计月份（YYYYMM）',
    dim_type                       VARCHAR(50)       COMMENT '维度类型（事业部产品线/事业部小计/项目经理）',
    business_division              VARCHAR(50)       COMMENT '事业部（光模块/终端）',
    product_line_display           VARCHAR(100)      COMMENT '产品线展示名（事业部维度有值，项目经理维度为NULL）',
    productowner                   VARCHAR(200)      COMMENT '项目经理（项目经理维度有值，事业部维度为NULL）',
    total_count                    INT               COMMENT '合计项目数（正常+延期+暂停+结题）',
    normal_count                   INT               COMMENT '正常项目数',
    delay_count                    INT               COMMENT '延期项目数',
    hold_count                     INT               COMMENT '暂停项目数（累计）',
    cancel_count                   INT               COMMENT '终止项目数（当月）',
    complete_count                 INT               COMMENT '结题项目数（当月）',
    impl_rate                      DECIMALV3(10,4)   COMMENT '按计划实施率（正常+结题）/合计',
    load_dt                        DATETIMEV2(0)     COMMENT '加载时间'
)
ENGINE = OLAP
DUPLICATE KEY(dt_month, dim_type, business_division)
COMMENT '应市项目按计划实施率汇总表'
DISTRIBUTED BY HASH(dt_month) BUCKETS 4
PROPERTIES ("replication_allocation" = "tag.location.default: 3");
