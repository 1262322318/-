# 多产品线分叉统一汇总模式

> 从002/004/005/006/007/008需求中提炼，覆盖IPM域最高频的DWS→ADS设计模式。

## 1. 适用场景

需要对**多条产品线**（冰箱/冷柜/洗衣机/家空/日立/视像/厨电/激光）执行**相似但有差异**的ETL逻辑，最终统一写入同一张目标表。

典型特征：
- 目标表按 product_line + company 区分各产品线数据
- 各产品线的数据源、关联路径、剔除规则不同
- ADS层统一按公司/产品线/内外销维度聚合

## 2. 识别信号

- 需求覆盖≥3条产品线
- 各产品线的核心指标公式相同，但取数路径不同
- 需求要求"集团汇总"或"事业部汇总"
- 关键词：全产品线、各事业部、统一看板

## 3. 处理规则

### DWS层结构（分支式INSERT）

```sql
-- 每条产品线一个独立的 DELETE + INSERT 段落
-- 段落内部使用CTE组织逻辑

-- === 第1段：冰冷洗 ===
DELETE FROM dws.target_table WHERE company = '冰冷' AND dt_month = ...;
INSERT INTO dws.target_table (字段列表)
WITH
  product_model AS (...),  -- 型号信息（来源各异）
  sales_data AS (...),     -- 销量数据（来源各异）
  kc_data AS (...)         -- 库存/其他业务数据（来源各异）
SELECT ... FROM product_model LEFT JOIN sales_data LEFT JOIN kc_data;

-- === 第2段：空调 ===
DELETE FROM dws.target_table WHERE company = '空调公司' AND dt_month = ...;
INSERT INTO dws.target_table (字段列表)
WITH ... SELECT ...;

-- === 第N段：激光 ===
-- 同结构，不同数据源和规则
```

### ADS层结构（统一聚合）

```sql
DELETE FROM ads.result_table WHERE dt_month = ...;
INSERT INTO ads.result_table (字段列表)
WITH
  weidu AS (SELECT ... FROM dim.dim_ipd_td_weidu_nd WHERE zhibiao='当前指标'),
  act_value AS (
    SELECT company, product_line, in_out_sale,
           COUNT(DISTINCT model) AS act_num  -- 或其他聚合
    FROM dws.target_table
    WHERE is_project = 'N' AND dt_month = ...
    GROUP BY company, product_line, in_out_sale
  ),
  -- 集团汇总段
  group_total AS (
    SELECT '集团汇总' AS company, '全部' AS product_line,
           SUM(act_num) AS act_num
    FROM act_value
    WHERE 各事业部筛选条件
  )
SELECT ... FROM weidu LEFT JOIN act_value ...
UNION ALL
SELECT ... FROM group_total LEFT JOIN plan_values ...;
```

### 关键设计决策

| 决策点 | 方案 | 原因 |
|--------|------|------|
| 各产品线独立INSERT vs 合并为一个大SQL | 独立INSERT | 便于扩展新产品线、便于定位问题、各段互不影响 |
| DELETE范围 | 按company+dt_month | 各产品线独立刷新，不影响其他产品线数据 |
| 字段列表 | 所有产品线统一 | 目标表结构固定，不存在的字段填NULL |
| 日立走单独的关联路径 | 是 | sale_model_code口径特殊（PUB-004），与其他产品线的model_name路径不同 |

## 4. 不适用条件

- 各产品线目标表结构完全不同（应拆分为独立需求）
- 只有1-2条产品线且无扩展预期
- 实时计算场景（本模式为批量T+1）
- 独立业务域（如009设计变更，无产品线概念）

## 5. 验证案例

| 项目 | 表 | 产品线数 |
|------|-----|----------|
| 004-sale-model-count | dws_ipd_ipm_sale_model_detail_dd | 内9+外7 |
| 002-dx-model-rate | dws_ipd_ipm_dxmodel_detail_dd | 内9+外7 |
| 007-single-model-sales | dws_ipd_ipm_dxhxl_detail_dd | 内8+外7 |

**效果**：新增产品线只需添加一个新段落（DELETE+INSERT+CTE），不改动已有产品线逻辑。实际经验：厨电从草稿→合入仅需追加一个段落。
