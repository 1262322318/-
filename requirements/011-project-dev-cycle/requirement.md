# 需求011：应市项目平均开发周期

## 当前状态速查

| 项目 | 内容 |
|------|------|
| 需求ID | 011-project-dev-cycle |
| 指标名称 | 应市项目平均开发周期 |
| 状态 | 开发完成，待测试 |
| 创建日期 | 2026-07-02 |
| 最后更新 | 2026-07-02 |
| 涉及脚本 | create_tables.sql, dws_ipd_ipd_project_dev_cycle_dd.sql, ads_ipd_ipd_project_dev_cycle_result_dd.sql |
| 三级域 | 管理集成产品开发/管理产品开发/整机产品开发 |
| 需求来源 | 黄炳琪/纳真科技公司-终端事业部-运营推进部-项目管理办公室 |

---

## 一、业务背景

每月需从PLM系统手动导出项目状态报表，人工筛选当月完成项目并计算开发周期，耗时约4.5H/月且准确率不高。本需求实现自动化统计，从PLM获取数据、自动计算开发周期（扣除暂停时段）、按事业部和项目类型聚合展示。

## 二、指标定义

| 项目 | 内容 |
|------|------|
| 指标名称 | 应市项目平均开发周期 |
| 业务含义 | 统计应市类项目从立项到鉴定实际完成的平均开发天数，扣除暂停时段 |
| 计算公式 | AVG(鉴定实际完成时间 - 立项时间 - 暂停时段总和)，单位：天 |
| 管理口径 | 项目维度 |
| 时间粒度 | 月度（当月完成 + 年累=本年1月到当前月累计） |
| 维度 | 光模块事业部 / 终端事业部 |

## 三、统计范围

### 项目类型
HBMTPDERIVETYPE字段：
- PS（含PS1/PS2/PS3等全部子类，LIKE 'PS%'）
- PA（含全部子类，LIKE 'PA%'）
- PB（含全部子类，LIKE 'PB%'）
- PC1、PC2
- HW（含全部子类，LIKE 'HW%'）
- FH（含全部子类，LIKE 'FH%'）

### 项目状态
projectcurrent IN ('Complete', 'Review', 'Archive')

### 排除条件
- 取消项目不纳入统计（有HBMTProjectCancleRequest记录的项目排除）

## 四、核心计算规则

### 单项目开发周期
```
开发周期(天) = DATEDIFF(hbmtpproductionactualedate, hbmtprojectcreatedate) - 暂停总天数
```

### 暂停时段计算
1. 通过 odsplm_bm_hbmtprojectadjust 表关联（projectname = productname）
2. 取 type='HBMTProjectHoldRequest' 的 releasedate 为暂停开始
3. 取 type='HBMTProjectResumeRequest' 的 releasedate 为暂停结束
4. 暂停天数 = DATEDIFF(恢复日期, 暂停日期)
5. 多次暂停累加所有暂停时段

### 聚合规则
- 当月：当月完成项目的AVG(开发周期)
- 年累：本年1月到当月所有完成项目的AVG(开发周期)
- "平均"行：按项目数加权平均

### 汇总指标
- 完成率 = 2 - 实际值/目标值
- 同比改善 = 1 - 实际值/同期值

## 五、数据来源

| 数据项 | 表 | 关键字段 |
|--------|-----|----------|
| 项目基础信息 | odsplm_bm_hbmtprojectkpi | productname, hbmtprojectcreatedate, hbmtpproductionactualedate, hbmtpproductline, HBMTPDERIVETYPE, projectcurrent, productowner |
| 项目调整单 | odsplm_bm_hbmtprojectadjust | projectname, type, releasedate |
| 目标值 | ods.ODS_FEISHU_WIKI_LHK6WMDWWI3GFQK7ZIACKU3KNCB_TBLTRBIEBXRYRKO4 | record_data(JSON: 时间/目标值/类型/维度) |

## 六、目标表

| 层级 | 表名 | 粒度 |
|------|------|------|
| DWS | dws.dws_ipd_ipd_project_dev_cycle_dd | 一行=一个项目×一个完成月份 |
| ADS | ads.ads_ipd_ipd_project_dev_cycle_result_dd | 一行=事业部×项目类型×时间范围类型×月份 |

## 七、脚本清单

| 序号 | 文件名 | 功能 | 执行顺序 |
|------|--------|------|----------|
| 1 | create_tables.sql | 建表DDL | 首次执行 |
| 2 | dws_ipd_ipd_project_dev_cycle_dd.sql | DWS明细层 | 每月调度-第1步 |
| 3 | ads_ipd_ipd_project_dev_cycle_result_dd.sql | ADS结果层 | 每月调度-第2步 |

## 八、展示报表

### 报表一：总指标表
- 行维度：事业部 × 类型(PA/PB/PC/平均)
- 列维度：目标、1月~12月实际值
- 分组：当月、年累

### 报表二：汇总对比表
- 行维度：光模块事业部、终端事业部、公司
- 列维度：PA/PB/PC实际、实际值、同期值、目标值、完成率、同比改善
- 分组：当月、累计

### 明细表
- 字段：项目名称、事业部、项目经理、项目类型、立项时间、完成时间、暂停天数、开发周期(天)等
- 底层数据包含所有DWS字段，前端按需展示

## 九、待澄清项

- [ ] 研发经理字段来源（表中无直接字段，暂空）
- [ ] hbmtpproductline字段具体存储值确认

## 十、调度配置

| 项目 | 配置 |
|------|------|
| 调度频率 | 月度 |
| 依赖关系 | DWS → ADS（串行） |
| 调度参数 | ${GP_START_DT} |
| 更新策略 | DELETE当月 + INSERT |
