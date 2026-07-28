---
inclusion: always
---
# 需求模式库（自学习）

## 概述
本文件记录已完成需求的"模式签名"，用于新需求进来时快速匹配相似历史需求，加速分析。
**自学习规则**：每次需求完成后，Agent自动将新模式追加到本文件末尾。

## 模式匹配规则

### 匹配流程
```
新需求关键词 → 与模式库逐条比对 → 关键词重叠度≥60% → 命中模式 → 参考历史需求
```

### 匹配后行为
- **命中模式**：直接参考历史需求的表组合、分层、规则，跳过部分分析步骤
- **未命中**：走完整分析流程（关键词提取→表匹配→分层识别）
- **部分命中**：参考历史但仍需澄清差异部分

## 已有模式

### PAT-001：低效型号占比与新品命中率
| 字段 | 值 |
|------|-----|
| 触发关键词 | 低效、型号、占比、命中率、规划量、BP、LX |
| 涉及表 | `ods.ods_mr_v_app_fm_imat_saledata` + `dw.dim_product_base_info_dd` + `dim.dim_ipd_productmodel_dd` + `dim.dim_ipd_salemodel_dd` + `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd` + GSS外销订单表（PUB-010） |
| 分层路径 | DWD → DWS → ADS |
| 应用规则 | PUB-001, PUB-002, PUB-003, PUB-004, PUB-005, PUB-006, PUB-008, PUB-009, PUB-010 |
| 复杂度 | 复杂（多产品线、双口径、保护期、内外销） |
| 参考需求 | 002-dx-model-rate |
| 创建时间 | 2026-04-23 |
| 最后命中时间 | 2026-06-13 |

### PAT-002：企划命中率
| 字段 | 值 |
|------|-----|
| 触发关键词 | 企划、命中率、项目、阶段、达标、红黑榜、央空、日立 |
| 涉及表 | `dim.dim_ipd_salemodel_dd` + `dim.dim_ipd_productmodel_dd` + `ods.ods_mr_v_app_fm_imat_saledata` + `dw.dim_product_base_info_dd` |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-004（日立口径）, PUB-008 |
| 复杂度 | 复杂（7阶段判定、滑动窗口、近12月固定窗口、项目维度聚合、stage_calc集中判定） |
| 参考需求 | 003-qihua-hit-rate |
| 创建时间 | 2026-04-29 |
| 最后命中时间 | 2026-06-18 |

### PAT-003：在销型号数
| 字段 | 值 |
|------|-----|
| 触发关键词 | 在销、型号数、生命周期、库存、清零 |
| 涉及表 | `dim.dim_ipd_productmodel_dd` + `dim.dim_ipd_salemodel_dd` + 库存多源表 + `dw.dim_product_base_info_dd` |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-001, PUB-003, PUB-004, PUB-006, PUB-007, PUB-008 |
| 复杂度 | 复杂（多产品线、库存清零、多源库存） |
| 参考需求 | 004-sale-model-count |
| 创建时间 | 2026-04-29 |
| 最后命中时间 | 2026-06-25 |

### PAT-004：在产型号数
| 字段 | 值 |
|------|-----|
| 触发关键词 | 在产、型号数、代工、生产基地 |
| 涉及表 | `dws.dws_ipd_ipm_sale_model_detail_dd`（筛选在产） |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-001, PUB-003, PUB-006, PUB-008 |
| 复杂度 | 中等（从在销筛选+代工剔除） |
| 参考需求 | 005-zcmodel-count |
| 依赖 | PAT-003（在销型号数） |
| 创建时间 | 2026-04-29 |
| 最后命中时间 | 2026-06-08 |

### PAT-005：平台数
| 字段 | 值 |
|------|-----|
| 触发关键词 | 平台、平台数、平台库、HDRP、JTPLM、RDM、PLM |
| 涉及表 | `dim.dim_ipd_productplatform_dd` + `dws.dws_ipd_ipm_zcmodel_detail_dd` + 平台源系统表 |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-003, PUB-004, PUB-006, PUB-008 |
| 复杂度 | 复杂（4个平台源系统、双维度：平台库+产品平台） |
| 参考需求 | 006-platform-count |
| 依赖 | PAT-004（在产型号数） |
| 创建时间 | 2026-04-29 |
| 最后命中时间 | 2026-06-08 |

### PAT-006：单型号销量
| 字段 | 值 |
|------|-----|
| 触发关键词 | 单型号、销量、销额、平均销量 |
| 涉及表 | `dws.dws_ipd_ipm_sale_model_detail_dd` + `ods.ods_mr_v_app_fm_imat_saledata` + `dw.dim_product_base_info_dd` + `dim.dim_ipd_tv_model_nengxiao_nd` |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-003, PUB-004, PUB-005, PUB-006, PUB-008 |
| 复杂度 | 中等（近3月滚动+年累两种口径） |
| 参考需求 | 007-single-model-sales |
| 依赖 | PAT-003（在销型号数提供分母） |
| 创建时间 | 2026-04-29 |
| 最后命中时间 | 2026-06-08 |

### PAT-007：单平台销量
| 字段 | 值 |
|------|-----|
| 触发关键词 | 单平台、平台销量、平台销额 |
| 涉及表 | `dws.dws_ipd_ipm_dxhxl_detail_dd` + `dws.dws_ipd_ipm_platform_detail_dd` + `ads.ads_ipd_ipm_platform_result_dd` |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-003, PUB-004, PUB-006, PUB-008 |
| 复杂度 | 中等（总销量/平台数，月度+年累） |
| 参考需求 | 008-single-platform-sales |
| 依赖 | PAT-005（平台数提供分母）、PAT-006（单型号销量提供销量） |
| 创建时间 | 2026-04-29 |
| 最后命中时间 | 2026-06-08 |

