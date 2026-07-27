---
inclusion: manual
---
# 表结构业务语义索引

> 本文档记录已录入数据表的**业务语义信息**（用途、关联规则、关键词、核心字段说明）。
> 完整字段列表和类型信息请通过 MCP postgres 查询 `public.table_metadata` 获取：
> ```sql
> SELECT column_name, column_type, column_comment 
> FROM public.table_metadata 
> WHERE table_name = '{表名}' ORDER BY id;
> ```

## 表清单索引

| 序号 | 表名 | 数据库 | 分层 | 用途简述 |
|------|------|--------|------|----------|
| 1 | dim_ipd_salemodel_dd | dim | DIM | 白电销售型号基础信息 |
| 2 | dim_ipd_productmodel_dd | dim | DIM | 白电产品型号基础信息 |
| 3 | ods_mr_v_app_fm_imat_saledata | ods | ODS | 管报实际销量/收入/成本 |
| 4 | dwd_ipd_ipm_bp_lx_model_mid_dd | dwd | DWD | BP及立项规划销量分月 |
| 5 | dim_product_base_info_dd | dw | DIM（dw库） | MDG产品主数据（桥梁表） |
| 6 | ads_ipd_ipm_add_reduce_result_dd | ads | ADS | 研发指标新增缩减结果值 |
| 7 | ads_ipd_ipm_dptxl_result_dd | ads | ADS | 单平台销量结果表 |
| 8 | ads_ipd_ipm_platform_library_result_dd | ads | ADS | 平台库平台结果表 |
| 9 | ads_ipd_ipm_platform_result_dd | ads | ADS | 产品平台数结果表 |
| 10 | ads_ipd_ipm_sale_model_result_dd | ads | ADS | 在销型号数结果表 |
| 11 | ads_ipd_ipm_zcmodel_result_dd | ads | ADS | 在产型号数结果表 |
| 12 | ads_ipd_ipm_zgd_model_dd | ads | ADS | 中高端型号数占比 |
| 13 | dim_date_nd | dw | DIM | 日期维度主表 |
| 14 | dim_ipd_jtplm_his_productversion_dd | dim | DIM | 视像科技生产版本表 |
| 15 | dim_ipd_productionversion_dd | dim | DIM | 生产版本基础信息表 |
| 16 | dim_ipd_productplatform_dd | dim | DIM | 白电产品平台基础信息表 |
| 17 | dim_ipd_tv_model_nengxiao_nd | dim | DIM | 视像科技能效机对应关系 |
| 18 | dws_ipd_ipm_add_reduce_detail_dd | dws | DWS | 研发指标新增缩减明细 |
| 19 | dws_ipd_ipm_dptxl_detail_dd | dws | DWS | 单平台销量明细表 |
| 20 | dws_ipd_ipm_dxhxl_detail_dd | dws | DWS | 单型号销量明细表 |
| 21 | dws_ipd_ipm_platform_detail_dd | dws | DWS | 产品平台数明细表 |
| 22 | dws_ipd_ipm_platform_library_detail_dd | dws | DWS | 平台库平台明细表 |
| 23 | dws_ipd_ipm_sale_model_detail_dd | dws | DWS | 在销型号数明细表 |
| 24 | dws_ipd_ipm_sales_detail_mid_dd | dws | DWS | 销量数据过渡表 |
| 25 | dws_ipd_ipm_zcmodel_detail_dd | dws | DWS | 在产型号数明细表 |
| 26 | ads_ipd_irs_design_change_kccl_dd | ads | ADS | 设计变更库存处理意见（IRS业务域） |
| 27 | dim_ipd_jtplm_his_productmodel_dd | dim | DIM | 集团PLM产品型号表（视像科技） |
| 28 | dws_ipd_ipm_dxmodel_detail_dd | dws | DWS | 低效型号明细表 |
| 29 | ads_ipd_ipm_dxmodel_result_dd | ads | ADS | 低效型号结果表 |
| 30 | ads_ipd_ipm_qihua_hit_result_dd | ads | ADS | 企划命中率结果表（待建表，003需求create_tables.sql定义） |
| 31 | dws_ipd_ipm_qihua_hit_detail_dd | dws | DWS | 企划命中率明细表（待建表，003需求create_tables.sql定义） |
| 32 | dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd | dwd | DWD | 海外分公司库存（外销库存源） |
| 33 | dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd | dwd | DWD | 基地库存（外销库存源） |
| 34 | dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd | dwd | DWD | 在途库存（外销库存源） |
| 35 | odsgss_im_order_agreement | ods | ODS | GSS冰冷洗协议订单头表（仅代码块引用） |
| 36 | odsgss_im_rolling_plan_detail | ods | ODS | GSS冰冷洗滚动计划明细（仅代码块引用） |
| 37 | odsgss_im_ecc_pln_bd_product_title | ods | ODS | GSS冰箱产品对照表（仅代码块引用） |
| 38 | odsgss_im_ecc_pln_bd_lg_product_title | ods | ODS | GSS冷柜产品对照表（仅代码块引用） |
| 39 | odsgss_im_ecc_pln_bd_xyj_product_title | ods | ODS | GSS洗衣机产品对照表（仅代码块引用） |
| 40 | odsgss_im_grs_dic | ods | ODS | GSS数据字典（仅代码块引用） |
| 41 | odsgss_im_sales_order_title | ods | ODS | GSS电视外销订单表（仅代码块引用） |
| 42 | odsgss_im_cw_order_ledger | ods | ODS | GSS厨电协议台账（仅代码块引用） |
| 43 | odsgss_im_jg_order | ods | ODS | GSS激光订单表（仅代码块引用） |

