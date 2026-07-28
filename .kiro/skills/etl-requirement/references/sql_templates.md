---
inclusion: fileMatch
fileMatchPattern: '**/*.sql'
---
# SQL实战模板库

## 概述

本文档包含从已有需求SQL中提取的**实战模板**，Agent生成SQL时优先使用这些模板组合，而非从零编写。

---

## 模板1：DELETE + INSERT 幂等模式（DWS层标准）

**适用场景**：DWS层按月增量加载，保护"老品清零"历史数据不被覆盖。

```sql
-- 删除当月非老品清零的旧数据（保护历史标记）
DELETE FROM {target_schema}.{target_table}
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND company IN ({company_list})
    AND product_line IN ({product_line_list})
    AND dt_type = '月'
    AND dt_day < CAST('${GP_START_DT}' AS DATE)
    AND model_label_10 <> '老品清零';

-- 删除当天及之后的数据（全量覆盖）
DELETE FROM {target_schema}.{target_table}
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND company IN ({company_list})
    AND product_line IN ({product_line_list})
    AND dt_type = '月'
    AND dt_day >= CAST('${GP_START_DT}' AS DATE);

-- 插入新数据
INSERT INTO {target_schema}.{target_table}(
    {field_list}
)
{select_statement};
```

**使用说明**：
- `{company_list}`：如 `'冰冷','洗衣机'`
- `{product_line_list}`：如 `'冰箱','冷柜','洗衣机'`
- 老品清零保护逻辑：已标记为老品清零的记录不删除，保留历史

---

## 模板2：冰冷洗产品线分类 CTE

**适用场景**：从 dim_ipd_productmodel_dd 中按产品大类/中类/小类判定产品线。

```sql
,product_model AS (
SELECT
    id,
    PG00061,    --产品型号名称
    CASE
        -- 内销：家用冰箱
        WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冰箱' AND PG00004 IN ('冷藏冷冻箱','冷藏箱') AND PG00020 = '内销' THEN '冰箱'
        WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冰箱' AND PG00004 = '冷冻箱' AND PC00001 = '冰箱' AND PG00020 = '内销' THEN '冰箱'
        WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冰箱' AND PG00004 = '冷冻箱' AND PG00020 = '内销' THEN '冷柜'
        -- 内销：家用冷柜
        WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冷柜' AND PG00020 = '内销' THEN '冷柜'
        -- 内销：家用展示柜（冰吧）
        WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用展示柜' AND PG00004 = '冰吧' AND PG00020 = '内销' THEN '冷柜'
        -- 外销：家用冰箱
        WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冰箱' AND PG00020 = '外销' THEN '冰箱'
        -- 外销：家用冷柜
        WHEN PG00002 = '控温储藏类产品' AND PG00003 = '家用冷柜' AND PG00020 = '外销' THEN '冷柜'
        -- 洗衣机
        WHEN PG00002 = '清洁卫生器具' AND PG00003 IN ('洗衣机','干衣机','护理机') THEN '洗衣机'
        ELSE '其他'
    END AS product_line,
    PG00029,    --产品型号生命周期状态
    PG00020,    --内销/外销
    PG00005,    --品牌
    {other_fields}
FROM dim.dim_ipd_productmodel_dd
)
```

---

## 模板3：冰冷洗指标范围判定 CTE

**适用场景**：判定型号是否纳入指标统计范围（gorenje剔除、外销标机样机CKD剔除）。

```sql
-- 在product_model CTE内部添加
,CASE
    WHEN PG00020 = '内销' THEN
        CASE WHEN PG00005 IN ('gorenje') THEN 'N' ELSE 'Y' END
    WHEN PG00020 = '外销' THEN
        CASE
            WHEN COALESCE(HX00026,'否') = '是' OR COALESCE(HX00027,'否') = '是' THEN 'N'  --标机/样机
            WHEN HX00023 IN ('欧洲大区','美洲大区') AND HX00226 = 'CKD' THEN 'N'  --全散件
            ELSE 'Y'
        END
    ELSE 'Y'
END AS is_zhibiaofanwei
```

---

## 模板4：库存清零判定 CTE

**适用场景**：根据退市状态+库存数量判定型号阶段。

