---
inclusion: fileMatch
fileMatchPattern: '**/*.sql'
---
# SQL开发规范与规则库

## SQL编码规范

### 基本格式规范
1. **关键字大写**：所有SQL关键字使用大写字母
   ```sql
   -- 正确
   SELECT column1, column2 FROM table_name WHERE condition = 'value';
   
   -- 错误
   select column1, column2 from table_name where condition = 'value';
   ```

2. **缩进对齐**：使用4个空格进行缩进，保持代码层次清晰
   ```sql
   SELECT 
       column1,
       column2,
       SUM(column3) AS total
   FROM 
       table_name
   WHERE 
       column4 = 'value'
   GROUP BY 
       column1, column2;
   ```

3. **行长度限制**：每行不超过100个字符，复杂表达式换行显示
4. **注释规范**：使用`--`进行单行注释，复杂逻辑添加详细说明

5. **INSERT+SELECT字段注释（强制）**：所有INSERT INTO ... SELECT语句中，INSERT字段列表和SELECT字段列表的每个字段后必须添加行内注释说明业务含义
   ```sql
   -- 正确：INSERT字段列表带注释
   INSERT INTO target_table (
       dt_month,                      -- 统计月份
       projectname,                   -- 项目名称
       business_division              -- 事业部
   )
   SELECT
       DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month,           -- 统计月份
       productname                              AS projectname,        -- 项目名称
       '光模块'                                 AS business_division   -- 事业部
   FROM source_table;
   
   -- 错误：无注释
   INSERT INTO target_table (dt_month, projectname, business_division)
   SELECT DATE_FORMAT('${GP_START_DT}', '%Y%m'), productname, '光模块'
   FROM source_table;
   ```
   **例外**：字段数≤3且含义显而易见时可省略（如 `SELECT COUNT(*), NOW()`）

### 命名规范
1. **表名**：小写字母，下划线分隔，体现分层和业务含义
   ```
   {layer}_{subject}_{entity}_{granularity}
   示例：dwd_sales_order_daily, dim_customer
   ```

2. **列名**：小写字母，下划线分隔，体现业务含义
   ```
   {entity}_{attribute}_{qualifier}
   示例：order_amount, customer_name, product_category_code
   ```

3. **别名**：使用有意义的别名，避免使用a、b、c等无意义名称
   ```sql
   -- 正确
   SELECT o.order_id, c.customer_name FROM orders o JOIN customers c ON o.customer_id = c.customer_id;
   
   -- 错误
   SELECT a.id, b.name FROM orders a JOIN customers b ON a.cid = b.cid;
   ```

## Apache Doris特定规范

### 标准数据类型映射表

新建表时，必须使用以下标准数据类型（Doris 2.1+ 推荐类型）：

| 业务含义 | 标准类型 | 说明 | 示例字段 |
|----------|----------|------|----------|
| 统计年月 | `VARCHAR(6)` | YYYYMM格式 | dt_month |
| 日期 | `DATE` | 纯日期，无时间 | business_date |
| 日期时间 | `DATETIMEV2(0)` | 精确到秒 | listing_date, load_dt |
| 主键/ID | `BIGINT` | 64位整数 | fact_id |
| 计数/数量（整数） | `INT` | 32位整数 | sku_count, act_num |
| 编码/名称（短文本） | `VARCHAR(200)` | ≤200字符 | product_line, model |
| 编码/名称（中文本） | `VARCHAR(300)` | ≤300字符 | salemodel_code, project_name |
| 编码/名称（长文本） | `VARCHAR(1000)` | ≤1000字符 | pc20080（合并文本） |
| 销量/金额（精确） | `DECIMALV3(20,4)` | 20位精度，4位小数 | sales_qty, rev_amt |
| 比率/占比 | `DECIMALV3(10,4)` | 10位精度，4位小数 | dxmodel_rate, hit_rate |
| 标记字段（Y/N） | `VARCHAR(2)` | Y或N | is_project, is_hit |
| 标签/类型 | `VARCHAR(50)` | 短标签文本 | stage_label, hit_type |

