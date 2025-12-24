-- ==========================================
-- 麒麟财务管理系统 - 销售发票和采购账单初始化数据脚本
-- ==========================================
-- 用途：生成10张销售发票和10张采购账单的测试数据
-- 包含：发票/账单主表、条目表、以及对应的会计分录（复式记账）
--
-- 使用方法：
-- 1. 确保已执行 database/init.sql 初始化数据库和科目数据
-- 2. 确保已执行 database/mock_data.sql 初始化客户和供应商数据
-- 3. 执行此脚本：mysql -u root -p kylin_finance < database/sales_invoice_and_purchase_bill_data.sql
-- 4. 脚本使用 INSERT IGNORE，可安全重复执行，不会产生重复数据
--
-- 数据说明：
-- - 销售发票：2张草稿，3张已过账未支付，5张已支付
-- - 采购账单：包含固定资产、日常运营费用、库存商品三类场景
-- - 所有已过账单据都会生成对应的会计分录（复式记账）
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 1. 获取必要的科目ID和币种ID
-- ==========================================
SET @accountsReceivableId = (SELECT account_id FROM fin_account WHERE account_code = '1122' LIMIT 1); -- 应收账款
SET @mainBusinessIncomeId = (SELECT account_id FROM fin_account WHERE account_code = '6001' LIMIT 1); -- 主营业务收入
SET @accountsPayableId = (SELECT account_id FROM fin_account WHERE account_code = '2202' LIMIT 1); -- 应付账款
SET @managementExpenseId = (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1); -- 管理费用
SET @fixedAssetId = (SELECT account_id FROM fin_account WHERE account_code = '1601' LIMIT 1); -- 固定资产
SET @inventoryId = (SELECT account_id FROM fin_account WHERE account_code = '1405' LIMIT 1); -- 库存商品
SET @cnyId = (SELECT commodity_id FROM fin_commodity WHERE commodity_code = 'CNY' LIMIT 1); -- 人民币

-- 验证必要数据是否存在
SET @accountsReceivableId = IFNULL(@accountsReceivableId, NULL);
SET @mainBusinessIncomeId = IFNULL(@mainBusinessIncomeId, NULL);
SET @accountsPayableId = IFNULL(@accountsPayableId, NULL);
SET @managementExpenseId = IFNULL(@managementExpenseId, NULL);
SET @fixedAssetId = IFNULL(@fixedAssetId, NULL);
SET @inventoryId = IFNULL(@inventoryId, NULL);
SET @cnyId = IFNULL(@cnyId, NULL);

-- ==========================================
-- 2. 获取客户和供应商ID（随机选择）
-- ==========================================
SET @customer1Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST001' LIMIT 1);
SET @customer2Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST002' LIMIT 1);
SET @customer3Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST003' LIMIT 1);
SET @customer4Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST004' LIMIT 1);
SET @customer5Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST005' LIMIT 1);
SET @customer6Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST006' LIMIT 1);
SET @customer7Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST007' LIMIT 1);
SET @customer8Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST008' LIMIT 1);
SET @customer9Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST009' LIMIT 1);
SET @customer10Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'CUSTOMER' AND code = 'CUST010' LIMIT 1);

SET @vendor1Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'VENDOR' AND code = 'SUPP001' LIMIT 1);
SET @vendor2Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'VENDOR' AND code = 'SUPP002' LIMIT 1);
SET @vendor3Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'VENDOR' AND code = 'SUPP003' LIMIT 1);
SET @vendor4Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'VENDOR' AND code = 'SUPP004' LIMIT 1);
SET @vendor5Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'VENDOR' AND code = 'SUPP005' LIMIT 1);

-- ==========================================
-- 3. 生成10张销售发票 (Sales Invoices)
-- ==========================================

-- 发票1：草稿状态（未过账）
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241001001', '2024-10-05', '2024-11-04', @customer1Id, 'DRAFT', @cnyId,
    12500.00, 1625.00, 10875.00, '软件开发服务费 - 草稿', 0, NULL,
    '2024-10-05 10:00:00', '2024-10-05 10:00:00', 0
);