```sql
,zx_model AS (
SELECT
    t1.*,
    t2.kc_sum,
    CASE
        WHEN t1.jieduan = '退市' AND COALESCE(t2.kc_sum, 0.0) = 0 THEN '老品清零'
        WHEN t1.jieduan = '退市' AND COALESCE(t2.kc_sum, 0.0) <> 0 THEN '老品'
        ELSE t1.jieduan
    END AS jieduan_final
FROM product_model t1
LEFT JOIN kc_all t2 ON t1.PG00061 = t2.productmodel
)
```

---

## 模板5：库存汇总 CTE（多源 UNION ALL）

**适用场景**：冰冷洗内销库存从多个源汇总。

```sql
,kc_nx AS (
-- 内销库存汇总
SELECT matnr, SUM(qty) AS kc_sum
FROM (
    -- 源1：大库龄明细
    SELECT goods_code AS matnr, qty
    FROM dws.dws_fi_mr_bxp_dklmx_di
    WHERE invstatus = '正品' AND daymonth_flag = '0'
        AND load_dt = CAST('${GP_START_DT}' AS DATE)

    UNION ALL
    -- 源2：营销产成品明细（寄售）
    SELECT matnr, occupynumber
    FROM dws.dws_fi_mr_bxp_yxccpmx_all_di
    WHERE qbkcfl IN ('寄售-线上','寄售-线下') AND daymonth_flag = '0'
        AND load_dt = CAST('${GP_START_DT}' AS DATE)
) t1
GROUP BY matnr
)
```

---

## 模板6：外销库存汇总 CTE（海外+基地+在途）

**适用场景**：外销库存从三个源汇总。

```sql
,kc_wx AS (
-- 海外分公司库存
SELECT matnr, clabs AS kc_sum, prouductmodel_rd, {fields}
FROM dwd.dwd_ipd_ipm_bd_s810_ztsd_zcpkc_rd_dd
WHERE lfgja = DATE_FORMAT('${GP_START_DT}', '%Y')
    AND lfmon = DATE_FORMAT('${GP_START_DT}', '%m')
    AND udate = CAST('${GP_START_DT}' AS DATE)
    AND lgort IS NOT NULL AND zkwlb = 'A'
    AND SUBSTRING(werks,1,2) <> '80'
    AND quzu_rd IN ('国际营销','东盟区')

UNION ALL
-- 基地库存
SELECT matnr, menge, prouductmodel_rd, {fields}
FROM dwd.dwd_ipd_ipm_bd_s810_zhd_zfi013_rd_dd
WHERE gjahr = DATE_FORMAT('${GP_START_DT}', '%Y')
    AND monat = DATE_FORMAT('${GP_START_DT}', '%m')
    AND pdate = CAST('${GP_START_DT}' AS DATE)
    AND quzu_rd IN ('国际营销','东盟区')

UNION ALL
-- 在途库存
SELECT matnr, menge, prouductmodel_rd, {fields}
FROM dwd.dwd_ipd_ipm_bd_s810_zbi_zrfi010z_d_rd_dd
WHERE budat = CAST('${GP_START_DT}' AS DATE)
    AND bukrs NOT IN ('8300','8320','8330','8370','8380','8390','83B0')
    AND menge >= 1
)
```

---

## 模板7：空调产品线分类 CTE

**适用场景**：从 dim_ipd_productmodel_dd 中判定空调内部组织。

```sql
,product_model AS (
SELECT id, PG00061,
    CASE
        WHEN PG00061 = 'KFR-120LW/SEA-X1' THEN '轻商内销'
        WHEN pg00003 IN ('除湿机') THEN '家空外销'
        WHEN pg00015 = '空调' AND PG00020 = '内销' AND pg00003 = '家用房间空调' AND pg00004 IN ('分体式空调器整机') THEN '家空内销'
        WHEN pg00015 = '空调' AND PG00020 = '外销' AND pg00003 = '家用房间空调' AND pg00004 IN ('分体式空调器整机','移动式空调器','窗式空调器') THEN '家空外销'
        WHEN pg00015 = '空调' AND PG00020 = '内销' AND pg00003 = '中央空调' AND COALESCE(PG00005,'Hisense') <> 'KELON' AND COALESCE(HX00083,'补充') <> 'ODM'
            AND pg00004 IN ('单元式内机','单元式外机','单元式整机','多联机内机','多联机外机','风机盘管','空气源热泵两联供','热泵热水机','涡旋式冷水(热泵)机组','新风换气机','一拖多外机') THEN '轻商内销'
        WHEN pg00015 = '日立' AND PG00020 = '内销' AND pg00003 = '中央空调' AND COALESCE(hx00427,'否') = '否'
            AND pg00004 IN ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') THEN '央空内销日立'
        WHEN pg00015 = '日立' AND PG00020 = '外销' AND pg00003 = '中央空调' AND COALESCE(hx00427,'否') = '否'
            AND pg00004 IN ('单元式整机','单元式内机','一拖多外机','多联机内机','多联机外机','空气源热泵两联供','空气源热泵三联供','空气消毒机','新风换气机','单元式外机','热泵热水机') THEN '央空外销日立'
        ELSE '其他'
    END AS kt_nbzz,
    {other_fields}
FROM dim.dim_ipd_productmodel_dd
WHERE pg00002 = '空气调节类产品'
    AND COALESCE(productline_syb, '填空') <> '环境电器'
)
```

