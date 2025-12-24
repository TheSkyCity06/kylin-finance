-- ==========================================
-- 麒麟财务管理系统 - 收款单和付款单初始化数据脚本
-- ==========================================
-- 用途：生成10条资金流水数据（5条收款单 + 5条付款单）
-- 包含：收款单核销发票、其他收款、付款单核销账单、直接支出
--
-- 使用方法：
-- 1. 确保已执行 database/init.sql 初始化数据库和科目数据
-- 2. 确保已执行 database/mock_data.sql 初始化客户和供应商数据
-- 3. 确保已执行 database/sales_invoice_and_purchase_bill_data.sql 初始化发票和账单数据
-- 4. 执行此脚本：mysql -u root -p kylin_finance < database/receipt_payment_vouchers_data.sql
-- 5. 脚本使用 INSERT IGNORE，可安全重复执行，不会产生重复数据
--
-- 数据说明：
-- - 收款单：3条核销发票 + 2条其他收款（银行利息收入、收到退税）
-- - 付款单：3条核销账单 + 2条直接支出（银行转账手续费、快递费）
-- - 所有已过账单据都会生成对应的会计分录（复式记账）
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 1. 获取必要的科目ID和币种ID
-- ==========================================
SET @cashAccountId = (SELECT account_id FROM fin_account WHERE account_code = '1001' LIMIT 1); -- 库存现金
SET @bankAccountId = (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1); -- 银行存款
SET @accountsReceivableId = (SELECT account_id FROM fin_account WHERE account_code = '1122' LIMIT 1); -- 应收账款
SET @accountsPayableId = (SELECT account_id FROM fin_account WHERE account_code = '2202' LIMIT 1); -- 应付账款
SET @interestIncomeId = (SELECT account_id FROM fin_account WHERE account_code = '6111' LIMIT 1); -- 投资收益（用于利息收入）
SET @otherIncomeId = (SELECT account_id FROM fin_account WHERE account_code = '6301' LIMIT 1); -- 营业外收入（用于退税）
SET @financialExpenseId = (SELECT account_id FROM fin_account WHERE account_code = '6603' LIMIT 1); -- 财务费用（用于银行手续费）
SET @managementExpenseId = (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1); -- 管理费用（用于快递费）
SET @cnyId = (SELECT commodity_id FROM fin_commodity WHERE commodity_code = 'CNY' LIMIT 1); -- 人民币

-- 如果投资收益科目不存在，使用营业外收入作为利息收入科目
SET @interestIncomeId = IFNULL(@interestIncomeId, @otherIncomeId);

-- 验证必要数据是否存在
SET @cashAccountId = IFNULL(@cashAccountId, NULL);
SET @bankAccountId = IFNULL(@bankAccountId, NULL);
SET @accountsReceivableId = IFNULL(@accountsReceivableId, NULL);
SET @accountsPayableId = IFNULL(@accountsPayableId, NULL);
SET @interestIncomeId = IFNULL(@interestIncomeId, NULL);
SET @otherIncomeId = IFNULL(@otherIncomeId, NULL);
SET @financialExpenseId = IFNULL(@financialExpenseId, NULL);
SET @managementExpenseId = IFNULL(@managementExpenseId, NULL);
SET @cnyId = IFNULL(@cnyId, NULL);

-- ==========================================
-- 2. 获取之前生成的发票和账单ID（用于核销）
-- ==========================================
-- 获取3个已过账未支付的发票（用于收款核销）
SET @invoice3Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241102003' AND is_deleted = 0 LIMIT 1);
SET @invoice4Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241118004' AND is_deleted = 0 LIMIT 1);
SET @invoice5Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241125005' AND is_deleted = 0 LIMIT 1);

-- 获取发票对应的客户信息
SET @customer3Id = (SELECT customer_id FROM fin_invoice WHERE invoice_no = 'INV20241102003' LIMIT 1);
SET @customer4Id = (SELECT customer_id FROM fin_invoice WHERE invoice_no = 'INV20241118004' LIMIT 1);
SET @customer5Id = (SELECT customer_id FROM fin_invoice WHERE invoice_no = 'INV20241125005' LIMIT 1);

