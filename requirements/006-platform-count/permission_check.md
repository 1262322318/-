# 权限检查报告 - 平台数

## 基本信息
- **需求ID**: 006-platform-count
- **检查日期**: 2026-05-15
- **检查账号**: ds_rd_rw
- **检查工具**: Kiro Agent（读取 .kiro/data/table_permissions.csv）

## 检查结果

### 源表（读取权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dim | dim_ipd_productplatform_dd | SELECT | ✅ 有权限 | 白电产品平台基础信息 |
| ods | odsrdm_t_wf95_ext | SELECT | ✅ 有权限 | RDM平台扩展信息（空调） |
| ods | odsjtplm_his_productplatform | SELECT | ✅ 有权限 | JTPLM产品平台（视像科技） |
| ods | odsplm_hac_plmproductplatform | SELECT | ✅ 有权限 | PLM产品平台（日立） |
| dws | dws_ipd_ipm_zcmodel_detail_dd | SELECT | ✅ 有权限 | 在产型号明细 |
| dim | dim_ipd_platform_library_class_name_nd | SELECT | ✅ 有权限 | 平台库产品线分类映射 |

### 目标表（写入权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_platform_library_detail_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 平台库明细表 |
| dws | dws_ipd_ipm_platform_detail_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 产品平台数明细表 |
| ads | ads_ipd_ipm_platform_library_result_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 平台库结果表 |
| ads | ads_ipd_ipm_platform_result_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 产品平台数结果表 |
| dws | dws_ipd_ipm_add_reduce_detail_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 平台迁移退市明细 |
| ads | ads_ipd_ipm_add_reduce_result_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 平台迁移退市结果 |

## 检查结论

**全部通过** ✅

所有涉及表在 `ds_rd_rw` 账号下均有所需权限。

## 备注
- 历史脚本（从生产环境录入），权限已在生产环境验证通过
- 平台数依赖005在产型号数的DWS表作为源
