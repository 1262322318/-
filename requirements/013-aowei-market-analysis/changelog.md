# 013-aowei-market-analysis 变更记录

| 日期 | 变更类型 | 变更内容 | 影响文件 | 状态 |
|------|----------|----------|----------|------|
| 2026-07-08 | 初始创建 | 新建需求：奥维中间表（行业市场分析），7张ads表+2张dim表 | 全部（10个SQL脚本） | 已完成 |
| 2026-07-21 | 表新增（CHG-03） | 龚英需求扩增3张中间表：表A（`ads_ipd_ipm_aowei_industry_brand_dd`）从源表聚合；表B（`ads_ipd_ipm_aowei_price_spec_brand_online_dd`）与表C（`ads_ipd_ipm_aowei_price_spec_brand_offline_dd`）基于013表2-4/2-5二次聚合。采用**单元格拼接格式**（额占有率2位小数%+中文全角逗号+产品均价2位小数），无 metric_name 字段，空值统一`—，—` | create_tables.sql（追加3张DDL）+ 3个新DML | 已完成待测试 |
| 2026-07-23 | 逻辑修正（CHG-04） | 表B/C占有率逻辑重写：①新增`price_segment='总体'`聚合行（品牌市占率+行业额占比）；②具体价格段×总体行改为**层级式占比**（分母=同规格段合计，非固定100%）；③从表2-5/2-4取原始销额销量自行计算占有率（不再直接取占有率字段）。表A/B/C全部JOIN改为`<=>`（NULL-safe equal）修复冰冷事业部NULL字段关联失败 | ads_ipd_ipm_aowei_price_spec_brand_offline_dd.sql, ads_ipd_ipm_aowei_price_spec_brand_online_dd.sql, ads_ipd_ipm_aowei_industry_brand_dd.sql | 已完成 |
