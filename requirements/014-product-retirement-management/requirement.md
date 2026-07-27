# 014-product-retirement-management 产品退市管理

## 当前状态速查

| 项目 | 内容 |
|------|------|
| 需求ID | 014-product-retirement-management |
| 状态 | ✅ 开发完成 |
| 指标 | 退市按计划执行率、退市周期缩减率 |
| 产品线 | 海信日立（中央空调） |
| 创建时间 | 2026-07-13 |
| 最后更新 | 2026-07-13 |
| PRD来源 | refined/20260713-product-retirement-management/2026-07-13_产品退市管理_prd.md |

## 一、需求概述

从GP迁移到Doris，同时将数据源从日立PLM切换为HDRP（dim_ipd_salemodel_dd + dim_ipd_productmodel_dd）。涉及2个指标：
1. **退市按计划执行率**：按时完成退市节点的型号数 / 应完成退市节点的总型号数
2. **退市周期缩减率**：本期平均退市周期用时 / 去年同期平均用时

## 二、业务规则

### 2.1 数据源筛选
- 产品大类：`PG00002 IN ('空气调节类产品','外购产品')`
- 产品中类：`PG00003 IN ('中央空调','外购设备','空气调节类配件')`
- 标准品：`PC20006 = '标准品'`

### 2.2 退市按计划执行率
- data_type：停签 / 停产 / 上市
- plan_time：来自飞书滚动计划表（dim.dim_ipd_ipm_rili_plan_dd）
- act_time：来自HDRP（PG00025上市 / PG00026停签 / PG00027停产）
- is_aqwc判定：act_time IS NOT NULL AND plan_time IS NOT NULL AND act_time <= plan_time → 'Y'
- ADS聚合：COUNT(DISTINCT is_aqwc='Y'的型号) / COUNT(DISTINCT 全部型号)

### 2.3 退市周期缩减率
- data_type：预停签-停签 / 停签-停产
- 预停签-停签天数：DATEDIFF(PG00026, 飞书.plan_yutingqian_time)
- 停签-停产天数：DATEDIFF(PG00027, PG00026)
- 筛选：预停签-停签取停签当月发生的型号，停签-停产取停产当月发生的型号
- ADS聚合：本期AVG(天数) / 去年同期AVG(天数)

### 2.4 维度交叉
| 指标 | dimension_1 | dimension_2 |
|------|------------|------------|
| 退市按计划执行率 | 总体/PM/营销部/渠道 | 总体/具体值/内销合计/合计 |
| 退市周期缩减率 | 总体/渠道/营销部 | 总体/具体值/合计 |

### 2.5 渠道映射
- 来源：dim.dim_ipd_td_weidu_nd WHERE zhibiao='渠道'
- 逻辑：营销部(udp1) → 渠道(udp2)
- 枚举：地产/公建/家装/电商

## 三、脚本清单

| 脚本 | 层级 | 目标表 | 说明 |
|------|------|--------|------|
| create_tables.sql | DDL | 3张表 | 新建DWS明细表×2 + 飞书虚拟表 |
| dws_ipd_ipm_rili_ajhwcl_detail_dd.sql | DWS | dws.dws_ipd_ipm_rili_ajhwcl_detail_dd | 退市按计划执行率明细 |
| ads_ipd_ipm_rili_ajhwcl_result_dd.sql | ADS | ads.ads_ipd_ipm_rili_ajhwcl_result_dd | 退市按计划执行率结果 |
| dws_ipd_ipm_rili_gjdsj_detail_dd.sql | DWS | dws.dws_ipd_ipm_rili_gjdsj_detail_dd | 退市周期缩减率明细 |
| ads_ipd_ipm_rili_gjdsj_result_dd.sql | ADS | ads.ads_ipd_ipm_rili_gjdsj_result_dd | 退市周期缩减率结果 |

## 四、调度依赖

```
dim.dim_ipd_ipm_rili_plan_dd（飞书虚拟表，需定期更新）
    ↓
dws_ipd_ipm_rili_ajhwcl_detail_dd → ads_ipd_ipm_rili_ajhwcl_result_dd
dws_ipd_ipm_rili_gjdsj_detail_dd → ads_ipd_ipm_rili_gjdsj_result_dd
```

## 五、待跟进事项

- [ ] 飞书虚拟表(dim.dim_ipd_ipm_rili_plan_dd)数据灌入：需对接飞书API或手工导入
- [ ] 渠道映射配置：确认dim_ipd_td_weidu_nd中zhibiao='渠道'的配置数据是否已录入
- [ ] ADS结果表历史数据回刷：去年同期数据需先通过DWS回刷后ADS才能计算缩减率