-- 获取客户名称
SET @customer3Name = (SELECT o.name FROM fin_owner o WHERE o.owner_id = @customer3Id LIMIT 1);
SET @customer4Name = (SELECT o.name FROM fin_owner o WHERE o.owner_id = @customer4Id LIMIT 1);
SET @customer5Name = (SELECT o.name FROM fin_owner o WHERE o.owner_id = @customer5Id LIMIT 1);

-- 获取发票金额
SET @invoice3Amount = (SELECT total_amount FROM fin_invoice WHERE invoice_no = 'INV20241102003' LIMIT 1);
SET @invoice4Amount = (SELECT total_amount FROM fin_invoice WHERE invoice_no = 'INV20241118004' LIMIT 1);
SET @invoice5Amount = (SELECT total_amount FROM fin_invoice WHERE invoice_no = 'INV20241125005' LIMIT 1);

-- 获取3个已过账的账单（用于付款核销）
SET @bill1Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20240915001' AND is_deleted = 0 LIMIT 1);
SET @bill2Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241020002' AND is_deleted = 0 LIMIT 1);
SET @bill3Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20240930003' AND is_deleted = 0 LIMIT 1);

-- 获取账单对应的供应商信息
SET @vendor1Id = (SELECT vendor_id FROM fin_bill WHERE bill_no = 'BILL20240915001' LIMIT 1);
SET @vendor2Id = (SELECT vendor_id FROM fin_bill WHERE bill_no = 'BILL20241020002' LIMIT 1);
SET @vendor3Id = (SELECT vendor_id FROM fin_bill WHERE bill_no = 'BILL20240930003' LIMIT 1);

-- 获取供应商名称
SET @vendor1Name = (SELECT o.name FROM fin_owner o WHERE o.owner_id = @vendor1Id LIMIT 1);
SET @vendor2Name = (SELECT o.name FROM fin_owner o WHERE o.owner_id = @vendor2Id LIMIT 1);
SET @vendor3Name = (SELECT o.name FROM fin_owner o WHERE o.owner_id = @vendor3Id LIMIT 1);

-- 获取账单金额
SET @bill1Amount = (SELECT total_amount FROM fin_bill WHERE bill_no = 'BILL20240915001' LIMIT 1);
SET @bill2Amount = (SELECT total_amount FROM fin_bill WHERE bill_no = 'BILL20241020002' LIMIT 1);
SET @bill3Amount = (SELECT total_amount FROM fin_bill WHERE bill_no = 'BILL20240930003' LIMIT 1);

-- ==========================================
-- 3. 生成5条收款单 (Receipts)
-- ==========================================

-- 收款单1：核销发票3（银行存款）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241105001', 'RECEIPT', @customer3Name, @customer3Id, @bankAccountId, @invoice3Amount, '2024-11-05',
    CONCAT('收到', @customer3Name, '货款'), 1, NULL,
    '2024-11-05 10:30:00', '2024-11-05 10:30:00', 0
);

SET @receipt1Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241105001' LIMIT 1);

-- 为收款单1生成会计分录（复式记账）
INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241105001', @cnyId, '2024-11-05', '2024-11-05 10:30:00',
    CONCAT('收款单 RP20241105001 - 收到', @customer3Name, '货款'), NULL, 1
);

SET @transReceipt1Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241105001' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transReceipt1Id, @bankAccountId, 'DEBIT', @invoice3Amount, '银行存款 - 收到客户货款', NULL, NULL,
 '2024-11-05 10:30:00', '2024-11-05 10:30:00', 0),
(@transReceipt1Id, @accountsReceivableId, 'CREDIT', @invoice3Amount, '应收账款 - 核销发票', @customer3Id, 'CUSTOMER',
 '2024-11-05 10:30:00', '2024-11-05 10:30:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transReceipt1Id WHERE `id` = @receipt1Id;

-- 收款单2：核销发票4（库存现金）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241120002', 'RECEIPT', @customer4Name, @customer4Id, @cashAccountId, @invoice4Amount, '2024-11-20',
    CONCAT('收到', @customer4Name, '货款'), 1, NULL,
    '2024-11-20 14:15:00', '2024-11-20 14:15:00', 0
);