### PAT-008：设计变更明细汇总统计
| 字段 | 值 |
|------|-----|
| 触发关键词 | 设计变更、变更明细、MCO、MCA、ECO、实施率、变更原因、变更阶段、工艺评估、采购评估、生效日、IRS |
| 涉及表 | ads.ads_ipd_irs_design_change_kccl_dd |
| 分层路径 | ADS（直接查询，无需建表） |
| 应用规则 | 无公共规则（独立业务域） |
| 复杂度 | 中等（单表多维度统计，10张报表，涉及时间转换和超期判断） |
| 参考需求 | 009-design-change-stats |
| 依赖 | 无 |
| 创建时间 | 2026-05-15 |
| 最后命中时间 | 2026-05-15 |

### PAT-009：外销新品规划命中率
| 字段 | 值 |
|------|-----|
| 触发关键词 | 外销、新品命中率、GSS、协议订单、规划命中、外销实际销量 |
| 涉及表 | `dim.dim_ipd_productmodel_dd` + `dim.dim_ipd_jtplm_his_productmodel_dd` + `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd` + GSS外销订单表（PUB-010各子规则） |
| 分层路径 | DWD → DWS |
| 应用规则 | PUB-001, PUB-003, PUB-006, PUB-008, PUB-009（空调）, PUB-010（非空调） |
| 复杂度 | 复杂（7条产品线、4种GSS数据源、各产品线剔除条件不同、空调内外机转换） |
| 参考需求 | 002-dx-model-rate（外销脚本dws_ipd_ipm_dxmodel_detail_dd_wx.sql） |
| 依赖 | PAT-001（共用DWD层BP/LX中间表和DWS目标表） |
| 创建时间 | 2026-06-08 |
| 最后命中时间 | 2026-06-08 |

## 模式追加模板

### PAT-010：应市项目平均开发周期
| 字段 | 值 |
|------|-----|
| 触发关键词 | 项目、开发周期、应市、PLM、暂停、恢复、鉴定、立项、事业部 |
| 涉及表 | `odsplm_bm_hbmtprojectkpi` + `odsplm_bm_hbmtprojectadjust` + 飞书目标值表 |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-008 |
| 复杂度 | 中等（暂停配对计算、JSON解析、当月+年累双口径） |
| 参考需求 | 011-project-dev-cycle |
| 依赖 | 无 |
| 创建时间 | 2026-07-02 |
| 最后命中时间 | 2026-07-02 |

### PAT-011：应市项目按计划实施率
| 字段 | 值 |
|------|-----|
| 触发关键词 | 项目、实施率、按计划、延期、结题、暂停、终止、工作日、PLM、事业部 |
| 涉及表 | `odsplm_bm_hbmtprojectkpi` + `odsplm_bm_hbmtprojectadjust` + `ods.odsrdm_holiday` |
| 分层路径 | DWS → ADS |
| 应用规则 | PUB-008 |
| 复杂度 | 中等（5种状态判定、工作日+3计算、多维度聚合） |
| 参考需求 | 012-project-impl-rate |
| 依赖 | 无（与PAT-010共用PLM数据源，但逻辑独立） |
| 创建时间 | 2026-07-08 |
| 最后命中时间 | 2026-07-08 |

### PAT-012：奥维行业市场分析（中间表聚合）
| 字段 | 值 |
|------|-----|
| 触发关键词 | 奥维、行业分析、价格段、规格段、品牌占有率、市场份额、中间表、AI使用、聚合表 |
| 涉及表 | `ads.ads_ipd_ipm_aowei_wd` + `dim.dim_ipd_ipm_aw_price_segment_dd` + `dim.dim_ipd_ipm_aw_spec_segment_dd` |
| 分层路径 | ADS（从已有ADS表再聚合） |
| 应用规则 | PUB-008 |
| 复杂度 | 复杂（7张独立表、2模块递进、全市场/筛选品牌交替、指标行格式） |
| 参考需求 | 013-aowei-market-analysis |
| 依赖 | 010-aowei-data-processing（上游数据源） |
| 创建时间 | 2026-07-08 |
| 最后命中时间 | 2026-07-08 |

## 模式追加模板

新需求完成后，按以下格式追加：
```
### PAT-0XX：[指标名称]
| 字段 | 值 |
|------|-----|
| 触发关键词 | [关键词列表] |
| 涉及表 | [表组合] |
| 分层路径 | [分层] |
| 应用规则 | [PUB-XXX列表] |
| 复杂度 | [简单/中等/复杂] |
| 参考需求 | [需求ID] |
| 依赖 | [依赖的其他模式，无则留空] |
| 创建时间 | [YYYY-MM-DD] |
| 最后命中时间 | [YYYY-MM-DD，初始=创建时间] |
```

## 模式库容量管理规则

- **容量阈值**：20条
- **阈值前**：所有模式均为active，不做清理
- **阈值后（总数≥20）**：开始按"最后命中时间"判定inactive
  - 最后命中时间距今 > 6个月 → 标记为 `inactive`
  - inactive模式不参与匹配，但保留在文件中（不删除）
  - 如果inactive模式被用户手动引用或再次命中 → 恢复为active，更新最后命中时间
- **每次模式匹配成功时**：更新该模式的"最后命中时间"为当天
- **注意**：容量阈值不是上限，模式库可以无限增长，阈值只是触发inactive判定的起点
