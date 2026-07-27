# 010-aowei-data-processing：奥维数据加工

## 当前状态速查

| 项目 | 内容 |
|------|------|
| 状态 | ✅ 已完成 |
| 创建日期 | 2026-07-01 |
| 最后更新 | 2026-07-01 |
| 需求来源 | 龚英 |
| 变更次数 | 0 |

## 一、需求概述

在奥维原始数据表 `dwd.dwd_mrs_mr_avcdtl_wd` 基础上，加工生成标准宽表 `ads.ads_ipd_ipm_aowei_wd`，供智能体使用。

核心操作：
1. 删除22个冗余字段
2. 字段改名（按"智能体-奥维表"规范）
3. 新增维度字段（事业部/产品大类/中类/小类/品类细分），通过映射表 `dim.dim_ipd_ipm_awproduct_dd` JOIN获取
4. 新增计算字段（品牌系列、核心规格）

## 二、涉及表

| 表名 | 层级 | 用途 | 操作 |
|------|------|------|------|
| `dwd.dwd_mrs_mr_avcdtl_wd` | DWD | 奥维销售明细（源表） | 只读 |
| `dim.dim_ipd_ipm_awproduct_dd` | DIM | 品线→产品维度映射 | 新建 |
| `ads.ads_ipd_ipm_aowei_wd` | ADS | 奥维数据加工宽表（目标表） | 新建 |

## 三、脚本清单

| 序号 | 文件 | 类型 | 说明 |
|------|------|------|------|
| 1 | `sql_scripts/create_tables.sql` | DDL | 建映射表+目标表 |
| 2 | `sql_scripts/dim_ipd_ipm_awproduct_dd_init.sql` | DML | 映射表初始化（28条记录） |
| 3 | `sql_scripts/ads_ipd_ipm_aowei_wd.sql` | DML | 目标表全量刷新 |

## 四、核心逻辑

### 4.1 映射逻辑

映射表通过3个输入字段（品线名称、产品属性、产品属性细分）映射到5个输出字段（事业部、产品大类、产品中类、产品小类、品类细分）。

JOIN规则：空值字段代表全匹配：
- `m.prdct_cate = ''` → 不参与匹配条件
- `m.prdct_cate_dtl = ''` → 不参与匹配条件

### 4.2 品牌系列

基于子品牌名称（sub_brand_name）做LIKE归类，海信/容声/科龙/vidda归为"海信系列"。

### 4.3 核心规格

按产品中类区分：
- 家用空调：取"制冷匹数"字段（match_size）
- 其他品类：取"产品尺寸"字段（spec_size）

## 五、更新策略

- 全量刷新（DELETE ALL + INSERT SELECT）
- 无增量逻辑
- 映射表为静态维度表，变更时手工维护

## 六、分区策略

- 分区键：`dt_wmcode`（按周动态分区）
- 分桶：`hash(markt_center, prdct_line_name)` 3个桶
- 副本：3副本，存储介质HDD

## 七、应用公共规则

| 规则 | 应用方式 |
|------|----------|
| PUB-008 | 调度参数（本脚本为全量刷新，暂不使用GP_START_DT） |

## 八、PRD文档

`refined/20260701-aowi-data-processing/2026-07-01_奥维数据加工_prd.md`