SET @receipt2Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241120002' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241120002', @cnyId, '2024-11-20', '2024-11-20 14:15:00',
    CONCAT('收款单 RP20241120002 - 收到', @customer4Name, '货款'), NULL, 1
);

SET @transReceipt2Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241120002' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transReceipt2Id, @cashAccountId, 'DEBIT', @invoice4Amount, '库存现金 - 收到客户货款', NULL, NULL,
 '2024-11-20 14:15:00', '2024-11-20 14:15:00', 0),
(@transReceipt2Id, @accountsReceivableId, 'CREDIT', @invoice4Amount, '应收账款 - 核销发票', @customer4Id, 'CUSTOMER',
 '2024-11-20 14:15:00', '2024-11-20 14:15:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transReceipt2Id WHERE `id` = @receipt2Id;

-- 收款单3：核销发票5（银行存款）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241128003', 'RECEIPT', @customer5Name, @customer5Id, @bankAccountId, @invoice5Amount, '2024-11-28',
    CONCAT('收到', @customer5Name, '货款'), 1, NULL,
    '2024-11-28 16:45:00', '2024-11-28 16:45:00', 0
);

SET @receipt3Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241128003' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241128003', @cnyId, '2024-11-28', '2024-11-28 16:45:00',
    CONCAT('收款单 RP20241128003 - 收到', @customer5Name, '货款'), NULL, 1
);

SET @transReceipt3Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241128003' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transReceipt3Id, @bankAccountId, 'DEBIT', @invoice5Amount, '银行存款 - 收到客户货款', NULL, NULL,
 '2024-11-28 16:45:00', '2024-11-28 16:45:00', 0),
(@transReceipt3Id, @accountsReceivableId, 'CREDIT', @invoice5Amount, '应收账款 - 核销发票', @customer5Id, 'CUSTOMER',
 '2024-11-28 16:45:00', '2024-11-28 16:45:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transReceipt3Id WHERE `id` = @receipt3Id;

-- 收款单4：银行利息收入（银行存款）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241015004', 'RECEIPT', '招商银行', NULL, @bankAccountId, 1250.00, '2024-10-15',
    '银行利息收入', 1, NULL,
    '2024-10-15 09:00:00', '2024-10-15 09:00:00', 0
);

SET @receipt4Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241015004' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241015004', @cnyId, '2024-10-15', '2024-10-15 09:00:00',
    '收款单 RP20241015004 - 银行利息收入', NULL, 1
);

SET @transReceipt4Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241015004' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transReceipt4Id, @bankAccountId, 'DEBIT', 1250.00, '银行存款 - 利息收入', NULL, NULL,
 '2024-10-15 09:00:00', '2024-10-15 09:00:00', 0),
(@transReceipt4Id, @interestIncomeId, 'CREDIT', 1250.00, '投资收益 - 银行利息收入', NULL, NULL,
 '2024-10-15 09:00:00', '2024-10-15 09:00:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transReceipt4Id WHERE `id` = @receipt4Id;

-- 收款单5：收到退税（银行存款）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241110005', 'RECEIPT', '税务局', NULL, @bankAccountId, 8500.00, '2024-11-10',
    '收到退税', 1, NULL,
    '2024-11-10 11:20:00', '2024-11-10 11:20:00', 0
);

SET @receipt5Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241110005' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241110005', @cnyId, '2024-11-10', '2024-11-10 11:20:00',
    '收款单 RP20241110005 - 收到退税', NULL, 1
);

SET @transReceipt5Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241110005' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transReceipt5Id, @bankAccountId, 'DEBIT', 8500.00, '银行存款 - 收到退税', NULL, NULL,
 '2024-11-10 11:20:00', '2024-11-10 11:20:00', 0),
(@transReceipt5Id, @otherIncomeId, 'CREDIT', 8500.00, '营业外收入 - 收到退税', NULL, NULL,
 '2024-11-10 11:20:00', '2024-11-10 11:20:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transReceipt5Id WHERE `id` = @receipt5Id;

-- ==========================================
-- 4. 生成5条付款单 (Payments)
-- ==========================================

-- 付款单1：核销账单1（银行存款 - 银行转账）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241020001', 'PAYMENT', @vendor1Name, @vendor1Id, @bankAccountId, @bill1Amount, '2024-10-20',
    CONCAT('支付', @vendor1Name, '货款 - 银行转账'), 1, NULL,
    '2024-10-20 10:00:00', '2024-10-20 10:00:00', 0
);

