-- ==========================================
-- 麒麟财务管理系统数据库初始化脚本
-- ==========================================

-- 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS kylin_finance DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE kylin_finance;

-- ==========================================
-- 1. 会计科目表 (fin_account)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_account` (
                                             `account_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '科目ID',
                                             `account_code` VARCHAR(50) NOT NULL COMMENT '科目代码，如1001',
    `account_name` VARCHAR(100) NOT NULL COMMENT '科目名称，如库存现金',
    `account_type` VARCHAR(20) NOT NULL COMMENT '科目类型：ASSET(资产), LIABILITY(负债), EQUITY(权益), INCOME(收入), EXPENSE(支出)',
    `parent_id` BIGINT NULL COMMENT '父科目ID，构建树形结构',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`account_id`),
    UNIQUE KEY `uk_account_code` (`account_code`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_account_type` (`account_type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会计科目表';

-- ==========================================
-- 2. 凭证主表 (fin_transaction)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_transaction` (
                                                 `trans_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '凭证ID',
                                                 `voucher_no` VARCHAR(50) NOT NULL COMMENT '凭证号，如V20241201001',
    `currency_id` BIGINT NULL COMMENT '币种ID',
    `trans_date` DATE NOT NULL COMMENT '交易日期',
    `enter_date` DATETIME NULL COMMENT '录入时间',
    `description` VARCHAR(500) NULL COMMENT '凭证摘要/描述',
    `creator_id` BIGINT NULL COMMENT '创建人ID',
    `status` INT DEFAULT 0 COMMENT '状态：0-草稿，1-已审核',
    PRIMARY KEY (`trans_id`),
    UNIQUE KEY `uk_voucher_no` (`voucher_no`),
    KEY `idx_trans_date` (`trans_date`),
    KEY `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='凭证主表';

-- ==========================================
-- 3. 凭证分录表 (fin_split)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_split` (
                                           `split_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '分录ID',
                                           `trans_id` BIGINT NOT NULL COMMENT '凭证ID（外键）',
                                           `account_id` BIGINT NOT NULL COMMENT '科目ID（外键）',
                                           `direction` VARCHAR(10) NOT NULL COMMENT '借贷方向：DEBIT(借), CREDIT(贷)',
    `amount` DECIMAL(18, 2) NOT NULL COMMENT '金额',
    `memo` VARCHAR(500) NULL COMMENT '分录备注/摘要',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`split_id`),
    KEY `idx_trans_id` (`trans_id`),
    KEY `idx_account_id` (`account_id`),
    KEY `idx_direction` (`direction`),
    CONSTRAINT `fk_split_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_split_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='凭证分录表';

-- ==========================================
-- 4. 初始化基础会计科目（参考企业会计准则）
-- ==========================================

-- 初始化根科目（使用 INSERT IGNORE 避免重复插入）
INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
('1000', '资产', 'ASSET', NULL),
('2000', '负债', 'LIABILITY', NULL),
('3000', '所有者权益', 'EQUITY', NULL),
('4000', '收入', 'INCOME', NULL),
('5000', '支出', 'EXPENSE', NULL);

-- 设置变量存储根节点ID（MySQL 8.0+）
SET @asset_root_id = (SELECT account_id FROM fin_account WHERE account_code = '1000');
SET @liability_root_id = (SELECT account_id FROM fin_account WHERE account_code = '2000');
SET @equity_root_id = (SELECT account_id FROM fin_account WHERE account_code = '3000');
SET @income_root_id = (SELECT account_id FROM fin_account WHERE account_code = '4000');
SET @expense_root_id = (SELECT account_id FROM fin_account WHERE account_code = '5000');

-- 资产类科目（使用 INSERT IGNORE 避免重复插入）
-- 创建货币资金分类
INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
    ('1100', '货币资金', 'ASSET', @asset_root_id);

SET @cash_id = (SELECT account_id FROM fin_account WHERE account_code = '1100');

INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
    ('1001', '库存现金', 'ASSET', @cash_id),
    ('1002', '银行存款', 'ASSET', @cash_id),
    ('1012', '其他货币资金', 'ASSET', @cash_id),
    ('1101', '交易性金融资产', 'ASSET', @asset_root_id),
    ('1121', '应收票据', 'ASSET', @asset_root_id),
    ('1122', '应收账款', 'ASSET', @asset_root_id),
    ('1123', '预付账款', 'ASSET', @asset_root_id),
    ('1131', '应收股利', 'ASSET', @asset_root_id),
    ('1132', '应收利息', 'ASSET', @asset_root_id),
    ('1221', '其他应收款', 'ASSET', @asset_root_id),
    ('1231', '坏账准备', 'ASSET', @asset_root_id),
    ('1401', '材料采购', 'ASSET', @asset_root_id),
    ('1403', '原材料', 'ASSET', @asset_root_id),
    ('1405', '库存商品', 'ASSET', @asset_root_id),
    ('1411', '周转材料', 'ASSET', @asset_root_id),
    ('1471', '存货跌价准备', 'ASSET', @asset_root_id),
    ('1501', '持有至到期投资', 'ASSET', @asset_root_id),
    ('1502', '持有至到期投资减值准备', 'ASSET', @asset_root_id),
    ('1503', '可供出售金融资产', 'ASSET', @asset_root_id),
    ('1511', '长期股权投资', 'ASSET', @asset_root_id),
    ('1512', '长期股权投资减值准备', 'ASSET', @asset_root_id),
    ('1521', '投资性房地产', 'ASSET', @asset_root_id),
    ('1531', '长期应收款', 'ASSET', @asset_root_id),
    ('1601', '固定资产', 'ASSET', @asset_root_id),
    ('1602', '累计折旧', 'ASSET', @asset_root_id),
    ('1603', '固定资产减值准备', 'ASSET', @asset_root_id),
    ('1604', '在建工程', 'ASSET', @asset_root_id),
    ('1605', '工程物资', 'ASSET', @asset_root_id),
    ('1606', '固定资产清理', 'ASSET', @asset_root_id),
    ('1701', '无形资产', 'ASSET', @asset_root_id),
    ('1702', '累计摊销', 'ASSET', @asset_root_id),
    ('1703', '无形资产减值准备', 'ASSET', @asset_root_id),
    ('1711', '商誉', 'ASSET', @asset_root_id),
    ('1801', '长期待摊费用', 'ASSET', @asset_root_id),
    ('1811', '递延所得税资产', 'ASSET', @asset_root_id),
    ('1901', '待处理财产损溢', 'ASSET', @asset_root_id);

-- 负债类科目
INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
    ('2001', '短期借款', 'LIABILITY', @liability_root_id),
    ('2101', '交易性金融负债', 'LIABILITY', @liability_root_id),
    ('2201', '应付票据', 'LIABILITY', @liability_root_id),
    ('2202', '应付账款', 'LIABILITY', @liability_root_id),
    ('2203', '预收账款', 'LIABILITY', @liability_root_id),
    ('2211', '应付职工薪酬', 'LIABILITY', @liability_root_id),
    ('2221', '应交税费', 'LIABILITY', @liability_root_id),
    ('2231', '应付利息', 'LIABILITY', @liability_root_id),
    ('2232', '应付股利', 'LIABILITY', @liability_root_id),
    ('2241', '其他应付款', 'LIABILITY', @liability_root_id),
    ('2401', '递延收益', 'LIABILITY', @liability_root_id),
    ('2501', '长期借款', 'LIABILITY', @liability_root_id),
    ('2502', '应付债券', 'LIABILITY', @liability_root_id),
    ('2701', '长期应付款', 'LIABILITY', @liability_root_id),
    ('2702', '未确认融资费用', 'LIABILITY', @liability_root_id),
    ('2711', '专项应付款', 'LIABILITY', @liability_root_id),
    ('2801', '预计负债', 'LIABILITY', @liability_root_id),
    ('2901', '递延所得税负债', 'LIABILITY', @liability_root_id);

-- 所有者权益类科目
INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
    ('4001', '实收资本', 'EQUITY', @equity_root_id),
    ('4002', '资本公积', 'EQUITY', @equity_root_id),
    ('4101', '盈余公积', 'EQUITY', @equity_root_id),
    ('4103', '本年利润', 'EQUITY', @equity_root_id),
    ('4104', '利润分配', 'EQUITY', @equity_root_id);

-- 成本类科目
INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
    ('5001', '生产成本', 'EXPENSE', @expense_root_id),
    ('5101', '制造费用', 'EXPENSE', @expense_root_id),
    ('5201', '劳务成本', 'EXPENSE', @expense_root_id),
    ('5301', '研发支出', 'EXPENSE', @expense_root_id);

-- 损益类科目 - 收入
INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
    ('6001', '主营业务收入', 'INCOME', @income_root_id),
    ('6051', '其他业务收入', 'INCOME', @income_root_id),
    ('6101', '公允价值变动损益', 'INCOME', @income_root_id),
    ('6111', '投资收益', 'INCOME', @income_root_id),
    ('6301', '营业外收入', 'INCOME', @income_root_id);

-- 损益类科目 - 支出
INSERT IGNORE INTO `fin_account` (`account_code`, `account_name`, `account_type`, `parent_id`) VALUES
    ('6401', '主营业务成本', 'EXPENSE', @expense_root_id),
    ('6402', '其他业务成本', 'EXPENSE', @expense_root_id),
    ('6403', '税金及附加', 'EXPENSE', @expense_root_id),
    ('6601', '销售费用', 'EXPENSE', @expense_root_id),
    ('6602', '管理费用', 'EXPENSE', @expense_root_id),
    ('6603', '财务费用', 'EXPENSE', @expense_root_id),
    ('6701', '资产减值损失', 'EXPENSE', @expense_root_id),
    ('6711', '营业外支出', 'EXPENSE', @expense_root_id),
    ('6801', '所得税费用', 'EXPENSE', @expense_root_id),
    ('6901', '以前年度损益调整', 'EXPENSE', @expense_root_id);

-- ==========================================
-- 5. 币种表 (fin_commodity)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_commodity` (
                                               `commodity_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '币种ID',
                                               `commodity_code` VARCHAR(10) NOT NULL COMMENT '币种代码，如CNY, USD, EUR',
    `commodity_name` VARCHAR(50) NOT NULL COMMENT '币种名称，如人民币、美元、欧元',
    `commodity_type` VARCHAR(20) DEFAULT 'CURRENCY' COMMENT '币种类型：CURRENCY(货币), STOCK(股票), MUTUAL(基金)',
    `fraction` INT DEFAULT 2 COMMENT '小数位数',
    `enabled` TINYINT DEFAULT 1 COMMENT '是否启用：0-禁用，1-启用',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`commodity_id`),
    UNIQUE KEY `uk_commodity_code` (`commodity_code`),
    KEY `idx_commodity_type` (`commodity_type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='币种表';

-- 初始化常用币种（使用 INSERT IGNORE 避免重复插入）
INSERT IGNORE INTO `fin_commodity` (`commodity_code`, `commodity_name`, `commodity_type`, `fraction`, `enabled`) VALUES
    ('CNY', '人民币', 'CURRENCY', 2, 1),
    ('USD', '美元', 'CURRENCY', 2, 1),
    ('EUR', '欧元', 'CURRENCY', 2, 1),
    ('GBP', '英镑', 'CURRENCY', 2, 1),
    ('JPY', '日元', 'CURRENCY', 0, 1);

-- ==========================================
-- 6. 业务实体表 (fin_owner)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_owner` (
                                           `owner_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '业务实体ID',
                                           `name` VARCHAR(100) NOT NULL COMMENT '实体名称',
    `code` VARCHAR(50) NULL COMMENT '实体代码/编号',
    `account_id` BIGINT NULL COMMENT '关联的往来科目ID（外键 -> fin_account.account_id）',
    `owner_type` VARCHAR(20) NOT NULL COMMENT '实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)',
    `contact_name` VARCHAR(50) NULL COMMENT '联系人姓名',
    `contact_phone` VARCHAR(20) NULL COMMENT '联系电话',
    `contact_email` VARCHAR(100) NULL COMMENT '联系邮箱',
    `address` VARCHAR(500) NULL COMMENT '地址',
    `notes` TEXT NULL COMMENT '备注',
    `enabled` TINYINT DEFAULT 1 COMMENT '是否启用：0-禁用，1-启用',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`owner_id`),
    KEY `idx_account_id` (`account_id`),
    KEY `idx_owner_type` (`owner_type`),
    KEY `idx_code` (`code`),
    CONSTRAINT `fk_owner_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='业务实体表';

-- ==========================================
-- 7. 客户表 (fin_customer)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_customer` (
                                              `customer_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '客户ID',
                                              `owner_id` BIGINT NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
                                              `credit_limit` DECIMAL(18, 2) NULL COMMENT '信用额度',
    `customer_level` VARCHAR(20) NULL COMMENT '客户等级',
    `industry` VARCHAR(50) NULL COMMENT '客户行业',
    PRIMARY KEY (`customer_id`),
    UNIQUE KEY `uk_owner_id` (`owner_id`),
    CONSTRAINT `fk_customer_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='客户表';

-- ==========================================
-- 8. 供应商表 (fin_vendor)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_vendor` (
                                            `vendor_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '供应商ID',
                                            `owner_id` BIGINT NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
                                            `vendor_type` VARCHAR(20) NULL COMMENT '供应商类型',
    `vendor_level` VARCHAR(20) NULL COMMENT '供应商等级',
    `payment_terms` VARCHAR(50) NULL COMMENT '付款条件（如：30天、60天）',
    PRIMARY KEY (`vendor_id`),
    UNIQUE KEY `uk_owner_id` (`owner_id`),
    CONSTRAINT `fk_vendor_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='供应商表';

-- ==========================================
-- 9. 员工表 (fin_employee)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_employee` (
                                              `employee_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '员工ID',
                                              `owner_id` BIGINT NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
                                              `employee_no` VARCHAR(50) NULL COMMENT '员工编号',
    `department` VARCHAR(50) NULL COMMENT '部门',
    `position` VARCHAR(50) NULL COMMENT '职位',
    `hire_date` DATE NULL COMMENT '入职日期',
    PRIMARY KEY (`employee_id`),
    UNIQUE KEY `uk_owner_id` (`owner_id`),
    UNIQUE KEY `uk_employee_no` (`employee_no`),
    CONSTRAINT `fk_employee_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工表';

-- ==========================================
-- 10. 分录表 (fin_entry) - 参考 GnuCash Entry
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_entry` (
                                           `entry_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '分录ID',
                                           `trans_id` BIGINT NOT NULL COMMENT '关联的交易ID（外键 -> fin_transaction.trans_id）',
                                           `account_id` BIGINT NOT NULL COMMENT '关联的科目ID（外键 -> fin_account.account_id）',
                                           `debit_amount` DECIMAL(18, 2) DEFAULT 0 COMMENT '借方金额',
    `credit_amount` DECIMAL(18, 2) DEFAULT 0 COMMENT '贷方金额',
    `memo` VARCHAR(500) NULL COMMENT '分录备注/摘要',
    `owner_id` BIGINT NULL COMMENT '关联的业务实体ID（可选）',
    `owner_type` VARCHAR(20) NULL COMMENT '业务实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`entry_id`),
    KEY `idx_trans_id` (`trans_id`),
    KEY `idx_account_id` (`account_id`),
    KEY `idx_owner` (`owner_id`, `owner_type`),
    CONSTRAINT `fk_entry_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_entry_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分录表（参考 GnuCash Entry）';

-- ==========================================
-- 11. 安全地更新表结构（检查列是否存在）
-- ==========================================

-- 为 fin_account 表添加 commodity_id 字段
SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_account'
      AND COLUMN_NAME = 'commodity_id'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `fin_account` ADD COLUMN `commodity_id` BIGINT NULL COMMENT \'币种ID（外键 -> fin_commodity.commodity_id）\' AFTER `parent_id`',
    'SELECT "Column commodity_id already exists in fin_account" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为 fin_account 表添加索引和外键约束
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_account'
      AND INDEX_NAME = 'idx_commodity_id'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `fin_account` ADD KEY `idx_commodity_id` (`commodity_id`)',
    'SELECT "Index idx_commodity_id already exists in fin_account" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查外键约束是否存在
SET @fk_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_account'
      AND CONSTRAINT_TYPE = 'FOREIGN KEY'
      AND CONSTRAINT_NAME = 'fk_account_commodity'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `fin_account` ADD CONSTRAINT `fk_account_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`)',
    'SELECT "Foreign key fk_account_commodity already exists in fin_account" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为 fin_split 表添加 owner_id 字段
SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_split'
      AND COLUMN_NAME = 'owner_id'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `fin_split` ADD COLUMN `owner_id` BIGINT NULL COMMENT \'关联的业务实体ID（可选）\' AFTER `memo`',
    'SELECT "Column owner_id already exists in fin_split" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为 fin_split 表添加 owner_type 字段
SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_split'
      AND COLUMN_NAME = 'owner_type'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `fin_split` ADD COLUMN `owner_type` VARCHAR(20) NULL COMMENT \'业务实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)\' AFTER `owner_id`',
    'SELECT "Column owner_type already exists in fin_split" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为 fin_split 表添加索引
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_split'
      AND INDEX_NAME = 'idx_owner'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `fin_split` ADD KEY `idx_owner` (`owner_id`, `owner_type`)',
    'SELECT "Index idx_owner already exists in fin_split" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================
-- 12. 商业单据相关表
-- ==========================================

-- 发票表
CREATE TABLE IF NOT EXISTS `fin_invoice` (
                                             `invoice_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '发票ID',
                                             `invoice_no` VARCHAR(50) NOT NULL COMMENT '发票编号',
    `invoice_date` DATE NOT NULL COMMENT '发票日期',
    `due_date` DATE NULL COMMENT '到期日期',
    `customer_id` BIGINT NOT NULL COMMENT '客户ID（外键 -> fin_owner.owner_id）',
    `status` VARCHAR(20) DEFAULT 'DRAFT' COMMENT '状态：DRAFT(草稿), OPEN(开放), PAID(已支付), CANCELLED(取消)',
    `commodity_id` BIGINT NULL COMMENT '币种ID（外键 -> fin_commodity.commodity_id）',
    `total_amount` DECIMAL(18, 2) NOT NULL COMMENT '发票金额（含税）',
    `tax_amount` DECIMAL(18, 2) DEFAULT 0 COMMENT '税额',
    `net_amount` DECIMAL(18, 2) NOT NULL COMMENT '不含税金额',
    `notes` TEXT NULL COMMENT '备注',
    `posted` TINYINT DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
    `trans_id` BIGINT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`invoice_id`),
    UNIQUE KEY `uk_invoice_no` (`invoice_no`),
    KEY `idx_customer_id` (`customer_id`),
    KEY `idx_invoice_date` (`invoice_date`),
    KEY `idx_status` (`status`),
    KEY `idx_trans_id` (`trans_id`),
    CONSTRAINT `fk_invoice_customer` FOREIGN KEY (`customer_id`) REFERENCES `fin_owner` (`owner_id`),
    CONSTRAINT `fk_invoice_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`),
    CONSTRAINT `fk_invoice_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发票表';

-- 发票条目表
CREATE TABLE IF NOT EXISTS `fin_invoice_item` (
                                                  `item_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '条目ID',
                                                  `invoice_id` BIGINT NOT NULL COMMENT '发票ID（外键 -> fin_invoice.invoice_id）',
                                                  `description` VARCHAR(500) NOT NULL COMMENT '项目描述',
    `income_account_id` BIGINT NOT NULL COMMENT '收入科目ID（外键 -> fin_account.account_id）',
    `quantity` DECIMAL(18, 6) DEFAULT 1 COMMENT '数量',
    `unit_price` DECIMAL(18, 6) NOT NULL COMMENT '单价',
    `amount` DECIMAL(18, 2) NOT NULL COMMENT '金额',
    `tax_rate` DECIMAL(5, 2) DEFAULT 0 COMMENT '税率（百分比）',
    `tax_amount` DECIMAL(18, 2) DEFAULT 0 COMMENT '税额',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`item_id`),
    KEY `idx_invoice_id` (`invoice_id`),
    KEY `idx_income_account_id` (`income_account_id`),
    CONSTRAINT `fk_invoice_item_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `fin_invoice` (`invoice_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_invoice_item_account` FOREIGN KEY (`income_account_id`) REFERENCES `fin_account` (`account_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发票条目表';

-- 账单表
CREATE TABLE IF NOT EXISTS `fin_bill` (
                                          `bill_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '账单ID',
                                          `bill_no` VARCHAR(50) NOT NULL COMMENT '账单编号',
    `bill_date` DATE NOT NULL COMMENT '账单日期',
    `due_date` DATE NULL COMMENT '到期日期',
    `vendor_id` BIGINT NOT NULL COMMENT '供应商ID（外键 -> fin_owner.owner_id）',
    `status` VARCHAR(20) DEFAULT 'DRAFT' COMMENT '状态：DRAFT(草稿), OPEN(开放), PAID(已支付), CANCELLED(取消)',
    `commodity_id` BIGINT NULL COMMENT '币种ID（外键 -> fin_commodity.commodity_id）',
    `total_amount` DECIMAL(18, 2) NOT NULL COMMENT '账单金额（含税）',
    `tax_amount` DECIMAL(18, 2) DEFAULT 0 COMMENT '税额',
    `net_amount` DECIMAL(18, 2) NOT NULL COMMENT '不含税金额',
    `notes` TEXT NULL COMMENT '备注',
    `posted` TINYINT DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
    `trans_id` BIGINT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`bill_id`),
    UNIQUE KEY `uk_bill_no` (`bill_no`),
    KEY `idx_vendor_id` (`vendor_id`),
    KEY `idx_bill_date` (`bill_date`),
    KEY `idx_status` (`status`),
    KEY `idx_trans_id` (`trans_id`),
    CONSTRAINT `fk_bill_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `fin_owner` (`owner_id`),
    CONSTRAINT `fk_bill_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`),
    CONSTRAINT `fk_bill_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账单表';

-- 账单条目表
CREATE TABLE IF NOT EXISTS `fin_bill_item` (
                                               `item_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '条目ID',
                                               `bill_id` BIGINT NOT NULL COMMENT '账单ID（外键 -> fin_bill.bill_id）',
                                               `description` VARCHAR(500) NOT NULL COMMENT '项目描述',
    `expense_account_id` BIGINT NOT NULL COMMENT '费用/资产科目ID（外键 -> fin_account.account_id）',
    `quantity` DECIMAL(18, 6) DEFAULT 1 COMMENT '数量',
    `unit_price` DECIMAL(18, 6) NOT NULL COMMENT '单价',
    `amount` DECIMAL(18, 2) NOT NULL COMMENT '金额',
    `tax_rate` DECIMAL(5, 2) DEFAULT 0 COMMENT '税率（百分比）',
    `tax_amount` DECIMAL(18, 2) DEFAULT 0 COMMENT '税额',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`item_id`),
    KEY `idx_bill_id` (`bill_id`),
    KEY `idx_expense_account_id` (`expense_account_id`),
    CONSTRAINT `fk_bill_item_bill` FOREIGN KEY (`bill_id`) REFERENCES `fin_bill` (`bill_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bill_item_account` FOREIGN KEY (`expense_account_id`) REFERENCES `fin_account` (`account_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账单条目表';

-- 冲销单据表
CREATE TABLE IF NOT EXISTS `fin_credit_note` (
                                                 `credit_note_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '冲销单据ID',
                                                 `credit_note_no` VARCHAR(50) NOT NULL COMMENT '冲销单据编号',
    `credit_note_date` DATE NOT NULL COMMENT '冲销单据日期',
    `original_doc_type` VARCHAR(20) NOT NULL COMMENT '原单据类型：INVOICE(发票), BILL(账单)',
    `original_doc_id` BIGINT NOT NULL COMMENT '原单据ID',
    `owner_id` BIGINT NOT NULL COMMENT '业务实体ID（客户或供应商）',
    `amount` DECIMAL(18, 2) NOT NULL COMMENT '冲销金额',
    `reason` VARCHAR(500) NULL COMMENT '原因',
    `notes` TEXT NULL COMMENT '备注',
    `posted` TINYINT DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
    `trans_id` BIGINT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`credit_note_id`),
    UNIQUE KEY `uk_credit_note_no` (`credit_note_no`),
    KEY `idx_original_doc` (`original_doc_type`, `original_doc_id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_credit_note_date` (`credit_note_date`),
    KEY `idx_trans_id` (`trans_id`),
    CONSTRAINT `fk_credit_note_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='冲销单据表';

-- ==========================================
-- 更新 fin_invoice 表，添加邮寄追踪字段
-- ==========================================
SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_invoice'
      AND COLUMN_NAME = 'shipping_status'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `fin_invoice` ADD COLUMN `shipping_status` VARCHAR(20) DEFAULT ''NOT_SENT'' COMMENT ''邮寄状态：NOT_SENT(未邮寄), SENT(已邮寄), DELIVERED(已送达)'' AFTER `trans_id`',
    'SELECT "Column shipping_status already exists in fin_invoice" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'fin_invoice'
      AND COLUMN_NAME = 'tracking_no'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `fin_invoice` ADD COLUMN `tracking_no` VARCHAR(100) NULL COMMENT ''快递单号/追踪号'' AFTER `shipping_status`',
    'SELECT "Column tracking_no already exists in fin_invoice" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================
-- 20. 员工报销单表 (fin_expense_claim)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_expense_claim` (
                                                   `claim_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '报销单ID',
                                                   `claim_no` VARCHAR(50) NOT NULL COMMENT '报销单编号',
    `claim_date` DATE NOT NULL COMMENT '报销日期',
    `employee_id` BIGINT NOT NULL COMMENT '员工ID（外键 -> fin_owner.owner_id）',
    `total_amount` DECIMAL(18, 2) NOT NULL COMMENT '报销总金额',
    `approval_status` VARCHAR(20) DEFAULT 'PENDING' COMMENT '审批状态：PENDING(待审批), APPROVED(已审批), REJECTED(已拒绝), POSTED(已过账)',
    `approver_id` BIGINT NULL COMMENT '审批人ID',
    `approval_date` DATE NULL COMMENT '审批时间',
    `approval_comment` VARCHAR(500) NULL COMMENT '审批意见',
    `notes` TEXT NULL COMMENT '备注',
    `posted` TINYINT DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
    `trans_id` BIGINT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`claim_id`),
    UNIQUE KEY `uk_claim_no` (`claim_no`),
    KEY `idx_employee_id` (`employee_id`),
    KEY `idx_approval_status` (`approval_status`),
    KEY `idx_claim_date` (`claim_date`),
    KEY `idx_trans_id` (`trans_id`),
    CONSTRAINT `fk_expense_claim_employee` FOREIGN KEY (`employee_id`) REFERENCES `fin_owner` (`owner_id`),
    CONSTRAINT `fk_expense_claim_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工报销单表';

-- ==========================================
-- 21. 员工报销明细表 (fin_expense_claim_item)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_expense_claim_item` (
                                                        `item_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
                                                        `claim_id` BIGINT NOT NULL COMMENT '报销单ID（外键 -> fin_expense_claim.claim_id）',
                                                        `description` VARCHAR(500) NOT NULL COMMENT '费用描述',
    `expense_account_id` BIGINT NOT NULL COMMENT '费用科目ID（外键 -> fin_account.account_id）',
    `amount` DECIMAL(18, 2) NOT NULL COMMENT '金额',
    `attachment` VARCHAR(500) NULL COMMENT '发票/单据附件',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`item_id`),
    KEY `idx_claim_id` (`claim_id`),
    KEY `idx_expense_account_id` (`expense_account_id`),
    CONSTRAINT `fk_expense_claim_item_claim` FOREIGN KEY (`claim_id`) REFERENCES `fin_expense_claim` (`claim_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expense_claim_item_account` FOREIGN KEY (`expense_account_id`) REFERENCES `fin_account` (`account_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='员工报销明细表';

-- ==========================================
-- 18. 支付表 (fin_payment)
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_payment` (
                                             `payment_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '支付ID',
                                             `payment_no` VARCHAR(50) NOT NULL COMMENT '支付编号',
    `payment_date` DATE NOT NULL COMMENT '支付日期',
    `payment_type` VARCHAR(20) NOT NULL COMMENT '支付类型：RECEIPT(收款), PAYMENT(付款)',
    `owner_id` BIGINT NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
    `account_id` BIGINT NOT NULL COMMENT '支付账户ID（外键 -> fin_account.account_id）',
    `commodity_id` BIGINT NULL COMMENT '币种ID（外键 -> fin_commodity.commodity_id）',
    `amount` DECIMAL(18, 2) NOT NULL COMMENT '支付金额',
    `memo` VARCHAR(500) NULL COMMENT '备注',
    `status` VARCHAR(20) DEFAULT 'CLEARED' COMMENT '状态：CLEARED(已清算), RECONCILED(已对账), VOID(作废)',
    `posted` TINYINT DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
    `trans_id` BIGINT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`payment_id`),
    UNIQUE KEY `uk_payment_no` (`payment_no`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_account_id` (`account_id`),
    KEY `idx_payment_date` (`payment_date`),
    KEY `idx_payment_type` (`payment_type`),
    KEY `idx_trans_id` (`trans_id`),
    CONSTRAINT `fk_payment_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`),
    CONSTRAINT `fk_payment_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`),
    CONSTRAINT `fk_payment_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`),
    CONSTRAINT `fk_payment_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付表';

-- ==========================================
-- 19. 支付分配表 (fin_payment_allocation) - Lot Tracking
-- ==========================================
CREATE TABLE IF NOT EXISTS `fin_payment_allocation` (
                                                        `allocation_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '分配ID',
                                                        `payment_id` BIGINT NOT NULL COMMENT '支付ID（外键 -> fin_payment.payment_id）',
                                                        `document_type` VARCHAR(20) NOT NULL COMMENT '单据类型：INVOICE(发票), BILL(账单)',
    `document_id` BIGINT NOT NULL COMMENT '单据ID',
    `amount` DECIMAL(18, 2) NOT NULL COMMENT '分配金额',
    `previous_unpaid_amount` DECIMAL(18, 2) NOT NULL COMMENT '分配前未结清金额',
    `remaining_unpaid_amount` DECIMAL(18, 2) NOT NULL COMMENT '分配后未结清金额',
    `allocation_status` VARCHAR(20) NOT NULL COMMENT '分配状态：PARTIAL(部分), FULL(全额)',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL COMMENT '创建时间',
    `update_time` DATETIME NULL COMMENT '更新时间',
    `is_deleted` INT DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`allocation_id`),
    KEY `idx_payment_id` (`payment_id`),
    KEY `idx_document` (`document_type`, `document_id`),
    CONSTRAINT `fk_allocation_payment` FOREIGN KEY (`payment_id`) REFERENCES `fin_payment` (`payment_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付分配表（Lot Tracking）';