---

## 模板8：ADS层汇总模板（含"全部"维度行）

**适用场景**：ADS层按公司/产品线/内外销汇总，同时生成"全部"维度的汇总行。

```sql
DELETE FROM {ads_table}
WHERE company IN ({company_list})
    AND dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND data_type = '{data_type}';

INSERT INTO {ads_table}(
    dt_month, dt_type, data_type, business_division, company,
    product_line, in_out_sale, act_num, load_dt
)
WITH weidu_neiwaixiao AS (
    SELECT '全部' AS in_out_sale UNION ALL SELECT '内外销' AS in_out_sale
)
,weidu_product_line AS (
    SELECT '全部' AS product_line UNION ALL SELECT '非全部' AS product_line
)
SELECT
    t1.dt_month,
    t1.dt_type,
    '{data_type}',
    t1.business_division,
    t1.company,
    CASE WHEN t3.product_line = '全部' THEN '全部' ELSE t1.product_line END AS product_line,
    CASE WHEN t2.in_out_sale = '全部' THEN '全部' ELSE t1.in_out_sale END AS in_out_sale,
    COUNT(DISTINCT t1.model),
    NOW()
FROM {dws_table} t1
LEFT JOIN weidu_neiwaixiao t2 ON 1=1
LEFT JOIN weidu_product_line t3 ON t1.company IN ({multi_product_line_companies})
WHERE t1.dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m')
    AND t1.company IN ({company_list})
    AND t1.is_project = 'N'
GROUP BY t1.dt_month, t1.company,
    CASE WHEN t3.product_line = '全部' THEN '全部' ELSE t1.product_line END,
    CASE WHEN t2.in_out_sale = '全部' THEN '全部' ELSE t1.in_out_sale END,
    t1.dt_type, t1.business_division;
```

**使用说明**：
- `weidu_neiwaixiao`：生成"全部"内外销的汇总行
- `weidu_product_line`：对有多条产品线的公司（冰冷、空调）生成"全部"产品线汇总行
- `{multi_product_line_companies}`：如 `'冰冷','空调公司'`

---

## 模板9：is_project 保护期判定

**适用场景**：DWS层判定型号是否纳入指标统计。

```sql
,CASE
    WHEN t1.is_zhibiaofanwei = 'N' THEN 'Y'                    --不在指标范围内
    WHEN t1.jieduan IN ('未上市','老品清零','其他') THEN 'Y'     --非在产阶段
    WHEN t1.jieduan IN ('老品') AND t2.productmodel IS NOT NULL THEN 'Y'  --历史已清零
    ELSE 'N'
END AS is_project
```

---

## 模板10：test库中间表模式（Doris临时表替代）

**适用场景**：需要多步计算的中间结果。

```sql
-- 先删除旧表（幂等）
DROP TABLE IF EXISTS test.{中间表名};

-- 创建中间表（CTAS方式）
CREATE TABLE test.{中间表名}
ENGINE = OLAP
DUPLICATE KEY({首列字段})
AS
SELECT
    {select_fields}
FROM {source_table}
WHERE {conditions};
```

---

## 模板11：管报数据关联MDG（物料→型号映射）

**适用场景**：从管报销量数据通过MDG主数据映射到产品型号。