---

## 1. dim.dim_ipd_salemodel_dd
- **用途**：白电销售型号基础信息，最小粒度=销售型号编码，含产品属性、销售属性、时间规划、能效信息
- **关键词**：销售型号、销售型号编码、白电销售型号、冰箱、冷柜、洗衣机、厨卫、空调
- **关联**：`PRODUCTMODEL_ID` → `dim_ipd_productmodel_dd.ID`（一个产品型号可对应多个销售型号）
- **核心字段**：PG00068(销售型号编码)、PG00061(名称)、PG00057(生命周期)、PG00025(实际上市时间)、PG00069(销售品牌)、PC20080(归属营销部)、HX00379(是否模块组合)、HX00223(产品线)、PC00001(品类细分)、HX00506~HX00541(第1~36月规划销量)、HX00020(第一年规划量)
- **场景**：日立口径（按PG00068汇总）、销售型号维度分析、企划命中率

## 2. dim.dim_ipd_productmodel_dd
- **用途**：白电产品型号基础信息，含产品属性、规格参数、规划信息、生命周期状态
- **关键词**：产品型号、白电产品型号、产品型号名称、产品系列、产品平台、品牌
- **关联**：`ID` → `dim_ipd_salemodel_dd.PRODUCTMODEL_ID`
- **核心字段**：ID(唯一标识)、PG00061(产品型号名称)、PG00029(生命周期状态)、PG00025(实际上市时间)、HX00501(实际退市准备时间)、PG00005(品牌)、PG00002/PG00003/PG00004(大类/中类/小类)、PG00020(内销/外销)、PG00015(产品公司)、PC00025(规划生产基地)、PC00001(品类细分)、PC10050(门类)、PC20029/PC20055(内机/外机产品型号)、HX00083(研发类型)、HX00427(是否重复型号)、PRODUCTLINE_SYB(产品线-事业部内部)、HX00506~HX00541(第1~36月规划销量)
- **场景**：产品型号口径分析、产品线分类（PUB-003/006）、ODM判断

## 3. ods.ods_mr_v_app_fm_imat_saledata
- **用途**：管报数据，按月存储实际销量、收入、成本
- **关键词**：管报、销量、收入、成本、毛利率、物料、事业部
- **关联**：`matnr` → `dw.dim_product_base_info_dd.product_code`（不与dim_ipd_productmodel_dd直接关联）
- **核心字段**：yearmonth(统计年月)、matnr(物料编码)、zzprdmodel(型号)、sale_qty(销量)、rev_amt(收入)、cost_amt(成本)、d_bg/desc_bg(事业部)
- **场景**：实际销量数据源、所有涉及销量/销额/毛利的指标