SET @invoice1Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241001001' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice1Id, '软件开发服务费', @mainBusinessIncomeId, 1.000000, 10875.00, 10875.00, 13.00, 1625.00,
    '2024-10-05 10:00:00', '2024-10-05 10:00:00', 0
);

-- 发票2：草稿状态（未过账）
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241015002', '2024-10-15', '2024-11-14', @customer2Id, 'DRAFT', @cnyId,
    8500.00, 1105.00, 7395.00, '年度维护费 - 草稿', 0, NULL,
    '2024-10-15 14:30:00', '2024-10-15 14:30:00', 0
);

SET @invoice2Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241015002' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice2Id, '年度维护费', @mainBusinessIncomeId, 1.000000, 7395.00, 7395.00, 13.00, 1105.00,
    '2024-10-15 14:30:00', '2024-10-15 14:30:00', 0
);

-- 发票3：已过账未支付（增加应收账款）
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241102003', '2024-11-02', '2024-12-02', @customer3Id, 'OPEN', @cnyId,
    28500.00, 3705.00, 24795.00, '咨询服务 - 已过账未支付', 1, NULL,
    '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0
);

SET @invoice3Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241102003' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice3Id, '咨询服务', @mainBusinessIncomeId, 1.000000, 24795.00, 24795.00, 13.00, 3705.00,
    '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0
);

-- 为发票3生成会计分录（复式记账）
INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-02', '%Y%m%d'), '001'), @cnyId, '2024-11-02', '2024-11-02 09:15:00',
    '销售发票 INV20241102003 - 咨询服务', NULL, 1
);

SET @trans3Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-02', '%Y%m%d'), '001') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans3Id, @accountsReceivableId, 'DEBIT', 28500.00, '应收账款 - 客户发票', @customer3Id, 'CUSTOMER',
 '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0),
(@trans3Id, @mainBusinessIncomeId, 'CREDIT', 28500.00, '主营业务收入 - 咨询服务', NULL, NULL,
 '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans3Id WHERE `invoice_id` = @invoice3Id;

-- 发票4：已过账未支付
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241118004', '2024-11-18', '2024-12-18', @customer4Id, 'OPEN', @cnyId,
    15200.00, 1976.00, 13224.00, '软件开发服务费 - 已过账未支付', 1, NULL,
    '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0
);

SET @invoice4Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241118004' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice4Id, '软件开发服务费', @mainBusinessIncomeId, 1.000000, 13224.00, 13224.00, 13.00, 1976.00,
    '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-18', '%Y%m%d'), '002'), @cnyId, '2024-11-18', '2024-11-18 11:20:00',
    '销售发票 INV20241118004 - 软件开发服务费', NULL, 1
);

SET @trans4Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-18', '%Y%m%d'), '002') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans4Id, @accountsReceivableId, 'DEBIT', 15200.00, '应收账款 - 客户发票', @customer4Id, 'CUSTOMER',
 '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0),
(@trans4Id, @mainBusinessIncomeId, 'CREDIT', 15200.00, '主营业务收入 - 软件开发服务费', NULL, NULL,
 '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans4Id WHERE `invoice_id` = @invoice4Id;

-- 发票5：已过账未支付
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241125005', '2024-11-25', '2024-12-25', @customer5Id, 'OPEN', @cnyId,
    36800.00, 4784.00, 32016.00, '年度维护费 - 已过账未支付', 1, NULL,
    '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0
);

SET @invoice5Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241125005' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice5Id, '年度维护费', @mainBusinessIncomeId, 1.000000, 32016.00, 32016.00, 13.00, 4784.00,
    '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-25', '%Y%m%d'), '003'), @cnyId, '2024-11-25', '2024-11-25 15:45:00',
    '销售发票 INV20241125005 - 年度维护费', NULL, 1
);

