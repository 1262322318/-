# 项目开发周期\-PRD 

|**版本号**|**更新日期**|**修订人**|**变更描述简介**|
|---|---|---|---|
|1\.0|2025\-05\-13|赵梦璇|建立|
|||||
|||||
|||||

# 一、需求基础信息

## 需求提出人/部门：

黄炳琪/纳真科技公司\-终端事业部\-运营推进部\-项目管理办公室

## 业务背景

每月需从现有系统手动导出包含所有项目状态的原始报表。由于报表数据量大且内容多，需人工逐一筛选出当月实际完成的项目，过程繁琐且耗时；筛选出后还需手动查询每个项目的实际开始日期（如需求确认日期/开发启动日期）和实际完成日期（如测试通过日期/上线日期），并计算开发周期。此过程易因人为因素导致数据不准确。人工完成数据收集和处理效率低，不利于及时发现问题、总结经验，需求转为自动化报表。

## 产品目标（可量化）

1. 开发应市项目开发周期统计功能，从PLM系统获取项目原始数据和产品线维度。

2. 开发前端展示报表，实现应市项目开发周期的展示监控。

3. 数据应用上线前，每个月手工做表的工时：4\.5H；数据应用上线后，工时解决4H。

4. 其他预期收益，量化计算，或做出非量化的说明：可实现项目完成状态自动识别、开发周期自动计算、报表自动生成与导出，将团队成员从繁琐重复的人工操作中解放出来，使其能专注于更具价值的项目管理和问题解决工作，每月至少减少4H的人力投入，准确率可提升至100%。

## 关联文档

