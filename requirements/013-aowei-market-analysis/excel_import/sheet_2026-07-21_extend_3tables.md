# 013扩增3张中间表 — Excel导入信息（2026-07-21）

> 本文件为2026-07-21龚英需求扩增3张中间表的Excel导入信息，格式与 `sheet1_tables.csv` + `sheet2_columns.csv` 对应。
> 关键差异：本次3张表采用 `_dd` 后缀（对齐013七张表实际实现），非旧规划的 `_nd`。

---

## Sheet1：表信息（对应 sheet1_tables.csv）

| 文件源类型 | 数据源名称 | 数据库名称 | 表名称 | 分层 | 主题分类 | 表中文名 | 表英文名/描述 | 存储模型 | 创建人 | 负责人 | 安全等级 | 重要程度 | 数据类型 | 更新方式 | 标签 |
|-----------|-----------|-----------|--------|------|----------|----------|---------------|----------|--------|--------|----------|----------|----------|----------|------|
| doris | ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | ads | 海信集团产品运营/研发产品线/产品 | 奥维行业总体分析（含总体渠道+品牌） | 奥维行业总体分析（含"总体"渠道虚拟维度+品牌，单元格拼接格式） | DUPLICATE | gongying2 | luxinping | 敏感级 |  |  |  |  |
| doris | ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | ads | 海信集团产品运营/研发产品线/产品 | 奥维分价格段分品牌-线上 | 奥维分价格段分规格段分品牌数据-线上（含"总体"品牌行，单元格拼接格式） | DUPLICATE | gongying2 | luxinping | 敏感级 |  |  |  |  |
| doris | ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | ads | 海信集团产品运营/研发产品线/产品 | 奥维分价格段分品牌-线下 | 奥维分价格段分规格段分品牌数据-线下（含"总体"品牌行，单元格拼接格式） | DUPLICATE | gongying2 | luxinping | 敏感级 |  |  |  |  |

---

## Sheet2：字段信息（对应 sheet2_columns.csv）

