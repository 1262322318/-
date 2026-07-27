# 009 - 变更模块变更明细汇总统计

## 当前状态速查（最后同步：changelog #001, 2026-05-15）

### 覆盖范围
| 维度 | 当前值 |
|------|--------|
| 业务域 | IRS（管理研发支撑）— 设计变更 |
| 数据源 | ads.ads_ipd_irs_design_change_kccl_dd（单表，4个flag场景） |
| 报表数 | 10张BI数据集（直接查询，无需建中间表） |
| 覆盖场景 | 设计变更报表(flag=1)/+MCA(flag=2)/+MCO(flag=3)/+库存处理意见(flag=4) |
| 应用公共规则 | 无（独立业务域） |

### 脚本清单
| 脚本 | 分层 | 说明 |
|------|------|------|
| design_change_bi_datasets.sql | BI数据集 | 10张报表SQL（直接查询，无INSERT） |
| validate_data_quality.sql | 检查 | 数据质量验证 |

### 文档同步状态
- 主体部分：与当前实现一致（无扩展）

## 基本信息

| 项目 | 内容 |
|------|------|
| 需求编号 | 009 |
| 需求名称 | 变更模块变更明细汇总统计 |
| 业务域 | IRS（管理研发支撑） |
| 需求类型 | 全新独立需求 |
| 产出形式 | 查询SQL数据集（无需建表） |
| 覆盖范围 | 集团下所有业务公司 |
| 数据源 | ads.ads_ipd_irs_design_change_kccl_dd |
| 创建日期 | 2026-05-18 |

## 业务背景

新PLM系统上线后，系统中缺少详细的设计变更单报表，缺少相应的分析维度字段，不利于对设计变更的管理：
1. 缺少实施维度，无法获得变更单发布/实施/未实施/超期未实施数量
2. 缺少变更原因字段，无法按原因监控完成情况
3. 对于降本项目，无法判断对应细类消耗周期是否满足要求

## 需求目标

1. 开发设计变更数据导出报表功能，从PLM系统获取设计变更发布数据、MCO数据和产品线维度
2. 开发前端展示报表，实现设计变更发布数据的展示监控
3. 产出10条BI数据集SQL，供BI开发工程师直接使用

## 公共筛选条件

| 序号 | 筛选项 | 字段 | 控件类型 | 默认值 |
|------|--------|------|----------|--------|
| 1 | 发布日期（月度范围） | approvedTIme | 开始/结束月度 | - |
| 2 | 所属公司 | company | 多选下拉 | 全选 |
| 3 | 发起部门 | HWA_ChangeSubmittingDepartment | 多选下拉 | 全选 |
| 4 | 所属工厂 | werks_name | 多选下拉 | 全选 |
| 5 | 变更原因 | HWA_ChangeReasonType | 多选下拉 | 全选 |
| 6 | 变更阶段 | HWA_ChangePhase | 多选下拉 | 全选 |
| 7 | 变更级别 | hwa_changelevel | 多选下拉 | 全选 |
| 8 | 场景类型 | flag | 多选下拉 | 全选 |

## 报表清单

### 表一：设计变更单实施率完成情况
- **图表类型**：柱状图
- **维度**：所属公司（company）
- **指标**：已实施率 = COUNT(DISTINCT 已完成+变更已实施的name) / COUNT(DISTINCT 除草稿外的name)
- **去重**：DISTINCT name

### 表二：变更原因分类占比
- **图表类型**：饼图
- **维度**：变更原因分类（HWA_ChangeReasonType，取括号外文字）
- **指标**：各原因的变更单数量占比
- **去重**：DISTINCT name

### 表三：变更阶段占比
- **图表类型**：饼图
- **维度**：变更阶段（HWA_ChangePhase）
- **指标**：各阶段的变更单数量占比
- **去重**：DISTINCT name

