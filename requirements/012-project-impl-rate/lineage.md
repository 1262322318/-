# 012-project-impl-rate 数据血缘

## 血缘关系图

```
ods.odsplm_bm_hbmtprojectkpi (ODS)
    │
    ├──→ dws.dws_ipd_ipd_project_impl_rate_dd (DWS)
    │         │
    │         └──→ ads.ads_ipd_ipd_project_impl_rate_result_dd (ADS)
    │
ods.odsplm_bm_hbmtprojectadjust (ODS)
    │
    ├──→ dws.dws_ipd_ipd_project_impl_rate_dd (DWS)  [project_base CTE子查询：当月取消单筛选]
    └──→ dws.dws_ipd_ipd_project_impl_rate_dd (DWS)  [cancel_info CTE：终止判定（取消+无恢复）]

ods.odsrdm_holiday (ODS)
    │
    └──→ dws.dws_ipd_ipd_project_impl_rate_dd (DWS)  [LEFT JOIN, id+3工作日截止日期]
```

## 表级血缘

| 源表 | 目标表 | 关联方式 | 用途 |
|------|--------|----------|------|
| ods.odsplm_bm_hbmtprojectkpi | dws.dws_ipd_ipd_project_impl_rate_dd | 直接查询 | 项目基础信息+状态判定 |
| ods.odsplm_bm_hbmtprojectadjust | dws.dws_ipd_ipd_project_impl_rate_dd | productname IN (子查询projectname) | project_base CTE：Cancel项目需当月有取消单才纳入统计范围 |
| ods.odsplm_bm_hbmtprojectadjust | dws.dws_ipd_ipd_project_impl_rate_dd | productname = projectname | cancel_info CTE：终止判定（当月取消+无恢复） |
| ods.odsrdm_holiday | dws.dws_ipd_ipd_project_impl_rate_dd | LEFT JOIN（id+3） | 延期判定+3工作日截止日期 |
| dws.dws_ipd_ipd_project_impl_rate_dd | ads.ads_ipd_ipd_project_impl_rate_result_dd | 聚合查询 | 按维度汇总实施率 |

## 字段级血缘（ADS层：ads.ads_ipd_ipd_project_impl_rate_result_dd）

| 目标字段 | 来源 | 计算逻辑 |
|----------|------|----------|
| dt_month | dws.dws_ipd_ipd_project_impl_rate_dd.dt_month | 直接透传 |
| dim_type | 常量 | '事业部产品线' / '事业部小计' / '项目经理'（三段UNION ALL） |
| business_division | dws.dws_ipd_ipd_project_impl_rate_dd.business_division | 直接透传 |
| product_line_display | dws.dws_ipd_ipd_project_impl_rate_dd.product_line_display | 事业部产品线维度=透传，事业部小计='小计'，项目经理维度=NULL |
| productowner | dws.dws_ipd_ipd_project_impl_rate_dd.productowner | 项目经理维度=透传，事业部维度=NULL |
| total_count | dws.project_situation | SUM(CASE WHEN IN ('正常','延期','暂停','结题') THEN 1 ELSE 0 END) |
| normal_count | dws.project_situation | SUM(CASE WHEN = '正常' THEN 1 ELSE 0 END) |
| delay_count | dws.project_situation | SUM(CASE WHEN = '延期' THEN 1 ELSE 0 END) |
| hold_count | dws.project_situation | SUM(CASE WHEN = '暂停' THEN 1 ELSE 0 END) |
| cancel_count | dws.project_situation | SUM(CASE WHEN = '终止' THEN 1 ELSE 0 END) |
| complete_count | dws.project_situation | SUM(CASE WHEN = '结题' THEN 1 ELSE 0 END) |
| impl_rate | dws.project_situation | (正常+结题) / (正常+延期+暂停+结题)，分母=0时返回0 |
| load_dt | NOW() | ETL加载时间 |

## 字段级血缘（DWS层关键字段）

