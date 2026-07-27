# 交互度量目录

## 说明

本目录存放每次需求处理过程的交互度量数据，用于：
1. 区分"用户侧问题"和"框架侧问题"
2. 识别瓶颈阶段，定位框架改进点
3. 积累样本，为未来归因阈值优化提供依据
4. 多层复盘（用户级/需求级/框架级）

## 文件清单

| 文件/目录 | 说明 |
|----------|------|
| `index.csv` | 所有需求的度量索引（一行一条），用于快速聚合分析 |
| `{需求ID}-metrics-{YYYYMMDD}.json` | 单次需求的详细度量JSON |
| `conversations/{需求ID}-{YYYYMMDD}.md` | 对话简介（复盘样本） |

## 度量字段速查

### input_quality（用户输入质量）
- `completeness_score` 0-14分（7维度×0-2分）
- `completeness_level` 明确/基本明确/模糊/非常模糊
- `missing_dimensions` 缺失维度清单

### stage_metrics（每阶段度量）
- `rounds` 来回轮次
- `duration_minutes` 耗时分钟
- `user_corrections` 用户修正次数
- `bottleneck` 是否瓶颈（轮次≥3 或 耗时≥30%）

### attribution（归因，最关键）
- `primary_cause` user / framework / mixed / clean
- `tags` 类似 `框架侧:模板缺失` / `用户侧:需求不完整`
- `framework_side_issues[].suggested_improvement` 每个框架问题必须给改进建议

## 触发方式

度量数据由 `.kiro/skills/interaction-metrics.md` 技能生成：
- **自动**：链路A的A7、链路B的B5完成后自动调用
- **手动**：用户说"记录度量"或 `#interaction-metrics`

## 复盘用法

### 单次复盘
```
查看 {需求ID}-metrics-{YYYYMMDD}.json 的 attribution 字段
查看 conversations/{需求ID}-{YYYYMMDD}.md 看完整对话节点
```

### 用户级复盘（同一操作人）
```
SELECT operator, AVG(input_completeness), COUNT(*)
FROM index.csv
GROUP BY operator
HAVING input_completeness < 6
```
→ 该用户需要定制需求填空模板

### 需求类型复盘（链路对比）
```
对比 link_type=A 和 link_type=B 的平均轮次和耗时
找出哪条链路效率更低
```

### 框架级复盘
```
查看 framework-improvement-backlog.md 中的改进项
高频出现的改进项 → 优先处理
```

## 阈值学习

当前归因阈值为70%（用户侧/框架侧问题占比）。
- 样本&lt;10：保持70%
- 样本≥10：人工抽样校验，准确率&lt;80%时调整
- 样本≥30：考虑引入多因子加权归因模型

## 文件保留策略

- JSON文件：永久保留（小文件，方便聚合）
- 对话样本（conversations/）：永久保留（用于未来训练改进）
- index.csv：永久追加，不删除历史记录

## 注意事项

- 用户首次提交原文默认保留，敏感场景可设置 `"sanitized": true`
- conversations目录下内容不外发，仅用于内部复盘
- 当前由Agent自评，存在±20%偏差，未来可升级为Hook客观采集
