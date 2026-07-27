# 变更记录 - 低效型号占比与新品规划命中率（002-dx-model-rate）

## 概述
本文档记录002需求开发过程中的变更历史。

---

## 变更记录

### #001 — 初始版本录入
- **日期**: 2026-04-23
- **变更描述**: 从已有生产脚本录入，包含DWD/DWS/ADS三层ETL脚本
- **影响文件**: `dwd_ipd_ipm_bp_lx_model_mid_dd.sql`, `dws_ipd_ipm_dxmodel_detail_dd.sql`, `ads_ipd_ipm_dxmodel_result_dd.sql`
- **变更人**: ETL智能辅助工具

### #002 — 新增数据质量检查脚本
- **日期**: 2026-05-09
- **变更描述**: 新增 `validate_data_quality.sql`，包含6项数据质量检查（行数、空值率、指标合理性、产品线覆盖）
- **影响文件**: `validate_data_quality.sql`, `lineage.md`
- **变更人**: ETL智能辅助工具

### #003 — 厨电产品线低效型号数+新品规划命中率闭环
- **日期**: 2026-05-20
- **变更描述**: 厨电产品线正式闭环。DWS层已包含厨电内销低效型号数（zhibiao_type='2'）和新品规划命中率（zhibiao_type='4'）逻辑，产品线通过HX00223字段筛选（烟机/灶具/洗碗机/电热水器/燃气热水器/烤箱），保护期判定同冰箱逻辑，无ODM剔除。ADS层已包含厨电按产品线维度汇总+集团汇总。草稿文件（`*_chudian_draft.sql`、`*_chudian_dx_draft.sql`）逻辑已手工合并到正式脚本，草稿保留供参考。
- **影响文件**: `dws_ipd_ipm_dxmodel_detail_dd.sql`, `ads_ipd_ipm_dxmodel_result_dd.sql`
- **变更人**: 用户（手工合并）

### #004 — 外销新品规划命中率扩展
- **日期**: 2026-05-26 ~ 2026-06-01
- **变更类型**: CHG-02 产品线扩展（内销→外销）
- **变更描述**: 新增外销7条产品线（冰箱/冷柜/洗衣机/家用空调/平板电视/厨电/激光）的新品规划命中率（zhibiao_type='4'）。DWD层新增外销LX规划量按产品线比例拆分（HX00020→12个月）；DWS层新增外销明细计算（GSS实际销量：空调用PUB-009排产单转换逻辑，其他产品线GSS协议订单占位待补充）。交付模式B，草稿已完成，用户批量手工合入正式脚本。
- **影响文件**: `drafts/dwd_ipd_ipm_bp_lx_model_mid_dd_wx_draft.sql`（DWD草稿）, `drafts/dws_ipd_ipm_dxmodel_detail_dd_wx_draft.sql`（DWS草稿）
- **状态**: ✅ 草稿完成，待用户手工合入
- **闭环分析备注**:
  - P0：DWD草稿INSERT用`in_out_sale`字段，DWS草稿用`model_label_6='外销'`筛选，需合入时统一为`model_label_6`
  - P1：DELETE条件与INSERT字段需保持一致
  - P2：`sequence(1, cardinality(...)+1)` 越界产生NULL行（与正式脚本一致，下游可过滤）
- **变更人**: ETL智能辅助工具 + 用户（手工合入）

