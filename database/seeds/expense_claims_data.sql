-- ==========================================
-- 麒麟财务管理系统 - 报销单初始化数据脚本
-- ==========================================
-- 用途：生成8张报销单及其明细数据，模拟真实的差旅和日常支出
-- 包含：差旅费、业务招待费、办公采购等场景
--
-- 使用方法：
-- 1. 确保已执行 database/init.sql 初始化数据库和科目数据
-- 2. 确保已执行 database/mock_data.sql 初始化员工数据
-- 3. 执行此脚本：mysql -u root -p kylin_finance < database/expense_claims_data.sql
-- 4. 脚本使用 INSERT IGNORE，可安全重复执行，不会产生重复数据
--
-- 数据说明：
-- - 报销单：2张草稿，2张待审核，2张已审核待支付，2张已支付
-- - 业务场景：差旅费、业务招待费、办公采购
-- - 所有已过账单据都会生成对应的会计分录（复式记账）
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 1. 获取必要的科目ID和币种ID
-- ==========================================
SET @bankAccountId = (SELECT account_id FROM fin_account WHERE account_code = '1002' LIMIT 1); -- 银行存款
SET @otherPayableId = (SELECT account_id FROM fin_account WHERE account_code = '2241' LIMIT 1); -- 其他应付款
SET @managementExpenseId = (SELECT account_id FROM fin_account WHERE account_code = '6602' LIMIT 1); -- 管理费用（用于差旅费、业务招待费、办公费）
SET @salesExpenseId = (SELECT account_id FROM fin_account WHERE account_code = '6601' LIMIT 1); -- 销售费用（备用）
SET @cnyId = (SELECT commodity_id FROM fin_commodity WHERE commodity_code = 'CNY' LIMIT 1); -- 人民币

-- 验证必要数据是否存在
SET @bankAccountId = IFNULL(@bankAccountId, NULL);
SET @otherPayableId = IFNULL(@otherPayableId, NULL);
SET @managementExpenseId = IFNULL(@managementExpenseId, NULL);
SET @salesExpenseId = IFNULL(@salesExpenseId, NULL);
SET @cnyId = IFNULL(@cnyId, NULL);

-- ==========================================
-- 2. 获取员工ID
-- ==========================================
SET @employee1Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'EMPLOYEE' AND code = 'EMP001' LIMIT 1); -- 张三
SET @employee2Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'EMPLOYEE' AND code = 'EMP002' LIMIT 1); -- 李四
SET @employee3Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'EMPLOYEE' AND code = 'EMP003' LIMIT 1); -- 王五
SET @employee4Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'EMPLOYEE' AND code = 'EMP004' LIMIT 1); -- 赵六
SET @employee5Id = (SELECT owner_id FROM fin_owner WHERE owner_type = 'EMPLOYEE' AND code = 'EMP005' LIMIT 1); -- 钱七

-- ==========================================
-- 3. 生成8张报销单
-- ==========================================

-- 报销单1：差旅费 - 草稿状态（Draft）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241012001', '2024-10-12', @employee2Id, 2850.00, 'PENDING', NULL, NULL, NULL, '差旅费报销 - 草稿状态（未提交）', 0, NULL,
    '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0
);

SET @claim1Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241012001' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim1Id, '往返高铁票', @managementExpenseId, 1200.00, '高铁票发票.jpg',
 '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0),
(@claim1Id, '酒店住宿费', @managementExpenseId, 1500.00, '酒店发票.jpg',
 '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0),
(@claim1Id, '市内交通', @managementExpenseId, 150.00, '出租车发票.jpg',
 '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0);

-- 报销单2：业务招待费 - 草稿状态（Draft）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241018002', '2024-10-18', @employee2Id, 850.00, 'PENDING', NULL, NULL, NULL, '业务招待费报销 - 草稿状态（未提交）', 0, NULL,
    '2024-10-18 14:30:00', '2024-10-18 14:30:00', 0
);

SET @claim2Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241018002' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim2Id, '客户宴请', @managementExpenseId, 650.00, '餐厅发票.jpg',
 '2024-10-18 14:30:00', '2024-10-18 14:30:00', 0),
(@claim2Id, '咖啡会议', @managementExpenseId, 200.00, '咖啡店小票.jpg',
 '2024-10-18 14:30:00', '2024-10-18 14:30:00', 0);

-- 报销单3：差旅费 - 待审核状态（Pending Approval）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241025003', '2024-10-25', @employee3Id, 3200.00, 'PENDING', NULL, NULL, NULL, '差旅费报销 - 待审核（已提交给经理）', 0, NULL,
    '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0
);

SET @claim3Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241025003' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim3Id, '往返高铁票', @managementExpenseId, 1500.00, '高铁票发票.jpg',
 '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0),