| 目标字段 | 来源 | 计算逻辑 |
|----------|------|----------|
| business_division | hbmtpproductline | CASE映射（A1~Coherent→光模块，BOX/Multimedia→终端） |
| product_line_display | hbmtpproductline | CASE映射（A1→TELECOM，A2→数通DATACOM，A3→FTTx，A4→无线，Coherent→相干产品线，BOX→BOX，Multimedia→多媒体） |
| derive_type_group | HBMTPDERIVETYPE | LIKE前缀截取（PS%→PS，PA%→PA等） |
| projectcurrent | projectcurrent（原值） | CASE翻译中文（Complete→完成，Review→复核，Archive→归档，Hold→暂停，Cancel→取消，Concept→概念，Create→项目立项，Assign→分配，Active→活动，其他保留原值） |
| is_design_delay | hbmtpdesignestimatededate + hbmtpdesignactualedate + hbmtpproductionactualedate + odsrdm_holiday | delay_calc CTE: 计划非空 AND 实际非空 AND 鉴定实际完成为空（排除结题项目）AND CAST(实际 AS DATE) > CAST(计划+3工作日 AS DATE) → Y，COALESCE兜底N |
| design_deadline_date | hbmtpdesignestimatededate + odsrdm_holiday | delay_calc CTE: h_design.date_time（design_base_id+3对应的工作日） |
| is_production_delay | hbmtpproductionestimatededate + hbmtpproductionactualedate + odsrdm_holiday + ${GP_START_DT} | delay_calc CTE: 计划非空 AND 实际非空 AND 鉴定完成月份≠统计当月（排除结题项目）AND CAST(实际 AS DATE) > CAST(计划+3工作日 AS DATE) → Y，COALESCE兜底N |
| production_deadline_date | hbmtpproductionestimatededate + odsrdm_holiday | delay_calc CTE: h_production.date_time（production_base_id+3对应的工作日） |
| project_situation | 多字段综合判定 | 结题>延期>暂停>终止>正常>其他（防御性兜底，正常情况不触发） |

## 脚本清单

| 序号 | 脚本 | 类型 | 输入表 | 输出表 |
|------|------|------|--------|--------|
| 1 | create_tables.sql | DDL | — | dws.dws_ipd_ipd_project_impl_rate_dd + ads.ads_ipd_ipd_project_impl_rate_result_dd |
| 2 | dws_ipd_ipd_project_impl_rate_dd.sql | DML | ods.odsplm_bm_hbmtprojectkpi + ods.odsplm_bm_hbmtprojectadjust + ods.odsrdm_holiday | dws.dws_ipd_ipd_project_impl_rate_dd |
| 3 | ads_ipd_ipd_project_impl_rate_result_dd.sql | DML | dws.dws_ipd_ipd_project_impl_rate_dd | ads.ads_ipd_ipd_project_impl_rate_result_dd |
| 4 | validate_data_quality.sql | 验证 | dws + ads | —（验证结果集） |

## 校验脚本血缘

### validate_data_quality.sql

**类型**：数据质量校验（只读，无写入目标表）

| 校验项 | 读取表 | 校验逻辑 | 预期结果 |
|--------|--------|----------|----------|
| 校验1：项目情况分布 | `dws.dws_ipd_ipd_project_impl_rate_dd` | 按project_situation+in_total_flag分组计数 | 5种状态互斥且完整 |
| 校验2：DWS vs ADS一致性 | `dws.dws_ipd_ipd_project_impl_rate_dd` + `ads.ads_ipd_ipd_project_impl_rate_result_dd` | DWS按事业部汇总total/numerator，对比ADS事业部小计行 | 数值一致 |
| 校验3：终止不纳入分母 | `dws.dws_ipd_ipd_project_impl_rate_dd` | project_situation='终止' 且 in_total_flag!='N' | 0行 |
| 校验4：结题优先级验证 | `dws.dws_ipd_ipd_project_impl_rate_dd` | project_situation='结题' 且有延期标记 | 允许存在（结题优先级高于延期） |
| 校验5：维度汇总一致 | `ads.ads_ipd_ipd_project_impl_rate_result_dd` | 项目经理维度SUM(total_count) vs 事业部小计SUM(total_count) | 两者相等 |
| 校验6：产品线范围 | `dws.dws_ipd_ipd_project_impl_rate_dd` | business_division NOT IN ('光模块','终端') | 0行 |