```sql
SELECT
    s.yearmonth,
    p.model_name AS prdct_model,    --产品型号名称
    SUM(s.sale_qty) AS act_sales_qty,
    SUM(s.rev_amt) AS act_sales_amt,
    SUM(s.cost_amt) AS act_cost,
    SUM(s.rev_amt) - SUM(s.cost_amt) AS act_gross_profit
FROM ods.ods_mr_v_app_fm_imat_saledata s
LEFT JOIN (
    SELECT product_code, model_name
    FROM dw.dim_product_base_info_dd
    WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y'
) p ON s.matnr = p.product_code
WHERE s.yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
GROUP BY s.yearmonth, p.model_name
```

---

## 模板12：日立销售型号编码口径汇总

**适用场景**：日立以sale_model_code为管理口径汇总销量。

```sql
SELECT
    p.sale_model_code,
    SUM(s.sale_qty) AS act_sales_qty,
    SUM(s.rev_amt) AS act_sales_amt,
    SUM(s.cost_amt) AS act_cost,
    SUM(s.rev_amt) - SUM(s.cost_amt) AS act_gross_profit
FROM ods.ods_mr_v_app_fm_imat_saledata s
LEFT JOIN (
    SELECT product_code, sale_model_code
    FROM dw.dim_product_base_info_dd
    WHERE product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y'
) p ON s.matnr = p.product_code
WHERE s.yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
GROUP BY p.sale_model_code
```

---

## 模板13：LX立项规划量行转列（SPLIT + LATERAL VIEW）

**适用场景**：将产品型号/销售型号的36个月规划字段（HX00506~HX00541）拆分为按月一行的记录，写入DWD层BP/LX中间表。

**来源**：002-dx-model-rate / dwd_ipd_ipm_bp_lx_model_mid_dd.sql

```sql
WITH hdrp_product AS (
    SELECT
        {model_name_field}                          -- 型号名称字段（PG00061）
        ,{category_fields}                          -- 产品大类/中类/小类（PG00002/PG00003/PG00004）
        ,PG00025                                    -- 实际上市时间
        ,CONCAT(
            DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 1 MONTH), '%Y%m'), ','
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 2 MONTH), '%Y%m'), ','
            -- ... 重复到36个月
            ,DATE_FORMAT(DATE_ADD(PG00025, INTERVAL 36 MONTH), '%Y%m')
        ) AS dt_month
        ,CONCAT(
            COALESCE(HX00506, 0.0), ','
            ,COALESCE(HX00507, 0.0), ','
            -- ... 重复到HX00541
            ,COALESCE(HX00541, 0.0)
        ) AS plan_sales
    FROM {source_dim_table}
    WHERE HX00506 IS NOT NULL
      AND PG00025 IS NOT NULL
      AND {filter_conditions}
)
SELECT
    {model_name_field}
    ,'LX' AS plan_type
    ,{category_fields}
    ,element_at(sbs_dt_month, idx) AS dt_month
    ,element_at(sbs_plan_sales, idx) AS plan_sales_qty
    ,NOW() AS load_dt
    ,'{model_type}' AS model_type
FROM (
    SELECT
        {fields}
        ,SPLIT_BY_STRING(dt_month, ',') AS sbs_dt_month
        ,SPLIT_BY_STRING(plan_sales, ',') AS sbs_plan_sales
        ,sequence(1, cardinality(SPLIT_BY_STRING(dt_month, ',')) + 1) AS idx_array
    FROM hdrp_product
) t
LATERAL VIEW explode(idx_array) tmp AS idx;
```

**使用说明**：
- `{source_dim_table}`：`dim.dim_ipd_productmodel_dd`（产品型号口径）或 `dim.dim_ipd_salemodel_dd`（销售型号编码口径）
- `{model_type}`：`'产品型号口径'` 或 `'销售型号编码口径'`
- Doris特有语法：`SPLIT_BY_STRING`、`element_at`、`LATERAL VIEW explode`
- 配合 DELETE + INSERT 幂等模式使用（先删除对应 plan_type + product_big 的旧数据）

---

## 模板14：DWS引用在销型号数做销量关联

**适用场景**：单型号销量等指标从在销型号数DWS表取型号范围，再LEFT JOIN管报销量数据。

**来源**：007-single-model-sales / dws_ipd_ipm_dxhxl_detail_dd.sql