SET @trans5Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-25', '%Y%m%d'), '003') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans5Id, @accountsReceivableId, 'DEBIT', 36800.00, '应收账款 - 客户发票', @customer5Id, 'CUSTOMER',
 '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0),
(@trans5Id, @mainBusinessIncomeId, 'CREDIT', 36800.00, '主营业务收入 - 年度维护费', NULL, NULL,
 '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans5Id WHERE `invoice_id` = @invoice5Id;

-- 发票6：已支付
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20240910006', '2024-09-10', '2024-10-10', @customer6Id, 'PAID', @cnyId,
    42000.00, 5460.00, 36540.00, '咨询服务 - 已支付', 1, NULL,
    '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0
);

SET @invoice6Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20240910006' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice6Id, '咨询服务', @mainBusinessIncomeId, 1.000000, 36540.00, 36540.00, 13.00, 5460.00,
    '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-09-10', '%Y%m%d'), '004'), @cnyId, '2024-09-10', '2024-09-10 08:30:00',
    '销售发票 INV20240910006 - 咨询服务', NULL, 1
);

SET @trans6Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-09-10', '%Y%m%d'), '004') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans6Id, @accountsReceivableId, 'DEBIT', 42000.00, '应收账款 - 客户发票', @customer6Id, 'CUSTOMER',
 '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0),
(@trans6Id, @mainBusinessIncomeId, 'CREDIT', 42000.00, '主营业务收入 - 咨询服务', NULL, NULL,
 '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans6Id WHERE `invoice_id` = @invoice6Id;

-- 发票7：已支付
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20240922007', '2024-09-22', '2024-10-22', @customer7Id, 'PAID', @cnyId,
    18500.00, 2405.00, 16095.00, '软件开发服务费 - 已支付', 1, NULL,
    '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0
);

SET @invoice7Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20240922007' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice7Id, '软件开发服务费', @mainBusinessIncomeId, 1.000000, 16095.00, 16095.00, 13.00, 2405.00,
    '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-09-22', '%Y%m%d'), '005'), @cnyId, '2024-09-22', '2024-09-22 13:15:00',
    '销售发票 INV20240922007 - 软件开发服务费', NULL, 1
);

SET @trans7Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-09-22', '%Y%m%d'), '005') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans7Id, @accountsReceivableId, 'DEBIT', 18500.00, '应收账款 - 客户发票', @customer7Id, 'CUSTOMER',
 '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0),
(@trans7Id, @mainBusinessIncomeId, 'CREDIT', 18500.00, '主营业务收入 - 软件开发服务费', NULL, NULL,
 '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans7Id WHERE `invoice_id` = @invoice7Id;

-- 发票8：已支付
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241008008', '2024-10-08', '2024-11-07', @customer8Id, 'PAID', @cnyId,
    9800.00, 1274.00, 8526.00, '年度维护费 - 已支付', 1, NULL,
    '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0
);

SET @invoice8Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241008008' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice8Id, '年度维护费', @mainBusinessIncomeId, 1.000000, 8526.00, 8526.00, 13.00, 1274.00,
    '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-10-08', '%Y%m%d'), '006'), @cnyId, '2024-10-08', '2024-10-08 16:20:00',
    '销售发票 INV20241008008 - 年度维护费', NULL, 1
);

SET @trans8Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-10-08', '%Y%m%d'), '006') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans8Id, @accountsReceivableId, 'DEBIT', 9800.00, '应收账款 - 客户发票', @customer8Id, 'CUSTOMER',
 '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0),
(@trans8Id, @mainBusinessIncomeId, 'CREDIT', 9800.00, '主营业务收入 - 年度维护费', NULL, NULL,
 '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans8Id WHERE `invoice_id` = @invoice8Id;

-- 发票9：已支付
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241028009', '2024-10-28', '2024-11-27', @customer9Id, 'PAID', @cnyId,
    32500.00, 4225.00, 28275.00, '咨询服务 - 已支付', 1, NULL,
    '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0
);

