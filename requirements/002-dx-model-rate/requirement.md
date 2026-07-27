# 需求文档 - 低效型号占比与新品规划命中率

## 当前状态速查（最后同步：changelog #008, 2026-06-13）

### 覆盖范围
| 维度 | 当前值 |
|------|--------|
| 内销产品线 | 冰箱、冷柜、洗衣机、家用空调、平板电视、中央空调（日立）、厨电、激光家用、激光商用 |
| 外销产品线 | 冰箱、冷柜、洗衣机、家用空调、平板电视、厨电、激光 |
| 指标口径 | zhibiao_type: 1=本月低效、2=年累低效、2-1=低效营销部项目、2-2=低效所有者项目、2-3=低效产品小类项目、3=生命周期累、4=新品命中率、4-1=命中率营销部项目、4-2=命中率所有者项目 |
| 实际销量来源（内销） | 管报（ods_mr_v_app_fm_imat_saledata） |
| 实际销量来源（外销） | GSS协议订单/排产单（PUB-009空调、PUB-010其他） |
| 规划量来源 | BP+LX组合（内销）、仅LX（外销） |
| 应用公共规则 | PUB-001, PUB-002, PUB-003, PUB-004, PUB-005, PUB-006, PUB-008, PUB-009, PUB-010 |
| 日立专属字段（#007新增） | is_project_nk、is_db_qty、is_db_amt、is_db_margin、HX00327、PG00039、HX00339、productmodel_life、PG00009、shangshi_y |
| 复产排除规则（#008新增） | 本年复产机型不考核，来源：dwd.dwd_ipd_ipm_hdrp_delisted_dd |

### 脚本清单
| 脚本 | 分层 | 说明 |
|------|------|------|
| dwd_ipd_ipm_bp_lx_model_mid_dd.sql | DWD | BP及LX规划量中间表 |
| dws_ipd_ipm_dxmodel_detail_dd.sql | DWS | 内销明细（全产品线，含低效+新品命中率+日立项目口径二级维度） |
| dws_ipd_ipm_dxmodel_detail_dd_wx.sql | DWS | 外销新品命中率明细（7条产品线） |
| ads_ipd_ipm_dxmodel_result_dd.sql | ADS | 内销汇总结果 |
| validate_data_quality.sql | 检查 | 数据质量验证 |

### 文档同步状态
- 主体部分覆盖到：初始4条内销产品线（冰箱/冷柜/洗衣机/空调/电视/日立）
- 厨电/激光/外销的详细规则见：changelog #003~#006
- 日立效率看板优化（内控口径+二级维度）见：changelog #007
- 本年复产机型不考核规则见：changelog #008
- 详细变更历史见：changelog.md

## 基本信息
- **需求ID**: 002-dx-model-rate
- **创建日期**: 2026-04-23
- **创建人**: ETL智能辅助工具
- **业务部门**: 集团IPD/各事业部（冰冷、洗护、空气、显示）
- **优先级**: 高
- **状态**: 已完成开发
- **数据仓库分层**: DWD → DWS → ADS

## 业务背景
集团需要按月监控各事业部（冰冷、洗护、空气、显示）的产品型号效率，核心考核两个指标：
1. **低效型号占比**：衡量在售型号中销量完成率低于80%的型号占比
2. **新品规划命中率**：衡量新品期内型号的规划销量命中情况

## 指标口径清单（zhibiao_type）

本需求包含多个独立指标口径，产品线扩展时**必须逐行检查每个口径是否都生成了对应SQL段落**：

| zhibiao_type | 指标名称 | 业务含义 | 考核范围 | 达标标准 |
|:---:|----------|----------|----------|----------|
| 1 | 低效型号占比（本月） | 当月单月销量完成率 | 在售且非保护期 | 销量完成率 ≥ 0.8 |
| 2 | 低效型号占比（年累） | 年初至今累计销量完成率 | 在售且非保护期 | 销量完成率 ≥ 0.8 |
| 3 | 低效型号占比（生命周期累） | 上市至今全生命周期累计 | 在售且非保护期 | 销量完成率 ≥ 0.8 |
| 4 | 新品规划命中率 | 新品期内（12个月）累计销量命中 | 新品期内型号 | 销量完成率 ≥ 0.8 |

**注意**：
- 当前各产品线实际使用的口径不完全相同，扩展时以需求文档为准
- 激光显示目前使用：zhibiao_type='2'（低效型号占比年累）+ zhibiao_type='4'（新品规划命中率）

## 指标计算逻辑

### 低效型号占比
- **考核范围**：在售且未处于保护期的型号
- **达标标准**：实际销量 / 规划销量 ≥ 0.8 为达标，< 0.8 为低效
- **指标公式**：低效型号数 / 总型号数
- **保护期规则**：上市3个月内不考核；本月上市的为第0月不纳入总数

