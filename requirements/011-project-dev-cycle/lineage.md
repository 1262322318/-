# 数据血缘：011-project-dev-cycle

## 数据流转图

```
odsplm_bm_hbmtprojectkpi ──────────────┐
                                         ├──→ dws.dws_ipd_ipd_project_dev_cycle_dd ──→ ads.ads_ipd_ipd_project_dev_cycle_result_dd
odsplm_bm_hbmtprojectadjust ───────────┘                                                          ↑
                                                                                                    │
ods.ODS_FEISHU_WIKI_..._TBLTRBIEBXRYRKO4 ─────────────────────────────────────────────────────────┤
                                                                                                    │
ads.ads_ipd_ipd_project_dev_cycle_result_dd（历史）─────────────────────────────────────────────────┘
```

## 表级血缘

| 目标表 | 源表 | 关联方式 |
|--------|------|----------|
| dws.dws_ipd_ipd_project_dev_cycle_dd | odsplm_bm_hbmtprojectkpi | 主表（项目信息） |
| dws.dws_ipd_ipd_project_dev_cycle_dd | odsplm_bm_hbmtprojectadjust | LEFT JOIN（暂停时段，projectname关联） |
| ads.ads_ipd_ipd_project_dev_cycle_result_dd | dws.dws_ipd_ipd_project_dev_cycle_dd | 聚合（按事业部×类型，当月+年累） |
| ads.ads_ipd_ipd_project_dev_cycle_result_dd | ods.ODS_FEISHU_WIKI_LHK6WMDWWI3GFQK7ZIACKU3KNCB_TBLTRBIEBXRYRKO4 | LEFT JOIN（目标值，JSON解析，按年份匹配） |
| ads.ads_ipd_ipd_project_dev_cycle_result_dd | ads.ads_ipd_ipd_project_dev_cycle_result_dd（自引用-历史） | LEFT JOIN（同期值，去年同月已计算结果，按事业部×类型×当月/年累匹配） |

## 字段级血缘（关键字段）

### DWS层：dws.dws_ipd_ipd_project_dev_cycle_dd

| 目标字段 | 源表.源字段 | 转换逻辑 |
|----------|------------|----------|
| dt_month | odsplm_bm_hbmtprojectkpi.hbmtpproductionactualedate | DATE_FORMAT('%Y%m') |
| projectname | odsplm_bm_hbmtprojectkpi.productname | 直接映射 |
| hbmtpproductline | odsplm_bm_hbmtprojectkpi.hbmtpproductline | CASE映射：A1/A2/A3/A4/Coherent→'光模块'，BOX/Multimedia→'终端'，其他→'其他' |
| hbmtpderivetype | odsplm_bm_hbmtprojectkpi.HBMTPDERIVETYPE | 直接映射 |
| derive_type_group | odsplm_bm_hbmtprojectkpi.HBMTPDERIVETYPE | CASE LIKE匹配前缀→PS/PA/PB/PC，其他保留原值 |
| projectcurrent | odsplm_bm_hbmtprojectkpi.projectcurrent | CASE WHEN英转中（Complete→完成, Review→复核, Archive→归档, Hold→暂停, Cancel→取消, Concept→概念, Create→项目立项, Assign→分配, Active→活动） |
| productcurrent | odsplm_bm_hbmtprojectkpi.productcurrent | 直接映射 |
| productowner | odsplm_bm_hbmtprojectkpi.productowner | 直接映射 |
| projectowner | odsplm_bm_hbmtprojectkpi.projectowner | 直接映射 |
| hbmtprddept | odsplm_bm_hbmtprojectkpi.hbmtprddept | 直接映射 |
| hbmtprocessplant | odsplm_bm_hbmtprojectkpi.hbmtprocessplant | 直接映射 |
| hbmtpprojectline | odsplm_bm_hbmtprojectkpi.hbmtpprojectline | 直接映射 |
| hbmtpprojecttype | odsplm_bm_hbmtprojectkpi.hbmtpprojecttype | 直接映射 |
| hbmtprojectcreatedate | odsplm_bm_hbmtprojectkpi.hbmtprojectcreatedate | 直接映射 |
| hbmtpdesignetime | odsplm_bm_hbmtprojectkpi.hbmtpdesignetime | 直接映射 |
| hbmtpdesignestimatededate | odsplm_bm_hbmtprojectkpi.hbmtpdesignestimatededate | 直接映射 |
| hbmtpdesignactualedate | odsplm_bm_hbmtprojectkpi.hbmtpdesignactualedate | 直接映射 |
| hbmtpproductiontrialetime | odsplm_bm_hbmtprojectkpi.hbmtpproductiontrialetime | 直接映射 |
| hbmtpproductionestimatededate | odsplm_bm_hbmtprojectkpi.hbmtpproductionestimatededate | 直接映射 |
| hbmtpproductionactualedate | odsplm_bm_hbmtprojectkpi.hbmtpproductionactualedate | 直接映射 |
| hold_days | odsplm_bm_hbmtprojectadjust.releasedate | SUM(恢复日-暂停日)，暂停单(HBMTProjectHoldRequest)+恢复单(HBMTProjectResumeRequest)按LEAD窗口函数配对计算 |
| dev_cycle_days | 计算字段 | DATEDIFF(hbmtpproductionactualedate, hbmtprojectcreatedate) - COALESCE(hold_days, 0) |