SET @invoice9Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241028009' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice9Id, '咨询服务', @mainBusinessIncomeId, 1.000000, 28275.00, 28275.00, 13.00, 4225.00,
    '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-10-28', '%Y%m%d'), '007'), @cnyId, '2024-10-28', '2024-10-28 10:50:00',
    '销售发票 INV20241028009 - 咨询服务', NULL, 1
);

SET @trans9Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-10-28', '%Y%m%d'), '007') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans9Id, @accountsReceivableId, 'DEBIT', 32500.00, '应收账款 - 客户发票', @customer9Id, 'CUSTOMER',
 '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0),
(@trans9Id, @mainBusinessIncomeId, 'CREDIT', 32500.00, '主营业务收入 - 咨询服务', NULL, NULL,
 '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans9Id WHERE `invoice_id` = @invoice9Id;

-- 发票10：已支付
INSERT IGNORE INTO `fin_invoice` (
    `invoice_no`, `invoice_date`, `due_date`, `customer_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'INV20241112010', '2024-11-12', '2024-12-12', @customer10Id, 'PAID', @cnyId,
    21500.00, 2795.00, 18705.00, '软件开发服务费 - 已支付', 1, NULL,
    '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0
);

SET @invoice10Id = (SELECT invoice_id FROM fin_invoice WHERE invoice_no = 'INV20241112010' LIMIT 1);

INSERT IGNORE INTO `fin_invoice_item` (
    `invoice_id`, `description`, `income_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @invoice10Id, '软件开发服务费', @mainBusinessIncomeId, 1.000000, 18705.00, 18705.00, 13.00, 2795.00,
    '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-12', '%Y%m%d'), '008'), @cnyId, '2024-11-12', '2024-11-12 14:00:00',
    '销售发票 INV20241112010 - 软件开发服务费', NULL, 1
);

SET @trans10Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-12', '%Y%m%d'), '008') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@trans10Id, @accountsReceivableId, 'DEBIT', 21500.00, '应收账款 - 客户发票', @customer10Id, 'CUSTOMER',
 '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0),
(@trans10Id, @mainBusinessIncomeId, 'CREDIT', 21500.00, '主营业务收入 - 软件开发服务费', NULL, NULL,
 '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0);

UPDATE `fin_invoice` SET `trans_id` = @trans10Id WHERE `invoice_id` = @invoice10Id;

-- ==========================================
-- 4. 生成10张采购账单 (Purchase Bills)
-- ==========================================

-- 账单1：固定资产采购（已逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20240915001', '2024-09-15', '2024-10-15', @vendor1Id, 'OPEN', @cnyId,
    12500.00, 1625.00, 10875.00, '高性能笔记本电脑采购 - 已逾期', 1, NULL,
    '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0
);

SET @bill1Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20240915001' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill1Id, '高性能笔记本电脑', @fixedAssetId, 2.000000, 5437.50, 10875.00, 13.00, 1625.00,
    '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-09-15', '%Y%m%d'), '009'), @cnyId, '2024-09-15', '2024-09-15 09:00:00',
    '采购账单 BILL20240915001 - 高性能笔记本电脑', NULL, 1
);

SET @transBill1Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-09-15', '%Y%m%d'), '009') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill1Id, @fixedAssetId, 'DEBIT', 12500.00, '固定资产 - 笔记本电脑', NULL, NULL,
 '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0),
(@transBill1Id, @accountsPayableId, 'CREDIT', 12500.00, '应付账款 - 供应商账单', @vendor1Id, 'VENDOR',
 '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill1Id WHERE `bill_id` = @bill1Id;

-- 账单2：固定资产采购（未逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241020002', '2024-10-20', '2024-12-20', @vendor2Id, 'OPEN', @cnyId,
    18500.00, 2405.00, 16095.00, '办公家具采购', 1, NULL,
    '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0
);

