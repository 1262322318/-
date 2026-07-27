---
inclusion: always
---
# 业务规则库（公共规则）

## 概述

本文档定义**跨需求复用的公共业务规则**。Agent在生成SQL时读取本文件应用匹配到的规则。
指标专属的计算规则（如低效型号判定公式、命中率公式等）记录在各需求的 `requirement.md` 中。

## 公共规则清单

### PUB-001：指标范围标记规则（is_project）
- **触发关键词**：保护期、指标范围、is_project
- **适用指标**：所有DWS层明细表
- **规则描述**：
  - 所有DWS明细表保留全量数据（包括不符合指标范围的数据），通过 `is_project` 字段标记是否纳入指标统计
  - `is_project = 'N'`：符合当前指标统计范围，ADS层汇总时只取这部分数据
  - `is_project = 'Y'`：不符合当前指标统计范围，但保留在明细表中供追溯和分析
  - 每个指标的具体判定逻辑不同（如在销型号数看生命周期+库存，低效型号看上市月份，平台数看平台状态等），具体规则记录在各需求的 `requirement.md` 中
- **设计目的**：明细表存全量、标记字段做筛选，既保证数据完整性，又支持灵活的指标口径切换

### PUB-002：BP与LX规划量选择规则
- **触发关键词**：BP、立项、规划量选择
- **适用指标**：低效型号占比、新品命中率、单型号销量等涉及规划量的指标
- **规则描述**：
  - BP规划量来自HDRP系统，按年度12个月
  - LX立项规划量来自产品型号/销售型号的36个月规划字段
  - 当立项首月在本年时，用LX替代BP
  - 滞后上市以实际上市时间开始算累计BP目标
- **SQL实现**：
```sql
SUM(CASE WHEN SUBSTRING(COALESCE(t3.min_dtmonth, '190001'), 1, 4) = '当前年'
    THEN t2.plan_sales_qty  -- 用LX
    ELSE t1.plan_sales_qty  -- 用BP
END) AS plan_sales_qty
```

### PUB-003：产品线分类规则（冰冷洗）
- **触发关键词**：冰箱、冷柜、冰冷事业部、洗衣机
- **适用指标**：所有涉及冰冷洗产品线的指标
- **规则描述**：
  - **内销冰箱**：
    - 产品大类='控温储藏类产品' AND 产品中类='家用冰箱' AND 产品小类 IN ('冷藏冷冻箱','冷藏箱')
    - 产品大类='控温储藏类产品' AND 产品中类='家用冰箱' AND 产品小类='冷冻箱' AND 品类细分='冰箱'
  - **内销冷柜**：
    - 产品大类='控温储藏类产品' AND 产品中类='家用冰箱' AND 产品小类='冷冻箱' AND 品类细分≠'冰箱'
    - 产品大类='控温储藏类产品' AND 产品中类='家用冷柜'
    - 产品大类='控温储藏类产品' AND 产品中类='家用展示柜' AND 产品小类='冰吧'
  - **外销冰箱**：产品大类='控温储藏类产品' AND 产品中类='家用冰箱'
  - **外销冷柜**：产品大类='控温储藏类产品' AND 产品中类='家用冷柜'
  - **洗衣机**：产品大类='清洁卫生器具' AND 产品中类 IN ('洗衣机','干衣机','护理机')
- **ODM剔除**：海信/容声品牌但非海信/平度基地 → is_odm = 'Y'
- **gorenje品牌剔除**
- **SQL实现**：
```sql
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
END AS product_line
```