```sql
WITH zx_model AS (
    -- 从在销型号数明细表取上月末型号范围
    SELECT *
    FROM dws.dws_ipd_ipm_sale_model_detail_dd
    WHERE product_line IN ({product_line_list})
      AND in_out_sale = '{in_out_sale}'
      AND dt_month = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
      AND dt_day = date_sub(STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d'), INTERVAL 1 DAY)
      AND dt_type = '月'
)
,sale_amt AS (
    -- 管报销量按型号汇总
    SELECT
        {model_mapping_field} AS model_name
        ,SUM(t1.sale_qty) AS sale_qty
        ,SUM(t1.rev_amt) AS rev_amt
        ,SUM(t1.cost_amt) AS cost_amt
        ,SUM(t1.rev_amt) - SUM(t1.cost_amt) AS gross_profit
    FROM ods.ods_mr_v_app_fm_imat_saledata t1
    LEFT JOIN (
        SELECT product_code, {model_mapping_field}
        FROM dw.dim_product_base_info_dd
        WHERE product_type_code = 'FERT' AND delete_flag != 'Y'
    ) t2 ON t1.matnr = t2.product_code
    WHERE t1.yearmonth = DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY {model_mapping_field}
)
SELECT DISTINCT
    DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m') AS dt_month
    ,'月' AS dt_type
    ,{business_division_logic} AS business_division
    ,t1.company
    ,t1.product_line
    ,'{in_out_sale}' AS in_out_sale
    ,t1.model
    ,t2.sale_qty
    ,t2.rev_amt
    ,'管报' AS sales_type
    ,{label_fields}
    ,COALESCE(t1.is_project, 'Y') AS is_project
    ,NOW() AS load_dt
    ,t2.cost_amt
    ,t2.gross_profit
FROM zx_model t1
LEFT JOIN sale_amt t2 ON t1.model = t2.model_name;
```

**使用说明**：
- `{model_mapping_field}`：非日立用 `model_name`，日立用 `sale_model_code`
- `dt_day` 取上月最后一天：`date_sub(本月1日, INTERVAL 1 DAY)`
- 在销型号表提供型号范围 + is_project标记，管报提供实际销量

---

## 模板15：滑动窗口12个月最大销量

**适用场景**：企划命中率等需要计算"累计连续12个月最大销量"的场景。通过CROSS JOIN生成偏移量，逐窗口聚合后取MAX。

**来源**：003-qihua-hit-rate / dws_ipd_ipm_qihua_hit_detail_dd.sql

```sql
-- 按月销量明细
,monthly_sales AS (
    SELECT
        {group_key}                                 -- 分组键（如project_code）
        ,ms.yearmonth                               -- 年月
        ,SUM(ms.sale_qty) AS sale_qty               -- 月销量
    FROM {monthly_sales_source} ms
    INNER JOIN {scope_table} sm ON {join_condition}
    GROUP BY {group_key}, ms.yearmonth
)
-- 滑动窗口计算（最多24个窗口偏移）
,rolling_12m_detail AS (
    SELECT
        pb.{group_key}
        ,offsets.offset
        ,SUM(COALESCE(pms.sale_qty, 0)) AS window_sum
    FROM {base_table} pb
    CROSS JOIN (
        SELECT 0 AS offset UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
        UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
        UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
        UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
    ) offsets
    LEFT JOIN monthly_sales pms
        ON pb.{group_key} = pms.{group_key}
       AND pms.yearmonth >= DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (1 + offsets.offset) MONTH), '%Y%m')
       AND pms.yearmonth < DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
    WHERE pb.listing_date IS NOT NULL
      AND DATE_FORMAT(DATE_ADD(pb.listing_date, INTERVAL (13 + offsets.offset) MONTH), '%Y%m')
          <= DATE_FORMAT(date_sub('${GP_START_DT}', INTERVAL 1 MONTH), '%Y%m')
    GROUP BY pb.{group_key}, offsets.offset
)
,rolling_12m AS (
    SELECT {group_key}, MAX(window_sum) AS max_rolling_12m_qty
    FROM rolling_12m_detail
    WHERE window_sum > 0
    GROUP BY {group_key}
)
```

**使用说明**：
- 窗口大小固定12个月，偏移量0~23覆盖上市后最多36个月
- `listing_date`：上市时间，窗口起点
- 最终取所有窗口中的MAX值作为"累计连续12个月最大销量"
- 适用于Doris不支持窗口函数RANGE BETWEEN的场景