> - 《MRD》链接：[02 需求文档\-MRD模板\-平均开发周期](https://hisense.feishu.cn/docx/VMhJdjyxUofcODxBX5Lc4S2Vnkc)
> 
> - 《MRD》需求评审登记链接：[01 数据产品需求池](https://hisense.feishu.cn/wiki/ABw2wuqRKiuiG7kKa2ccZxSznse?fromScene=spaceOverview&table=tblvTFKWyhK5QbQs&view=vew5wSiQtW)
> 
> 

# 二、数据定义

## 指标探源：

[05 指标内容收集 副本](https://hisense.feishu.cn/sheets/EfgesJOfdhwyegt7NL9ce0TIn0g)

## TP探源明细表（如已有标准数据模型，非必填）

[07 数据探源明细表\(1\)\.xlsx](https://hisense.feishu.cn/file/HVxdb8PzVoe0mrxlAeEcwP0Zn8e)

## ~~数据问题清单~~~~ ~~数据问题需要填写写到数据需求池 治理问题清单中

[06 数据问题清单](https://hisense.feishu.cn/wiki/LPIhw3gRgimAI2kxPnRcKU1an8b?fromScene=spaceOverview)

## 数据逻辑说明：

涉及到的表与关联关系

"PLMASSIST"\."HBMTPROJECTKPI"

"PLMASSIST"\."HBMTPROJECTADJUST"



涉及字段

|指标名称|来源表|来源指标|
|---|---|---|
|项目开始时间|"PLMASSIST"\."HBMTPROJECTKPI"|HBMTPROJECTCREATEDATE|
|项目完成时间|"PLMASSIST"\."HBMTPROJECTKPI"|HBMTPPRODUCTIONACTUALEDATE|
|类型（PA\-PC）<br>|"PLMASSIST"\."HBMTPROJECTKPI"|HBMTPDERIVETYPE<br>|
|维度（光模块/终端）|"PLMASSIST"\."HBMTPROJECTKPI"|HBMTPPRODUCTLINE|
|项目名称|"PLMASSIST"\."HBMTPROJECTKPI"|PRODUCTNAME|
|目标值（手动维护）|多维表格||
|项目状态|"PLMASSIST"\."HBMTPROJECTKPI"|PRODUCTCURRENT|
|进度统计|"PLMASSIST"\."HBMTPROJECTADJUST"||
|项目经理|||
|研发经理（责任人）|||

项目暂停单，用于计算项目暂停至项目重启的时间段不纳入开发周期统计  
PLM需要新增变更单表格："PLMASSIST"\."HBMTPROJECTADJUST"

通过如下表格获取暂停单发布日期，根据"PLMASSIST"\."HBMTPROJECTKPI" 获取到PRODUCTNAME，结合项目调整单"PLMASSIST"\."HBMTPROJECTADJUST"中项目名称：PROJECTNAME进行联合查询，根据申请单发布时间，得出项目暂停单发布时间、项目恢复单发布时间，得出项目暂停日期范围；

|指标名称|来源表|来源指标|PLM字段|
|---|---|---|---|
|编码|"PLMASSIST"\."HBMTPROJECTADJUST"|name|name|
|变更类型<br>|"PLMASSIST"\."HBMTPROJECTADJUST"<br>|HBMTProjectHoldRequest=项目暂停单<br>HBMTProjectCancleRequest=项目取消单<br>HBMTProjectResumeRequest=项目恢复单<br>HBMTProjectAdjustRequest = 项目调整单|type|
|项目名称|"PLMASSIST"\."HBMTPROJECTADJUST"|PROJECTNAME|to\[HBMTProjectAdjustRequest\]\.from\.name|
|发起者|"PLMASSIST"\."HBMTPROJECTADJUST"|OWNER|owner|
|发布日期<br>|"PLMASSIST"\."HBMTPROJECTADJUST"<br>|RELEASEDATE|state\[Release\]\.actual|
|调整原因<br>|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTREASON|HBMTAbnormalNegativeInfluence|
|调整后项目结束日期|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTWBSDELAYDATE<br>|HBMTWBSDelayedDate|
|调整说明|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTADJUSTMENT|HBMTAbnormalProgressAdjustment|
|延期因素<br>|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTDELAYFACTOR|HBMTDelayFactor|
|调整后开发阶段结束日期<br>|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTWBSDESIGNDATE|HBMTWBSDesignDate|
|项目暂停原因<br>|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTPROJECTHOLDREASON|HBMTProjectHoldReason|
|项目恢复原因|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTProjectResumeReason|HBMTProjectResumeReason|
|项目取消原因|"PLMASSIST"\."HBMTPROJECTADJUST"|HBMTProjectCancleReason|HBMTProjectCancleReason|



新增指标

应市项目平均开发周期（项目类型：应市类）：使用项目完成时间减项目立项时间，记为项目开发周期 一定范围内所有项目的开发周期取平均值得到

2. 统计范围为PS、PA、PB、PC（PC1、PC2），HW,FH类应市产品型号（项目分类字段为PS\(全部\)、PA（全部）、PB（全部）、PC1、PC2 、HW，FH）

“实际完成时间”为当月

3. 暂停重启项目，项目暂停至项目重启的时间段不纳入开发周期统计  

进度统计里重启时间\-取消/暂停时间 （时间按照发布时间）



![Image](https://internal-api-drive-stream.feishu.cn/space/api/box/stream/download/authcode/?code=ZWNjM2ZmNTZjNjVjOTk1YzVmYmM1OWE0YzkwYWM3YWJfNTg2NmZkMmFiZjdjZGI1MGMyYjllOGY0NzUwNmQ4YWVfSUQ6NzIxNjI1MDE2NTY4MTMyNDAzM18xNzgyODcyMzgxOjE3ODI5NTg3ODFfVjM)

![Image](https://internal-api-drive-stream.feishu.cn/space/api/box/stream/download/authcode/?code=YzM2ZjM1MjhjNTExMDAxOGNlNzEzNjA1MzdmMzAzOWRfNzRmZDEzYmY5NzhlZDdjYzQwMzc1MWYzOWM5YjNlYjRfSUQ6NzIxNjI1MDE2NTY4MTMyNDAzM18xNzgyODcyMzgxOjE3ODI5NTg3ODFfVjM)

![Image](https://internal-api-drive-stream.feishu.cn/space/api/box/stream/download/authcode/?code=M2M4NTMyOWE3NzNkZmI4NjY0NzFjYTMxMGVlNTQ3YTVfNTEwYzFhNGFlYzgzZjFkYmQ5YTRkMjhiNzMyMmE0Y2VfSUQ6NzIxNjI1MDE2NTY4MTMyNDAzM18xNzgyODcyMzgxOjE3ODI5NTg3ODFfVjM)

# 三、功能需求

按数据产品的核心流程（数据查询与分析、数据可视化、 数据服务）拆分功能模块，每个功能需明确 “做什么、怎么做、验收标准”。

## 数据查询、分析、可视化模块



**数据产品原型图：**

明细字段参考数据探源明细。

## 数据服务模块（非必填）

无

# **四、非功能需求**

非功能需求影响产品的稳定性、安全性、易用性，是数据产品落地的关键保障。这些需求通常包括：

安全文档**（非必填，如涉及到数据出入境，境外存储，外发等涉及数据安全需求需要填写）**：不涉及

[09 安全需求点检表模版\_V1\.0](https://hisense.feishu.cn/wiki/BzAuwaI5pi7YA4kgcFycQienn25?renamingWikiNode=false)

用户体验文档**（非必填，不涉及用户体验相关内容则不需要填写）**：不涉及

[08 数据产品用户体验指标模版\_V1\.0](https://hisense.feishu.cn/base/BAvibFrWdaduNGsv4cRcI5AXnze?previous_navigation_time=1756288499570&table=tblfskev6fmUzgWC&view=vew33Y4iRf)

# 五、权限清单：

[13 权限清单 副本](https://hisense.feishu.cn/sheets/OiPPsCHJthalxgt8gxOcdYprneh)



# 六、用户旅程

1. 登录信数，进入 “研发管理” 版块

2. 选择时间维度、其他业务维度

3. 系统刷新报表数据，用户确认无误，关闭，确认有问题，查看明细数据



# 六、实施排期与资源（从模型设计到需求交付）

|阶段|时间节点|交付物|负责角色|预计人天|
|---|---|---|---|---|
|数据模型设计||数据模型|数据开发工程师|1|
|数据模型开发||完成 ODS/DWD/DWS 层表设计与开发|数据开发工程师|2|
|BI报表搭建||完成报表可视化<br>|BI工程师|1|
|测试与上线<br>||测试报告、上线文档、用户培训材料<br>|测试TSE，数据开发工程师|1|

# 七、风险与应对

# 八、测试用例

当前使用生产数据搭建宽表，通过用户直接验证数据是否完整，是否与预期一致，由此完成测试部分。

# 九、附录

- 术语定义：解释文档中出现的专业术语。

- 参考资料：如数据模型设计规范、公司安全合规要求、竞品功能截图等。

- 原型链接：附上 Figma、Axure 等原型工具的链接，方便开发对照设计。