SET @payment1Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241020001' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241020001', @cnyId, '2024-10-20', '2024-10-20 10:00:00',
    CONCAT('付款单 RP20241020001 - 支付', @vendor1Name, '货款'), NULL, 1
);

SET @transPayment1Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241020001' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transPayment1Id, @accountsPayableId, 'DEBIT', @bill1Amount, '应付账款 - 核销账单', @vendor1Id, 'VENDOR',
 '2024-10-20 10:00:00', '2024-10-20 10:00:00', 0),
(@transPayment1Id, @bankAccountId, 'CREDIT', @bill1Amount, '银行存款 - 支付供应商货款', NULL, NULL,
 '2024-10-20 10:00:00', '2024-10-20 10:00:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transPayment1Id WHERE `id` = @payment1Id;

-- 付款单2：核销账单2（银行存款 - 银行转账）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241101002', 'PAYMENT', @vendor2Name, @vendor2Id, @bankAccountId, @bill2Amount, '2024-11-01',
    CONCAT('支付', @vendor2Name, '货款 - 银行转账'), 1, NULL,
    '2024-11-01 14:30:00', '2024-11-01 14:30:00', 0
);

SET @payment2Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241101002' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241101002', @cnyId, '2024-11-01', '2024-11-01 14:30:00',
    CONCAT('付款单 RP20241101002 - 支付', @vendor2Name, '货款'), NULL, 1
);

SET @transPayment2Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241101002' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transPayment2Id, @accountsPayableId, 'DEBIT', @bill2Amount, '应付账款 - 核销账单', @vendor2Id, 'VENDOR',
 '2024-11-01 14:30:00', '2024-11-01 14:30:00', 0),
(@transPayment2Id, @bankAccountId, 'CREDIT', @bill2Amount, '银行存款 - 支付供应商货款', NULL, NULL,
 '2024-11-01 14:30:00', '2024-11-01 14:30:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transPayment2Id WHERE `id` = @payment2Id;

-- 付款单3：核销账单3（库存现金）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241105003', 'PAYMENT', @vendor3Name, @vendor3Id, @cashAccountId, @bill3Amount, '2024-11-05',
    CONCAT('支付', @vendor3Name, '货款 - 现金'), 1, NULL,
    '2024-11-05 16:00:00', '2024-11-05 16:00:00', 0
);

SET @payment3Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241105003' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241105003', @cnyId, '2024-11-05', '2024-11-05 16:00:00',
    CONCAT('付款单 RP20241105003 - 支付', @vendor3Name, '货款'), NULL, 1
);

SET @transPayment3Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241105003' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transPayment3Id, @accountsPayableId, 'DEBIT', @bill3Amount, '应付账款 - 核销账单', @vendor3Id, 'VENDOR',
 '2024-11-05 16:00:00', '2024-11-05 16:00:00', 0),
(@transPayment3Id, @cashAccountId, 'CREDIT', @bill3Amount, '库存现金 - 支付供应商货款', NULL, NULL,
 '2024-11-05 16:00:00', '2024-11-05 16:00:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transPayment3Id WHERE `id` = @payment3Id;

-- 付款单4：银行转账手续费（银行存款 - 银行转账）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241025004', 'PAYMENT', '招商银行', NULL, @bankAccountId, 50.00, '2024-10-25',
    '支付银行转账手续费 - 银行转账', 1, NULL,
    '2024-10-25 09:30:00', '2024-10-25 09:30:00', 0
);

SET @payment4Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241025004' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241025004', @cnyId, '2024-10-25', '2024-10-25 09:30:00',
    '付款单 RP20241025004 - 支付银行转账手续费', NULL, 1
);

SET @transPayment4Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241025004' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transPayment4Id, @financialExpenseId, 'DEBIT', 50.00, '财务费用 - 银行转账手续费', NULL, NULL,
 '2024-10-25 09:30:00', '2024-10-25 09:30:00', 0),
