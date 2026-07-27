# 需求文档 - 单平台销量

## 当前状态速查（最后同步：changelog #005, 2026-06-08）

### 覆盖范围
| 维度 | 当前值 |
|------|--------|
| 内销产品线 | 冰箱、冷柜、洗衣机、家用空调（家空+轻商）、平板电视、中央空调（日立）、厨电、激光 |
| 外销产品线 | 冰箱、冷柜、洗衣机、家用空调、平板电视、厨电、激光 |
| 计算公式 | 总销量/销额 ÷ 平台数 |
| 统计口径 | 月度 + 年累 |
| 应用公共规则 | PUB-003, PUB-004, PUB-006, PUB-008 |
| 依赖 | 006-platform-count（平台数提供分母）、007-single-model-sales（销量提供分子） |

### 脚本清单
| 脚本 | 分层 | 说明 |
|------|------|------|
| dws_ipd_ipm_dptxl_detail_dd.sql | DWS | 单平台销量明细（全产品线） |
| ads_ipd_ipm_dptxl_result_dd.sql | ADS | 单平台销量汇总 |
| validate_data_quality.sql | 检查 | 数据质量验证 |

### 文档同步状态
- 主体部分覆盖到：冰箱/冷柜/洗衣机/空调/电视/日立（初始6条）
- 激光扩展见：changelog #004~#005
- 详细变更历史见：changelog.md

## 基本信息
- **需求ID**: 008-single-platform-sales
- **创建日期**: 2026-04-29
- **创建人**: ETL智能辅助工具
- **业务部门**: 集团IPD/各事业部（冰冷、洗护、空气、显示）
- **优先级**: 高
- **状态**: 已完成开发
- **数据仓库分层**: DWS → ADS

## 业务背景
集团需要按月监控各事业部的单平台平均销量和单平台平均销额。单平台销量 = 总销量 / 平台数，反映每个平台的平均销售效率，是衡量平台投资回报的核心指标。

### 核心逻辑
- **单平台销量**：总销量 / 平台数，月度和年累两种口径
- **单平台销额**：总销额 / 平台数，月度和年累两种口径
- **DWS层**：从单型号销量明细（dws_ipd_ipm_dxhxl_detail_dd）关联平台信息，生成单平台销量明细
- **ADS层**：汇总销量/销额，除以平台数结果（ads_ipd_ipm_platform_result_dd），得到单平台销量/销额
- **内销数据来源**：管报数据（通过单型号销量明细获取）
- **外销数据来源**：sellin全量数据（dws.dws_ipd_ipm_sales_detail_mid_dd）
- **日立**：通过日立管报（odsmr_v_hitach_ykfpmxb）获取销量/销额/成本/毛利率

## 涉及数据表

### 源表（读取）
- `dws.dws_ipd_ipm_dxhxl_detail_dd` — 单型号销量明细（内销管报数据）
- `dws.dws_ipd_ipm_platform_detail_dd` — 产品平台数明细（日立平台关联）
- `dws.dws_ipd_ipm_sales_detail_mid_dd` — 销量数据过渡表（外销sellin数据）
- `dws.dws_ipd_ipm_dptxl_detail_dd` — 单平台销量明细（自引用）
- `ads.ads_ipd_ipm_platform_result_dd` — 产品平台数结果（提供平台数）
- `ads.ads_ipd_ipm_platform_library_result_dd` — 平台库结果（平台库口径）
- `dim.dim_ipd_td_weidu_nd` — 指标维度配置
- `dw.dim_date_nd` — 日期维度
- `ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU` — 飞书计划值
- `ods.odsmr_v_hitach_ykfpmxb` — 日立管报数据

### 目标表（写入）
- `dws.dws_ipd_ipm_dptxl_detail_dd` — 单平台销量明细表（DWS层）
- `ads.ads_ipd_ipm_dptxl_result_dd` — 单平台销量结果表（ADS层）

## 数据流程
```
dws.dws_ipd_ipm_dxhxl_detail_dd (单型号销量明细)
dws.dws_ipd_ipm_platform_detail_dd (产品平台数明细)
         ↓
dws.dws_ipd_ipm_dptxl_detail_dd (单平台销量明细：平台+销量+销额)
         ↓
ads.ads_ipd_ipm_dptxl_result_dd (单平台销量结果：总销量/平台数)
  ← ads.ads_ipd_ipm_platform_result_dd (平台数)
  ← 飞书计划值
```

## 关键指标
- `sales_qty` — 实际销量
- `sales_amt` — 实际销额
- `platform_num` — 平台数
- `sum_qty` — 销量汇总
- `dptxl` — 单平台销量 = sum_qty / platform_num
- `dptxe` — 单平台销额 = sum_amt / platform_num
- `plan_dptxl` — 单平台销量计划值
- `completion_rate_dptxl` — 单平台销量完成率

## 业务规则

### 本指标专属规则
- **单平台销量公式**：总销量 / 平台数（月度和年累两种口径）
- **单平台销额公式**：总销额 / 平台数（月度和年累两种口径）
- **明细同步保护期**：单平台销量明细同步在产型号数和平台数的保护期逻辑
- **冰冷洗内销剔除代工**：剔除非海信自有工厂代工产品
- **洗衣机剔除无效平台**：剔除平台为"其他"的型号
- **视像科技剔除无效平台**：剔除平台为"不涉及"的型号
- **空调内销双平台维度**：取室内箱体和室外箱体两个维度的平台
- **日立销量来源**：通过日立管报（odsmr_v_hitach_ykfpmxb）获取销量/销额/成本/毛利率
- **出口额外剔除**：冰冷出口剔除全散件
- **集团汇总**：各事业部加总
- **完成率**：实际值 / 计划值

### 引用公共规则（详见 .kiro/steering/business_rules.md）
- **PUB-003**：产品线分类规则-冰冷洗
- **PUB-004**：日立管理口径规则
- **PUB-006**：空调产品线分类规则

## 验收标准
- [x] DWS层：各产品线单平台销量明细正确计算
- [x] ADS层：月度单平台销量/销额正确计算
- [x] ADS层：年累口径正确计算
- [x] 日立单平台销量正确计算
- [x] 集团汇总正确加总

## 相关文档
- 表清单：tables.txt
- SQL脚本：sql_scripts/
- 血缘关系：lineage.md

## 变更记录
| 日期 | 版本 | 变更描述 | 变更人 |
|------|------|----------|--------|
| 2026-04-29 | 1.0 | 初始版本（从已有脚本录入） | ETL智能辅助工具 |
