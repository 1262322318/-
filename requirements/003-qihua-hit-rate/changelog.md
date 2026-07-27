# 调整记录 - 企划命中率（003-qihua-hit-rate）

## 概述
本文档记录003需求开发过程中每一次问题及对应的解决方式，便于后续追溯和复盘。

---

## 调整记录

### #001 — 初始需求拆分为两段式结构
- **日期**: 2026-04-24
- **问题**: 原始需求将型号口径和项目口径混在一个SQL中，可读性差，不便于分段调试和数据校验
- **解决方式**: 将DWS脚本拆分为两段：
  - 第一段：型号口径 — 只输出基础数据（取数范围、上下市时间、销量、规划量），不做阶段判定
  - 第二段：项目口径 — 从型号口径按project_code聚合后，在项目级别做6个阶段的判定和达标判断
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`, `lineage.md`, `requirement.md`

### #002 — 下市时间字段修正
- **日期**: 2026-04-24
- **问题**: 原使用 `HX00501`（退市准备时间）作为下市时间，但实际业务应使用停产时间
- **解决方式**: 将下市时间字段改为 `PG00027`（停产时间）
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`, `lineage.md`

### #003 — 滑动窗口CTE拆分优化
- **日期**: 2026-04-24
- **问题**: 滑动窗口12个月最大销量的计算在单个CTE中完成，包含HAVING过滤，调试不便
- **解决方式**: 拆分为两步CTE：
  - `rolling_12m_detail`：按窗口偏移量计算每个窗口的SUM
  - `rolling_12m`：取MAX(window_sum)，WHERE过滤window_sum>0
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`, `lineage.md`

### #004 — 血缘自动更新hook去除Python依赖
- **日期**: 2026-04-24
- **问题**: `.kiro/hooks/auto-update-lineage.kiro.hook` 中使用python脚本更新血缘关系，与纯Kiro方案冲突，每次编辑SQL都会弹出python脚本执行
- **解决方式**: 重写hook为askAgent方式，提示Agent直接用fsWrite更新lineage.md，不依赖任何Python脚本
- **影响文件**: `.kiro/hooks/auto-update-lineage.kiro.hook`

### #005 — ADS汇总层脚本开发
- **日期**: 2026-04-24
- **问题**: 需求中要求红黑榜展示，缺少ADS层汇总脚本
- **解决方式**: 新增 `ads_ipd_ipm_qihua_hit_result_dd.sql`，从DWS项目口径按营销部+阶段维度GROUP BY，统计总项目数、总SKU数、不达标项目数、不达标SKU数、达标率；另外增加stage=99的"不达标合计"行按营销部汇总所有阶段
- **影响文件**: `ads_ipd_ipm_qihua_hit_result_dd.sql`, `lineage.md`, `tables.txt`

### #006 — 首年规划量数据源变更
- **日期**: 2026-04-24
- **问题**: 原首年规划量从 `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd`（LX立项，销售型号编码口径）汇总SUM得到，但实际业务中首年规划量直接存储在销售型号基本信息表中
- **解决方式**: 改为从 `dim.dim_ipd_salemodel_dd.HX00020`（第一年规划量）直接取值，删除了 `plan_first_year` CTE 和对 `dwd` 表的依赖
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`, `requirement.md`, `lineage.md`, `tables.txt`, `data_mapping.md`
- **具体变更**:
  - DWS脚本：在sale_model CTE中新增 `COALESCE(t1.HX00020, 0) AS plan_first_year_qty`，删除plan_first_year CTE和LEFT JOIN
  - tables.txt：移除 `dwd.dwd_ipd_ipm_bp_lx_model_mid_dd`
  - data_mapping.md：补充 `HX00020` 字段说明
  - lineage.md：字段血缘、影响分析同步更新，版本升至2.3

### #007 — GROUP_CONCAT语法修正
- **日期**: 2026-04-24
- **问题**: GROUP_CONCAT中使用 `ORDER BY pc20080` 排序导致Doris报错（不支持在GROUP_CONCAT中使用ORDER BY），且 `SEPARATOR ','` 语法在Doris中不支持
- **解决方式**: 移除ORDER BY子句和SEPARATOR关键字，改为 `GROUP_CONCAT(DISTINCT pc20080, ',')`（Doris用第二个参数作为分隔符）
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`

### #008 — 项目停产逻辑修正
- **日期**: 2026-04-24
- **问题**: 项目口径中 `stop_production_date` 使用 `MAX(stop_production_date)` 取最晚停产时间，但需求文档要求"所有SKU都停产才算项目停产"。`MAX` 只要有一个SKU停产就有值，逻辑不一致
- **解决方式**: 改为 `CASE WHEN COUNT(CASE WHEN stop_production_date IS NULL THEN 1 END) = 0 THEN MAX(stop_production_date) ELSE NULL END`，即只有所有SKU的停产时间都非NULL时才取MAX，否则返回NULL
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`, `lineage.md`

### #009 — requirement.md字段名与SQL同步
- **日期**: 2026-04-24
- **问题**: requirement.md中关键字段设计表的字段名与SQL实际字段名不一致（`pc20080_list`→`pc20080`、`min_listing_date`→`listing_date`、`project_stop_date`→`stop_production_date`、`act_sales_qty`→`cum_sales_qty`、`plan_sales_qty`→`plan_first_year_qty`）
- **解决方式**: 统一requirement.md中的字段名为SQL实际使用的字段名，并补充 `data_type` 字段
- **影响文件**: `requirement.md`

### #010 — 新增事业部项目口径（第三段）
- **日期**: 2026-06-08
- **问题**: 业务需要按事业部（归属营销部pc20080）维度细分项目达标情况，现有项目口径只按project_code汇总，不区分事业部
- **解决方式**: 在DWS脚本末尾新增第三段（data_type='事业部项目口径'），逻辑与第二段完全一致，唯一差异是GROUP BY增加pc20080维度，滑动窗口和判定逻辑按事业部+项目分组
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`, `changelog.md`

### #011 — 正式版逻辑全面调整
- **日期**: 2026-06-18
- **问题**: 正式版取数逻辑落地，需调整多项规则
- **解决方式**: 
  - 产品小类从日立专属列表缩减为7个明确小类
  - 去掉品牌筛选和hx00427重复型号剔除
  - 新增委外工厂(PC00025)和模块组合(HX00379)剔除
  - 营销部增加"海外业务部(大客户)"共9个
  - 阶段4修正为仅=24月在产；停产②③仅取本月停产
  - 新增阶段5-7（停止下单相关），门槛=0
  - 新增红黑榜/考核标记字段（is_in_hongheibang、is_kaohe）
  - 新增近12个月销量字段（recent_12m_qty）
  - 新增停止下单时间字段（stop_order_date, PG00026）
  - 优化：stage_calc CTE集中阶段判定，消除重复CASE条件
  - ADS层增加is_in_hongheibang='Y'筛选
- **影响文件**: `dws_ipd_ipm_qihua_hit_detail_dd.sql`, `ads_ipd_ipm_qihua_hit_result_dd.sql`, `alter_tables_zhengshiban_draft.sql`
- **PRD来源**: `refined/20260616-yangkong-qihua-hitrate/2026-06-16_003_央空企划命中率正式版_prd.md`

---

## 模板（新增调整时复制）

### #0XX — 标题
- **日期**: YYYY-MM-DD
- **问题**: [描述遇到的问题]
- **解决方式**: [描述如何解决]
- **影响文件**: [列出受影响的文件]