### PUB-004：日立管理口径规则
- **触发关键词**：日立、中央空调、销售型号编码口径
- **适用指标**：所有涉及日立/中央空调的指标
- **规则描述**：
  - 日立以销售型号编码（sale_model_code）为管理口径
  - 实际销量：管报 → MDG(product_code→sale_model_code) → 按sale_model_code汇总
  - 规划量：LX立项使用 model_type='销售型号编码口径'
  - MDG过滤：product_type_code IN ('FERT','ZTAO') AND delete_flag != 'Y'
  - 归属营销部过滤：日立家装营销部、海信家装营销部、大客户部、工程营销部、电商事业部、约克家装营销部、海外业务部(氟系统)、科龙商空营销部
  - 排除非标准品、委外工厂（1000-海信日立委外工厂）、模块组合
- **SQL实现**：
```sql
-- 日立口径：按销售型号编码汇总实际销量
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

### PUB-005：电视能效机转换规则
- **触发关键词**：平板电视、能效机、视像科技
- **适用指标**：所有涉及视像科技销量的指标
- **规则描述**：能效机的销量需要转换为原型机统计
- **映射表**：`dim.dim_ipd_tv_model_nengxiao_nd`（model_nengxiao → model）
- **SQL实现**：
```sql
COALESCE(t3.model, t2.model_name) AS zzprdmodel  -- 优先用原型机名称
```

### PUB-006：空调产品线分类规则
- **触发关键词**：空调、家用空调、轻商、中央空调
- **适用指标**：所有涉及空调产品线的指标
- **规则描述**：
  - 家空内销：产品公司='空调' AND 内销 AND 产品中类='家用房间空调' AND 产品小类='分体式空调器整机'
  - 家空外销：产品公司='空调' AND 外销 AND 产品中类='家用房间空调' AND 产品小类 IN ('分体式空调器整机','移动式空调器','窗式空调器')
  - 轻商内销：产品公司='空调' AND 内销 AND 产品中类='中央空调' AND 非KELON品牌 AND 非ODM
  - 央空内销日立：产品公司='日立' AND 内销 AND 产品中类='中央空调' AND 非重复型号
  - 央空外销日立：产品公司='日立' AND 外销 AND 产品中类='中央空调' AND 非重复型号
  - 排除环境电器产品（productline_syb != '环境电器'）
  - 轻商单元式内外机有整机的不单独计算

### PUB-007：库存清零判定规则
- **触发关键词**：库存清零、老品清零、退市
- **适用指标**：在销型号数、在产型号数
- **规则描述**：
  - 退市型号（停止服务/停止生产）库存为0 → 标记为"老品清零"
  - 退市型号库存不为0 → 标记为"老品"
  - 已清零型号不再重复纳入在销范围
- **SQL实现**：
```sql
CASE
    WHEN jieduan = '退市' AND COALESCE(kc_sum, 0) = 0 THEN '老品清零'
    WHEN jieduan = '退市' AND COALESCE(kc_sum, 0) <> 0 THEN '老品'
    ELSE jieduan
