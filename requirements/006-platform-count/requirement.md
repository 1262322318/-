# 需求文档 - 平台数

## 当前状态速查（最后同步：changelog #005, 2026-06-08）

### 覆盖范围
| 维度 | 当前值 |
|------|--------|
| 内销产品线 | 冰箱、冷柜、洗衣机、家用空调（家空+轻商）、平板电视、中央空调（日立）、厨电、激光 |
| 外销产品线 | 冰箱、冷柜、洗衣机、家用空调、平板电视、厨电、激光 |
| 双维度 | 平台库（平台管理视角）+ 产品平台数（实际有机型使用的平台） |
| 平台源系统 | HDRP（白电）、JTPLM（视像+激光）、RDM（日立） |
| 应用公共规则 | PUB-003, PUB-004, PUB-006, PUB-008 |
| 依赖 | 005-zcmodel-count（在产型号数提供平台关联基础） |

### 脚本清单
| 脚本 | 分层 | 说明 |
|------|------|------|
| dws_ipd_ipm_platform_library_detail_dd.sql | DWS | 平台库明细 |
| dws_ipd_ipm_platform_detail_dd.sql | DWS | 产品平台数明细 |
| ads_ipd_ipm_platform_library_result_dd.sql | ADS | 平台库汇总 |
| ads_ipd_ipm_platform_result_dd.sql | ADS | 产品平台数汇总 |
| validate_data_quality.sql | 检查 | 数据质量验证 |

### 文档同步状态
- 主体部分覆盖到：冰箱/冷柜/洗衣机/空调/电视/日立（初始6条）
- 激光扩展见：changelog #004~#005
- 详细变更历史见：changelog.md

## 基本信息
- **需求ID**: 006-platform-count
- **创建日期**: 2026-04-29
- **创建人**: ETL智能辅助工具
- **业务部门**: 集团IPD/各事业部（冰冷、洗护、空气、日立、显示）
- **优先级**: 高
- **状态**: 已完成开发
- **数据仓库分层**: DWS → ADS

## 业务背景
集团需要按月监控各事业部的产品平台数量。平台数指标包含两个维度：
1. **平台库平台数**：从HDRP/JTPLM平台库中统计处于"发布"或"禁选"状态的平台数量，反映平台资产规模
2. **产品平台数**：从在产型号关联的平台中统计活跃平台数量，反映实际在用的平台规模

### 核心逻辑
- **平台库平台数**：从各系统平台库（HDRP白电平台、RDM空调平台、JTPLM视像平台、PLM日立平台）中提取平台信息，筛选发布/禁选状态
- **产品平台数**：从在产型号明细关联平台信息，统计有在产型号引用的平台数量
- **冰冷洗**：通过 `dim.dim_ipd_productplatform_dd` 获取平台库信息
- **空调**：通过 `ods.odsrdm_t_wf95_ext` 获取RDM平台库信息
- **视像科技**：通过 `ods.odsjtplm_his_productplatform` 获取JTPLM平台库信息
- **日立**：通过 `ods.odsplm_hac_plmproductplatform` 获取PLM平台库信息
- **ADS层汇总**：按公司/产品线/内外销维度聚合平台数，支持月度和年累两种口径

## 涉及数据表

### 源表（读取）
- `dim.dim_ipd_productplatform_dd` — 白电产品平台基础信息（冰冷洗平台库）
- `ods.odsrdm_t_wf95_ext` — RDM平台扩展信息（空调平台库）
- `ods.odsrdm_t_obj_baseitem` — RDM基础项（空调平台属性解码）
- `ods.odsjtplm_his_productplatform` — JTPLM产品平台（视像科技平台库）
- `ods.odsplm_hac_plmproductplatform` — PLM产品平台（日立平台库）
- `dim.dim_ipd_platform_library_class_name_nd` — 平台库产品线分类映射
- `dws.dws_ipd_ipm_zcmodel_detail_dd` — 在产型号明细（产品平台数关联）
- `dws.dws_ipd_ipm_platform_library_detail_dd` — 平台库明细（产品平台数关联）
- `dws.dws_ipd_ipm_platform_detail_dd` — 产品平台数明细（自引用）
- `dim.dim_ipd_jtplm_his_productversion_dd` — 视像科技生产版本
- `dim.dim_ipd_tv_new_oldmodel_nd` — 电视新旧型号映射
- `test.dwrdm_inzchmodel_kt` — 空调在产型号中间表
- `dwd.dwd_ipd_ipm_rlxhyptgx_dd` — 日立型号平台关系
- `ods.odsmdm_mat_bi_base_info` — MDM物料基础信息
- `dim.dim_ipd_td_weidu_nd` — 指标维度配置
- `dw.dim_date_nd` — 日期维度
- `ads.ads_ipd_ipm_platform_library_result_dd` — 平台库结果（产品平台数引用）
- `ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tblugJ2ghgEELtWU` — 飞书计划值

