# 数据库初始化脚本幂等性改进

本文档说明了 `init.sql` 脚本的幂等性改进，使其可以安全地多次执行而不会出现错误。

## 改进内容

### 1. CREATE TABLE 语句
```sql
-- 改进前
CREATE TABLE `fin_account` (
    -- 字段定义
);

-- 改进后
CREATE TABLE IF NOT EXISTS `fin_account` (
    -- 字段定义
);
```
使用 `IF NOT EXISTS` 子句防止重复创建表。

### 2. INSERT 语句
```sql
-- 改进前
INSERT INTO `fin_account` VALUES (...);

-- 改进后
INSERT IGNORE INTO `fin_account` VALUES (...);
```
使用 `INSERT IGNORE` 避免重复插入数据时的主键冲突。

### 3. ALTER TABLE 语句
```sql
-- 改进前（直接执行ALTER TABLE，重复执行会报错）
ALTER TABLE `fin_account` ADD COLUMN `commodity_id` BIGINT NULL;

-- 改进后（动态检查并执行）
SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_account'
      AND COLUMN_NAME = 'commodity_id'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `fin_account` ADD COLUMN `commodity_id` BIGINT NULL',
    'SELECT "Column already exists" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```
使用 `INFORMATION_SCHEMA` 系统表动态检查列、索引、外键是否存在，只有在不存在时才执行相应的 DDL 操作。

## 改进的具体操作

### 表结构检查
- **列存在性检查**: 使用 `INFORMATION_SCHEMA.COLUMNS`
- **索引存在性检查**: 使用 `INFORMATION_SCHEMA.STATISTICS`
- **外键约束检查**: 使用 `INFORMATION_SCHEMA.TABLE_CONSTRAINTS`

### 动态SQL执行
```sql
SET @sql = IF(@condition = 0, '执行DDL语句', '跳过执行');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```

## 商业单据表结构

新增了以下商业单据相关表：
- `fin_invoice` - 客户发票表
- `fin_invoice_item` - 发票条目表
- `fin_bill` - 供应商账单表
- `fin_bill_item` - 账单条目表
- `fin_credit_note` - 冲销单据表

## 测试验证

运行 `test_idempotent.sql` 脚本来验证幂等性：

```bash
# 在MySQL中执行
mysql -u username -p database_name < database/test_idempotent.sql
```

测试流程：
1. 第一次执行 `init.sql`
2. 第二次执行 `init.sql`（验证幂等性）
3. 第三次执行 `init.sql`（再次验证）
4. 检查表结构和数据完整性

## 幂等性保证

### ✅ 支持的操作
- 数据库创建（`CREATE DATABASE IF NOT EXISTS`）
- 表创建（`CREATE TABLE IF NOT EXISTS`）
- 数据插入（`INSERT IGNORE`）
- 列添加（条件检查后执行）
- 索引添加（条件检查后执行）
- 外键约束添加（条件检查后执行）

### ✅ 验证结果
- 脚本可多次安全执行
- 不产生重复数据
- 不破坏现有数据结构
- 保持数据库状态一致性

## 使用说明

### 正常使用
```bash
mysql -u root -p < database/init.sql
```

### 开发环境测试
```bash
mysql -u root -p < database/test_idempotent.sql
```

### 注意事项
1. 脚本依赖 MySQL 8.0+ 的动态SQL功能
2. 需要有足够的权限访问 `INFORMATION_SCHEMA`
3. 建议在开发环境中先运行测试脚本验证幂等性