### 表四：变更级别占比
- **图表类型**：饼图
- **维度**：变更级别（hwa_changelevel）
- **指标**：各级别的变更单数量占比
- **去重**：DISTINCT name

### 表五：生命周期状态占比
- **图表类型**：饼图
- **维度**：生命周期状态（design_current）
- **指标**：各状态的变更单数量占比
- **去重**：DISTINCT name

### 表六：各部门设计变更实施完成情况
- **图表类型**：柱状图 + 折线图
- **维度**：发起部门（HWA_ChangeSubmittingDepartment）
- **指标**：已实施率 = COUNT(DISTINCT 已完成+变更已实施的name) / COUNT(DISTINCT 除草稿外的name)
- **去重**：DISTINCT name

### 表七①：各工厂MCO实施完成情况
- **图表类型**：柱状图
- **维度**：所属工厂（werks_name）
- **指标**：
  - MCO已实施率 = MCO_current='变更已实施'的数量 / MCO总数
  - MCO已完成率 = design_current='MCO完成'的数量 / MCO总数
- **去重**：DISTINCT MCO_name

### 表七②：各工厂MCO未实施完成情况
- **图表类型**：柱状图 + 折线图
- **维度**：所属工厂（werks_name）
- **指标**：
  - 未实施率 = MCO_current非'变更已实施'的数量 / MCO总数
  - 超3月未实施率 = (非'变更已实施' 且 CURDATE()-MCOcjsj>90天) / MCO总数
- **去重**：DISTINCT MCO_name

### 表八：各工厂工艺评估和采购评估未完成数量
- **图表类型**：柱状图
- **维度**：所属工厂（werks_name）
- **指标**：
  - 工艺评估未完成数量/占比：MCO_current='草稿'
  - 工艺未评估超2天数量/占比：MCO_current='草稿' 且 gypgclsc/24>2
  - 采购评估未完成数量/占比：MCO_current='工艺评估完成'
  - 采购评估超3天数量/占比：MCO_current='工艺评估完成' 且 cgpgclsc/24>3
- **去重**：DISTINCT MCO_name

### 表九：各工厂工艺评估和采购评估平均时长
- **图表类型**：柱状图
- **维度**：所属工厂（werks_name）
- **指标**：
  - 工艺评估平均时长(h)：MCO_current='工艺评估完成'时 AVG(gypgclsc)
  - 采购评估平均时长(h)：MCO_current='采购评估完成'时 AVG(cgpgclsc)
- **去重**：DISTINCT MCO_name

### 表十：各工厂MCO生效日已过实施情况
- **图表类型**：柱状图 + 折线图（次坐标轴）
- **维度**：所属工厂（werks_name）
- **指标**：
  - 生效日已过未实施占比 = (MCO_current='MCO完成' 且 HWA_BreakpointDate<=CURDATE()) / (MCO完成+变更已实施)
  - 生效日已过未实施数量（折线图次坐标轴）
- **去重**：DISTINCT MCO_name

## 技术要点

1. **时间字段处理**：approvedTIme/MCOcjsj/HWA_BreakpointDate 均为 varchar，格式 '2025-09-13 09:44:23'
   - 月度筛选：`LEFT(approvedTIme, 7)`
   - 日期比较：`CAST(LEFT(字段, 10) AS DATE)`
2. **时长字段处理**：gypgclsc/cgpgclsc 存储小时数（整数），超期判断需 `/24` 转天
3. **去重逻辑**：设计变更用 `DISTINCT name`，MCO用 `DISTINCT MCO_name`
4. **变更原因截取**：取括号外文字，兼容中英文括号
5. **当前日期**：使用 `CURDATE()`

## 产出文件

| 文件 | 说明 |
|------|------|
| sql_scripts/design_change_bi_datasets.sql | 10条BI数据集SQL |
| 变更模块变更明细汇总统计-需求.md | 原始需求文档 |
| image.png ~ image-10.png | 需求原型图 |