**注意事项**：
- 历史脚本（002/004~008）中已使用的类型不做回溯修改
- 新建表（如003及后续需求）必须遵循上述标准
- `DECIMAL` → 统一使用 `DECIMALV3`（Doris 2.1+推荐）
- `DATETIME` → 统一使用 `DATETIMEV2(0)`（Doris 2.1+推荐）
- ODS层源表字段类型保持原样，不做转换要求

### 表设计规范
1. **分区键选择**：选择高频查询的日期字段作为分区键
   ```sql
   CREATE TABLE dwd_sales_order_daily (
       order_id BIGINT,
       order_date DATE,
       customer_id BIGINT,
       amount DECIMAL(10,2)
   )
   PARTITION BY RANGE(order_date) ()
   DISTRIBUTED BY HASH(order_id) BUCKETS 10;
   ```

2. **分桶键选择**：选择高基数列作为分桶键，避免数据倾斜
3. **索引使用**：为高频查询条件创建前缀索引

### 性能优化规范
1. **物化视图**：对复杂聚合查询创建物化视图
   ```sql
   CREATE MATERIALIZED VIEW mv_sales_summary
   AS
   SELECT 
       order_date,
       customer_id,
       SUM(amount) AS total_amount,
       COUNT(*) AS order_count
   FROM dwd_sales_order_daily
   GROUP BY order_date, customer_id;
   ```

2. **查询优化**：使用合适的JOIN顺序，小表驱动大表
3. **避免全表扫描**：合理使用WHERE条件过滤数据

## ETL脚本开发规范

### 调度参数规范

| 参数名 | 含义 | 格式 | 示例 |
|--------|------|------|------|
| `${GP_START_DT}` | 调度日期（昨天） | yyyymmdd | 20260423 |

**使用说明**：
- `${GP_START_DT}` 是调度系统传入的参数，代表脚本执行日期的前一天（即昨天）
- 脚本中通常用 `date_sub('${GP_START_DT}', interval 1 month)` 取上月
- 常见用法：
```sql
-- 取上月年月
DATE_FORMAT(date_sub('${GP_START_DT}', interval 1 month), '%Y%m')

-- 取上月所在年
DATE_FORMAT(date_sub('${GP_START_DT}', interval 1 month), '%Y')

-- 取上月1日
STR_TO_DATE(CONCAT(DATE_FORMAT('${GP_START_DT}', '%Y-%m'), '-01'), '%Y-%m-%d')
```

### 数据提取规范
1. **增量提取**：使用时间戳或增量标识进行增量数据提取
   ```sql
   -- 增量提取示例
   SELECT * 
   FROM source_table 
   WHERE update_time > '${last_extract_time}';
   ```

2. **批量提取**：大数据量时使用分页或分批提取
3. **连接管理**：及时关闭数据库连接，避免连接泄漏

### 数据转换规范
1. **数据清洗**：处理空值、异常值和格式不一致问题
   ```sql
   -- 空值处理
   SELECT 
       COALESCE(column1, 'default_value') AS column1_clean,
       NULLIF(column2, 'invalid_value') AS column2_clean
   FROM source_table;
   ```

2. **类型转换**：明确的数据类型转换
   ```sql
   -- 类型转换
   SELECT 
       CAST(string_column AS INT) AS int_column,
       TO_DATE(date_string, 'YYYY-MM-DD') AS date_column
   FROM source_table;
   ```

3. **业务逻辑**：复杂的业务逻辑拆分为多个步骤，添加注释说明

### 数据加载规范
1. **批量加载**：使用INSERT INTO ... SELECT进行批量加载
   ```sql
   INSERT INTO target_table (col1, col2, col3)
   SELECT src_col1, src_col2, src_col3
   FROM source_table
   WHERE condition;
   ```

2. **更新策略**：根据业务需求选择INSERT/UPDATE/UPSERT策略
3. **数据验证**：加载前后进行数据一致性验证

### Doris临时表与UPDATE替代方案

由于当前版本Doris不支持临时表（TEMPORARY TABLE）和直接UPDATE语句，采用以下替代方案：

#### 1. 临时表替代：在test库创建中间表
```sql
-- 先删除旧表（幂等）
DROP TABLE IF EXISTS test.{中间表名};
-- 创建中间表（CTAS方式）
CREATE TABLE test.{中间表名}
ENGINE=OLAP
DUPLICATE KEY({首列字段})
AS
SELECT ...
FROM ...;
```