### 新品规划命中率
- **考核范围**：新品期内（上市12个月内）的型号
- **达标标准**：实际销量 / 规划销量 ≥ 0.8 为命中
- **指标公式**：命中型号数 / 新品期总型号数

### 各产品线差异
| 产品线 | 管理口径 | 实际销量来源 | 规划量来源 | 特殊规则 |
|--------|----------|-------------|-----------|----------|
| 冰箱/冷柜/洗衣机 | 产品型号 | 管报→MDG→model_name | BP+LX | 内销；ODM/gorenje品牌剔除 |
| 平板电视 | 产品型号 | 管报→MDG→model_name | BP+LX | 内销；能效机转换原型机 |
| 家用空调 | 产品型号 | 管报→MDG→model_name | BP+LX | 内销；排除环境电器 |
| 中央空调（日立） | 销售型号编码 | 管报→MDG→sale_model_code | BP+LX（销售型号编码口径） | 内销+外销；按归属营销部过滤 |

## 涉及数据表

### 源表（读取）
- `ods.ods_mr_v_app_fm_imat_saledata` — 管报数据（实际销量、收入、成本）
- `dim.dim_ipd_productmodel_dd` — 白电产品型号基础信息
- `dim.dim_ipd_salemodel_dd` — 白电销售型号基础信息
- `dw.dim_product_base_info_dd` — MDG产品主数据（物料→型号映射桥梁）
- `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd` — BP及立项规划销量分月数据
- `ods.odshdrp_hisense_basis_point_target` — HDRP BP目标数据
- `dim.dim_ipd_jtplm_his_productmodel_dd` — 视像科技产品型号（PLM）
- `dim.dim_ipd_tv_model_nengxiao_nd` — 电视能效机型号映射
- `dim.dim_ipd_td_weidu_nd` — 指标维度配置
- `dw.dim_date_nd` — 日期维度
- `ods.ods_feishu_base_P8vTbFzrTaWtQLspDwgcpbm8nng_tbl8PBYKby97MVvy` — 飞书计划值

### 目标表（写入）
- `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd` — BP及立项规划销量分月中间表
- `dws.dws_ipd_ipm_dxmodel_detail_dd` — 低效型号明细表（DWS层）
- `ads.ads_ipd_ipm_dxmodel_result_dd` — 低效型号结果表（ADS层）

## 数据流程
```
dim.dim_ipd_productmodel_dd (产品型号基础信息)
dim.dim_ipd_salemodel_dd (销售型号基础信息)
ods.ods_mr_v_app_fm_imat_saledata (管报实际销量)
         ↓
dw.dim_product_base_info_dd (MDG桥梁：物料→型号映射)
         ↓
dwd.dwd_ipd_ipm_bp_lx_model_mid_dd (BP/LX规划销量分月)
         ↓
dws.dws_ipd_ipm_dxmodel_detail_dd (低效型号明细：实际vs规划)
         ↓
ads.ads_ipd_ipm_dxmodel_result_dd (低效型号占比/新品命中率结果)
```

## 关键指标
- `act_sales_qty`：实际销量
- `plan_sales_qty`：规划销量
- `sales_qty_rate`：销量完成率 = 实际销量 / 规划销量
- `is_dx`：是否低效（Y/N），sales_qty_rate < 0.8 则为Y
- `is_project`：是否保护期（Y=不考核，N=考核）
- `dxmodel_rate`：低效型号占比 = 低效型号数 / 总型号数
- `completion_dxmodel_rate`：完成率 = (1 - 低效占比) / (1 - 计划值)

## 业务规则
- 上市3个月内为保护期，不纳入考核
- 本月上市的型号为第0月，不纳入总数
- gorenje品牌剔除（冰冷）
- ODM产品剔除（冰冷：海信/容声品牌但非海信/平度基地）
- OEM品牌剔除（空调）
- 能效机销量转换为原型机（电视）
- 日立以销售型号编码为管理口径
- BP规划量优先使用立项（LX）数据，当立项首月在本年时用LX替代BP
- 空调单元式内外机有整机的不单独考核

## 验收标准
- [x] DWD层：BP/LX规划销量正确分月展开
- [x] DWS层：各产品线低效型号明细正确计算
- [x] ADS层：低效型号占比和新品命中率汇总正确
- [x] 日立以销售型号编码口径正确汇总
- [x] 保护期规则正确执行

## 相关文档
- 表清单：tables.txt
- SQL脚本：sql_scripts/
- 血缘关系：lineage.md

## 变更记录
| 日期 | 版本 | 变更描述 | 变更人 |
|------|------|----------|--------|
| 2026-04-23 | 1.0 | 初始版本（自动生成） | ETL智能辅助工具 |
