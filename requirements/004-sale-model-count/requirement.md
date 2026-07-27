# 需求文档 - 在销型号数

## 当前状态速查（最后同步：changelog #010, 2026-06-25）

### 覆盖范围
| 维度 | 当前值 |
|------|--------|
| 内销产品线 | 冰箱、冷柜、洗衣机、家用空调（家空+轻商）、平板电视、中央空调（日立）、厨电、激光家用、激光商用 |
| 外销产品线 | 冰箱、冷柜、洗衣机、家用空调、平板电视、厨电、激光 |
| 实际销量来源 | 不涉及（本指标不计算销量） |
| 库存来源（内销） | 大库龄明细+营销产成品寄售 |
| 库存来源（外销） | 海外分公司+基地+在途库存 |
| 应用公共规则 | PUB-001, PUB-003, PUB-004, PUB-006, PUB-007, PUB-008 |

### 脚本清单
| 脚本 | 分层 | 说明 |
|------|------|------|
| dws_ipd_ipm_sale_model_detail_dd.sql | DWS | 在销型号明细（全产品线） |
| ads_ipd_ipm_sale_model_result_dd.sql | ADS | 在销型号数汇总 |
| validate_data_quality.sql | 检查 | 数据质量验证 |

### 文档同步状态
- 主体部分覆盖到：冰箱/冷柜/洗衣机/空调/电视/日立（初始6条）
- 厨电扩展见：changelog #004~#007
- 激光扩展见：changelog #008~#009
- 详细变更历史见：changelog.md

## 基本信息
- **需求ID**: 004-sale-model-count
- **创建日期**: 2026-04-29
- **创建人**: ETL智能辅助工具
- **业务部门**: 集团IPD/各事业部（冰冷、洗护、空气、显示）
- **优先级**: 高
- **状态**: 已完成开发
- **数据仓库分层**: DWS → ADS

## 业务背景
集团需要按月监控各事业部（冰冷、洗护、空气、显示）的在销型号数量。在销型号数反映当前市场上正在销售的产品型号规模，是衡量产品组合丰富度和市场覆盖能力的核心指标。

### 核心逻辑
- **在销型号判定**：产品型号处于"在产"阶段（上市、退市准备、停止下单），且未处于保护期（is_project = 'N'）
- **冰冷洗**：以产品型号口径统计，区分内销/外销，排除gorenje品牌、ODM产品、标机/样机（外销）
- **空调**：区分家用空调（含轻商）和中央空调（日立以销售型号口径），排除环境电器、OEM品牌
- **中央空调双口径**：集团口径（is_project，原7个小类）+ 内控口径（is_project_nk，14个小类+空气调节类配件），内控范围更广
- **视像科技**：以产品型号口径统计，内销通过生产版本关联，外销通过JTPLM关联
- **库存清零判定**：退市型号库存为0则标记为"老品清零"，不纳入在销范围
- **ADS层汇总**：按公司/产品线/内外销维度聚合在销型号数，支持"全部"维度

## 涉及数据表

### 源表（读取）
- `dim.dim_ipd_productmodel_dd` — 白电产品型号基础信息（型号生命周期、上市时间、品牌等）
- `dim.dim_ipd_productionversion_dd` — 生产版本基础信息（BOM编码）
- `dim.dim_ipd_jtplm_his_productversion_dd` — 视像科技生产版本（电视型号信息）
- `dim.dim_ipd_tv_new_oldmodel_nd` — 电视新旧型号映射
- `dim.dim_ipd_salemodel_dd` — 白电销售型号基础信息（日立口径）
- `dw.dim_product_base_info_dd` — MDG产品主数据（物料→型号映射）
- `dws.dws_fi_mr_bxp_dklmx_di` — 冰箱大库龄明细（库存数据）
- `dws.dws_fi_mr_bxp_yxccpmx_all_di` — 冰箱营销产成品明细（寄售库存）
- `dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd` — 海外分公司库存
- `dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd` — 基地库存
- `dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd` — 在途库存
- `test.dwfi_fa_tf_acp_prostockdetail` — 空调自有库存
- `ods.odss900_mchb` / `ods.odss900_mchbh` — OEM库存
- `dws.dws_ipd_ipm_sale_model_detail_dd` — 在销型号明细（自引用，历史数据）
- `dws.dws_ipd_ipm_salemodelid_dd` — 销售型号ID明细

### 目标表（写入）
- `dws.dws_ipd_ipm_sale_model_detail_dd` — 在销型号明细表（DWS层）
- `ads.ads_ipd_ipm_sale_model_result_dd` — 在销型号数结果表（ADS层）

## 数据流程
```
dim.dim_ipd_productmodel_dd (产品型号基础信息)
dim.dim_ipd_salemodel_dd (销售型号基础信息)
库存数据（多源：大库龄/寄售/海外/基地/在途/空调自有/OEM）
         ↓
dws.dws_ipd_ipm_sale_model_detail_dd (在销型号明细：型号+库存+生命周期判定)
         ↓
ads.ads_ipd_ipm_sale_model_result_dd (在销型号数结果：按公司/产品线/内外销汇总)
```

## 关键指标
- `model` — 产品型号名称
- `model_label_10` — 型号阶段（在产/老品/老品清零/未上市）
- `model_label_16` — 在销型号数范围（is_zhibiaofanwei）
- `is_project` — 是否保护期（Y=不纳入统计，N=纳入统计）
- `inventory_qty` — 库存数量
- `act_num` — 在销型号数（ADS层汇总值）

## 业务规则

### 本指标专属规则
- **在销型号判定**：产品型号生命周期状态为"上市/退市准备/停止下单"视为在产阶段，纳入在销范围
- **外销剔除标机、样机**：外销型号中"是否标机"或"是否样机"为"是"的剔除
- **外销剔除CKD全散件**：销售大区为欧洲/美洲且出口方式为CKD的型号剔除
- **视像科技排除代工产品**：is_daigong = '是' 的型号剔除
- **ADS层汇总维度**：支持按公司/产品线/内外销聚合，同时生成"全部"维度的汇总行

### 引用公共规则（详见 .kiro/steering/business_rules.md）
- **PUB-001**：保护期规则（上市3个月内不考核）
- **PUB-003**：产品线分类规则-冰冷洗（gorenje品牌剔除、ODM剔除）
- **PUB-004**：日立管理口径规则（销售型号编码口径、排除非标准品/委外/模块组合）
- **PUB-006**：空调产品线分类规则（排除环境电器、轻商单元式内外机去重）
- **PUB-007**：库存清零判定规则（退市+库存为0→老品清零）

## 验收标准
- [x] DWS层：各产品线在销型号明细正确计算
- [x] DWS层：库存清零逻辑正确执行
- [x] ADS层：在销型号数按公司/产品线/内外销正确汇总
- [x] 日立以销售型号口径正确统计
- [x] 保护期规则正确执行

## 相关文档
- 表清单：tables.txt
- SQL脚本：sql_scripts/
- 血缘关系：lineage.md

## 变更记录
| 日期 | 版本 | 变更描述 | 变更人 |
|------|------|----------|--------|
| 2026-04-29 | 1.0 | 初始版本（从已有脚本录入） | ETL智能辅助工具 |