**命名规范**：`test.{目标表简称}_{用途}`，如 `test.productmodel_xmndxf`

**使用场景**：
- 需要多步骤计算的中间结果
- 需要被多个后续步骤引用的数据集
- 复杂JOIN前的数据预处理

#### 2. UPDATE替代：DELETE + INSERT模式
```sql
-- 步骤1：在test库创建包含更新数据的中间表
DROP TABLE IF EXISTS test.{更新数据表};
CREATE TABLE test.{更新数据表} ENGINE=OLAP DUPLICATE KEY(...) AS
SELECT ... FROM ...;

-- 步骤2：从目标表删除需要更新的记录
DELETE FROM {目标表} WHERE {条件} IN (SELECT {条件} FROM test.{更新数据表});

-- 步骤3：将更新后的数据插回目标表
INSERT INTO {目标表} SELECT ... FROM test.{更新数据表};
```

**注意事项**：
- test库中的中间表为临时性质，脚本开头用 `DROP TABLE IF EXISTS` 保证幂等
- 中间表使用 `DUPLICATE KEY` 模型（无需去重约束）
- 脚本执行完成后中间表保留（便于调试），下次执行时自动覆盖
- 不要在中间表上建分区（临时数据无需分区管理）

## 错误处理规范

### 异常捕获
1. **TRY-CATCH模式**：关键操作使用异常捕获
   ```sql
   BEGIN
       -- 业务逻辑
       INSERT INTO target_table SELECT * FROM source_table;
   EXCEPTION
       WHEN OTHERS THEN
           -- 记录错误日志
           INSERT INTO error_log (error_time, error_message)
           VALUES (NOW(), SQLERRM);
   END;
   ```

2. **重试机制**：网络异常或临时故障实现重试逻辑
3. **错误日志**：详细记录错误信息，便于问题排查

### 数据质量检查
1. **记录数验证**：验证源表和目标表记录数一致性
2. **关键字段验证**：验证关键业务字段的数据质量
3. **业务规则验证**：验证业务逻辑的正确性

## 性能与优化规则

### 查询优化
1. **避免SELECT ***：明确指定需要的列
2. **合理使用索引**：为高频查询条件创建合适索引
3. **减少JOIN数量**：优化查询逻辑，减少不必要的JOIN

### 资源管理
1. **内存使用**：监控查询内存使用，避免OOM
2. **并发控制**：合理控制并发查询数量
3. **超时设置**：为长时间运行查询设置超时时间

## 安全规范

### 数据安全
1. **敏感数据脱敏**：对敏感信息进行脱敏处理
2. **访问控制**：严格的数据访问权限控制
3. **审计日志**：记录数据访问和修改日志

### SQL注入防护
1. **参数化查询**：使用参数化查询避免SQL注入
2. **输入验证**：对所有输入参数进行验证
3. **最小权限原则**：使用最小必要权限的数据库账户

## 文档与注释规范

### 脚本头注释
```sql
/*
 * 脚本名称: etl_ods_dwd_sales_transform.sql
 * 功能描述: 从ODS层销售数据转换到DWD层销售明细事实表
 * 作者: [作者姓名]
 * 创建时间: YYYY-MM-DD
 * 修改记录:
 *   YYYY-MM-DD [修改人] [修改描述]
 * 依赖关系:
 *   输入: ods.sales_raw
 *   输出: dwd.sales_fact_daily
 * 业务规则:
 *   1. 过滤已删除订单
 *   2. 金额单位转换为元
 *   3. 日期格式标准化
 */
```

### 关键逻辑注释
1. **复杂业务逻辑**：详细注释说明业务规则
2. **性能优化点**：注释说明性能优化措施
3. **临时解决方案**：标记临时解决方案，说明原因

## 测试规范

### 单元测试
1. **边界条件测试**：测试空值、极值等边界条件
2. **业务规则测试**：验证业务逻辑正确性
3. **性能测试**：测试查询性能是否符合要求

### 集成测试
1. **数据流转测试**：验证数据在各层间的正确流转
2. **数据一致性测试**：验证数据转换前后的数据一致性
3. **错误处理测试**：验证异常情况下的错误处理机制