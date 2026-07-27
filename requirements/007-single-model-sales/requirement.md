# 需求文档 - 单型号销量

## 当前状态速查（最后同步：changelog #005, 2026-06-08）

### 覆盖范围
| 维度 | 当前值 |
|------|--------|
| 内销产品线 | 冰箱、冷柜、洗衣机、家用空调（家空+轻商）、平板电视、中央空调（日立）、厨电、激光 |
| 外销产品线 | 冰箱、冷柜、洗衣机、家用空调、平板电视、厨电、激光 |
| 实际销量来源（内销） | 管报（含能效机转换PUB-005） |
| 实际销量来源（外销） | sellin全量（dws_ipd_ipm_sales_detail_mid_dd） |
| 统计口径 | 近3月滚动 + 年累 |
| 应用公共规则 | PUB-003, PUB-004, PUB-005, PUB-006, PUB-008 |
| 依赖 | 004-sale-model-count（在销型号数提供型号范围） |

### 脚本清单
| 脚本 | 分层 | 说明 |
|------|------|------|
| dws_ipd_ipm_dxhxl_detail_dd.sql | DWS | 单型号销量明细（全产品线） |
| ads_ipd_ipm_dxhxl_result_dd.sql | ADS | 单型号销量汇总 |
| validate_data_quality.sql | 检查 | 数据质量验证 |

### 文档同步状态
- 主体部分覆盖到：冰箱/冷柜/洗衣机/空调/电视/日立（初始6条）
- 激光扩展见：changelog #004~#005
- 详细变更历史见：changelog.md

## 基本信息
- **需求ID**: 007-single-model-sales
- **创建日期**: 2026-04-29
- **创建人**: ETL智能辅助工具
- **业务部门**: 集团IPD/各事业部（冰冷、洗护、空气、显示）
- **优先级**: 高
- **状态**: 已完成开发
- **数据仓库分层**: DWS → ADS

## 业务背景
集团需要按月监控各事业部的单型号平均销量和单型号平均销额。单型号销量 = 总销量 / 在销型号数，反映每个型号的平均销售效率，是衡量产品组合效率的核心指标。

### 核心逻辑
- **单型号销量**：总销量（近3个月累计）/ 在销型号数（近3个月累计），月度口径
- **单型号销额**：总销额（近3个月累计）/ 在销型号数（近3个月累计），月度口径
- **年累口径**：本年累计总销量 / 本年累计在销型号数
- **内销数据来源**：管报数据（ods.ods_mr_v_app_fm_imat_saledata）通过MDG映射到型号
- **外销数据来源**：sellin全量数据（dws.dws_ipd_ipm_sales_detail_mid_dd）
- **视像科技**：能效机销量转换为原型机统计
- **空调日立**：通过sale_model_name口径汇总

## 涉及数据表

### 源表（读取）
- `dws.dws_ipd_ipm_sale_model_detail_dd` — 在销型号明细（提供型号列表和保护期判定）
- `ods.ods_mr_v_app_fm_imat_saledata` — 管报数据（实际销量、收入、成本）
- `dw.dim_product_base_info_dd` — MDG产品主数据（物料→型号映射）
- `dim.dim_ipd_tv_model_nengxiao_nd` — 电视能效机型号映射
- `dws.dws_ipd_ipm_platform_detail_dd` — 产品平台数明细（判断型号是否有平台引用）
- `dws.dws_ipd_ipm_dxhxl_detail_dd` — 单型号销量明细（ADS层读取）
- `dws.dws_ipd_ipm_sales_detail_mid_dd` — 销量数据过渡表（外销sellin数据）
- `ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblT8dRgmsgrWu9c` — 飞书计划值

### 目标表（写入）
- `dws.dws_ipd_ipm_dxhxl_detail_dd` — 单型号销量明细表（DWS层）
- `ads.ads_ipd_ipm_dxhxl_result_dd` — 单型号销量结果表（ADS层）

## 数据流程
```
dws.dws_ipd_ipm_sale_model_detail_dd (在销型号明细)
ods.ods_mr_v_app_fm_imat_saledata (管报实际销量)
dw.dim_product_base_info_dd (MDG桥梁：物料→型号映射)
         ↓
dws.dws_ipd_ipm_dxhxl_detail_dd (单型号销量明细：型号+销量+销额)
         ↓
ads.ads_ipd_ipm_dxhxl_result_dd (单型号销量结果：近3月平均/年累)
```

## 关键指标
- `sales_qty` — 实际销量
- `sales_amt` — 实际销额
- `act_cost` — 实际成本
- `act_gross_profit` — 实际毛利
- `model_num` — 型号数
- `sum_qty` — 销量汇总
- `dxhxl` — 单型号销量 = sum_qty / model_num
- `dxhxe` — 单型号销额 = sum_amt / model_num
- `plan_dxhxl` — 单型号销量计划值
- `completion_rate_dxhxl` — 单型号销量完成率

## 业务规则

### 本指标专属规则
- **月度口径**：近3个月滚动平均（总销量/在销型号数）
- **年累口径**：本年1月至当月累计
- **内销取管报数据**：通过MDG映射物料→型号后汇总
- **外销取sellin全量数据**：从销量数据过渡表获取
- **冰冷洗剔除ODM产品**：通过model_label_4判断是否海信工厂
- **集团汇总**：各事业部加总
- **完成率**：实际值 / 计划值

### 引用公共规则（详见 .kiro/steering/business_rules.md）
- **PUB-003**：产品线分类规则-冰冷洗
- **PUB-004**：日立管理口径规则（通过sale_model_name口径汇总）
- **PUB-005**：电视能效机转换规则（能效机销量转换为原型机）
- **PUB-006**：空调产品线分类规则

## 验收标准
- [x] DWS层：各产品线单型号销量明细正确计算
- [x] ADS层：月度近3月平均正确计算
- [x] ADS层：年累口径正确计算
- [x] 集团汇总正确加总

## 相关文档
- 表清单：tables.txt
- SQL脚本：sql_scripts/
- 血缘关系：lineage.md

## 变更记录
| 日期 | 版本 | 变更描述 | 变更人 |
|------|------|----------|--------|
| 2026-04-29 | 1.0 | 初始版本（从已有脚本录入） | ETL智能辅助工具 |
