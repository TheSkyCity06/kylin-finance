-- ==========================================
-- 资金管理-报销单模块数据库表结构
-- 创建时间: 2024
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 1. 报销单主表 (biz_expense_claim)
-- ==========================================
CREATE TABLE IF NOT EXISTS `biz_expense_claim` (
    `claim_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '报销单ID（主键）',
    `claim_no` VARCHAR(50) NOT NULL COMMENT '报销单号，如EXP20241201001',
    `applicant_id` BIGINT NOT NULL COMMENT '申请人ID（外键 -> fin_owner.owner_id，关联员工）',
    `claim_date` DATE NOT NULL COMMENT '报销日期',
    `total_amount` DECIMAL(18, 2) NOT NULL DEFAULT 0.00 COMMENT '报销总金额',
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT '状态：DRAFT(草稿), POSTED(已过账), REVERSED(已冲销)',
    `credit_account_id` BIGINT NOT NULL COMMENT '贷方科目ID（付款账户，如银行存款，外键 -> fin_account.account_id）',
    `notes` TEXT NULL COMMENT '备注说明',
    `voucher_id` BIGINT NULL COMMENT '关联的凭证ID（过账后生成，外键 -> fin_transaction.trans_id）',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` INT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`claim_id`),
    UNIQUE KEY `uk_claim_no` (`claim_no`),
    KEY `idx_applicant_id` (`applicant_id`),
    KEY `idx_claim_date` (`claim_date`),
    KEY `idx_status` (`status`),
    KEY `idx_credit_account_id` (`credit_account_id`),
    KEY `idx_voucher_id` (`voucher_id`),
    KEY `idx_create_time` (`create_time`),
    CONSTRAINT `fk_expense_claim_applicant` FOREIGN KEY (`applicant_id`) REFERENCES `fin_owner` (`owner_id`),
    CONSTRAINT `fk_expense_claim_credit_account` FOREIGN KEY (`credit_account_id`) REFERENCES `fin_account` (`account_id`),
    CONSTRAINT `fk_expense_claim_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `fin_transaction` (`trans_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报销单主表';

-- ==========================================
-- 2. 报销明细表 (biz_expense_claim_detail)
-- ==========================================
CREATE TABLE IF NOT EXISTS `biz_expense_claim_detail` (
    `detail_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '报销明细ID（主键）',
    `claim_id` BIGINT NOT NULL COMMENT '报销单ID（外键 -> biz_expense_claim.claim_id）',
    `debit_account_id` BIGINT NOT NULL COMMENT '借方科目ID（费用科目，如差旅费，外键 -> fin_account.account_id）',
    `amount` DECIMAL(18, 2) NOT NULL DEFAULT 0.00 COMMENT '金额',
    `description` VARCHAR(500) NULL COMMENT '摘要说明',
    `id` BIGINT NULL COMMENT '主键ID（BaseEntity）',
    `create_time` DATETIME NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` INT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`detail_id`),
    KEY `idx_claim_id` (`claim_id`),
    KEY `idx_debit_account_id` (`debit_account_id`),
    KEY `idx_create_time` (`create_time`),
    CONSTRAINT `fk_expense_claim_detail_claim` FOREIGN KEY (`claim_id`) REFERENCES `biz_expense_claim` (`claim_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expense_claim_detail_debit_account` FOREIGN KEY (`debit_account_id`) REFERENCES `fin_account` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报销明细表';

-- ==========================================
-- 表结构说明
-- ==========================================
-- 
-- 【报销单主表 (biz_expense_claim)】
-- - claim_id: 主键，自增ID
-- - claim_no: 报销单号，唯一索引，用于业务查询和展示
-- - applicant_id: 申请人ID，关联员工表（fin_owner）
-- - claim_date: 报销日期，用于按日期查询和统计
-- - total_amount: 报销总金额，应与明细表金额总和一致
-- - status: 状态枚举值：
--   * DRAFT: 草稿状态，可以修改和删除
--   * POSTED: 已过账状态，已生成凭证，不能修改
--   * REVERSED: 已冲销状态，已生成冲销凭证
-- - credit_account_id: 贷方科目ID（付款账户），如银行存款（1002）
-- - notes: 备注信息，支持长文本
-- - voucher_id: 关联的凭证ID，过账后自动生成凭证并关联
-- - create_time/update_time: 审计字段，自动维护
-- - is_deleted: 逻辑删除标记，0-正常，1-已删除
--
-- 【报销明细表 (biz_expense_claim_detail)】
-- - detail_id: 主键，自增ID
-- - claim_id: 关联报销单主表，级联删除
-- - debit_account_id: 借方科目ID（费用科目），如差旅费、办公费等
-- - amount: 明细金额，所有明细金额总和应等于主表total_amount
-- - description: 摘要说明，描述该笔费用的具体内容
-- - create_time/update_time: 审计字段，自动维护
-- - is_deleted: 逻辑删除标记，0-正常，1-已删除
--
-- 【会计处理逻辑】
-- 当报销单过账（status=POSTED）时，系统应自动生成凭证：
-- - 借方：各明细行的借方科目（费用科目）
-- - 贷方：主表的贷方科目（付款账户，如银行存款）
-- - 借贷金额必须平衡
--
-- 【索引设计说明】
-- 1. 主键索引：claim_id, detail_id
-- 2. 唯一索引：claim_no（报销单号唯一）
-- 3. 普通索引：
--    - applicant_id: 按申请人查询
--    - claim_date: 按日期范围查询
--    - status: 按状态筛选
--    - credit_account_id/debit_account_id: 按科目查询
--    - voucher_id: 关联凭证查询
--    - create_time: 按创建时间排序
--
-- 【外键约束说明】
-- 1. applicant_id -> fin_owner.owner_id: 确保申请人存在
-- 2. credit_account_id -> fin_account.account_id: 确保付款账户科目存在
-- 3. debit_account_id -> fin_account.account_id: 确保费用科目存在
-- 4. voucher_id -> fin_transaction.trans_id: 确保关联的凭证存在
-- 5. claim_id -> biz_expense_claim.claim_id: 明细表关联主表，级联删除

