---
inclusion: always
---
# 领域数据表映射库

## 概述

本文档记录当前领域下现有数据对应的表、关键词映射和表间关联规则。详细的表结构和字段说明见 `表规则以及信息.md`。

## 表间关联关系总览

| 关联路径 | 左表字段 | 右表字段 | 说明 |
|----------|----------|----------|------|
| 销售型号 ↔ 产品型号 | `dim.dim_ipd_salemodel_dd.PRODUCTMODEL_ID` | `dim.dim_ipd_productmodel_dd.ID` | 销售型号归属产品型号 |
| 管报数据 ↔ MDG主数据 | `ods.ods_mr_v_app_fm_imat_saledata.matnr` | `dw.dim_product_base_info_dd.product_code` | 物料编码关联产品主数据 |
| MDG主数据（桥梁） | `dw.dim_product_base_info_dd.model_code` | — | 产品型号编码 |
| MDG主数据（桥梁） | `dw.dim_product_base_info_dd.sale_model_code` | — | 销售型号编码（日立口径） |
| BP规划 ↔ MDG主数据 | `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd.matnr` | `dw.dim_product_base_info_dd.product_code` | 物料编码关联 |
| BP规划 ↔ 销售型号 | `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd.salemodelcode` | `dim.dim_ipd_salemodel_dd.PG00068` | 销售型号编码关联 |
| 视像产品型号 ↔ 视像生产版本 | `dim.dim_ipd_jtplm_his_productmodel_dd.title` | `dim.dim_ipd_jtplm_his_productversion_dd.modelname` | 通过产品型号名称关联，用于获取生产版本上的产品线属性（his_pmdproductlinename） |

**注意**：
- `ods.ods_mr_v_app_fm_imat_saledata` 不与 `dim.dim_ipd_productmodel_dd` 直接关联
- 日立：通过 `dw.dim_product_base_info_dd` 将物料映射到 `sale_model_code`
- 其他产品线：通过 `dw.dim_product_base_info_dd` 将物料映射到 `model_name`

## 关键词→数据表映射