(@claim3Id, '酒店住宿费', @managementExpenseId, 1600.00, '酒店发票.jpg',
 '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0),
(@claim3Id, '市内交通', @managementExpenseId, 100.00, '出租车发票.jpg',
 '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0);

-- 报销单4：办公采购 - 待审核状态（Pending Approval）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241102004', '2024-11-02', @employee3Id, 2800.00, 'PENDING', NULL, NULL, NULL, '办公采购报销 - 待审核（已提交给经理）', 0, NULL,
    '2024-11-02 11:20:00', '2024-11-02 11:20:00', 0
);

SET @claim4Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241102004' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim4Id, '测试手机', @managementExpenseId, 2800.00, '手机发票.jpg',
 '2024-11-02 11:20:00', '2024-11-02 11:20:00', 0);

-- 报销单5：差旅费 - 已审核待支付状态（Approved，形成其他应付款）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241108005', '2024-11-08', @employee4Id, 2450.00, 'APPROVED', @employee1Id, '2024-11-08', '已审核，待支付', '差旅费报销 - 已审核待支付', 0, NULL,
    '2024-11-08 08:30:00', '2024-11-08 15:00:00', 0
);

SET @claim5Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241108005' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim5Id, '往返高铁票', @managementExpenseId, 1100.00, '高铁票发票.jpg',
 '2024-11-08 08:30:00', '2024-11-08 08:30:00', 0),
(@claim5Id, '酒店住宿费', @managementExpenseId, 1200.00, '酒店发票.jpg',
 '2024-11-08 08:30:00', '2024-11-08 08:30:00', 0),
(@claim5Id, '市内交通', @managementExpenseId, 150.00, '出租车发票.jpg',
 '2024-11-08 08:30:00', '2024-11-08 08:30:00', 0);

-- 为报销单5生成会计分录（形成其他应付款）
INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241108001', @cnyId, '2024-11-08', '2024-11-08 15:00:00',
    '报销单 EXP20241108005 - 差旅费（已审核待支付）', NULL, 1
);

SET @transClaim5Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241108001' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transClaim5Id, @managementExpenseId, 'DEBIT', 2450.00, '管理费用 - 差旅费', NULL, NULL,
 '2024-11-08 15:00:00', '2024-11-08 15:00:00', 0),
(@transClaim5Id, @otherPayableId, 'CREDIT', 2450.00, '其他应付款 - 员工报销', @employee4Id, 'EMPLOYEE',
 '2024-11-08 15:00:00', '2024-11-08 15:00:00', 0);

UPDATE `fin_expense_claim` SET `trans_id` = @transClaim5Id WHERE `claim_id` = @claim5Id;

-- 报销单6：业务招待费 - 已审核待支付状态（Approved，形成其他应付款）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241115006', '2024-11-15', @employee5Id, 1200.00, 'APPROVED', @employee1Id, '2024-11-15', '已审核，待支付', '业务招待费报销 - 已审核待支付', 0, NULL,
    '2024-11-15 09:45:00', '2024-11-15 16:30:00', 0
);

SET @claim6Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241115006' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim6Id, '客户宴请', @managementExpenseId, 900.00, '餐厅发票.jpg',
 '2024-11-15 09:45:00', '2024-11-15 09:45:00', 0),
(@claim6Id, '咖啡会议', @managementExpenseId, 300.00, '咖啡店小票.jpg',
 '2024-11-15 09:45:00', '2024-11-15 09:45:00', 0);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241115002', @cnyId, '2024-11-15', '2024-11-15 16:30:00',
    '报销单 EXP20241115006 - 业务招待费（已审核待支付）', NULL, 1
);

SET @transClaim6Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241115002' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transClaim6Id, @managementExpenseId, 'DEBIT', 1200.00, '管理费用 - 业务招待费', NULL, NULL,
 '2024-11-15 16:30:00', '2024-11-15 16:30:00', 0),
(@transClaim6Id, @otherPayableId, 'CREDIT', 1200.00, '其他应付款 - 员工报销', @employee5Id, 'EMPLOYEE',
 '2024-11-15 16:30:00', '2024-11-15 16:30:00', 0);

UPDATE `fin_expense_claim` SET `trans_id` = @transClaim6Id WHERE `claim_id` = @claim6Id;

-- 报销单7：办公采购 - 已支付状态（Paid）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241028007', '2024-10-28', @employee1Id, 580.00, 'APPROVED', @employee1Id, '2024-10-28', '已审核并支付', '办公采购报销 - 已支付', 1, NULL,
    '2024-10-28 10:00:00', '2024-10-28 17:00:00', 0
);

SET @claim7Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241028007' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim7Id, '专业书籍', @managementExpenseId, 580.00, '书店发票.jpg',
 '2024-10-28 10:00:00', '2024-10-28 10:00:00', 0);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241028003', @cnyId, '2024-10-28', '2024-10-28 17:00:00',
    '报销单 EXP20241028007 - 办公采购（已支付）', NULL, 1
);

SET @transClaim7Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241028003' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transClaim7Id, @managementExpenseId, 'DEBIT', 580.00, '管理费用 - 办公费', NULL, NULL,
 '2024-10-28 17:00:00', '2024-10-28 17:00:00', 0),
