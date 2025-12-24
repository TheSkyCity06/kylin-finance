-- ==========================================
-- 修复 sys_user 表 password 字段长度问题
-- 问题：BCrypt 密码哈希值需要至少 60 字符，如果字段长度不足会导致截断
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 1. 修改 password 字段长度为 VARCHAR(100)
-- ==========================================
-- 说明：BCrypt 哈希值通常是 60 字符，设置为 100 以确保安全余量
ALTER TABLE `sys_user` 
MODIFY COLUMN `password` VARCHAR(100) NOT NULL COMMENT '密码（BCrypt加密，至少60字符）';

-- ==========================================
-- 2. 重置 admin 用户密码为 admin123
-- ==========================================
-- ⚠️ 重要：请先运行 PasswordToolController 生成正确的 BCrypt 哈希值
-- 访问：http://localhost:8080/admin/tool/generate-password?password=admin123
-- 然后将返回的 bcryptHash 值替换到下面的 SQL 中
-- 
-- 说明：使用 BCrypt 加密后的密码哈希值
-- 明文密码：admin123
-- 
-- 临时哈希值（请替换为工具生成的值）：
-- BCrypt 哈希值：$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
-- 
-- ⚠️ 注意：上面的哈希值可能不正确，请使用工具生成新的哈希值
UPDATE `sys_user` 
SET `password` = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    `update_time` = NOW()
WHERE `username` = 'admin';

-- ==========================================
-- 3. 验证修复结果
-- ==========================================
-- 检查字段长度
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'kylin_finance'
  AND TABLE_NAME = 'sys_user'
  AND COLUMN_NAME = 'password';

-- 检查 admin 用户的密码哈希值
SELECT 
    id,
    username,
    LENGTH(password) AS password_length,
    LEFT(password, 4) AS password_prefix,
    password
FROM sys_user
WHERE username = 'admin';

-- ==========================================
-- 说明：
-- 1. BCrypt 哈希值格式：$2a$10$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-- 2. 总长度：60 字符
-- 3. 前缀：$2a$10$ 表示 BCrypt 算法版本和成本因子
-- 4. 如果字段长度小于 60，会导致哈希值被截断，从而无法正确验证密码
-- ==========================================

