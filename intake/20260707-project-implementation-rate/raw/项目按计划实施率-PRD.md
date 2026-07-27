# 项目按计划实施率-PRD  

|**版本号**|**更新日期**|**修订人**|**变更描述简介**|
|---|---|---|---|
|1.0|2025-05-13|赵梦璇|建立|

# 一、需求基础信息

## 需求提出人/部门：

黄炳琪/纳真科技公司-终端事业部-运营推进部-项目管理办公室

## 业务背景

数据来源于系统，诉求系统上可以做好数据筛选与处理，节省统计人力。每月需从现有系统手动导出包含所有项目状态的原始报表。由于报表数据量大且内容多，需人工逐一筛选出当月活动、暂停、取消、完成状态的项目个数，区分项目所属产品线并记录数据，过程繁琐且耗时；还需手动计算每个产品线当月的项目按计划实施率，并按项目经理统计每人负责的项目数和实施率，此过程易因人为因素导致数据不准确。人工完成数据收集和处理效率低，不利于及时发现问题、总结经验，需求转为自动化报表。

## 产品目标（可量化）

1. 开发应市项目开发周期统计功能，从PLM系统获取项目原始数据和产品线维度。
2. 开发前端展示报表，实现应市项目开发周期的展示监控。
3. 数据应用上线前，每个月手工做表的工时：4.5h；数据应用上线后，工时解决4h。年收益约50H

## 数据逻辑说明：

涉及到的表与关联关系：
- PLMASSIST.HBMTPROJECTKPI
- PLMASSIST.HBMTPROJECTADJUST

HBMTPROJECTKPI 获取到PRODUCTNAME，结合项目调整单HBMTPROJECTADJUST中项目名称PROJECTNAME进行联合查询

涉及字段：

|指标名称|来源表|来源指标|
|---|---|---|
|项目状态|HBMTPROJECTKPI|projectcurrent|
|项目名称|HBMTPROJECTKPI|PRODUCTNAME|
|产品线|HBMTPROJECTKPI|HBMTPProductLine|
|开发计划完成时间-市场因素变更后|HBMTPROJECTKPI|HBMTPDESIGNESTIMATEDEDATE|
|开发实际完成时间|HBMTPROJECTKPI|HBMTPDESIGNACTUALEDATE|
|鉴定计划完成时间-市场因素变更后|HBMTPROJECTKPI|HBMTPPRODUCTIONESTIMATEDEDATE|
|鉴定实际完成时间|HBMTPROJECTKPI|HBMTPPRODUCTIONACTUALEDATE|
|项目类型|HBMTPROJECTKPI|HBMTPPROJECTTYPE|

产品线枚举：
- emxFramework.Range.HBMTPProductLine.A1=TELECOM
- emxFramework.Range.HBMTPProductLine.A2=数通DATACOM
- emxFramework.Range.HBMTPProductLine.A3=FTTx
- emxFramework.Range.HBMTPProductLine.A4=无线
- emxFramework.Range.HBMTPProductLine.A5=OSA
- emxFramework.Range.HBMTPProductLine.A7=芯片产品线
- emxFramework.Range.HBMTPProductLine.A8=技术预研部
- emxFramework.Range.HBMTPProductLine.Coherent=相干产品线
- emxFramework.Range.HBMTPProductLine.BOX=BOX
- emxFramework.Range.HBMTPProductLine.Multimedia=多媒体

终端事业部：BOX、多媒体
光模块事业部：A1、A2、A3、A4、Coherent

1. 纳入统计范围：
   - 项目分类为PS(全部)、PA(全部)、PB(全部)、PC1、PC2、HW、FH类应市产品型号
   - 项目类型：应市类
   - '鉴定实际完成时间'为空时，项目状态为"分配"，"活动"，"项目立项"的项目；或'鉴定实际完成时间'为当月的全部状态的项目

2. 项目情况判定：
   - 结题：'鉴定实际完成时间'为当月均为结题
   - 延期：设计性试制（开发）或生产线试制（鉴定）中有一个延期即为延期（实际完成时间超过计划完成时间大于3个工作日为延期），不包括结题项目
   - 暂停：项目状态为"保持"
   - 终止：项目状态为"取消"，取消单发布日期为当月且当月没有恢复
   - 正常：不属于延期、暂停、终止的任何一种

3. 合计计数逻辑：正常项目数量 + 延期项目数量 + 结题项目数量

4. 应市项目按计划实施率 = (正常项目数 + 结题项目数) / 合计项目数

## 项目调整单变更类型：
- HBMTProjectHoldRequest = 项目暂停单
- HBMTProjectCancleRequest = 项目取消单
- HBMTProjectResumeRequest = 项目恢复单
- HBMTProjectAdjustRequest = 项目调整单