### #005 — 激光产品线低效型号占比+新品规划命中率DWS草稿
- **日期**: 2026-05-29 ~ 2026-06-01
- **变更类型**: CHG-02 产品线扩展（激光家用/激光商用）
- **变更描述**: 新增激光产品线两个DWS层草稿：①低效型号占比（zhibiao_type='2'，只做内销年累，管报实际销量含能效机转换PUB-005，规划量取BP/LX中间表product_line='激光'）；②新品规划命中率（zhibiao_type='4'，只做内销，新品期12个月，规划量只取LX，实际销量取全量累计）。产品线通过生产版本判定。新增焦距和规划销售渠道字段。
- **影响文件**: `drafts/dws_ipd_ipm_dxmodel_detail_dd_jiguang_draft.sql`, `drafts/dws_ipd_ipm_dxmodel_detail_dd_jiguang_xinpin_draft.sql`
- **状态**: ✅ 已完成（ADS层不提供，用户批量手工合入正式脚本）
- **前置条件**: 目标表需ALTER TABLE新增focallength VARCHAR(300)字段；DWD层需确认激光BP/LX规划量写入来源（当前正式DWD脚本中无激光段落）
- **变更人**: ETL智能辅助工具 + 用户（手工合入）

### #006 — 激光+外销新品命中率全部闭环，正式脚本手工更新
- **日期**: 2026-06-08
- **变更描述**: 激光产品线低效型号占比+新品规划命中率逻辑全部闭环；外销新品命中率（7条产品线：冰箱/冷柜/洗衣机/家用空调/平板电视/厨电/激光）全部闭环。用户手工将草稿逻辑合入正式脚本，并新增 `dws_ipd_ipm_dxmodel_detail_dd_wx.sql` 独立记录外销口径逻辑。GSS协议订单逻辑已录入公共规则库PUB-010。
- **影响文件**: `dws_ipd_ipm_dxmodel_detail_dd.sql`, `dws_ipd_ipm_dxmodel_detail_dd_wx.sql`, `ads_ipd_ipm_dxmodel_result_dd.sql`, `dwd_ipd_ipm_bp_lx_model_mid_dd.sql`
- **状态**: ✅ 已闭环
- **变更人**: 用户（手工更新）

### #007 — 海信日立产品效率看板优化（低效型号数+新品命中率）
- **日期**: 2026-06-11
- **变更类型**: CHG-03+CHG-01（字段新增+逻辑变更复合）
- **变更描述**: 中央空调（日立）低效型号数和新品命中率DWS层优化。①新增is_project_nk内控保护期逻辑（营销部扩展3个+外销品牌扩展HITACHI/YORK）；②新增6个明细字段（HX00327/PG00039/HX00339/PG00057→productmodel_life/PG00009/shangshi_y）；③新增3个达标判定字段is_db_qty/is_db_amt/is_db_margin（仅zhibiao_type='4'）；④新增项目口径二级维度：2-1(营销部)/2-2(所有者)/2-3(产品小类)/4-1(营销部)/4-2(所有者)，含CROSS JOIN集团/内控双口径。草稿逻辑已由用户手工合入正式脚本。
- **影响文件**: `dws_ipd_ipm_dxmodel_detail_dd.sql`
- **状态**: ✅ 已闭环
- **参考PRD**: `refined/20260608-hitachi-efficiency-optimization/2026-06-08_002_日立效率看板优化_prd.md`
- **变更人**: 用户（手工合入）

### #008 — 本年复产机型不考核规则
- **日期**: 2026-06-13
- **变更类型**: CHG-01 逻辑变更（新增排除条件）
- **变更描述**: 所有产品线的is_project判定中新增"本年复产不考核"规则。数据来源`dwd.dwd_ipd_ipm_hdrp_delisted_dd`（formstatus='发布' AND formtype='再上市'），产品型号口径用masterDataName匹配，销售型号编码口径（中央空调日立）用mdgno匹配。内销脚本12处修改（zhibiao_type='2'和'4'各6处，含is_project_nk同步），外销脚本5处修改（5条产品线的zhibiao_type='4'）。
- **影响文件**: `dws_ipd_ipm_dxmodel_detail_dd.sql`, `dws_ipd_ipm_dxmodel_detail_dd_wx.sql`
- **状态**: ✅ 已闭环
- **变更人**: ETL智能辅助工具

---

## 模板（新增变更时复制）

### #0XX — 标题
- **日期**: YYYY-MM-DD
- **变更描述**: [描述变更内容]
- **影响文件**: [列出受影响的文件]
- **变更人**: [变更人]