SET @bill2Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241020002' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill2Id, '办公家具', @fixedAssetId, 1.000000, 16095.00, 16095.00, 13.00, 2405.00,
    '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-10-20', '%Y%m%d'), '010'), @cnyId, '2024-10-20', '2024-10-20 10:30:00',
    '采购账单 BILL20241020002 - 办公家具', NULL, 1
);

SET @transBill2Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-10-20', '%Y%m%d'), '010') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill2Id, @fixedAssetId, 'DEBIT', 18500.00, '固定资产 - 办公家具', NULL, NULL,
 '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0),
(@transBill2Id, @accountsPayableId, 'CREDIT', 18500.00, '应付账款 - 供应商账单', @vendor2Id, 'VENDOR',
 '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill2Id WHERE `bill_id` = @bill2Id;

-- 账单3：日常运营费用 - 办公室租金（已逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20240930003', '2024-09-30', '2024-10-30', @vendor3Id, 'OPEN', @cnyId,
    8500.00, 1105.00, 7395.00, '办公室租金 - 已逾期', 1, NULL,
    '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0
);

SET @bill3Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20240930003' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill3Id, '办公室租金', @managementExpenseId, 1.000000, 7395.00, 7395.00, 13.00, 1105.00,
    '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-09-30', '%Y%m%d'), '011'), @cnyId, '2024-09-30', '2024-09-30 11:00:00',
    '采购账单 BILL20240930003 - 办公室租金', NULL, 1
);

SET @transBill3Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-09-30', '%Y%m%d'), '011') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill3Id, @managementExpenseId, 'DEBIT', 8500.00, '管理费用 - 办公室租金', NULL, NULL,
 '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0),
(@transBill3Id, @accountsPayableId, 'CREDIT', 8500.00, '应付账款 - 供应商账单', @vendor3Id, 'VENDOR',
 '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill3Id WHERE `bill_id` = @bill3Id;

-- 账单4：日常运营费用 - 电费（未逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241105004', '2024-11-05', '2024-12-05', @vendor4Id, 'OPEN', @cnyId,
    3200.00, 416.00, 2784.00, '电费', 1, NULL,
    '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0
);

SET @bill4Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241105004' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill4Id, '电费', @managementExpenseId, 1.000000, 2784.00, 2784.00, 13.00, 416.00,
    '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-05', '%Y%m%d'), '012'), @cnyId, '2024-11-05', '2024-11-05 08:45:00',
    '采购账单 BILL20241105004 - 电费', NULL, 1
);

SET @transBill4Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-05', '%Y%m%d'), '012') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill4Id, @managementExpenseId, 'DEBIT', 3200.00, '管理费用 - 电费', NULL, NULL,
 '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0),
(@transBill4Id, @accountsPayableId, 'CREDIT', 3200.00, '应付账款 - 供应商账单', @vendor4Id, 'VENDOR',
 '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill4Id WHERE `bill_id` = @bill4Id;

-- 账单5：日常运营费用 - AWS/阿里云服务器续费（未逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241120005', '2024-11-20', '2024-12-20', @vendor5Id, 'OPEN', @cnyId,
    12500.00, 1625.00, 10875.00, 'AWS/阿里云服务器续费', 1, NULL,
    '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0
);

SET @bill5Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241120005' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill5Id, 'AWS/阿里云服务器续费', @managementExpenseId, 1.000000, 10875.00, 10875.00, 13.00, 1625.00,
    '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-20', '%Y%m%d'), '013'), @cnyId, '2024-11-20', '2024-11-20 15:20:00',
    '采购账单 BILL20241120005 - AWS/阿里云服务器续费', NULL, 1
);

SET @transBill5Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-20', '%Y%m%d'), '013') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill5Id, @managementExpenseId, 'DEBIT', 12500.00, '管理费用 - 服务器续费', NULL, NULL,
 '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0),