END AS jieduan
```

### PUB-008：调度参数规范
- **触发关键词**：调度参数、GP_START_DT
- **适用指标**：所有ETL脚本
- **规则描述**：
  - `${GP_START_DT}` 是调度系统传入的参数，代表脚本执行日期的前一天（即昨天），格式 yyyymmdd
  - 取上月年月：`DATE_FORMAT(date_sub('${GP_START_DT}', interval 1 month), '%Y%m')`
  - 取当月年月：`DATE_FORMAT('${GP_START_DT}', '%Y%m')`

### PUB-009：空调外销GSS排产单查询规则
- **触发关键词**：GSS、排产单、空调外销排产、排产通知单、技术评审
- **适用指标**：涉及空调外销排产数据的指标
- **规则描述**：
  - 数据来源：GSS系统排产单三表关联（头表+行表+开发行表）
  - 头表与行表通过 `prod_id` 关联
  - 开发行表额外条件 `is_zx = 2`
  - 关联关系：`oispl.h_spec` = `dim.dim_ipd_productmodel_dd.PG00061`（产品型号名称）
  - 批次状态（sale_stat）枚举：1=排产通知单未提交 / 3=未到开发 / 5=已到开发 / 7=技术评审通过 / 9=生产评审通过 / 11=草稿 / 13=待工艺审核 / 15=工艺审核中 / 17=已审核 / 19=待区域经理审核 / 21=待技术评审 / 23=工厂技术评审中 / 25=待工厂计划评审 / 27=工厂计划评审中 / 29=工厂计划已审核 / 31=订单已取消
  - 产品类型（item_type）枚举：1=整机 / 2=内机 / 3=外机 / 4=移动空调 / 5=空气净化器 / 6=窗机 / 7=除湿机 / 8=选购件 / 10=配件箱 / 11=面板组件 / 12=备件 / 13=全热交换器 / 14=半散件 / 15=全散件 / 16=电控 / 17=两器 / 18=冷凝器组件 / 19~21=原材料 / 22=加湿器 / 23=干衣机 / 25=一体式热泵热水器 / 26=整体式屋顶机
- **SQL实现**：
```sql
SELECT
    oisph.sale_stat,
    CASE oisph.sale_stat
        WHEN 1 THEN '排产通知单未提交'
        WHEN 3 THEN '排产通知单未到开发'
        WHEN 5 THEN '排产通知单已到开发'
        WHEN 7 THEN '技术评审通过'
        WHEN 9 THEN '生产评审通过'
        WHEN 11 THEN '草稿状态'
        WHEN 13 THEN '业务已提交，待工艺审核'
        WHEN 15 THEN '工艺审核中'
        WHEN 17 THEN '已审核'
        WHEN 19 THEN '业务已提交，待区域经理审核'
        WHEN 21 THEN '区域经理已提交，待技术评审'
        WHEN 23 THEN '工厂技术评审中'
        WHEN 25 THEN '技术已评审，待工厂计划评审'
        WHEN 27 THEN '工厂计划评审中'
        WHEN 29 THEN '工厂计划已审核'
        WHEN 31 THEN '订单已取消'
        ELSE '未知状态'
    END AS sale_stat_desc,
    oispl.item_type,
    CASE oispl.item_type
        WHEN 1 THEN '整机'
        WHEN 2 THEN '内机'
        WHEN 3 THEN '外机'
        WHEN 4 THEN '移动空调'
        WHEN 5 THEN '空气净化器'
        WHEN 6 THEN '窗机'
        WHEN 7 THEN '除湿机'
        WHEN 8 THEN '选购件'
        WHEN 10 THEN '配件箱'
        WHEN 11 THEN '面板组件'
        WHEN 12 THEN '备件'
        WHEN 13 THEN '全热交换器'
        WHEN 14 THEN '半散件'
        WHEN 15 THEN '全散件'
        WHEN 16 THEN '电控'
        WHEN 17 THEN '两器'
        WHEN 18 THEN '冷凝器组件'
        WHEN 19 THEN '原材料1'
        WHEN 20 THEN '原材料2'
        WHEN 21 THEN '原材料3'
        WHEN 22 THEN '加湿器'
        WHEN 23 THEN '干衣机'
        WHEN 25 THEN '一体式热泵热水器'
        WHEN 26 THEN '整体式屋顶机'
        ELSE '未知类型'
    END AS item_type_desc,
    oispl.h_spec,       -- 产品型号（原型），关联 dim.dim_ipd_productmodel_dd.PG00061
    oispl.qty,          -- 数量
    oispkl.ps_date      -- 技术评审通过时间
FROM ods.odsgss_im_sale_prod_header oisph
LEFT JOIN ods.odsgss_im_sale_prod_line oispl
    ON oisph.prod_id = oispl.prod_id
LEFT JOIN ods.odsgss_im_sale_prod_kf_line oispkl
    ON oisph.prod_id = oispkl.prod_id
    AND oispkl.is_zx = 2;