### ADS层：ads.ads_ipd_ipd_project_dev_cycle_result_dd

**架构说明**：采用维度骨架模式（dim_combinations），硬编码所有事业部(光模块/终端)×类型分组(PA/PB/PC/平均)×时间类型(当月/年累)的全组合，LEFT JOIN实际数据，确保无数据时也输出完整维度行（project_count=0）。

| 目标字段 | 源表.源字段 | 转换逻辑 |
|----------|------------|----------|
| dt_month | 调度参数 | DATE_FORMAT('${GP_START_DT}', '%Y%m') |
| hbmtpproductline | dim_combinations（硬编码：光模块/终端） | 维度骨架驱动，非数据驱动 |
| derive_type_group | dim_combinations（硬编码：PA/PB/PC/平均） | 维度骨架驱动，非数据驱动 |
| dt_type | dim_combinations（硬编码：当月/年累） | 维度骨架驱动 |
| project_count | dws记录 / actual_data | COALESCE(ad.project_count, 0)；无数据时为0 |
| avg_dev_cycle | dws.dev_cycle_days / actual_data | AVG(按分组)，ROUND(,1)；"平均"行=CASE WHEN SUM(count)>0 THEN SUM(avg*count)/SUM(count) ELSE NULL END |
| target_value | 飞书表.record_data | JSON解析：$.目标值[0].text，CAST为DECIMAL(10,1)，按年份+事业部+类型匹配 |
| completion_rate | 计算字段 | avg_dev_cycle IS NOT NULL AND target_value IS NOT NULL AND !=0时：ROUND(2 - avg_dev_cycle/target_value, 4)，否则NULL |
| last_year_value | ads.ads_ipd_ipd_project_dev_cycle_result_dd（自引用）.avg_dev_cycle | 直接取去年同月已计算结果，ROUND(,1)，按事业部×类型×dt_type匹配 |
| yoy_improvement | 计算字段 | avg_dev_cycle IS NOT NULL AND last_year_value IS NOT NULL AND !=0时：ROUND(1 - avg_dev_cycle/last_year_value, 4)，否则NULL |
| load_dt | 系统函数 | NOW() |

## 变更记录

| 日期 | 变更内容 |
|------|----------|
| 2026-07-02 | 初始版本 |
| 2026-07-02 | ADS同期值来源变更：从DWS表重新计算改为直接读取ADS历史结果表（自引用），保证与历史结果一致且支持手工修正场景 |
| 2026-07-07 | DWS层新增product_line_category字段（光模块/终端分类）；hbmtpproductline改为事业部原值；derive_type_group去掉HW/FH分类；WHERE条件新增hbmtpproductline IN过滤、去掉HW%/FH%项目类型 |
| 2026-07-07 | DWS层合并字段：删除product_line_category，hbmtpproductline直接输出CASE映射结果（光模块/终端），不再保留事业部原值 |
| 2026-07-16 | ADS层重构：新增dim_combinations维度骨架CTE（硬编码事业部×类型×时间全组合），改为骨架驱动LEFT JOIN实际数据，确保无数据维度也输出行（project_count=0）；derive_type_group精简为PA/PB/PC/平均；completion_rate和yoy_improvement增加avg_dev_cycle非空判断 |
| 2026-07-16 | ADS层dim_combinations事业部维度值修正：'光模块事业部'→'光模块'，与DWS层hbmtpproductline输出值对齐 |