| 关键词 | 推荐表 | 关联字段 | 说明 |
|--------|--------|----------|------|
| 管报、销量、收入、成本、毛利率 | `ods.ods_mr_v_app_fm_imat_saledata` | — | 管报实际销量数据（主表） |
| 产品型号、白电产品型号、产品型号名称 | `dim.dim_ipd_productmodel_dd` | — | 白电产品型号基础信息 |
| 销售型号、销售型号编码、白电销售型号 | `dim.dim_ipd_salemodel_dd` | PRODUCTMODEL_ID→dim_ipd_productmodel_dd.ID | 白电销售型号基础信息 |
| MDG、主数据、物料、产品编码 | `dw.dim_product_base_info_dd` | product_code→ods管报.matnr | MDG产品主数据（桥梁表） |
| BP、立项、规划销量、规划销额 | `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd` | — | BP及立项规划销量分月数据 |
| 低效型号、低效型号占比 | `dws.dws_ipd_ipm_dxmodel_detail_dd` | — | 低效型号明细（DWS层） |
| 低效型号结果、新品命中率 | `ads.ads_ipd_ipm_dxmodel_result_dd` | — | 低效型号结果（ADS层） |
| 冰箱、冷柜、洗衣机、空调 | `dim.dim_ipd_productmodel_dd` | — | 通过PG00002/PG00003/PG00004分类 |
| 日立、中央空调 | `dim.dim_ipd_salemodel_dd` | — | 日立以销售型号编码为管理口径 |
| 研发指标、新增缩减 | `ads.ads_ipd_ipm_add_reduce_result_dd` | — | 研发指标新增缩减结果值（ADS层） |
| 研发指标明细 | `dws.dws_ipd_ipm_add_reduce_detail_dd` | — | 研发指标新增缩减明细（DWS层） |
| 单平台销量、单平台销额 | `ads.ads_ipd_ipm_dptxl_result_dd` | — | 单平台销量结果表（ADS层） |
| 单平台销量明细 | `dws.dws_ipd_ipm_dptxl_detail_dd` | — | 单平台销量明细表（DWS层） |
| 平台库、平台结果 | `ads.ads_ipd_ipm_platform_library_result_dd` | — | 平台库平台结果表（ADS层） |
| 平台库明细 | `dws.dws_ipd_ipm_platform_library_detail_dd` | — | 平台库平台明细表（DWS层） |
| 产品平台数 | `ads.ads_ipd_ipm_platform_result_dd` | — | 产品平台数结果表（ADS层） |
| 产品平台数明细 | `dws.dws_ipd_ipm_platform_detail_dd` | — | 产品平台数明细表（DWS层） |
| 在销型号数 | `ads.ads_ipd_ipm_sale_model_result_dd` | — | 在销型号数结果表（ADS层） |
| 在销型号明细 | `dws.dws_ipd_ipm_sale_model_detail_dd` | — | 在销型号数明细表（DWS层） |
| 在产型号数 | `ads.ads_ipd_ipm_zcmodel_result_dd` | — | 在产型号数结果表（ADS层） |
| 在产型号明细 | `dws.dws_ipd_ipm_zcmodel_detail_dd` | — | 在产型号数明细表（DWS层） |
| 中高端、型号数占比 | `ads.ads_ipd_ipm_zgd_model_dd` | — | 中高端型号数占比（ADS层） |
| 单型号销量 | `dws.dws_ipd_ipm_dxhxl_detail_dd` | — | 单型号销量明细表（DWS层） |
| 销量数据过渡 | `dws.dws_ipd_ipm_sales_detail_mid_dd` | — | 销量数据过渡表（DWS层，内部中间表，被单型号销量等引用） |
| 日期维度、日历、年月、季度 | `dw.dim_date_nd` | — | 日期维度主表（DIM层，通用维度，按需关联） |
| 产品平台、白电平台 | `dim.dim_ipd_productplatform_dd` | — | 白电产品平台基础信息表（DIM层） |
| 生产版本 | `dim.dim_ipd_productionversion_dd` | — | 生产版本基础信息表（DIM层） |
| 视像科技、电视生产版本 | `dim.dim_ipd_jtplm_his_productversion_dd` | — | 视像科技生产版本表（DIM层） |
| 能效机、电视型号映射 | `dim.dim_ipd_tv_model_nengxiao_nd` | — | 视像科技能效机对应关系（DIM层） |
| 设计变更、库存处理意见、MCO、MCA、ECO、kccl、IRS、变更类型 | `ads.ads_ipd_irs_design_change_kccl_dd` | — | 设计变更库存处理意见结果表，按flag字段区分4种场景：1=设计变更报表/2=+MCA/3=+MCO/4=+kccl（ADS层，全量刷新） |
| 视像科技产品型号、集团PLM产品型号、电视产品型号、JTPLM产品型号 | `dim.dim_ipd_jtplm_his_productmodel_dd` | — | 视像科技产品线产品型号基础信息（集团PLM，含屏幕尺寸/平台/生命周期等）。注意：白电产品型号用 `dim.dim_ipd_productmodel_dd`，视像科技专用本表 |
| GSS排产单、排产通知单、空调外销排产 | `ods.odsgss_im_sale_prod_header` + `ods.odsgss_im_sale_prod_line` + `ods.odsgss_im_sale_prod_kf_line` | prod_id关联，h_spec→dim_ipd_productmodel_dd.PG00061 | GSS系统排产单三表（头表+行表+开发行表），详见PUB-009 |
| 冰冷洗外销协议订单、GSS协议查询 | `ods.odsgss_im_order_agreement` + `ods.odsgss_im_rolling_plan_detail` + 产品对照表 | roll_plan_number关联，product_code→product_model | GSS冰冷洗外销协议订单发布量，详见PUB-010-A |
| 电视外销订单、GSS电视订单 | `ods.odsgss_im_sales_order_title` | PRODUCT_CODE→dim_product_base_info_dd.short_desc_zh | GSS电视外销订单量，详见PUB-010-B |
| 厨电外销协议订单、GSS厨电订单 | `ods.odsgss_im_cw_order_ledger` | export_type_no=出口型号 | GSS厨电外销协议订单量，详见PUB-010-C |
| 激光外销订单、GSS激光订单 | `ods.odsgss_im_jg_order` | model_code→dim_product_base_info_dd.short_desc_zh | GSS激光外销订单量，详见PUB-010-D |

