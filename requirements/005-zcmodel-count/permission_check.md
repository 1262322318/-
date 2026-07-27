# 权限检查报告 - 在产型号数

## 基本信息
- **需求ID**: 005-zcmodel-count
- **检查日期**: 2026-05-15
- **检查账号**: ds_rd_rw
- **检查工具**: Kiro Agent（读取 .kiro/data/table_permissions.csv）

## 检查结果

### 源表（读取权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_sale_model_detail_dd | SELECT | ✅ 有权限 | 在销型号明细表（筛选在产） |
| dim | dim_ipd_productionversion_dd | SELECT | ✅ 有权限 | 生产版本基础信息（代工判定） |

### 目标表（写入权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_zcmodel_detail_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 在产型号明细表（DWS层） |
| ads | ads_ipd_ipm_zcmodel_result_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 在产型号数结果表（ADS层） |

## 检查结论

**全部通过** ✅

所有涉及表在 `ds_rd_rw` 账号下均有所需权限。

## 备注
- 历史脚本（从生产环境录入），权限已在生产环境验证通过
- 在产型号数依赖004在销型号数的DWS表作为源