## 4. dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
- **用途**：BP规划量和立项规划量的分月数据
- **关键词**：BP、立项、规划销量、规划销额、规划毛利率
- **关联**：`matnr` → `dw.dim_product_base_info_dd.product_code`；`salemodelcode` → `dim_ipd_salemodel_dd.PG00068`
- **核心字段**：dt_month(月份)、plan_type(LX=立项/BP=BP规划)、prdct_model(型号名称)、salemodelcode(销售型号编码)、plan_sales_qty/plan_sales_amt(规划销量/销额)、model_type(产品型号口径/销售型号编码口径)、model_label_1(型号标签，BP来源：HDRP)
- **场景**：低效型号占比、新品命中率等涉及规划量的指标

## 5. dw.dim_product_base_info_dd
- **用途**：MDG主数据产品桥梁表，物料号→产品型号编码/销售型号编码的映射
- **关键词**：MDG、主数据、物料、产品编码
- **关联**：`product_code` → `ods管报.matnr`（桥梁映射：model_code→产品型号，sale_model_code→销售型号）
- **核心字段**：product_code(物料号)、model_code/model_name(产品型号编码/名称)、sale_model_code/sale_model_name(销售型号编码/名称)、brand_name(品牌)、big_class_name/mid_class_name/small_class_name(大类/中类/小类)、product_type_code(FERT=成品,ZTAO=套装)、delete_flag(排除Y)
- **场景**：日立口径（通过sale_model_code）、其他产品线（通过model_name）

## 6. ads.ads_ipd_ipm_add_reduce_result_dd
- **用途**：ADS层，研发指标新增/缩减的结果汇总
- **关键词**：研发指标、新增缩减、结果值、完成率

## 7. ads.ads_ipd_ipm_dptxl_result_dd
- **用途**：ADS层，单平台销量/销额的汇总结果
- **关键词**：单平台销量、平台数、销额、完成率

## 8. ads.ads_ipd_ipm_platform_library_result_dd
- **用途**：ADS层，平台库中各平台的汇总结果，含各状态实际值
- **关键词**：平台库、平台结果、平台状态

## 9. ads.ads_ipd_ipm_platform_result_dd
- **用途**：ADS层，产品平台数的汇总结果
- **关键词**：产品平台数、平台结果、完成率

## 10. ads.ads_ipd_ipm_sale_model_result_dd
- **用途**：ADS层，在销型号数的汇总结果
- **关键词**：在销型号数、型号结果、完成率

## 11. ads.ads_ipd_ipm_zcmodel_result_dd
- **用途**：ADS层，在产型号数的汇总结果
- **关键词**：在产型号数、在产结果、完成率

## 12. ads.ads_ipd_ipm_zgd_model_dd
- **用途**：ADS层，中高端型号数占比的汇总结果
- **关键词**：中高端、型号数占比、占比完成率

## 13. dw.dim_date_nd
- **用途**：DIM层，日期维度主表，含自然日历、海信预测日历、NRF日历
- **关键词**：日期、日期维度、年月、季度、周次

## 14. dim.dim_ipd_jtplm_his_productversion_dd
- **用途**：DIM层，视像科技产品的生产版本详细信息，含产品规格、面板参数、软件系统
- **关键词**：视像科技、生产版本、电视、平板、面板、屏幕
- **关联**：通过产品型号编码关联 `dim_ipd_jtplm_his_productmodel_dd`

## 15. dim.dim_ipd_productionversion_dd
- **用途**：DIM层，白电产品生产版本基础信息，含产品规格、部件物料号
- **关键词**：生产版本、白电生产版本、BOM、压缩机、电机

## 16. dim.dim_ipd_productplatform_dd
- **用途**：DIM层，白电产品平台基础信息，含平台属性、规格参数、生命周期状态
- **关键词**：产品平台、白电平台、平台生命周期、平台分类
- **核心字段**：ID、PG00061(物料描述)、PG00056(平台生命周期状态)、PG00044(平台分类)、HX00223(产品线)、PG00015(产品公司)