## 核心关联SQL

### 通用：管报数据关联MDG主数据
```sql
SELECT s.yearmonth, s.matnr, s.sale_qty, s.rev_amt, s.cost_amt,
    p.model_name, p.sale_model_code, p.brand_name,
    p.big_class_name, p.mid_class_name, p.small_class_name
FROM ods.ods_mr_v_app_fm_imat_saledata s
LEFT JOIN dw.dim_product_base_info_dd p ON s.matnr = p.product_code
WHERE p.product_type_code IN ('FERT','ZTAO') AND p.delete_flag != 'Y';
```

### 日立专用：按销售型号编码汇总
```sql
SELECT t2.sale_model_code, SUM(t1.sale_qty) AS sale_qty, SUM(t1.rev_amt) AS rev_amt,
    SUM(t1.cost_amt) AS cost_amt, SUM(t1.rev_amt) - SUM(t1.cost_amt) AS gross_profit
FROM ods.ods_mr_v_app_fm_imat_saledata t1
LEFT JOIN (SELECT product_code, sale_model_code FROM dw.dim_product_base_info_dd
    WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y') t2
ON t1.matnr = t2.product_code
GROUP BY t2.sale_model_code;
```

### 产品型号关联销售型号
```sql
SELECT p.ID, p.PG00061 AS product_model_name, s.PG00068 AS sale_model_code, s.PG00061 AS sale_model_name
FROM dim.dim_ipd_productmodel_dd p
LEFT JOIN dim.dim_ipd_salemodel_dd s ON p.ID = s.PRODUCTMODEL_ID;
```

## 详细表结构参考

> 完整字段列表和类型信息通过 MCP postgres 查询获取（用 Q1，见 `.kiro/skills/etl-requirement/mcp-table-metadata.md` 契约）。
> 业务语义（用途、关联规则、使用场景）见 `table_structures.md`（Agent按需读取）。
> 本文件（data_mapping.md）为快速索引。

### ods.ods_mr_v_app_fm_imat_saledata 核心字段
| 字段 | 类型 | 说明 |
|------|------|------|
| yearmonth | varchar(6) | 统计年月（YYYYMM） |
| d_bg / desc_bg | varchar | 事业部编码/名称 |
| matnr | varchar(40) | 物料编码（核心关联字段→MDG.product_code） |
| zzprdmodel | varchar(120) | 型号名称 |
| sale_qty | decimal(38,9) | 销量 |
| rev_amt | decimal(38,9) | 收入 |
| cost_amt | decimal(38,9) | 成本 |

### dim.dim_ipd_productmodel_dd 核心字段
| 字段 | 类型 | 说明 |
|------|------|------|
| ID | varchar(300) | 唯一标识（关联salemodel_dd.PRODUCTMODEL_ID） |
| PG00061 | varchar(1500) | 产品型号名称 |
| PG00029 | varchar(1500) | 产品型号生命周期状态 |
| PG00025 | datetime | 实际上市时间 |
| HX00501 | datetime | 实际退市准备时间 |
| PG00005 | varchar(1500) | 品牌 |
| PG00002/PG00003/PG00004 | varchar(1500) | 产品大类/中类/小类 |
| PG00020 | varchar(1500) | 内销/外销 |
| PG00015 | varchar(1500) | 产品公司 |
| HX00506~HX00541 | decimal(20,4) | 第1~36个月规划销量（LX立项） |

