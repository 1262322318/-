# 权限检查报告 - 单型号销量

## 基本信息
- **需求ID**: 007-single-model-sales
- **检查日期**: 2026-05-15
- **检查账号**: ds_rd_rw
- **检查工具**: Kiro Agent（读取 .kiro/data/table_permissions.csv）

## 检查结果

### 源表（读取权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_sale_model_detail_dd | SELECT | ✅ 有权限 | 在销型号明细（型号列表+保护期） |
| ods | ods_mr_v_app_fm_imat_saledata | SELECT | ✅ 有权限 | 管报实际销量 |
| dw | dim_product_base_info_dd | SELECT | ✅ 有权限 | MDG产品主数据 |
| dim | dim_ipd_tv_model_nengxiao_nd | SELECT | ✅ 有权限 | 电视能效机型号映射 |
| dws | dws_ipd_ipm_platform_detail_dd | SELECT | ✅ 有权限 | 产品平台数明细 |
| dws | dws_ipd_ipm_sales_detail_mid_dd | SELECT | ✅ 有权限 | 外销sellin全量数据 |

### 目标表（写入权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_dxhxl_detail_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 单型号销量明细表 |
| ads | ads_ipd_ipm_dxhxl_result_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 单型号销量结果表 |

## 检查结论

**全部通过** ✅

所有涉及表在 `ds_rd_rw` 账号下均有所需权限。

## 备注
- 历史脚本（从生产环境录入），权限已在生产环境验证通过
- 单型号销量依赖004在销型号数的DWS表作为源
