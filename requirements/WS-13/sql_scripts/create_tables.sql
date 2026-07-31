-- ============================================================================
-- 需求: WS-13 应市项目平均开发周期
-- 文件: create_tables.sql
-- 目标: 创建 DWS 层目标表
-- 创建时间: 2026-07-31
-- ============================================================================
-- ⚠️ 假设声明:
--   ODS 表物理列名采用 PRD §5 源 PLM 属性名小写形式，MCP 不可用未校验。
--   后续 MCP 可用时需重新验证列名是否匹配。
-- ============================================================================

-- DWS层: 应市项目平均开发周期月度表
-- 粒度: 产品线 × 统计月
-- 模型: Duplicate（允许同粒度多次写入，通过 DELETE+INSERT 保证幂等）
CREATE TABLE IF NOT EXISTS dws.dws_plm_project_dev_cycle_monthly
(
    dt_month              VARCHAR(6)       COMMENT '统计月份(YYYYMM)',
    product_line_code     VARCHAR(50)      COMMENT '产品线编码(A1/A2/A3/A4/Coherent/BOX/Multimedia)',
    product_line_name     VARCHAR(200)     COMMENT '产品线名称(中文)',
    business_division     VARCHAR(50)      COMMENT '事业部维度(终端/光模块)',
    project_count         INT              COMMENT '当月完成项目数量',
    total_dev_cycle_days  DECIMALV3(20,4)  COMMENT '开发周期总天数(已扣暂停)',
    avg_dev_cycle_days    DECIMALV3(10,1)  COMMENT '平均开发周期(天,保留1位小数)',
    etl_time              DATETIMEV2(0)    COMMENT 'ETL加载时间'
)
DUPLICATE KEY(dt_month, product_line_code)
COMMENT '应市项目平均开发周期月度表(WS-13)'
DISTRIBUTED BY HASH(dt_month) BUCKETS 4
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);