## 17. dim.dim_ipd_tv_model_nengxiao_nd
- **用途**：DIM层，视像科技能效机与原型机的对应关系
- **关键词**：能效机、视像科技、电视型号映射、原型机
- **核心字段**：brand(品牌)、model(原型机型号)、model_nengxiao(能效机名称)
- **场景**：PUB-005能效机转换规则

## 18. dws.dws_ipd_ipm_add_reduce_detail_dd
- **用途**：DWS层，研发指标新增/缩减的明细数据
- **关键词**：研发指标、新增缩减、明细

## 19. dws.dws_ipd_ipm_dptxl_detail_dd
- **用途**：DWS层，单平台销量明细，含物料级别销量/销额/成本
- **关键词**：单平台销量、平台明细、销量、销额

## 20. dws.dws_ipd_ipm_dxhxl_detail_dd
- **用途**：DWS层，单型号销量明细
- **关键词**：单型号销量、型号明细、销量、销额

## 21. dws.dws_ipd_ipm_platform_detail_dd
- **用途**：DWS层，实际有机型在使用的平台明细（只有平台下存在在产机型时才出现）
- **关键词**：产品平台数、平台明细、在产平台
- **与平台库明细表区别**：平台库明细表记录所有平台（含无在产机型），本表只记录实际有在产机型使用的平台

## 22. dws.dws_ipd_ipm_platform_library_detail_dd
- **用途**：DWS层，平台库模块中所有平台的明细（含平台生命周期：创建→立项→开发→发布→迁移→禁选→停止生产→作废）
- **关键词**：平台库、平台明细、平台生命周期、HDRP、JTPLM
- **与平台数明细表区别**：本表侧重平台管理视角（平台本身的生命周期），平台数明细表侧重实际有机型使用的平台

## 23. dws.dws_ipd_ipm_sale_model_detail_dd
- **用途**：DWS层，在销型号数明细，含型号生命周期、库存、销售区域
- **关键词**：在销型号、型号明细、上市、退市、库存、清尾

## 24. dws.dws_ipd_ipm_sales_detail_mid_dd
- **用途**：DWS层，销量数据中间过渡表（内部中间表，被单型号销量等引用）
- **关键词**：销量数据、过渡表、物料

## 25. dws.dws_ipd_ipm_zcmodel_detail_dd
- **用途**：DWS层，在产型号数明细，含型号生命周期、生产版本
- **关键词**：在产型号、在产明细、生产版本、停产

## 26. ads.ads_ipd_irs_design_change_kccl_dd
- **用途**：ADS层，设计变更全集数据，覆盖ECO采购会签、QCA、工艺评估、MCO、MCA、库存处理意见。通过flag字段区分4种场景：1=设计变更报表/2=+MCA/3=+MCO/4=+kccl
- **关键词**：设计变更、库存处理意见、MCO、MCA、ECO、kccl、IRS、变更类型、变更阶段
- **业务域**：IRS（管理研发支撑）
- **刷新方式**：全量刷新（无分区）
- **主键**：DUPLICATE KEY(name, objectid)
- **核心字段**：name(编号/变更类型)、objectid(唯一ID)、flag(场景区分)、hwa_changetype_chg(变更类型)、HWA_ChangePhase(变更阶段)、HWA_BreakpointDate(生效日)、MCO_name(MCO编号)、mca_name(MCA编号)、company(所属公司)

## 27. dim.dim_ipd_jtplm_his_productmodel_dd
- **用途**：DIM层，视像科技产品型号基础信息（来源：集团PLM），含屏幕参数、平台信息、生命周期
- **关键词**：视像科技产品型号、集团PLM、电视产品型号、JTPLM、屏幕尺寸
- **关联**：通过`title`关联能效机映射表；通过产品型号编码关联视像科技生产版本表
- **注意**：视像科技专用，白电产品型号用 `dim.dim_ipd_productmodel_dd`
- **核心字段**：objectid(主键)、his_productmdgcode(MDG编码)、title(产品型号描述)、his_productsbrand(品牌)、his_oembrand(OEM品牌)、his_domesticsalesorexport(内销/外销)、his_prdplatform(产品平台名称)、his_actualtimetomarket(实际上市时间)、his_actualdelistingtime(实际退市时间)、his_productscreensize(屏幕尺寸)、lifecycle_status(生命周期状态)、his_pmdproductlinename(产品线)、project_id/project_code/project_name(项目信息)