| 数据源名称 | 数据库名称 | 表名称 | 字段中文名称 | 字段名称 | 类型 | 默认值 | 聚合类型 | 主键 | 允许为空 | 描述 | 安全分级 | 基础标准编码 | 是否分区列 | 来源信息 |
|-----------|-----------|--------|-------------|----------|------|--------|----------|------|----------|------|----------|-------------|-----------|----------|
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 事业部 | business_unit | VARCHAR(300) |  |  | 是 | 否 | 事业部 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 产品中类 | product_mid_class | VARCHAR(300) |  |  |  | 是 | 产品中类 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 产品小类 | product_small_class | VARCHAR(300) |  |  |  | 是 | 产品小类 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 品类细分 | category_segment | VARCHAR(300) |  |  |  | 是 | 品类细分 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 统计渠道 | channel_type_agg | VARCHAR(10) |  |  |  | 是 | 统计渠道（总体/线上/线下） | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 统计品牌 | stat_brand | VARCHAR(300) |  |  |  | 是 | 统计品牌（含小天鹅/三星；不含总体品牌行） | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 3年前值 | val_y3 | VARCHAR(50) |  |  |  | 是 | 3年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 2年前值 | val_y2 | VARCHAR(50) |  |  |  | 是 | 2年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 1年前值 | val_y1 | VARCHAR(50) |  |  |  | 是 | 1年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 当年T值 | val_curr | VARCHAR(50) |  |  |  | 是 | 当年T【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | 去年同期值 | val_y1_ytd | VARCHAR(50) |  |  |  | 是 | 去年同期【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_industry_brand_dd | ETL加载日期 | load_dt | DATETIMEV2(0) |  |  |  | 是 | ETL加载日期 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 事业部 | business_unit | VARCHAR(300) |  |  | 是 | 否 | 事业部 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 品线名称 | prdct_line_name | VARCHAR(80) |  |  |  | 是 | 品线名称 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 产品中类 | product_mid_class | VARCHAR(300) |  |  |  | 是 | 产品中类 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 产品小类 | product_small_class | VARCHAR(300) |  |  |  | 是 | 产品小类 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 品类细分 | category_segment | VARCHAR(300) |  |  |  | 是 | 品类细分 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 线上线下 | o2o_type | VARCHAR(10) |  |  |  | 是 | 线上线下（固定=线上） | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 价格段 | price_segment | VARCHAR(50) |  |  |  | 是 | 价格段 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 规格段 | spec_segment | VARCHAR(50) |  |  |  | 是 | 规格段 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 统计品牌 | stat_brand | VARCHAR(300) |  |  |  | 是 | 统计品牌（总体/海信系列/…） | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 3年前值 | val_y3 | VARCHAR(50) |  |  |  | 是 | 3年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 2年前值 | val_y2 | VARCHAR(50) |  |  |  | 是 | 2年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 1年前值 | val_y1 | VARCHAR(50) |  |  |  | 是 | 1年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 当年T值 | val_curr | VARCHAR(50) |  |  |  | 是 | 当年T【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | 去年同期值 | val_y1_ytd | VARCHAR(50) |  |  |  | 是 | 去年同期【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_online_dd | ETL加载日期 | load_dt | DATETIMEV2(0) |  |  |  | 是 | ETL加载日期 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 事业部 | business_unit | VARCHAR(300) |  |  | 是 | 否 | 事业部 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 品线名称 | prdct_line_name | VARCHAR(80) |  |  |  | 是 | 品线名称 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 产品中类 | product_mid_class | VARCHAR(300) |  |  |  | 是 | 产品中类 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 产品小类 | product_small_class | VARCHAR(300) |  |  |  | 是 | 产品小类 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 品类细分 | category_segment | VARCHAR(300) |  |  |  | 是 | 品类细分 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 线上线下 | o2o_type | VARCHAR(10) |  |  |  | 是 | 线上线下（固定=线下） | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 价格段 | price_segment | VARCHAR(50) |  |  |  | 是 | 价格段 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 规格段 | spec_segment | VARCHAR(50) |  |  |  | 是 | 规格段 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 统计品牌 | stat_brand | VARCHAR(300) |  |  |  | 是 | 统计品牌（总体/海信系列/…） | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 3年前值 | val_y3 | VARCHAR(50) |  |  |  | 是 | 3年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 2年前值 | val_y2 | VARCHAR(50) |  |  |  | 是 | 2年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 1年前值 | val_y1 | VARCHAR(50) |  |  |  | 是 | 1年前【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 当年T值 | val_curr | VARCHAR(50) |  |  |  | 是 | 当年T【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | 去年同期值 | val_y1_ytd | VARCHAR(50) |  |  |  | 是 | 去年同期【额占有率，产品均价】拼接值 | 敏感级 |  |  |  |
| ds_rd_rw | ads | ads_ipd_ipm_aowei_price_spec_brand_offline_dd | ETL加载日期 | load_dt | DATETIMEV2(0) |  |  |  | 是 | ETL加载日期 | 敏感级 |  |  |  |

---

## 备注

### 与旧sheet差异说明

1. **表命名后缀**：本次3表用 `_dd`（对齐013实际实现和create_tables.sql），非旧sheet的 `_nd`
2. **无 metric_name 字段**：本次3表采用**单元格拼接格式**（每维度组合1行），val字段存 `"额占有率%，产品均价"` 拼接字符串，因此不需要 metric_name 字段区分指标
3. **表A（industry_brand）无 o2o_type 字段**：改用 `channel_type_agg`（含"总体"虚拟维度）
4. **单元格格式**：占有率2位小数+`%`（如 `1.00%`）；均价2位小数（如 `2000.00`）；分隔符=中文全角逗号 `，`；空值统一 `"—，—"`

### 主键与允许为空说明

- 每张表**首列 business_unit** 标记为主键（`是`），允许为空=`否`
- 其他字段主键=空，允许为空=`是`
- 沿用 sheet2_columns.csv 的现有规则
