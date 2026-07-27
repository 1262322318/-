# 权限检查报告 - 在销型号数

## 基本信息
- **需求ID**: 004-sale-model-count
- **检查日期**: 2026-05-15
- **检查账号**: ds_rd_rw
- **检查工具**: Kiro Agent（读取 .kiro/data/table_permissions.csv）

## 检查结果

### 源表（读取权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dim | dim_ipd_productmodel_dd | SELECT | ✅ 有权限 | 白电产品型号基础信息 |
| dim | dim_ipd_productionversion_dd | SELECT | ✅ 有权限 | 生产版本基础信息 |
| dim | dim_ipd_salemodel_dd | SELECT | ✅ 有权限 | 白电销售型号基础信息 |
| dw | dim_product_base_info_dd | SELECT | ✅ 有权限 | MDG产品主数据 |
| dws | dws_fi_mr_bxp_dklmx_di | SELECT | ✅ 有权限 | 冰箱大库龄明细 |
| dws | dws_fi_mr_bxp_yxccpmx_all_di | SELECT | ✅ 有权限 | 冰箱营销产成品明细 |
| dwd | dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd | SELECT | ✅ 有权限 | 海外分公司库存 |
| dwd | dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd | SELECT | ✅ 有权限 | 基地库存 |
| dwd | dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd | SELECT | ✅ 有权限 | 在途库存 |
| test | dwfi_fa_tf_acp_prostockdetail | SELECT | ✅ 有权限 | 空调自有库存 |
| ods | odss900_mchb | SELECT | ✅ 有权限 | OEM库存 |

### 目标表（写入权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dws | dws_ipd_ipm_sale_model_detail_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 在销型号明细表（DWS层） |
| ads | ads_ipd_ipm_sale_model_result_dd | SELECT/INSERT/DELETE | ✅ 有权限 | 在销型号数结果表（ADS层） |

## 检查结论

**全部通过** ✅

所有涉及表在 `ds_rd_rw` 账号下均有所需权限。

## 备注
- 历史脚本（从生产环境录入），权限已在生产环境验证通过
- DWS/ADS层使用DELETE+INSERT幂等模式，需要DELETE权限