### dim.dim_ipd_salemodel_dd 核心字段
| 字段 | 类型 | 说明 |
|------|------|------|
| ID | varchar(300) | 唯一标识 |
| PRODUCTMODEL_ID | varchar(300) | 产品型号ID（关联productmodel_dd.ID） |
| PG00068 | varchar(300) | 销售型号编码 |
| PG00061 | varchar(300) | 销售型号名称 |
| PG00057 | varchar(300) | 销售型号生命周期状态 |
| PG00025 | datetime | 实际上市时间 |
| PG00069 | varchar(300) | 销售品牌 |
| PC20080 | varchar(300) | 归属营销部 |
| HX00379 | varchar(300) | 是否模块组合 |
| HX00020 | decimal(20,4) | 第一年规划量（首年规划量，企划命中率用） |
| PC00001 | varchar(1500) | 品类细分（冰箱/立式冷冻柜等，用于PUB-003冰箱vs冷柜区分） |
| HX00506~HX00541 | decimal(20,4) | 第1~36个月规划销量（LX立项，销售型号编码口径） |

### dw.dim_product_base_info_dd 核心字段
| 字段 | 类型 | 说明 |
|------|------|------|
| product_code | varchar(40) | 产品编码/物料号（关联ods管报.matnr） |
| model_code | varchar(40) | 产品型号编码 |
| model_name | varchar(80) | 产品型号名称 |
| sale_model_code | varchar(40) | 销售型号编码（日立口径） |
| sale_model_name | varchar(80) | 销售型号名称 |
| brand_name | varchar(18) | 品牌名称 |
| big_class_name / mid_class_name / small_class_name | varchar(80) | 大类/中类/小类名称 |
| product_type_code | varchar(4) | 产品类型编码（FERT=成品，ZTAO=套装） |
| delete_flag | varchar(2) | 删除标记（排除Y） |

### dwd.dwd_ipd_ipm_bp_lx_model_mid_dd 核心字段
| 字段 | 类型 | 说明 |
|------|------|------|
| dt_month | varchar(200) | 月份 |
| plan_type | varchar(200) | LX=立项规划量，BP=BP规划量 |
| prdct_model | varchar(200) | 型号名称 |
| salemodelcode | varchar(200) | 销售型号编码 |
| plan_sales_qty | decimal(20,2) | 规划销量 |
| plan_sales_amt | decimal(20,4) | 规划销额 |
| plan_gross_profit | decimal(20,4) | 规划毛利额 |
| model_type | varchar(200) | 产品型号口径/销售型号编码口径 |
| model_label_1 | varchar(200) | 型号标签（BP来源：HDRP） |

### dim.dim_ipd_jtplm_his_productmodel_dd 核心字段
| 字段 | 类型 | 说明 |
|------|------|------|
| objectid | varchar(100) | 主键ID |
| his_productmdgcode | varchar(150) | 产品型号MDG编码 |
| title | varchar(300) | 产品型号描述（中文） |
| his_pmdproductaffiliatedcompany | varchar(150) | 创建公司 |
| his_productbigcategories | varchar(100) | 产品大类名称 |
| his_productmiddlecategories | varchar(100) | 产品中类名称 |
| his_productsmallcategories | varchar(100) | 产品小类名称 |
| his_productsbrand | varchar(300) | 品牌名称 |
| his_oembrand | varchar(300) | OEM品牌名称 |
| his_pmdproductpositioning | varchar(300) | 产品定位名称 |
| his_domesticsalesorexport | varchar(300) | 内销/外销 |
| platformmdgcode | varchar(300) | MDG产品平台编码 |
| his_prdplatform | varchar(300) | 产品平台名称 |
| his_plannedtimetomarket | varchar(300) | 规划上市时间 |
| his_actualtimetomarket | varchar(300) | 实际上市时间 |
| his_actualdelistingtime | varchar(300) | 实际退市时间 |
| his_stopproductiontime | varchar(300) | 停止生产时间 |
| his_plannedsalesvolume | varchar(300) | 规划销量 |
| his_productscreensize | varchar(300) | 屏幕尺寸(英寸) |
| his_screentype | varchar(300) | 屏幕类型 |
| his_proscreenresolution | varchar(300) | 分辨率 |
| his_backlightmode | varchar(300) | 背光类型 |
| lifecycle_status | varchar(100) | 产品型号生命周期状态 |
| his_pmdproductlinename | varchar(300) | 产品线 |
| his_pmdcategorysegmentation | varchar(300) | 品类细分 |
| project_id | varchar(2000) | 项目ID |
| project_code | varchar(1000) | 项目编码 |
| project_name | varchar(2000) | 项目名称 |