(@transPayment4Id, @bankAccountId, 'CREDIT', 50.00, '银行存款 - 支付银行手续费', NULL, NULL,
 '2024-10-25 09:30:00', '2024-10-25 09:30:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transPayment4Id WHERE `id` = @payment4Id;

-- 付款单5：快递费（库存现金 - 现金支付）
INSERT IGNORE INTO `biz_receipt_payment` (
    `code`, `type`, `partner_name`, `owner_id`, `account_id`, `amount`, `date`, `remark`, `status`, `voucher_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'RP20241115005', 'PAYMENT', '顺丰速运', NULL, @cashAccountId, 120.00, '2024-11-15',
    '支付快递费 - 现金支付', 1, NULL,
    '2024-11-15 15:20:00', '2024-11-15 15:20:00', 0
);

SET @payment5Id = (SELECT id FROM biz_receipt_payment WHERE code = 'RP20241115005' LIMIT 1);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241115005', @cnyId, '2024-11-15', '2024-11-15 15:20:00',
    '付款单 RP20241115005 - 支付快递费', NULL, 1
);

SET @transPayment5Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241115005' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transPayment5Id, @managementExpenseId, 'DEBIT', 120.00, '管理费用 - 快递费', NULL, NULL,
 '2024-11-15 15:20:00', '2024-11-15 15:20:00', 0),
(@transPayment5Id, @cashAccountId, 'CREDIT', 120.00, '库存现金 - 支付快递费', NULL, NULL,
 '2024-11-15 15:20:00', '2024-11-15 15:20:00', 0);

UPDATE `biz_receipt_payment` SET `voucher_id` = @transPayment5Id WHERE `id` = @payment5Id;

-- ==========================================
-- 5. 数据验证和统计
-- ==========================================
SELECT '收款单统计' AS '数据类型';
SELECT 
    type AS '类型',
    COUNT(*) AS '数量',
    SUM(amount) AS '总金额'
FROM biz_receipt_payment
WHERE type = 'RECEIPT' AND is_deleted = 0
GROUP BY type;

SELECT '付款单统计' AS '数据类型';
SELECT 
    type AS '类型',
    COUNT(*) AS '数量',
    SUM(amount) AS '总金额'
FROM biz_receipt_payment
WHERE type = 'PAYMENT' AND is_deleted = 0
GROUP BY type;

SELECT '收款单明细' AS '数据类型';
SELECT 
    code AS '单据编号',
    partner_name AS '往来单位',
    amount AS '金额',
    date AS '日期',
    remark AS '备注',
    CASE WHEN account_id = @cashAccountId THEN '库存现金' ELSE '银行存款' END AS '结算账户'
FROM biz_receipt_payment
WHERE type = 'RECEIPT' AND is_deleted = 0
ORDER BY date;

SELECT '付款单明细' AS '数据类型';
SELECT 
    code AS '单据编号',
    partner_name AS '往来单位',
    amount AS '金额',
    date AS '日期',
    remark AS '备注',
    CASE WHEN account_id = @cashAccountId THEN '库存现金' ELSE '银行存款' END AS '结算账户'
FROM biz_receipt_payment
WHERE type = 'PAYMENT' AND is_deleted = 0
ORDER BY date;

SELECT '已过账收款单对应的会计分录' AS '数据类型';
SELECT 
    t.voucher_no AS '凭证号',
    t.description AS '摘要',
    COUNT(s.split_id) AS '分录数量',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE 0 END) AS '借方合计',
    SUM(CASE WHEN s.direction = 'CREDIT' THEN s.amount ELSE 0 END) AS '贷方合计'
FROM fin_transaction t
INNER JOIN fin_split s ON t.trans_id = s.trans_id
WHERE t.description LIKE '%收款单%'
GROUP BY t.trans_id, t.voucher_no, t.description;

SELECT '已过账付款单对应的会计分录' AS '数据类型';
SELECT 
    t.voucher_no AS '凭证号',
    t.description AS '摘要',
    COUNT(s.split_id) AS '分录数量',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE 0 END) AS '借方合计',
    SUM(CASE WHEN s.direction = 'CREDIT' THEN s.amount ELSE 0 END) AS '贷方合计'
FROM fin_transaction t
INNER JOIN fin_split s ON t.trans_id = s.trans_id
WHERE t.description LIKE '%付款单%'
GROUP BY t.trans_id, t.voucher_no, t.description;