(@transBill5Id, @accountsPayableId, 'CREDIT', 12500.00, '应付账款 - 供应商账单', @vendor5Id, 'VENDOR',
 '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill5Id WHERE `bill_id` = @bill5Id;

-- 账单6：库存商品采购（已逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241010006', '2024-10-10', '2024-11-10', @vendor1Id, 'OPEN', @cnyId,
    28500.00, 3705.00, 24795.00, '原材料采购 - 已逾期', 1, NULL,
    '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0
);

SET @bill6Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241010006' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill6Id, '原材料采购', @inventoryId, 100.000000, 247.95, 24795.00, 13.00, 3705.00,
    '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-10-10', '%Y%m%d'), '014'), @cnyId, '2024-10-10', '2024-10-10 13:30:00',
    '采购账单 BILL20241010006 - 原材料采购', NULL, 1
);

SET @transBill6Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-10-10', '%Y%m%d'), '014') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill6Id, @inventoryId, 'DEBIT', 28500.00, '库存商品 - 原材料', NULL, NULL,
 '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0),
(@transBill6Id, @accountsPayableId, 'CREDIT', 28500.00, '应付账款 - 供应商账单', @vendor1Id, 'VENDOR',
 '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill6Id WHERE `bill_id` = @bill6Id;

-- 账单7：库存商品采购（未逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241115007', '2024-11-15', '2024-12-15', @vendor2Id, 'OPEN', @cnyId,
    15200.00, 1976.00, 13224.00, '原材料采购', 1, NULL,
    '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0
);

SET @bill7Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241115007' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill7Id, '原材料采购', @inventoryId, 50.000000, 264.48, 13224.00, 13.00, 1976.00,
    '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-15', '%Y%m%d'), '015'), @cnyId, '2024-11-15', '2024-11-15 09:15:00',
    '采购账单 BILL20241115007 - 原材料采购', NULL, 1
);

SET @transBill7Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-15', '%Y%m%d'), '015') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill7Id, @inventoryId, 'DEBIT', 15200.00, '库存商品 - 原材料', NULL, NULL,
 '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0),
(@transBill7Id, @accountsPayableId, 'CREDIT', 15200.00, '应付账款 - 供应商账单', @vendor2Id, 'VENDOR',
 '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill7Id WHERE `bill_id` = @bill7Id;

-- 账单8：固定资产采购（未逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241128008', '2024-11-28', '2025-01-28', @vendor3Id, 'OPEN', @cnyId,
    36800.00, 4784.00, 32016.00, '高性能笔记本电脑采购', 1, NULL,
    '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0
);

SET @bill8Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241128008' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill8Id, '高性能笔记本电脑', @fixedAssetId, 3.000000, 10672.00, 32016.00, 13.00, 4784.00,
    '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-28', '%Y%m%d'), '016'), @cnyId, '2024-11-28', '2024-11-28 10:00:00',
    '采购账单 BILL20241128008 - 高性能笔记本电脑', NULL, 1
);

SET @transBill8Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-28', '%Y%m%d'), '016') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill8Id, @fixedAssetId, 'DEBIT', 36800.00, '固定资产 - 笔记本电脑', NULL, NULL,
 '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0),
(@transBill8Id, @accountsPayableId, 'CREDIT', 36800.00, '应付账款 - 供应商账单', @vendor3Id, 'VENDOR',
 '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill8Id WHERE `bill_id` = @bill8Id;

-- 账单9：日常运营费用 - 办公室租金（未逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241130009', '2024-11-30', '2024-12-30', @vendor4Id, 'OPEN', @cnyId,
    8500.00, 1105.00, 7395.00, '办公室租金', 1, NULL,
    '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0
);

SET @bill9Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241130009' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill9Id, '办公室租金', @managementExpenseId, 1.000000, 7395.00, 7395.00, 13.00, 1105.00,
    '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-11-30', '%Y%m%d'), '017'), @cnyId, '2024-11-30', '2024-11-30 11:00:00',
    '采购账单 BILL20241130009 - 办公室租金', NULL, 1
);

