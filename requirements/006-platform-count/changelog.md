# 变更记录 - 平台数（006-platform-count）

## 概述
本文档记录006需求开发过程中的变更历史。

---

## 变更记录

### #001 — 初始版本录入
- **日期**: 2026-04-29
- **变更描述**: 从已有生产脚本录入，包含DWS/ADS两层ETL脚本（平台库+产品平台数）
- **影响文件**: `dws_ipd_ipm_platform_library_detail_dd.sql`, `dws_ipd_ipm_platform_detail_dd.sql`, `ads_ipd_ipm_platform_library_result_dd.sql`, `ads_ipd_ipm_platform_result_dd.sql`
- **变更人**: ETL智能辅助工具

### #002 — 新增数据质量检查脚本
- **日期**: 2026-05-09
- **变更描述**: 新增 `validate_data_quality.sql`，包含6项数据质量检查（平台库/产品平台行数、平台名称空值率、平台数合理性）
- **影响文件**: `validate_data_quality.sql`
- **变更人**: ETL智能辅助工具

### #003 — 补全lineage.md字段级血缘
- **日期**: 2026-05-09
- **变更描述**: 补充详细血缘关系，包含源表/目标表清单、平台库DWS层、产品平台数DWS层和ADS层字段级血缘映射
- **影响文件**: `lineage.md`
- **变更人**: ETL智能辅助工具

### #004 — 激光产品线平台库+产品平台数DWS草稿
- **日期**: 2026-05-29 ~ 2026-06-01
- **变更类型**: CHG-02 产品线扩展（激光）
- **变更描述**: 新增激光产品线两个DWS层草稿：①平台库（从odsjtplm_his_productplatform取，筛选产品小类IN激光电视/家用投影/商用投影，状态取发布+禁选，不区分内外销）；②产品平台数（从在产型号明细取platform字段，区分内外销）。商用投影平台标记is_project='Y'不计入统计。
- **影响文件**: `drafts/dws_ipd_ipm_platform_library_detail_dd_jiguang_draft.sql`, `drafts/dws_ipd_ipm_platform_detail_dd_jiguang_draft.sql`
- **状态**: ✅ 已完成（ADS层不提供，用户批量手工合入正式脚本）
- **前置条件**: 产品平台数依赖005激光在产型号数先合入执行
- **变更人**: ETL智能辅助工具 + 用户（手工合入）

### #005 — 激光产品线平台库+产品平台数闭环，正式脚本手工更新
- **日期**: 2026-06-08
- **变更描述**: 激光产品线平台库和产品平台数逻辑正式闭环。用户手工将激光草稿逻辑合入DWS/ADS正式脚本，平台库从JTPLM取激光电视/家用投影/商用投影平台，产品平台数从在产型号明细取platform字段。
- **影响文件**: `dws_ipd_ipm_platform_library_detail_dd.sql`, `dws_ipd_ipm_platform_detail_dd.sql`, `ads_ipd_ipm_platform_library_result_dd.sql`, `ads_ipd_ipm_platform_result_dd.sql`
- **状态**: ✅ 已闭环
- **变更人**: 用户（手工更新）

---

## 模板（新增变更时复制）

### #0XX — 标题
- **日期**: YYYY-MM-DD
- **变更描述**: [描述变更内容]
- **影响文件**: [列出受影响的文件]
- **变更人**: [变更人]
