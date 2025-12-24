-- ==========================================
-- 凭证模拟数据生成脚本
-- ==========================================
-- 生成20个凭证及其分录，覆盖过去90天
-- 包含三种业务场景：收入、费用、工资
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 凭证1: 收入场景 - 收到客户货款
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(1, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到客户货款', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到客户货款', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到客户货款', NOW(), NOW(), 0);

-- ==========================================
-- 凭证2: 费用场景 - 支付办公用品费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(2, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '支付办公用品费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(100 + RAND() * 1900);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1), 'DEBIT', @amount, '支付办公用品费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'CREDIT', @amount, '支付办公用品费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证3: 工资场景 - 计提员工工资
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(3, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '计提员工工资', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(10000 + RAND() * 40000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6601' LIMIT 1), 'DEBIT', @amount, '计提员工工资', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '2211' LIMIT 1), 'CREDIT', @amount, '计提员工工资', NOW(), NOW(), 0);

-- ==========================================
-- 凭证4: 收入场景 - 收到销售回款
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(4, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到销售回款', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到销售回款', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到销售回款', NOW(), NOW(), 0);

-- ==========================================
-- 凭证5: 费用场景 - 支付水电费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(5, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '支付水电费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(100 + RAND() * 1900);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1), 'DEBIT', @amount, '支付水电费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'CREDIT', @amount, '支付水电费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证6: 收入场景 - 收到项目款
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(6, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到项目款', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到项目款', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到项目款', NOW(), NOW(), 0);

-- ==========================================
-- 凭证7: 工资场景 - 计提管理人员工资
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(7, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '计提管理人员工资', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(10000 + RAND() * 40000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6601' LIMIT 1), 'DEBIT', @amount, '计提管理人员工资', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '2211' LIMIT 1), 'CREDIT', @amount, '计提管理人员工资', NOW(), NOW(), 0);

-- ==========================================
-- 凭证8: 费用场景 - 支付差旅费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(8, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '支付差旅费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(100 + RAND() * 1900);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1), 'DEBIT', @amount, '支付差旅费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'CREDIT', @amount, '支付差旅费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证9: 收入场景 - 收到服务费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(9, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到服务费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到服务费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到服务费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证10: 费用场景 - 支付通讯费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(10, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '支付通讯费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(100 + RAND() * 1900);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1), 'DEBIT', @amount, '支付通讯费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'CREDIT', @amount, '支付通讯费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证11: 工资场景 - 计提销售人员工资
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(11, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '计提销售人员工资', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(10000 + RAND() * 40000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6601' LIMIT 1), 'DEBIT', @amount, '计提销售人员工资', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '2211' LIMIT 1), 'CREDIT', @amount, '计提销售人员工资', NOW(), NOW(), 0);

-- ==========================================
-- 凭证12: 收入场景 - 收到预收款
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(12, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到预收款', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到预收款', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到预收款', NOW(), NOW(), 0);

-- ==========================================
-- 凭证13: 费用场景 - 支付租赁费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(13, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '支付租赁费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(100 + RAND() * 1900);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1), 'DEBIT', @amount, '支付租赁费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'CREDIT', @amount, '支付租赁费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证14: 收入场景 - 收到客户货款
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(14, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到客户货款', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到客户货款', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到客户货款', NOW(), NOW(), 0);

-- ==========================================
-- 凭证15: 费用场景 - 支付维修费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(15, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '支付维修费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(100 + RAND() * 1900);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1), 'DEBIT', @amount, '支付维修费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'CREDIT', @amount, '支付维修费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证16: 工资场景 - 计提技术人员工资
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(16, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '计提技术人员工资', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(10000 + RAND() * 40000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6601' LIMIT 1), 'DEBIT', @amount, '计提技术人员工资', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '2211' LIMIT 1), 'CREDIT', @amount, '计提技术人员工资', NOW(), NOW(), 0);

-- ==========================================
-- 凭证17: 收入场景 - 收到销售回款
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(17, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到销售回款', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到销售回款', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到销售回款', NOW(), NOW(), 0);

-- ==========================================
-- 凭证18: 费用场景 - 支付咨询费
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(18, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '支付咨询费', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(100 + RAND() * 1900);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1), 'DEBIT', @amount, '支付咨询费', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'CREDIT', @amount, '支付咨询费', NOW(), NOW(), 0);

-- ==========================================
-- 凭证19: 收入场景 - 收到项目款
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(19, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '收到项目款', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(5000 + RAND() * 45000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1), 'DEBIT', @amount, '收到项目款', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1), 'CREDIT', @amount, '收到项目款', NOW(), NOW(), 0);

-- ==========================================
-- 凭证20: 工资场景 - 计提员工工资
-- ==========================================
SET @voucher_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND()*90) DAY);
SET @voucher_no = CONCAT('V', DATE_FORMAT(@voucher_date, '%Y%m%d'), LPAD(20, 3, '0'));
INSERT INTO fin_transaction (voucher_no, currency_id, trans_date, enter_date, description, creator_id, status)
VALUES (@voucher_no, 1, @voucher_date, NOW(), '计提员工工资', NULL, 1);
SET @trans_id = LAST_INSERT_ID();
SET @amount = FLOOR(10000 + RAND() * 40000);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '6601' LIMIT 1), 'DEBIT', @amount, '计提员工工资', NOW(), NOW(), 0);
INSERT INTO fin_split (trans_id, account_id, direction, amount, memo, create_time, update_time, is_deleted)
VALUES (@trans_id, (SELECT account_id FROM fin_account WHERE account_code = '2211' LIMIT 1), 'CREDIT', @amount, '计提员工工资', NOW(), NOW(), 0);

-- ==========================================
-- 验证：检查借贷平衡（按凭证）
-- ==========================================
SELECT 
    t.voucher_no AS '凭证号',
    t.trans_date AS '凭证日期',
    t.description AS '摘要',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE 0 END) AS '借方合计',
    SUM(CASE WHEN s.direction = 'CREDIT' THEN s.amount ELSE 0 END) AS '贷方合计',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE -s.amount END) AS '差额（应为0）'
FROM fin_transaction t
JOIN fin_split s ON t.trans_id = s.trans_id AND s.is_deleted = 0
WHERE t.voucher_no LIKE 'V%'
GROUP BY t.trans_id, t.voucher_no, t.trans_date, t.description
ORDER BY t.trans_date DESC, t.voucher_no;

-- ==========================================
-- 验证：总体借贷平衡
-- ==========================================
SELECT 
    '总体借贷平衡验证' AS '验证项',
    COUNT(DISTINCT t.trans_id) AS '凭证总数',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE 0 END) AS '借方合计',
    SUM(CASE WHEN s.direction = 'CREDIT' THEN s.amount ELSE 0 END) AS '贷方合计',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE -s.amount END) AS '差额（应为0）'
FROM fin_transaction t
JOIN fin_split s ON t.trans_id = s.trans_id AND s.is_deleted = 0
WHERE t.voucher_no LIKE 'V%';