(@transClaim7Id, @bankAccountId, 'CREDIT', 580.00, '银行存款 - 支付员工报销', NULL, NULL,
 '2024-10-28 17:00:00', '2024-10-28 17:00:00', 0);

UPDATE `fin_expense_claim` SET `trans_id` = @transClaim7Id, `posted` = 1 WHERE `claim_id` = @claim7Id;

-- 报销单8：差旅费 - 已支付状态（Paid）
INSERT IGNORE INTO `fin_expense_claim` (
    `claim_no`, `claim_date`, `employee_id`, `total_amount`, `approval_status`, `approver_id`, `approval_date`, `approval_comment`, `notes`, `posted`, `trans_id`,
    `create_time`, `update_time`, `is_deleted`
) VALUES (
    'EXP20241122008', '2024-11-22', @employee2Id, 1950.00, 'APPROVED', @employee1Id, '2024-11-22', '已审核并支付', '差旅费报销 - 已支付', 1, NULL,
    '2024-11-22 08:20:00', '2024-11-22 18:00:00', 0
);

SET @claim8Id = (SELECT claim_id FROM fin_expense_claim WHERE claim_no = 'EXP20241122008' LIMIT 1);

INSERT IGNORE INTO `fin_expense_claim_item` (
    `claim_id`, `description`, `expense_account_id`, `amount`, `attachment`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@claim8Id, '往返高铁票', @managementExpenseId, 900.00, '高铁票发票.jpg',
 '2024-11-22 08:20:00', '2024-11-22 08:20:00', 0),
(@claim8Id, '酒店住宿费', @managementExpenseId, 950.00, '酒店发票.jpg',
 '2024-11-22 08:20:00', '2024-11-22 08:20:00', 0),
(@claim8Id, '市内交通', @managementExpenseId, 100.00, '出租车发票.jpg',
 '2024-11-22 08:20:00', '2024-11-22 08:20:00', 0);

INSERT IGNORE INTO `fin_transaction` (
    `voucher_no`, `currency_id`, `trans_date`, `enter_date`, `description`, `creator_id`, `status`
) VALUES (
    'V20241122004', @cnyId, '2024-11-22', '2024-11-22 18:00:00',
    '报销单 EXP20241122008 - 差旅费（已支付）', NULL, 1
);

SET @transClaim8Id = (SELECT trans_id FROM fin_transaction WHERE voucher_no = 'V20241122004' LIMIT 1);

INSERT IGNORE INTO `fin_split` (
    `trans_id`, `account_id`, `direction`, `amount`, `memo`, `owner_id`, `owner_type`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
(@transClaim8Id, @managementExpenseId, 'DEBIT', 1950.00, '管理费用 - 差旅费', NULL, NULL,
 '2024-11-22 18:00:00', '2024-11-22 18:00:00', 0),
(@transClaim8Id, @bankAccountId, 'CREDIT', 1950.00, '银行存款 - 支付员工报销', NULL, NULL,
 '2024-11-22 18:00:00', '2024-11-22 18:00:00', 0);

UPDATE `fin_expense_claim` SET `trans_id` = @transClaim8Id, `posted` = 1 WHERE `claim_id` = @claim8Id;

-- ==========================================
-- 4. 数据验证和统计
-- ==========================================
SELECT '报销单统计' AS '数据类型';
SELECT 
    approval_status AS '审批状态',
    COUNT(*) AS '数量',
    SUM(total_amount) AS '总金额'
FROM fin_expense_claim
WHERE is_deleted = 0
GROUP BY approval_status;

SELECT '报销单明细统计' AS '数据类型';
SELECT 
    ec.claim_no AS '报销单号',
    o.name AS '申请人',
    ec.total_amount AS '总金额',
    ec.approval_status AS '审批状态',
    COUNT(eci.item_id) AS '明细条数'
FROM fin_expense_claim ec
LEFT JOIN fin_owner o ON ec.employee_id = o.owner_id
LEFT JOIN fin_expense_claim_item eci ON ec.claim_id = eci.claim_id AND eci.is_deleted = 0
WHERE ec.is_deleted = 0
GROUP BY ec.claim_id, ec.claim_no, o.name, ec.total_amount, ec.approval_status
ORDER BY ec.claim_date;

SELECT '已过账报销单对应的会计分录' AS '数据类型';
SELECT 
    t.voucher_no AS '凭证号',
    t.description AS '摘要',
    COUNT(s.split_id) AS '分录数量',
    SUM(CASE WHEN s.direction = 'DEBIT' THEN s.amount ELSE 0 END) AS '借方合计',
    SUM(CASE WHEN s.direction = 'CREDIT' THEN s.amount ELSE 0 END) AS '贷方合计'
FROM fin_transaction t
INNER JOIN fin_split s ON t.trans_id = s.trans_id
WHERE t.description LIKE '%报销单%'
GROUP BY t.trans_id, t.voucher_no, t.description;

