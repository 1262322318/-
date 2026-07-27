# 013-aowei-market-analysis 奥维中间表（行业市场分析）

## 当前状态速查

| 项目 | 内容 |
|------|------|
| 状态 | 开发完成，待测试 |
| 最后更新 | 2026-07-23 |
| 关联需求 | 010-aowei-data-processing |
| 脚本数 | 13个（1 DDL + 2 dim初始化 + 10 DML） |
| 目标表数 | 12张（2 dim + 10 ads） |

---

## 一、需求概述

| 字段 | 值 |
|------|-----|
| 需求ID | 013-aowei-market-analysis |
| 需求名称 | 奥维中间表（行业市场分析） |
| 需求来源 | 龚英 |
| 提出日期 | 2026-07-08 |
| 类型 | 新建（基于010需求扩增） |
| 业务背景 | 010需求的ads表数据量约1亿行，AI无法直接使用，需聚合为中间表供产品规划智能体使用 |

## 二、指标定义

本需求包含7个子报表（7张独立物理表），分为2个模块：

| 模块 | 子表 | 目标表 | 数据范围 |
|------|------|--------|----------|
| 模块1 | 表1-1 行业分渠道 | ads.ads_ipd_ipm_aowei_industry_channel_dd | 全市场 |
| 模块1 | 表1-2 分渠道分品牌 | ads.ads_ipd_ipm_aowei_channel_brand_dd | 筛选品牌 |
| 模块2 | 表2-1 型号均价及价格段 | ads.ads_ipd_ipm_aowei_model_price_spec_dd | 筛选品牌 |
| 模块2 | 表2-2 分价格段 | ads.ads_ipd_ipm_aowei_price_segment_dd | 全市场 |
| 模块2 | 表2-3 分价格段分品牌 | ads.ads_ipd_ipm_aowei_price_brand_dd | 筛选品牌 |
| 模块2 | 表2-4 分价格段分规格段 | ads.ads_ipd_ipm_aowei_price_spec_dd | 全市场 |
| 模块2 | 表2-5 分价格段分规格段分品牌 | ads.ads_ipd_ipm_aowei_price_spec_brand_dd | 筛选品牌 |
| 模块3 | 表A 行业总体分析（2026-07-21扩增） | ads.ads_ipd_ipm_aowei_industry_brand_dd | 筛选品牌（含"总体"渠道虚拟维度） |
| 模块3 | 表B 分价格段分品牌-线上（2026-07-21扩增） | ads.ads_ipd_ipm_aowei_price_spec_brand_online_dd | 筛选品牌+"总体"品牌 |
| 模块3 | 表C 分价格段分品牌-线下（2026-07-21扩增） | ads.ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 筛选品牌+"总体"品牌 |

维度表：
| 表名 | 说明 |
|------|------|
| dim.dim_ipd_ipm_aw_price_segment_dd | 价格段映射（74条） |
| dim.dim_ipd_ipm_aw_spec_segment_dd | 规格段映射（52条） |

## 三、核心业务规则

### 数据筛选
- 只取月维度数据（wm_type='月'）
- 时间范围：当前年往前推3年（动态）
- 源表：ads.ads_ipd_ipm_aowei_wd

### 品牌规则
- 没有"统计品牌"维度的表 = 全市场（不限品牌）
- 有"统计品牌"维度的表 = 只展示筛选品牌
- 小天鹅（洗护，通过sub_brand_name筛选）和三星（显示，通过brand_name筛选）为独立维度，允许与系列重复计数

### 占有率规则
- 分母 = 去掉最小粒度维度后的全市场（不限品牌）总量
- 表1-1"总体"行占有率 = NULL

### 价格段/规格段
- 价格段按年度均价匹配，区间左闭右开
- 规格段：空调按字面值匹配，其他品类按数值区间匹配
- 映射数据存dim维度表

### 表结构
- 指标行格式：一行 = 一个维度组合 + 一个指标名称 + 5个年度值列
- 所有表含load_dt字段

## 四、脚本清单

| 序号 | 脚本 | 类型 | 说明 | 调度顺序 |
|------|------|------|------|----------|
| 1 | create_tables.sql | DDL | 建12张表（原9张+2026-07-21扩增3张） | 1 |
| 2 | dim_price_segment_init.sql | DML | 价格段dim初始化 | 2 |
| 3 | dim_spec_segment_init.sql | DML | 规格段dim初始化 | 2 |
| 4 | ads_ipd_ipm_aowei_model_price_spec_dd.sql | DML | 表2-1 | 3 |
| 5 | ads_ipd_ipm_aowei_industry_channel_dd.sql | DML | 表1-1 | 3 |
| 6 | ads_ipd_ipm_aowei_channel_brand_dd.sql | DML | 表1-2 | 3 |
| 7 | ads_ipd_ipm_aowei_price_segment_dd.sql | DML | 表2-2 | 4 |
| 8 | ads_ipd_ipm_aowei_price_brand_dd.sql | DML | 表2-3（依赖表2-2） | 5 |
| 9 | ads_ipd_ipm_aowei_price_spec_dd.sql | DML | 表2-4 | 4 |
| 10 | ads_ipd_ipm_aowei_price_spec_brand_dd.sql | DML | 表2-5（依赖表2-4） | 5 |
| 11 | ads_ipd_ipm_aowei_industry_brand_dd.sql | DML | 表A 行业总体分析（2026-07-21扩增，源表聚合） | 6 |
| 12 | ads_ipd_ipm_aowei_price_spec_brand_online_dd.sql | DML | 表B 分价格段分品牌-线上（2026-07-21扩增，依赖表2-4+2-5） | 6 |
| 13 | ads_ipd_ipm_aowei_price_spec_brand_offline_dd.sql | DML | 表C 分价格段分品牌-线下（2026-07-21扩增，依赖表2-4+2-5） | 6 |

## 五、应用的公共规则

| 规则 | 在本需求中的具体应用 |
|------|---------------------|
| PUB-008 | 调度参数 ${GP_START_DT} 用于计算年度范围和load_dt |

## 六、变更记录

| 日期 | 变更内容 | 影响文件 |
|------|----------|----------|
| 2026-07-08 | 初始创建 | 全部 |
| 2026-07-21 | 龚英需求扩增3张中间表（表A行业总体分析+表B/C分价格段分品牌线上/线下），采用单元格拼接格式（额占有率+产品均价拼接为一个单元格，中文全角逗号分隔，2位小数），无 metric_name 字段。表A从源表 `ads.ads_ipd_ipm_aowei_wd` 重新聚合（含"总体"渠道虚拟维度）；表B/C基于013表2-4+表2-5二次聚合（filter 线上/线下 + "总体"品牌行占有率固定100.00%） | create_tables.sql（追加3张DDL）+ 3个新DML脚本 |
| 2026-07-23 | 表B/C占有率逻辑修正：新增"总体"价格段聚合行（4种行类型）；具体价格段×总体行改为层级式占比（分母=同规格段合计）；从表2-5/2-4取原始销额销量自行计算；表A/B/C全部JOIN改为`<=>`修复冰冷事业部NULL字段关联失败 | ads_ipd_ipm_aowei_price_spec_brand_offline_dd.sql, ads_ipd_ipm_aowei_price_spec_brand_online_dd.sql, ads_ipd_ipm_aowei_industry_brand_dd.sql |
