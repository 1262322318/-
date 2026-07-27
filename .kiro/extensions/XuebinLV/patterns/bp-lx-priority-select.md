# BP/LX优先选择模式

> 从002需求（低效型号/新品命中率）中提炼，适用于所有涉及规划量与实际量对比的指标。

## 1. 适用场景

需要将"实际销量"与"规划销量"做对比（如完成率、命中率、低效判定），且规划量有两个来源：
- **BP**（Business Plan）：来自HDRP系统，按年度12个月分配
- **LX**（立项规划量）：来自产品型号/销售型号维表的36个月规划字段

## 2. 识别信号

- 需求涉及"规划量"、"BP"、"LX"、"命中率"、"完成率"
- 关键词：规划量选择、BP vs LX、立项规划量
- 涉及表：dwd.dwd_ipd_ipm_bp_lx_model_mid_dd

## 3. 处理规则

### DWD层：规划量中间表

将BP和LX两种规划量展开为统一的**月度×型号**粒度中间表：

```sql
-- LX立项规划量（从产品型号36个月字段展开）
INSERT INTO dwd.dwd_ipd_ipm_bp_lx_model_mid_dd
SELECT
  dt_month,          -- 展开后的月份
  'LX' AS plan_type,
  prdct_model,       -- 型号名称
  salemodelcode,     -- 销售型号编码（日立用）
  plan_sales_qty,    -- 当月规划销量
  '产品型号口径' AS model_type
FROM dim.dim_ipd_productmodel_dd
-- 将HX00506~HX00541（36个月字段）UNPIVOT为36行

UNION ALL

-- BP规划量（从HDRP系统12个月展开）
SELECT
  dt_month,
  'BP' AS plan_type,
  matnr → model_name,
  NULL AS salemodelcode,
  plan_sales_qty,
  '产品型号口径' AS model_type
FROM ods.odshdrp_hisense_basis_point_target
-- 将12个月字段展开为12行
```

### DWS层：BP/LX选择逻辑

```sql
-- 核心：当立项首月在本年时用LX，否则用BP
SUM(
  CASE
    WHEN SUBSTRING(COALESCE(t_lx.min_dtmonth, '190001'), 1, 4) = YEAR('${GP_START_DT}')
    THEN t_lx.plan_sales_qty   -- 用LX
    ELSE t_bp.plan_sales_qty   -- 用BP
  END
) AS plan_sales_qty
```

### 时间对齐规则

| 场景 | 处理 |
|------|------|
| LX首月在本年 | 用LX，从立项首月开始累计 |
| LX首月在去年 | 用BP，按自然月累计 |
| 滞后上市 | 以实际上市时间开始算累计BP目标 |
| 外销新品命中率 | 仅用LX（无BP），按HX00020比例拆分12个月 |

## 4. 不适用条件

- 指标不涉及规划量对比（如在销型号数、平台数）
- 规划量来源为飞书手工填入的目标值（如ADS完成率的plan_value）
- 企划命中率（直接取HX00020首年规划量，不走BP/LX选择）

## 5. 验证案例

| 项目 | 应用方式 |
|------|----------|
| 002-dx-model-rate（低效型号） | DWD层BP/LX中间表 → DWS层按规则选择 |
| 002-dx-model-rate（新品命中率-内销） | 同上 |
| 002-dx-model-rate（新品命中率-外销） | 仅LX（HX00020拆分12个月） |
| 003-qihua-hit-rate（企划命中率） | 不走本模式，直接取HX00020 |
