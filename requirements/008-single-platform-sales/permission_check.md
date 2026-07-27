# 权限检查报告 - 单平台销量

## 基本信息
- **需求ID**: 008-single-platform-sales
- **检查日期**: 2026-05-15
- **检查账号**: ds_rd_rw
- **检查工具**: Kiro Agent（读取 .kiro/data/table_permissions.csv）

## 检查结果

### 源表（读取权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_dxhxl_detail_dd | SELECT | ✅ 有权限 | 单型号销量明细 |
| dws | dws_ipd_ipm_platform_detail_dd | SELECT | ✅ 有权限 | 产品平台数明细 |
| dws | dws_ipd_ipm_sales_detail_mid_dd | SELECT | ✅ 有权限 | 外销sellin全量数据 |
| ods | odsmr_v_hitach_ykfpmxb | SELECT | ✅ 有权限 | 日立管报数据 |
| ads | ads_ipd_ipm_platform_result_dd | SELECT | ✅ 有权限 | 产品平台数结果 |
| ads | ads_ipd_ipm_platform_library_result_dd | SELECT | ✅ 有权限 | 平台库结果 |

### 目标表（写入权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_dptxl_detail_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 单平台销量明细表 |
| ads | ads_ipd_ipm_dptxl_result_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 单平台销量结果表 |

## 检查结论

**全部通过** ✅

所有涉及表在 `ds_rd_rw` 账号下均有所需权限。

## 备注
- 历史脚本（从生产环境录入），权限已在生产环境验证通过
- 单平台销量依赖007单型号销量和006平台数的结果