```

#### PUB-009补充：家空/轻商内外机转换规则
- **适用场景**：外销新品命中率中空调实际销量的计算
- **映射表**：`dim.dim_ipd_productmodel_dd` 中产品小类='分体式空调器整机'的产品，其 `PC20029`（内机产品型号）和 `pc20055`（外机产品型号）字段提供整机↔内外机的映射关系
- **家空外销转换规则**（以整机为管理口径）：
  - 整机订单（item_type=1）：直接计入整机型号的销量
  - 内机订单（item_type=2）：通过映射表找到对应整机型号，销量×0.5计入整机
  - 外机订单（item_type=3）：通过映射表找到对应整机型号，销量×0.5计入整机
  - 其他品类（移动空调/窗机/除湿机等）：直接计入对应型号
- **轻商外销转换规则**（以内机/外机为管理口径，与家空相反）：
  - 内机/外机订单：直接计入对应型号的销量
  - 整机订单：通过映射表的PC20029/pc20055拆分到对应的内机和外机，各计入一份销量
- **注意**：不限制item_type筛选，只对整机/内机/外机做转换规则处理
- **非空调产品线外销实际销量**：见PUB-010

### PUB-010：外销GSS协议订单量规则（非空调产品线）
- **触发关键词**：GSS协议订单、外销实际销量、协议发布量、冰冷洗外销订单、电视外销订单、厨电外销订单、激光外销订单
- **适用指标**：外销新品命中率等涉及非空调产品线外销实际销量的指标
- **规则描述**：
  - 空调外销走PUB-009排产单逻辑，其他产品线走本规则的GSS协议订单逻辑
  - 本规则属于其它领域数据，不需要O层详细规则说明，仅提供代码块作为数据集使用
  - 各产品线GSS系统不同、表不同、筛选条件不同，分别列出

#### PUB-010-A：冰冷洗外销GSS协议订单
- **数据源**：`ods.odsgss_im_order_agreement` + `ods.odsgss_im_rolling_plan_detail` + 产品对照表
- **协议状态**：'协议已发布' / '工艺BOM已发布'
- **输出**：产品型号(product_model) + 数量(act_qty)
- **SQL实现**：
```sql
SELECT
    t.product_model AS prdct_model,
    SUM(b.amount) AS act_qty
FROM ods.odsgss_im_order_agreement a
LEFT JOIN ods.odsgss_im_rolling_plan_detail b
    ON b.roll_plan_number = a.roll_plan_number AND b.enable_flag = 'T'
LEFT JOIN (
    SELECT t1.product_code, t1.product_model FROM ods.odsgss_im_ecc_pln_bd_product_title t1 WHERE t1.enable_flag = 'T'
    UNION
    SELECT t2.product_code, t2.product_model FROM ods.odsgss_im_ecc_pln_bd_lg_product_title t2 WHERE t2.enable_flag = 'T'
    UNION
    SELECT t3.product_code, t3.product_model FROM ods.odsgss_im_ecc_pln_bd_xyj_product_title t3 WHERE t3.enable_flag = 'T'
) t ON t.product_code = b.country_product
LEFT JOIN ods.odsgss_im_grs_dic d
    ON a.status = d.property_code AND d.dic_code = 'XIEYI_STATUS' AND d.enable_flag = 'T'
WHERE a.enable_flag = 'T'
    AND d.property_value IN ('协议已发布','工艺BOM已发布')
GROUP BY t.product_model
```

#### PUB-010-B：平板电视外销GSS订单
- **数据源**：`ods.odsgss_im_sales_order_title`
- **筛选条件**：滚动单号非R/B开头、订单状态排除(1002/1003/1005/1006)、有面板号(PANEL_CODE)、enable_flag='T'
- **型号映射**：生产版本(PRODUCT_CODE) → `dw.dim_product_base_info_dd`(short_desc_zh→model_name, product_type_code='ZZPV')，无法映射时截取括号前部分
- **输出**：产品型号(prdct_model) + 数量(act_qty)
- **SQL实现**：
```sql
SELECT
    SUM(t1.ORDER_QTY) AS act_qty,
    COALESCE(t2.model_name, SUBSTRING_INDEX(t1.PRODUCT_CODE, '(', 1)) AS prdct_model