SET @transBill9Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-11-30', '%Y%m%d'), '017') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill9Id, @managementExpenseId, 'DEBIT', 8500.00, '管理费用 - 办公室租金', NULL, NULL,
 '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0),
(@transBill9Id, @accountsPayableId, 'CREDIT', 8500.00, '应付账款 - 供应商账单', @vendor4Id, 'VENDOR',
 '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill9Id WHERE `bill_id` = @bill9Id;

-- 账单10：库存商品采购（未逾期）
INSERT IGNORE INTO `fin_bill` (
    `bill_no`, `bill_date`, `due_date`, `vendor_id`, `status`, `commodity_id`,
    `total_amount`, `tax_amount`, `net_amount`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'BILL20241201010', '2024-12-01', '2025-01-01', @vendor5Id, 'OPEN', @cnyId,
    21500.00, 2795.00, 18705.00, '原材料采购', 1, NULL,
    '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0
);

SET @bill10Id = (SELECT bill_id FROM fin_bill WHERE bill_no = 'BILL20241201010' LIMIT 1);

INSERT IGNORE INTO `fin_bill_item` (
    `bill_id`, `description`, `expense_account_id`, `quantity`, `unit_price`, `amount`, `tax_rate`, `tax_amount`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    @bill10Id, '原材料采购', @inventoryId, 75.000000, 249.40, 18705.00, 13.00, 2795.00,
    '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0
);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    CONCAT('V', DATE_FORMAT('2024-12-01', '%Y%m%d'), '018'), @cnyId, '2024-12-01', '2024-12-01 14:30:00',
    '采购账单 BILL20241201010 - 原材料采购', NULL, 1
);

SET @transBill10Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = CONCAT('V', DATE_FORMAT('2024-12-01', '%Y%m%d'), '018') LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transBill10Id, @inventoryId, 'DEBIT', 21500.00, '库存商品 - 原材料', NULL, NULL,
 '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0),
(@transBill10Id, @accountsPayableId, 'CREDIT', 21500.00, '应付账款 - 供应商账单', @vendor5Id, 'VENDOR',
 '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0);

UPDATE `fin_bill` SET `trans_id` = @transBill10Id WHERE `bill_id` = @bill10Id;

-- ==========================================
-- 5. 数据验证和统计
-- ==========================================
SELECT '销售发票统计' AS '数据类型';
SELECT 
    status AS '状态',
    COUNT(*) AS '数量',
    SUM(total_amount) AS '总金额'
FROM fin_invoice
WHERE is_deleted = 0
GROUP BY status;

SELECT '采购账单统计' AS '数据类型';
SELECT 
    status AS '状态',
    COUNT(*) AS '数量',
    SUM(total_amount) AS '总金额'
FROM fin_bill
WHERE is_deleted = 0
GROUP BY status;

SELECT '已过账发票对应的会计分录' AS '数据类型';
SELECT 
    t.voucher_no AS '凭证号',
    t.description AS '摘要',
    COUNT(s.split_id) AS '分录数量',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE 0 END) AS '借方合计',
    SUM(CASE WHEN s.direction = 'CREDIT' THEN s.amount ELSE 0 END) AS '贷方合计'
FROM fin_transaction t
INNER JOIN fin_split s ON t.trans_id = s.trans_id
WHERE t.description LIKE '%销售发票%'
GROUP BY t.trans_id, t.voucher_no, t.description;

SELECT '已过账账单对应的会计分录' AS '数据类型';
SELECT 
    t.voucher_no AS '凭证号',
    t.description AS '摘要',
    COUNT(s.split_id) AS '分录数量',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE 0 END) AS '借方合计',
    SUM(CASE WHEN s.direction = 'CREDIT' THEN s.amount ELSE 0 END) AS '贷方合计'
FROM fin_transaction t
INNER JOIN fin_split s ON t.trans_id = s.trans_id
WHERE t.description LIKE '%采购账单%'
GROUP BY t.trans_id, t.voucher_no, t.description;

