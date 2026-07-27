# 012-project-impl-rate 变更记录

| 日期 | 版本 | 变更类型 | 变更内容 | 影响文件 | 状态 |
|------|------|----------|----------|----------|------|
| 2026-07-08 | v1.0 | 新建 | 初始版本：DWS明细表（5种状态判定）+ ADS汇总表（3维度聚合） | create_tables.sql, dws_*.sql, ads_*.sql, validate_*.sql | ✅ 完成 |
| 2026-07-08 | v1.1 | 逻辑优化 | "正常"判定从ELSE兜底改为显式校验projectcurrent IN ('Create','Active','Assign')，新增"其他"防御分支 | dws_ipd_itd_project_impl_rate_dd.sql | ✅ 完成 |
| 2026-07-09 | v1.2 | 逻辑修复 | 1.延期判定改为Doris兼容JOIN方式(去掉关联子查询) 2.新增design_deadline_date/production_deadline_date字段 3.projectcurrent输出转中文 4.Cancel项目只纳入当月有取消单的 5.日期比较统一CAST AS DATE 6.延期排除结题项目 | dws_ipd_itd_project_impl_rate_dd.sql, create_tables.sql | ✅ 完成 |
