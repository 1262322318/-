# 数据目录

## 文件清单

| 文件/目录 | 说明 |
|----------|------|
| `table_permissions.csv` | 表权限信息CSV，Agent在权限检查时读取 |
| `feeding-log.md` | 知识投喂日志（追溯：谁在什么时候投喂了什么） |
| `feeding-counter.json` | 投喂计数器（累计次数 + 上次健康检查时间） |
| `interaction-metrics/` | 交互度量数据目录（详见目录内 README） |
| `feedback-records/` | 反馈自动捕获记录目录（由 feedback-collector 技能自动写入） |
| `framework-improvement-backlog.md` | 框架改进Backlog（由 interaction-metrics 技能自动追加） |

## table_permissions.csv

表权限信息CSV文件，Agent在权限检查时读取此文件。

**维护方式**：直接编辑CSV文件，添加/修改/删除行即可。

**格式**：
```csv
database,table_name,username,permission_level,last_verified,notes
```

**权限级别**：read（读）、write（读写）、none（无权限）

## interaction-metrics/

存放每次需求处理的交互度量数据，用于：
1. 区分"用户侧问题"和"框架侧问题"
2. 识别瓶颈阶段，定位框架改进点
3. 积累样本，为未来归因阈值优化提供依据
4. 多层复盘（用户级/需求级/框架级）

由 `.kiro/skills/interaction-metrics.md` 技能在链路A的A7、链路B的B5完成后自动生成。

## framework-improvement-backlog.md

框架改进Backlog，由度量技能自动维护：
- 自动追加每次发现的框架侧问题
- 高频问题自动标记到顶部
- 用户定制提示自动追加
- 阈值校准记录
