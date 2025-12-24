-- ==========================================
-- 期初余额设置脚本
-- ==========================================
-- 用途：为会计科目设置期初余额，使试算平衡表不为零
-- 方法：通过创建期初凭证（在系统开始日期之前）来设置期初余额
--
-- 使用说明：
-- 1. 确保已执行 database/init.sql 初始化科目数据
-- 2. 执行此脚本设置期初余额
-- 3. 期初凭证日期设置为系统开始日期之前（如：2024-01-01）
--
-- 注意：此脚本会创建期初凭证，确保借贷平衡
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 1. 获取科目ID
-- ==========================================
SET @bank_account_id = (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1); -- 银行存款
SET @cash_account_id = (SELECT account_id FROM fin_account WHERE account_code = '1001' LIMIT 1); -- 库存现金
SET @paid_in_capital_id = (SELECT account_id FROM fin_account WHERE account_code = '4001' LIMIT 1); -- 实收资本
SET @receivable_account_id = (SELECT account_id FROM fin_account WHERE account_code = '1122' LIMIT 1); -- 应收账款
SET @inventory_account_id = (SELECT account_id FROM fin_account WHERE account_code = '1405' LIMIT 1); -- 库存商品
SET @fixed_asset_account_id = (SELECT account_id FROM fin_account WHERE account_code = '1601' LIMIT 1); -- 固定资产

-- 验证科目是否存在
SELECT 
    CASE WHEN @bank_account_id IS NULL THEN 'ERROR: 银行存款(1002)不存在' ELSE 'OK: 银行存款' END AS bank_check,
    CASE WHEN @cash_account_id IS NULL THEN 'ERROR: 库存现金(1001)不存在' ELSE 'OK: 库存现金' END AS cash_check,
    CASE WHEN @paid_in_capital_id IS NULL THEN 'ERROR: 实收资本(4001)不存在' ELSE 'OK: 实收资本' END AS capital_check;

-- ==========================================
-- 2. 设置期初日期（系统开始日期之前）
-- ==========================================
SET @opening_date = '2024-01-01'; -- 期初日期，可根据实际情况调整
SET @currency_id = (SELECT commodity_id FROM fin_commodity WHERE commodity_code = 'CNY' LIMIT 1); -- 人民币币种ID
SET @currency_id = IFNULL(@currency_id, 1); -- 如果不存在，使用默认值1

-- ==========================================
-- 3. 创建期初凭证
-- ==========================================
-- 期初凭证号格式：OPEN + yyyyMMdd + 序号
SET @voucher_no = CONCAT('OPEN', DATE_FORMAT(@opening_date, '%Y%m%d'), '001');

-- 检查是否已存在期初凭证
SET @existing_voucher = (SELECT COUNT(*) FROM fin_transaction WHERE voucher_no = @voucher_no);

-- 如果不存在，则创建期初凭证
-- 注意：使用 INSERT IGNORE 避免重复插入
INSERT IGNORE INTO fin_transaction (
    voucher_no, currency_id, trans_date, enter_date, description, creator_id, status
) VALUES (
    @voucher_no,
    @currency_id,
    @opening_date,
    NOW(),
    '期初余额',
    NULL,
    1
);

-- 获取期初凭证ID（如果刚插入）或已存在的ID
SET @trans_id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = @voucher_no LIMIT 1);

-- 只有当凭证ID存在且分录不存在时才插入分录
-- 检查是否已有分录
SET @existing_splits = (SELECT COUNT(*) FROM fin_split WHERE trans_id = @trans_id);

-- 插入期初余额分录（仅当不存在时）
-- 借方：资产类科目
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
SELECT @trans_id, @bank_account_id, 'DEBIT', 500000.00, '期初余额-银行存款', NOW(), NOW(), 0
WHERE @existing_splits = 0 AND @bank_account_id IS NOT NULL;

INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
SELECT @trans_id, @cash_account_id, 'DEBIT', 20000.00, '期初余额-库存现金', NOW(), NOW(), 0
WHERE @existing_splits = 0 AND @cash_account_id IS NOT NULL;

INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
SELECT @trans_id, @receivable_account_id, 'DEBIT', 15000.00, '期初余额-应收账款', NOW(), NOW(), 0
WHERE @existing_splits = 0 AND @receivable_account_id IS NOT NULL;

INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
SELECT @trans_id, @inventory_account_id, 'DEBIT', 25000.00, '期初余额-库存商品', NOW(), NOW(), 0
WHERE @existing_splits = 0 AND @inventory_account_id IS NOT NULL;

INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
SELECT @trans_id, @fixed_asset_account_id, 'DEBIT', 80000.00, '期初余额-固定资产', NOW(), NOW(), 0
WHERE @existing_splits = 0 AND @fixed_asset_account_id IS NOT NULL;

-- 贷方：实收资本：640,000.00（贷方）- 等于所有借方之和 (500000 + 20000 + 15000 + 25000 + 80000)
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
SELECT @trans_id, @paid_in_capital_id, 'CREDIT', 640000.00, '期初余额-实收资本', NOW(), NOW(), 0
WHERE @existing_splits = 0 AND @paid_in_capital_id IS NOT NULL;

-- ==========================================
-- 4. 验证借贷平衡
-- ==========================================
SELECT 
    '期初余额验证' AS '验证项',
    voucher_no AS '凭证号',
    trans_date AS '凭证日期',
    description AS '摘要',
    (SELECT SUM(amount) FROM fin_split WHERE trans_id = t.trans_id AND direction = 'DEBIT') AS '借方合计',
    (SELECT SUM(amount) FROM fin_split WHERE trans_id = t.trans_id AND direction = 'CREDIT') AS '贷方合计',
    (SELECT SUM(amount) FROM fin_split WHERE trans_id = t.trans_id AND direction = 'DEBIT') - 
    (SELECT SUM(amount) FROM fin_split WHERE trans_id = t.trans_id AND direction = 'CREDIT') AS '差额'
FROM fin_transaction t
WHERE voucher_no = @voucher_no;

-- ==========================================
-- 5. 显示期初余额明细
-- ==========================================
SELECT 
    a.account_code AS '科目代码',
    a.account_name AS '科目名称',
    a.account_type AS '科目类型',
    CASE 
        WHEN s.direction = 'DEBIT' THEN s.amount
        ELSE 0
    END AS '借方金额',
    CASE 
        WHEN s.direction = 'CREDIT' THEN s.amount
        ELSE 0
    END AS '贷方金额',
    CASE 
        WHEN a.account_type IN ('ASSET', 'EXPENSE') THEN 
            (SELECT COALESCE(SUM(CASE WHEN direction = 'DEBIT' THEN amount ELSE -amount END), 0) 
             FROM fin_split WHERE account_id = a.account_id AND is_deleted = 0)
        ELSE 
            (SELECT COALESCE(SUM(CASE WHEN direction = 'CREDIT' THEN amount ELSE -amount END), 0) 
             FROM fin_split WHERE account_id = a.account_id AND is_deleted = 0)
    END AS '余额'
FROM fin_transaction t
JOIN fin_split s ON t.trans_id = s.trans_id AND s.is_deleted = 0
JOIN fin_account a ON s.account_id = a.account_id
WHERE t.voucher_no = @voucher_no
ORDER BY a.account_code;

-- ==========================================
-- 6. 验证会计恒等式（仅针对期初凭证）
-- ==========================================
SELECT 
    '会计恒等式验证（期初余额）' AS '验证项',
    (SELECT COALESCE(SUM(amount), 0) FROM fin_split s 
     JOIN fin_account a ON s.account_id = a.account_id 
     WHERE s.trans_id = @trans_id AND s.is_deleted = 0
     AND s.direction = 'DEBIT' AND a.account_type IN ('ASSET', 'EXPENSE')) AS '资产+费用（借方）',
    (SELECT COALESCE(SUM(amount), 0) FROM fin_split s 
     JOIN fin_account a ON s.account_id = a.account_id 
     WHERE s.trans_id = @trans_id AND s.is_deleted = 0
     AND s.direction = 'CREDIT' AND a.account_type IN ('LIABILITY', 'EQUITY', 'INCOME')) AS '负债+权益+收入（贷方）',
    (SELECT COALESCE(SUM(amount), 0) FROM fin_split s 
     JOIN fin_account a ON s.account_id = a.account_id 
     WHERE s.trans_id = @trans_id AND s.is_deleted = 0
     AND s.direction = 'DEBIT' AND a.account_type IN ('ASSET', 'EXPENSE')) - 
    (SELECT COALESCE(SUM(amount), 0) FROM fin_split s 
     JOIN fin_account a ON s.account_id = a.account_id 
     WHERE s.trans_id = @trans_id AND s.is_deleted = 0
     AND s.direction = 'CREDIT' AND a.account_type IN ('LIABILITY', 'EQUITY', 'INCOME')) AS '差额（应为0）';