## 28. dws.dws_ipd_ipm_dxmodel_detail_dd
- **用途**：DWS层，低效型号明细，含型号级别的实际销量/规划量/完成率/低效判定
- **关键词**：低效型号、低效明细、销量完成率、销额完成率
- **核心字段**：dt_month(月份)、product_line(产品线)、in_out_sale(内外销)、zhibiao_type(指标口径)、prdct_model(型号名)、act_sales_qty/plan_sales_qty(实际/规划销量)、sales_qty_rate(销量完成率)、is_dx(是否低效)、is_project(是否保护期)、shangshi_time(上市时间)

## 29. ads.ads_ipd_ipm_dxmodel_result_dd
- **用途**：ADS层，低效型号占比和新品命中率的汇总结果
- **关键词**：低效型号结果、新品命中率、低效占比

## 30. ads.ads_ipd_ipm_qihua_hit_result_dd
- **用途**：ADS层，企划命中率汇总结果
- **关键词**：企划命中率、项目命中率
- **状态**：⚠️ 待建表（003需求create_tables.sql已定义DDL，尚未在生产环境执行）

## 31. dws.dws_ipd_ipm_qihua_hit_detail_dd
- **用途**：DWS层，企划命中率明细
- **关键词**：企划命中、项目明细、阶段判定
- **状态**：⚠️ 待建表（003需求create_tables.sql已定义DDL，尚未在生产环境执行）

## 32. dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
- **用途**：DWD层，海外分公司库存（外销型号的实物库存数据源之一）
- **关键词**：海外库存、分公司库存、外销库存
- **场景**：外销在销型号数的库存清零判定（PUB-007），SQL模板6引用

## 33. dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
- **用途**：DWD层，基地库存（外销型号在生产基地的库存数据源之一）
- **关键词**：基地库存、外销库存
- **场景**：外销在销型号数的库存清零判定（PUB-007），SQL模板6引用

## 34. dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
- **用途**：DWD层，在途库存（外销型号的在途物流库存数据源之一）
- **关键词**：在途库存、外销库存
- **场景**：外销在销型号数的库存清零判定（PUB-007），SQL模板6引用

## 35~43. GSS外销订单相关表（仅代码块引用，不做详细语义记录）

以下9张表属于GSS系统（其他领域数据），仅作为外销实际销量数据集使用，具体SQL逻辑见PUB-010：

| 表名 | 用途 |
|------|------|
| `ods.odsgss_im_order_agreement` | 冰冷洗协议订单头表 |
| `ods.odsgss_im_rolling_plan_detail` | 冰冷洗滚动计划明细 |
| `ods.odsgss_im_ecc_pln_bd_product_title` | 冰箱产品编码→型号对照 |
| `ods.odsgss_im_ecc_pln_bd_lg_product_title` | 冷柜产品编码→型号对照 |
| `ods.odsgss_im_ecc_pln_bd_xyj_product_title` | 洗衣机产品编码→型号对照 |
| `ods.odsgss_im_grs_dic` | GSS数据字典（协议状态枚举） |
| `ods.odsgss_im_sales_order_title` | 电视外销订单表 |
| `ods.odsgss_im_cw_order_ledger` | 厨电协议台账 |
| `ods.odsgss_im_jg_order` | 激光订单表 |

---

## 查询表结构的标准方式

当需要查看某张表的完整字段列表时，使用以下SQL查询 `public.table_metadata`：

```sql
-- 查看某张表的所有字段
SELECT column_name, column_type, column_comment 
FROM public.table_metadata 
WHERE table_name = '{表名}' 
ORDER BY id;

-- 查看某个库下所有表
SELECT DISTINCT table_name, table_comment 
FROM public.table_metadata 
WHERE db_name = '{库名}' 
ORDER BY table_name;

-- 搜索包含某关键词的字段
SELECT table_name, column_name, column_type, column_comment 
FROM public.table_metadata 
WHERE column_comment LIKE '%{关键词}%' 
ORDER BY table_name, id;
```
