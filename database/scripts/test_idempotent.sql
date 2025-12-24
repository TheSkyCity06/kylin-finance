-- 测试 init.sql 脚本的幂等性
-- 运行此脚本验证多次执行 init.sql 是否会出错

-- 首先清空数据库（仅用于测试）
DROP DATABASE IF EXISTS test_kylin_finance;
CREATE DATABASE test_kylin_finance DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE test_kylin_finance;

-- 第一次执行 init.sql
SOURCE schema/init.sql;

-- 检查表是否创建成功
SHOW TABLES;

-- 检查科目数据
SELECT COUNT(*) as account_count FROM fin_account;

-- 检查币种数据
SELECT COUNT(*) as commodity_count FROM fin_commodity;

-- 第二次执行 init.sql（测试幂等性）
SOURCE schema/init.sql;

-- 再次检查数据量是否变化（应该不变）
SELECT COUNT(*) as account_count_after_rerun FROM fin_account;
SELECT COUNT(*) as commodity_count_after_rerun FROM fin_commodity;

-- 第三次执行（再次测试）
SOURCE schema/init.sql;

-- 最终检查
SELECT COUNT(*) as final_account_count FROM fin_account;
SELECT COUNT(*) as final_commodity_count FROM fin_commodity;

-- 验证 ALTER TABLE 操作的幂等性
DESCRIBE fin_account;
DESCRIBE fin_split;

SELECT '测试完成 - 如果没有错误信息，则说明脚本具有良好的幂等性' as result;
