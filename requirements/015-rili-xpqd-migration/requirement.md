# 015-rili-xpqd-migration：海信日立新品签单量

## 当前状态速查

| 项目 | 内容 |
|------|------|
| 状态 | ✅ 开发完成 |
| 最后更新 | 2026-07-15 |
| 指标名称 | 新品签单量（含出货量、完成率） |
| 业务域 | 海信日立中央空调 |
| 管理口径 | 销售型号编码口径 |
| 脚本数 | 3（1 DIM + 2 DWS） |
| 下游依赖 | 无 |

---

## 一、需求背景

将海信日立"新品签单量"指标从GP数仓迁移到Doris数仓。核心变更：产品/项目维度从GP的PLM表（`dw.dwplm_hac_product_info`）改用HDRP数据源（`dim.dim_ipd_salemodel_dd`）。

## 二、指标定义

统计海信日立"上市三年期内"（1~36个月）的新品型号，在各维度下的签单量和出货量表现，以及与LX规划量的对比（完成率）。

### 新品范围
- 产品大类：`PG00002 IN ('空气调节类产品', '外购产品')`
- 产品中类：`PG00003 IN ('中央空调', '外购设备', '空气调节类配件')`
- 产品小类：`PG00004 IN ('单元式内机', '单元式外机', '多联机内机', '多联机外机', '空气源热泵两联供', '空气源热泵三联供', '新风换气机', '热泵热水机')`
- 生命周期：`PG00057 IN ('上市', '预停签')`
- 上市月数：1~36个月

### 三种聚合口径
| 口径 | 粒度 | 上市时间定义 |
|------|------|-------------|
| 型号 | 销售型号编码 × 地理维度 | 该型号自身PG00025 |
| 项目 | 项目 × 事业部 | MIN(项目下所有新品的PG00025) |
| 事业部 | 事业部(营销部) | MIN(事业部下所有新品的PG00025) |

### 内外销判定
由数据来源表决定：内销=内销签单/出货表；外销=外销签单/出货表（国际合同）。

## 三、数据源

| 用途 | 表名 |
|------|------|
| 产品维度（HDRP） | `dim.dim_ipd_salemodel_dd` |
| MDG桥接 | `dw.dim_product_base_info_dd` |
| 内销签单 | `DW.DWSD_RILISMS_TF_HAC_CONTRACT` |
| 外销签单 | `ods.odsemp_sms_hac_hh_gj_contract` + `_detail` |
| 内销出货 | `DW.DWSD_RILISMS_TF_HAC_SHIPMENT` |
| 外销出货 | `ods.odsemp_sms_hac_hh_gj_tr_notice` + `_detial` |
| 组织架构 | `ods.odsemp_sms_hac_hise_dept` + `_country` |
| 规划量（LX） | `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd` |
| 上市时间维度 | `dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd` |

## 四、目标表

| 表名 | 分层 | 用途 |
|------|------|------|
| `dim.dim_ipd_ipm_rili_syb_xm_shangshitime_dd` | DIM | 事业部/项目上市时间维度 |
| `dws.dws_ipd_ipm_rili_qdch_m_detail_dd` | DWS | 签单量&出货量月度明细 |
| `dws.dws_ipd_ipm_rili_xpqd_detail_dd` | DWS | 上市三年期新品签单汇总 |

## 五、脚本清单

| 执行顺序 | 脚本文件 | 功能 |
|----------|----------|------|
| 1 | `dim_ipd_ipm_rili_syb_xm_shangshitime_dd.sql` | 计算事业部/项目口径上市时间维度 |
| 2 | `dws_ipd_ipm_rili_qdch_m_detail_dd.sql` | 签单量&出货量月度明细（3次INSERT） |
| 3 | `dws_ipd_ipm_rili_xpqd_detail_dd.sql` | 汇总+规划量+完成率（3种口径） |

## 六、公共规则引用

| 规则 | 应用 |
|------|------|
| PUB-004 | 日立管理口径（销售型号编码），MDG桥接 |
| PUB-008 | 调度参数规范（${GP_START_DT}） |

## 七、变更记录

| 日期 | 类型 | 说明 |
|------|------|------|
| 2026-07-15 | 新建 | GP→Doris迁移，产品维度改用HDRP |
