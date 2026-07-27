-- =====================================================================
-- 脚本名称：create_tables.sql
-- 功能说明：创建应市项目开发周期相关表
-- 三级域：管理集成产品开发/管理产品开发/整机产品开发
-- =====================================================================

-- =====================================================================
-- DWS层：项目开发周期明细表
-- =====================================================================
CREATE TABLE IF NOT EXISTS dws.dws_ipd_ipd_project_dev_cycle_dd (
    dt_month                      VARCHAR(6)       COMMENT '统计月份（项目完成所在月，YYYYMM）',
    projectname                   VARCHAR(150)     COMMENT '项目名称',
    hbmtpproductline              VARCHAR(150)     COMMENT '事业部（光模块/终端）',
    hbmtpderivetype               VARCHAR(150)     COMMENT '项目分类原值（PA1/PB2/PC1等）',
    derive_type_group             VARCHAR(10)      COMMENT '项目类型分组（PS/PA/PB/PC）',
    projectcurrent                VARCHAR(60)      COMMENT '项目状态',
    productcurrent                VARCHAR(60)      COMMENT '产品阶段',
    productowner                  VARCHAR(150)     COMMENT '项目经理',
    projectowner                  VARCHAR(150)     COMMENT '推进主管',
    hbmtprddept                   VARCHAR(150)     COMMENT '在研部门',
    hbmtprocessplant              VARCHAR(150)     COMMENT '生产工厂',
    hbmtpprojectline              VARCHAR(150)     COMMENT '开发目的',
    hbmtpprojecttype              VARCHAR(150)     COMMENT '项目类型',
    hbmtprojectcreatedate         DATETIME         COMMENT '立项时间',
    hbmtpdesignetime              DATETIME         COMMENT '开发计划完成时间（首次）',
    hbmtpdesignestimatededate     DATETIME         COMMENT '开发计划完成时间（市场因素变更后）',
    hbmtpdesignactualedate        DATETIME         COMMENT '开发实际完成时间',
    hbmtpproductiontrialetime     DATETIME         COMMENT '鉴定计划完成时间（首次）',
    hbmtpproductionestimatededate DATETIME         COMMENT '鉴定计划完成时间（市场因素变更后）',
    hbmtpproductionactualedate    DATETIME         COMMENT '鉴定实际完成时间',
    hold_days                     DECIMAL(10,1)    COMMENT '暂停总天数',
    dev_cycle_days                DECIMAL(10,1)    COMMENT '开发周期（天）= 鉴定完成 - 立项 - 暂停天数',
    load_dt                       DATETIME         COMMENT '加载时间'
)
COMMENT '应市项目开发周期明细表'
DISTRIBUTED BY HASH(projectname) BUCKETS 8
PROPERTIES ("replication_allocation" = "tag.location.default: 1");

-- =====================================================================
-- ADS层：项目开发周期结果表
-- =====================================================================
CREATE TABLE IF NOT EXISTS ads.ads_ipd_ipd_project_dev_cycle_result_dd (
    dt_month                      VARCHAR(6)       COMMENT '统计月份（YYYYMM）',
    hbmtpproductline              VARCHAR(150)     COMMENT '事业部（光模块/终端）',
    derive_type_group             VARCHAR(10)      COMMENT '项目类型分组（PA/PB/PC/PS/平均）',
    dt_type                       VARCHAR(10)      COMMENT '时间范围类型（当月/年累）',
    project_count                 INT              COMMENT '项目数量',
    avg_dev_cycle                 DECIMAL(10,1)    COMMENT '平均开发周期（天）',
    target_value                  DECIMAL(10,1)    COMMENT '目标值（天）',
    completion_rate               DECIMAL(10,4)    COMMENT '完成率 = 2 - 实际值/目标值',
    last_year_value               DECIMAL(10,1)    COMMENT '同期值（去年同期平均开发周期）',
    yoy_improvement               DECIMAL(10,4)    COMMENT '同比改善 = 1 - 实际值/同期值',
    load_dt                       DATETIME         COMMENT '加载时间'
)
COMMENT '应市项目平均开发周期结果表'
DISTRIBUTED BY HASH(dt_month) BUCKETS 4
PROPERTIES ("replication_allocation" = "tag.location.default: 1");