---

## 模板16：BI数据集公共筛选条件模式

**适用场景**：BI报表数据集SQL，支持多参数全选/多选，无需建表直接查询。

**来源**：009-design-change-stats / design_change_bi_datasets.sql

```sql
SELECT
    {select_fields}
FROM {source_table}
WHERE LEFT({time_field}, 7) >= '${start_month}'
    AND LEFT({time_field}, 7) <= '${end_month}'
    AND ({dim_field_1} IN (${param_1}) OR '${param_1}' = '%')
    AND ({dim_field_2} IN (${param_2}) OR '${param_2}' = '%')
    AND ({dim_field_3} IN (${param_3}) OR '${param_3}' = '%')
GROUP BY {group_fields}
ORDER BY {order_fields};
```

**使用说明**：
- 每个筛选条件用 `OR '${param}' = '%'` 实现"全选"逻辑
- 时间字段为varchar时用 `LEFT(field, 7)` 截取年月进行范围比较
- 适用于无需建表、直接查询的BI数据集场景（如设计变更统计）
- 去重计数用 `COUNT(DISTINCT name)` 而非 `COUNT(*)`

---

## 模板17：空调内机→整机转换（轻商去重）

**适用场景**：空调在销型号数中，轻商单元式内机/外机有对应整机时不单独计数，避免重复。

**来源**：004-sale-model-count / dws_ipd_ipm_sale_model_detail_dd.sql

```sql
-- 识别有整机对应的内机/外机（需要剔除）
,danyuanji_tichu AS (
    -- 有整机对应的内机
    SELECT PG00061
    FROM {model_cte}
    WHERE pg00004 IN ('单元式内机', '热风机内机')
      AND is_project = 'N'
      AND PG00061 IN (
          SELECT DISTINCT pc20029
          FROM {model_cte}
          WHERE pg00004 IN ('单元式整机', '热风机整机')
            AND is_project = 'N'
            AND pc20029 IS NOT NULL
      )

    UNION ALL
    -- 有整机对应的外机
    SELECT PG00061
    FROM {model_cte}
    WHERE pg00004 IN ('单元式外机', '热风机外机')
      AND is_project = 'N'
      AND PG00061 IN (
          SELECT DISTINCT pc20055
          FROM {model_cte}
          WHERE pg00004 IN ('单元式整机', '热风机整机')
            AND is_project = 'N'
            AND pc20055 IS NOT NULL
      )
)
-- 最终结果中将被剔除的内外机标记为保护期
SELECT
    ...
    ,CASE WHEN t2.PG00061 IS NOT NULL THEN 'Y' ELSE t1.is_project END AS is_project
FROM {model_cte} t1
LEFT JOIN danyuanji_tichu t2
    ON t1.PG00061 = t2.PG00061
    AND t1.kt_nbzz = '轻商内销';
```

**使用说明**：
- `pc20029`：内机产品型号字段（dim_ipd_productmodel_dd）
- `pc20055`：外机产品型号字段（dim_ipd_productmodel_dd）
- 逻辑：如果一个内机/外机型号能在整机的pc20029/pc20055中找到，说明有对应整机，则该内机/外机不单独计数
- 仅对轻商内销生效（`kt_nbzz = '轻商内销'`）

---

## 模板选择规则

| 需求场景 | 推荐模板组合 |
|----------|-------------|
| 冰冷洗在销/在产型号 | 模板1 + 模板2 + 模板3 + 模板4 + 模板5 + 模板9 |
| 冰冷洗外销型号 | 模板1 + 模板2 + 模板3 + 模板4 + 模板6 + 模板9 |
| 空调型号类指标 | 模板1 + 模板7 + 模板4 + 模板9 + 模板17 |
| ADS层汇总 | 模板8 |
| 涉及管报销量（非日立） | 模板11 |
| 涉及管报销量（日立） | 模板12 |
| 需要中间计算 | 模板10 |
| DWD层LX规划量拆分 | 模板13 |
| 单型号销量/销额 | 模板14 + 模板1 |
| 企划命中率（滑动窗口） | 模板15 + 模板12 |
| BI数据集（无需建表） | 模板16 |
| 空调轻商去重 | 模板17 + 模板7 |