### 目标表（写入）
- `dws.dws_ipd_ipm_platform_library_detail_dd` — 平台库平台明细表（DWS层）
- `dws.dws_ipd_ipm_platform_detail_dd` — 产品平台数明细表（DWS层）
- `ads.ads_ipd_ipm_platform_library_result_dd` — 平台库平台结果表（ADS层）
- `ads.ads_ipd_ipm_platform_result_dd` — 产品平台数结果表（ADS层）
- `dws.dws_ipd_ipm_add_reduce_detail_dd` — 平台迁移退市明细（DWS层）
- `ads.ads_ipd_ipm_add_reduce_result_dd` — 平台迁移退市结果（ADS层）

## 数据流程
```
平台库数据源（HDRP/RDM/JTPLM/PLM）
         ↓
dws.dws_ipd_ipm_platform_library_detail_dd (平台库明细)
         ↓
ads.ads_ipd_ipm_platform_library_result_dd (平台库结果)

dws.dws_ipd_ipm_zcmodel_detail_dd (在产型号) + 平台库明细
         ↓
dws.dws_ipd_ipm_platform_detail_dd (产品平台数明细)
         ↓
ads.ads_ipd_ipm_platform_result_dd (产品平台数结果)
```

## 关键指标
- `platform` — 平台名称
- `platform_state` — 平台生命周期状态（创建/立项/开发/迁移/发布/禁选/停产/作废）
- `is_project` — 是否保护期（Y=不纳入统计，N=纳入统计）
- `act_value` — 平台数实际值
- `plan_value` — 平台数计划值
- `completion_rate` — 完成率

## 业务规则

### 本指标专属规则
- **平台库统计范围**：发布/禁选状态的平台纳入统计
- **冰箱欧产平台剔除**：is_eurp_product = 'Y' 的平台不纳入
- **外部代工专用平台剔除**：is_exclusive_only = 'Y' 的平台不纳入
- **外购平台剔除**：is_outsourcing = 'Y' 的平台不纳入
- **产品平台数逻辑**：在产型号引用的平台，排除代工专用平台
- **内外销交叉校验**：内销专用平台不计入外销统计，反之亦然
- **冰冷产品线交叉校验**：冰箱平台不计入冷柜统计，反之亦然
- **完成率公式**：2 - 实际值/计划值（平台数越少越好）
- **平台迁移退市**：记录平台状态变化（新增迁移/新增退市）

### 引用公共规则（详见 .kiro/steering/business_rules.md）
- **PUB-003**：产品线分类规则-冰冷洗
- **PUB-004**：日立管理口径规则（排除非标准品/委外/模块组合）
- **PUB-006**：空调产品线分类规则

## 验收标准
- [x] DWS层：各产品线平台库明细正确提取
- [x] DWS层：产品平台数明细正确关联
- [x] ADS层：平台库平台数按公司/产品线正确汇总
- [x] ADS层：产品平台数按公司/产品线/内外销正确汇总
- [x] 平台迁移退市逻辑正确执行

## 相关文档
- 表清单：tables.txt
- SQL脚本：sql_scripts/
- 血缘关系：lineage.md

## 变更记录
| 日期 | 版本 | 变更描述 | 变更人 |
|------|------|----------|--------|
| 2026-04-29 | 1.0 | 初始版本（从已有脚本录入） | ETL智能辅助工具 |
