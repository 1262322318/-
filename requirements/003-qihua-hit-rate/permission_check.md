# 权限检查报告 - 企划命中率（央空内销/日立）

## 基本信息
- **需求ID**: 003-qihua-hit-rate
- **检查日期**: 2026-05-09
- **检查账号**: ds_rd_rw
- **检查工具**: Kiro Agent（读取 .kiro/data/table_permissions.csv）

## 检查结果

### 源表（读取权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dim | dim_ipd_salemodel_dd | SELECT | ✅ 有权限 | 销售型号基础信息表 |
| dim | dim_ipd_productmodel_dd | SELECT | ✅ 有权限 | 白电产品型号基础信息表 |
| ods | ods_mr_v_app_fm_imat_saledata | SELECT | ✅ 有权限 | 管报实际销量数据 |
| dw | dim_product_base_info_dd | SELECT | ✅ 有权限 | MDG产品主数据（桥梁表） |

### 目标表（写入权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_qihua_hit_detail_dd | SELECT/INSERT/DROP | ✅ 有权限 | 企划命中率明细表（DWS层） |
| ads | ads_ipd_ipm_qihua_hit_result_dd | SELECT/INSERT/DROP | ✅ 有权限 | 企划命中率结果表（ADS层） |

## 检查结论

**全部通过** ✅

所有涉及表在 `ds_rd_rw` 账号下均有所需权限：
- 4张源表：均有 SELECT 权限
- 2张目标表：均有 SELECT/INSERT/DROP 权限（支持 DELETE+INSERT 模式）

## 备注
- ds_rd_rw 为ETL开发默认账号，对 dim/ods/dw 层有读取权限，对 dws/ads 层有读写权限
- 目标表为新建表（通过 create_tables.sql 创建），权限在建表时自动继承
