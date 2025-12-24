-- ==========================================
-- 资金管理-收付款单模块数据库表结构
-- 创建时间: 2024
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 收付款单表 (biz_receipt_payment)
-- ==========================================
CREATE TABLE IF NOT EXISTS `biz_receipt_payment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '收付款单ID（主键）',
    `code` VARCHAR(50) NOT NULL COMMENT '单据编号，如RP20241201001（Receipt Payment）',
    `type` VARCHAR(20) NOT NULL COMMENT '类型：RECEIPT(收款), PAYMENT(付款)',
    `partner_name` VARCHAR(200) NOT NULL COMMENT '往来单位名称（客户/供应商名称）',
    `owner_id` BIGINT NOT NULL COMMENT '往来单位ID（外键 -> fin_owner.owner_id）',
    `account_id` BIGINT NOT NULL COMMENT '结算账户ID（外键 -> fin_account.account_id，如现金、银行存款）',
    `amount` DECIMAL(18, 2) NOT NULL DEFAULT 0.00 COMMENT '金额',
    `date` DATE NOT NULL COMMENT '收付款日期',
    `remark` VARCHAR(500) NULL COMMENT '摘要说明',
    `status` INT NOT NULL DEFAULT 0 COMMENT '状态：0=草稿(DRAFT), 1=已过账(POSTED)',
    `voucher_id` BIGINT NULL COMMENT '关联的凭证ID（过账后生成，外键 -> fin_transaction.trans_id）',
    `create_by` VARCHAR(50) NULL COMMENT '创建人',
    `create_time` DATETIME NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_by` VARCHAR(50) NULL COMMENT '更新人',
    `update_time` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` INT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_code` (`code`),
    KEY `idx_type` (`type`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_account_id` (`account_id`),
    KEY `idx_date` (`date`),
    KEY `idx_status` (`status`),
    KEY `idx_voucher_id` (`voucher_id`),
    KEY `idx_create_time` (`create_time`),
    KEY `idx_create_by` (`create_by`),
    CONSTRAINT `fk_receipt_payment_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`),
    CONSTRAINT `fk_receipt_payment_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`),
    CONSTRAINT `fk_receipt_payment_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `fin_transaction` (`trans_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收付款单表';

-- ==========================================
-- 表结构说明
-- ==========================================
-- 
-- 【收付款单表 (biz_receipt_payment)】
-- 
-- 【业务字段说明】
-- - id: 主键，自增ID
-- - code: 单据编号，唯一索引，格式：RP + yyyyMMdd + 序号（如RP20241201001）
-- - type: 类型枚举值：
--   * RECEIPT: 收款单（客户付款）
--   * PAYMENT: 付款单（向供应商付款）
-- - partner_name: 往来单位名称，冗余字段，便于查询和展示
-- - owner_id: 往来单位ID，关联 fin_owner 表（客户或供应商）
-- - account_id: 结算账户ID，关联 fin_account 表（如库存现金1001、银行存款1002等资产类科目）
-- - amount: 收付款金额，必须大于0
-- - date: 收付款日期，用于按日期查询和统计
-- - remark: 摘要说明，描述收付款的具体业务内容
-- - status: 状态枚举值：
--   * 0 (DRAFT): 草稿状态，可以修改和删除
--   * 1 (POSTED): 已过账状态，已生成凭证，不能修改
-- - voucher_id: 关联的凭证ID，过账后自动生成凭证并关联
-- 
-- 【审计字段说明】
-- - create_by: 创建人（用户名或用户ID），记录单据创建者
-- - create_time: 创建时间，自动设置为当前时间戳
-- - update_by: 更新人（用户名或用户ID），记录最后修改者
-- - update_time: 更新时间，自动更新为当前时间戳
-- - is_deleted: 逻辑删除标记，0-正常，1-已删除
-- 
-- 【会计处理逻辑】
-- 当收付款单过账（status=1）时，系统应自动生成凭证：
-- - 收款单（RECEIPT）:
--   * 借方：结算账户（资产增加）
--   * 贷方：应收账款或其他对应科目（需要根据业务规则确定）
-- - 付款单（PAYMENT）:
--   * 借方：应付账款或其他对应科目（需要根据业务规则确定）
--   * 贷方：结算账户（资产减少）
-- - 借贷金额必须平衡
-- 
-- 【索引设计说明】
-- 1. 主键索引：id
-- 2. 唯一索引：code（单据编号唯一）
-- 3. 普通索引：
--    - type: 按类型筛选（收款/付款）
--    - owner_id: 按往来单位查询
--    - account_id: 按结算账户查询
--    - date: 按日期范围查询
--    - status: 按状态筛选
--    - voucher_id: 关联凭证查询
--    - create_time: 按创建时间排序
--    - create_by: 按创建人查询
-- 
-- 【外键约束说明】
-- 1. owner_id -> fin_owner.owner_id: 确保往来单位存在
-- 2. account_id -> fin_account.account_id: 确保结算账户科目存在
-- 3. voucher_id -> fin_transaction.trans_id: 确保关联的凭证存在（可为空）
-- 
-- 【数据完整性约束】
-- 1. code 必须唯一，不能重复
-- 2. amount 必须大于0
-- 3. type 只能是 'RECEIPT' 或 'PAYMENT'
-- 4. status 只能是 0 或 1
-- 5. date 不能为空
-- 
-- 【业务规则】
-- 1. 草稿状态的单据可以修改和删除
-- 2. 已过账状态的单据不能修改和删除，只能查看
-- 3. 过账时会自动生成凭证，并更新关联的凭证ID
-- 4. 单据编号由系统自动生成，格式：RP + 日期(yyyyMMdd) + 序号(3位)