FROM (
    SELECT PRODUCT_CODE, ORDER_QTY
    FROM ods.odsgss_im_sales_order_title
    WHERE ROLL_PLAN_NUMBER NOT LIKE 'R%'
        AND ROLL_PLAN_NUMBER NOT LIKE 'B%'
        AND ORDER_STATUS_CODE NOT IN ('1002','1003','1005','1006')
        AND COALESCE(PANEL_CODE, '无') != '无'
        AND enable_flag = 'T'
) t1
LEFT JOIN (
    SELECT DISTINCT short_desc_zh, model_name
    FROM dw.dim_product_base_info_dd
    WHERE product_type_code = 'ZZPV' AND delete_flag != 'Y'
) t2 ON t1.PRODUCT_CODE = t2.short_desc_zh
GROUP BY COALESCE(t2.model_name, SUBSTRING_INDEX(t1.PRODUCT_CODE, '(', 1))
```

#### PUB-010-C：厨电外销GSS协议订单
- **数据源**：`ods.odsgss_im_cw_order_ledger`
- **筛选条件**：agreement_status IN ('bom_published','published')、product_line_name IN ('洗碗机','厨电')
- **输出**：出口型号(export_type_no→prdct_model) + 数量(act_qty)
- **SQL实现**：
```sql
SELECT
    export_type_no AS prdct_model,
    SUM(qty) AS act_qty
FROM ods.odsgss_im_cw_order_ledger
WHERE agreement_status IN ('bom_published','published')
    AND product_line_name IN ('洗碗机','厨电')
GROUP BY export_type_no
```

#### PUB-010-D：激光外销GSS订单
- **数据源**：`ods.odsgss_im_jg_order`
- **筛选条件**：TURN_STATUS IN ('8','9','10','11','12','13')、排除空壳样机(MODEL_CODE NOT LIKE '%(30)%')、排除DUMMY客户型号、排除CKD-DK出口方式
- **型号映射**：生产版本(model_code) → `dw.dim_product_base_info_dd`(short_desc_zh→model_name, product_type_code='ZZPV')，无法映射时截取括号前部分
- **输出**：产品型号(prdct_model) + 数量(act_qty)
- **SQL实现**：
```sql
SELECT
    SUM(t1.expect_qty) AS act_qty,
    COALESCE(t2.model_name, SUBSTRING_INDEX(t1.model_code, '(', 1)) AS prdct_model
FROM (
    SELECT model_code, expect_qty
    FROM ods.odsgss_im_jg_order
    WHERE TURN_STATUS IN ('8','9','10','11','12','13')
        AND MODEL_CODE NOT LIKE '%(30)%'
        AND UPPER(CUSTOMER_MODEL) NOT LIKE '%DUMMY%'
        AND EXPORT_PACKING_WAY != 'CKD-DK'
) t1
LEFT JOIN (
    SELECT DISTINCT short_desc_zh, model_name
    FROM dw.dim_product_base_info_dd
    WHERE product_type_code = 'ZZPV' AND delete_flag != 'Y'
) t2 ON t1.model_code = t2.short_desc_zh
GROUP BY COALESCE(t2.model_name, SUBSTRING_INDEX(t1.model_code, '(', 1))
```

## 规则匹配优先级
- **P0（必须应用）**：PUB-001（保护期）、PUB-003/006（产品线分类）
- **P1（建议应用）**：PUB-002（BP/LX选择）、PUB-004（日立口径）、PUB-007（库存清零）
- **P2（按需应用）**：PUB-005（能效机转换）、PUB-008（调度参数）、PUB-009（GSS排产单）、PUB-010（外销GSS协议订单）
