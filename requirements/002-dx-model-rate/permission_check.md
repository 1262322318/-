# 权限检查报告 - 低效型号占比与新品规划命中率

## 基本信息
- **需求ID**: 002-dx-model-rate
- **检查日期**: 2026-05-15
- **检查账号**: ds_rd_rw
- **检查工具**: Kiro Agent（读取 .kiro/data/table_permissions.csv）

## 检查结果

### 源表（读取权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| ods | ods_mr_v_app_fm_imat_saledata | SELECT | ✅ 有权限 | 管报实际销量数据 |
| dim | dim_ipd_productmodel_dd | SELECT | ✅ 有权限 | 白电产品型号基础信息 |
| dim | dim_ipd_salemodel_dd | SELECT | ✅ 有权限 | 白电销售型号基础信息 |
| dw | dim_product_base_info_dd | SELECT | ✅ 有权限 | MDG产品主数据（桥梁表） |
| dwd | dwd_ipd_ipm_bp_lx_model_mid_dd | SELECT | ✅ 有权限 | BP及立项规划销量分月数据 |
| dim | dim_ipd_jtplm_his_productmodel_dd | SELECT | ✅ 有权限 | 视像科技产品型号 |
| dim | dim_ipd_tv_model_nengxiao_nd | SELECT | ✅ 有权限 | 电视能效机型号映射 |

### 目标表（写入权限）

| 数据库 | 表名 | 权限 | 状态 | 说明 |
|--------|------|------|------|------|
| dwd | dwd_ipd_ipm_bp_lx_model_mid_dd | SELECT/INSERT/DROP | ✅ 有权限 | BP规划销量中间表 |
| dws | dws_ipd_ipm_dxmodel_detail_dd | SELECT/INSERT/DROP | ✅ 有权限 | 低效型号明细表（DWS层） |
| ads | ads_ipd_ipm_dxmodel_result_dd | SELECT/INSERT/DROP | ✅ 有权限 | 低效型号结果表（ADS层） |
| test | productmodel_xmndxf | SELECT/CREATE/DROP | ✅ 有权限 | 中间表（项目开发难度） |
| test | salesmodel_xmndxf | SELECT/CREATE/DROP | ✅ 有权限 | 中间表（销售型号开发难度） |
| test | productmodel_tv_xmndxf | SELECT/CREATE/DROP | ✅ 有权限 | 中间表（视像科技开发难度） |

## 检查结论

**全部通过** ✅

所有涉及表在 `ds_rd_rw` 账号下均有所需权限。

## 备注
- 历史脚本（从生产环境录入），权限已在生产环境验证通过
- test库中间表使用CTAS方式创建，需要CREATE/DROP权限
