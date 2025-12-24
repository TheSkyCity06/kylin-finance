/*
 Navicat Premium Data Transfer

 Source Server         : kylin_finance
 Source Server Type    : MySQL
 Source Server Version : 80013
 Source Host           : localhost:3306
 Source Schema         : kylin_finance

 Target Server Type    : MySQL
 Target Server Version : 80013
 File Encoding         : 65001

 Date: 24/12/2025 20:00:59
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for biz_expense_claim
-- ----------------------------
DROP TABLE IF EXISTS `biz_expense_claim`;
CREATE TABLE `biz_expense_claim`  (
  `claim_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '报销单ID（主键）',
  `claim_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '报销单号，如EXP20241201001',
  `applicant_id` bigint(20) NOT NULL COMMENT '申请人ID（外键 -> fin_owner.owner_id，关联员工）',
  `claim_date` date NOT NULL COMMENT '报销日期',
  `total_amount` decimal(18, 2) NOT NULL DEFAULT 0.00 COMMENT '报销总金额',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT' COMMENT '状态：DRAFT(草稿), POSTED(已过账), REVERSED(已冲销)',
  `credit_account_id` bigint(20) NOT NULL COMMENT '贷方科目ID（付款账户，如银行存款，外键 -> fin_account.account_id）',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL COMMENT '备注说明',
  `voucher_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的凭证ID（过账后生成，外键 -> fin_transaction.trans_id）',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` int(11) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`claim_id`) USING BTREE,
  UNIQUE INDEX `uk_claim_no`(`claim_no` ASC) USING BTREE,
  INDEX `idx_applicant_id`(`applicant_id` ASC) USING BTREE,
  INDEX `idx_claim_date`(`claim_date` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_credit_account_id`(`credit_account_id` ASC) USING BTREE,
  INDEX `idx_voucher_id`(`voucher_id` ASC) USING BTREE,
  INDEX `idx_create_time`(`create_time` ASC) USING BTREE,
  CONSTRAINT `fk_expense_claim_applicant` FOREIGN KEY (`applicant_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_expense_claim_credit_account` FOREIGN KEY (`credit_account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_expense_claim_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '报销单主表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of biz_expense_claim
-- ----------------------------
INSERT INTO `biz_expense_claim` VALUES (1, 'EXP20251224001', 1, '2025-12-24', 1000.00, 'DRAFT', 1, '', NULL, NULL, NULL, NULL, 0);
INSERT INTO `biz_expense_claim` VALUES (2, 'EXP20251224002', 1, '2025-12-24', 1000.00, 'POSTED', 1, '', 6, NULL, NULL, NULL, 0);

-- ----------------------------
-- Table structure for biz_expense_claim_detail
-- ----------------------------
DROP TABLE IF EXISTS `biz_expense_claim_detail`;
CREATE TABLE `biz_expense_claim_detail`  (
  `detail_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '报销明细ID（主键）',
  `claim_id` bigint(20) NOT NULL COMMENT '报销单ID（外键 -> biz_expense_claim.claim_id）',
  `debit_account_id` bigint(20) NOT NULL COMMENT '借方科目ID（费用科目，如差旅费，外键 -> fin_account.account_id）',
  `amount` decimal(18, 2) NOT NULL DEFAULT 0.00 COMMENT '金额',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '摘要说明',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` int(11) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`detail_id`) USING BTREE,
  INDEX `idx_claim_id`(`claim_id` ASC) USING BTREE,
  INDEX `idx_debit_account_id`(`debit_account_id` ASC) USING BTREE,
  INDEX `idx_create_time`(`create_time` ASC) USING BTREE,
  CONSTRAINT `fk_expense_claim_detail_claim` FOREIGN KEY (`claim_id`) REFERENCES `biz_expense_claim` (`claim_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_expense_claim_detail_debit_account` FOREIGN KEY (`debit_account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '报销明细表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of biz_expense_claim_detail
-- ----------------------------
INSERT INTO `biz_expense_claim_detail` VALUES (1, 1, 60, 1000.00, '', NULL, NULL, '2025-12-24 15:04:03', 1);
INSERT INTO `biz_expense_claim_detail` VALUES (2, 1, 60, 1000.00, '', NULL, NULL, NULL, 0);
INSERT INTO `biz_expense_claim_detail` VALUES (3, 2, 60, 1000.00, '', NULL, NULL, NULL, 0);

-- ----------------------------
-- Table structure for biz_receipt_payment
-- ----------------------------
DROP TABLE IF EXISTS `biz_receipt_payment`;
CREATE TABLE `biz_receipt_payment`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '收付款单ID（主键）',
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '单据编号，如RP20241201001（Receipt Payment）',
  `type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '类型：RECEIPT(收款), PAYMENT(付款)',
  `partner_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '往来单位名称（客户/供应商名称）',
  `owner_id` bigint(20) NOT NULL COMMENT '往来单位ID（外键 -> fin_owner.owner_id）',
  `account_id` bigint(20) NOT NULL COMMENT '结算账户ID（外键 -> fin_account.account_id，如现金、银行存款）',
  `amount` decimal(18, 2) NOT NULL DEFAULT 0.00 COMMENT '金额',
  `date` date NOT NULL COMMENT '收付款日期',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '摘要说明',
  `status` int(11) NOT NULL DEFAULT 0 COMMENT '状态：0=草稿(DRAFT), 1=已过账(POSTED)',
  `voucher_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的凭证ID（过账后生成，外键 -> fin_transaction.trans_id）',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '创建人',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` int(11) NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_code`(`code` ASC) USING BTREE,
  INDEX `idx_type`(`type` ASC) USING BTREE,
  INDEX `idx_owner_id`(`owner_id` ASC) USING BTREE,
  INDEX `idx_account_id`(`account_id` ASC) USING BTREE,
  INDEX `idx_date`(`date` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_voucher_id`(`voucher_id` ASC) USING BTREE,
  INDEX `idx_create_time`(`create_time` ASC) USING BTREE,
  INDEX `idx_create_by`(`create_by` ASC) USING BTREE,
  CONSTRAINT `fk_receipt_payment_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_receipt_payment_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_receipt_payment_voucher` FOREIGN KEY (`voucher_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '收付款单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of biz_receipt_payment
-- ----------------------------
INSERT INTO `biz_receipt_payment` VALUES (1, 'RP20251224001', 'RECEIPT', '中南大学商学院', 2, 1, 10000.00, '2025-12-24', '', 0, NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `biz_receipt_payment` VALUES (2, 'RP20251224002', 'RECEIPT', '11', 3, 1, 11000.00, '2025-12-24', '', 0, NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `biz_receipt_payment` VALUES (3, 'RP20241105001', 'RECEIPT', '深圳华强电子股份有限公司', 7, 2, 28500.00, '2024-11-05', '收到深圳华强电子股份有限公司货款', 1, 47, NULL, '2024-11-05 10:30:00', NULL, '2025-12-24 17:16:39', 0);
INSERT INTO `biz_receipt_payment` VALUES (4, 'RP20241120002', 'RECEIPT', '广州美达贸易行', 8, 1, 15200.00, '2024-11-20', '收到广州美达贸易行货款', 1, 48, NULL, '2024-11-20 14:15:00', NULL, '2025-12-24 17:16:39', 0);
INSERT INTO `biz_receipt_payment` VALUES (5, 'RP20241128003', 'RECEIPT', '杭州西湖软件科技有限公司', 9, 2, 36800.00, '2024-11-28', '收到杭州西湖软件科技有限公司货款', 1, 49, NULL, '2024-11-28 16:45:00', NULL, '2025-12-24 17:16:39', 0);
INSERT INTO `biz_receipt_payment` VALUES (8, 'RP20241020001', 'PAYMENT', '北京办公用品供应中心', 15, 2, 12500.00, '2024-10-20', '支付北京办公用品供应中心货款 - 银行转账', 1, 52, NULL, '2024-10-20 10:00:00', NULL, '2025-12-24 17:16:39', 0);
INSERT INTO `biz_receipt_payment` VALUES (9, 'RP20241101002', 'PAYMENT', '深圳电子元器件批发市场', 16, 2, 18500.00, '2024-11-01', '支付深圳电子元器件批发市场货款 - 银行转账', 1, 53, NULL, '2024-11-01 14:30:00', NULL, '2025-12-24 17:16:39', 0);
INSERT INTO `biz_receipt_payment` VALUES (10, 'RP20241105003', 'PAYMENT', '上海化工原料有限公司', 17, 1, 8500.00, '2024-11-05', '支付上海化工原料有限公司货款 - 现金', 1, 54, NULL, '2024-11-05 16:00:00', NULL, '2025-12-24 17:16:39', 0);

-- ----------------------------
-- Table structure for fin_account
-- ----------------------------
DROP TABLE IF EXISTS `fin_account`;
CREATE TABLE `fin_account`  (
  `account_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '科目ID',
  `account_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '科目代码，如1001',
  `account_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '科目名称，如库存现金',
  `account_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '科目类型：ASSET(资产), LIABILITY(负债), EQUITY(权益), INCOME(收入), EXPENSE(支出)',
  `parent_id` bigint(20) NULL DEFAULT NULL COMMENT '父科目ID，构建树形结构',
  `commodity_id` bigint(20) NULL DEFAULT NULL COMMENT '币种ID（外键 -> fin_commodity.commodity_id）',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`account_id`) USING BTREE,
  UNIQUE INDEX `uk_account_code`(`account_code` ASC) USING BTREE,
  INDEX `idx_parent_id`(`parent_id` ASC) USING BTREE,
  INDEX `idx_account_type`(`account_type` ASC) USING BTREE,
  INDEX `idx_commodity_id`(`commodity_id` ASC) USING BTREE,
  CONSTRAINT `fk_account_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 296 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '会计科目表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_account
-- ----------------------------
INSERT INTO `fin_account` VALUES (1, '1001', '库存现金', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (2, '1002', '银行存款', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (3, '1012', '其他货币资金', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (4, '1101', '交易性金融资产', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (5, '1121', '应收票据', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (6, '1122', '应收账款', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (7, '1123', '预付账款', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (8, '1131', '应收股利', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (9, '1132', '应收利息', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (10, '1221', '其他应收款', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (11, '1231', '坏账准备', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (12, '1401', '材料采购', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (13, '1403', '原材料', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (14, '1405', '库存商品', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (15, '1411', '周转材料', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (16, '1471', '存货跌价准备', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (17, '1501', '持有至到期投资', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (18, '1502', '持有至到期投资减值准备', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (19, '1503', '可供出售金融资产', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (20, '1511', '长期股权投资', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (21, '1512', '长期股权投资减值准备', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (22, '1521', '投资性房地产', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (23, '1531', '长期应收款', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (24, '1601', '固定资产', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (25, '1602', '累计折旧', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (26, '1603', '固定资产减值准备', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (27, '1604', '在建工程', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (28, '1605', '工程物资', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (29, '1606', '固定资产清理', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (30, '1701', '无形资产', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (31, '1702', '累计摊销', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (32, '1703', '无形资产减值准备', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (33, '1711', '商誉', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (34, '1801', '长期待摊费用', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (35, '1811', '递延所得税资产', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (36, '1901', '待处理财产损溢', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (37, '2001', '短期借款', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (38, '2101', '交易性金融负债', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (39, '2201', '应付票据', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (40, '2202', '应付账款', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (41, '2203', '预收账款', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (42, '2211', '应付职工薪酬', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (43, '2221', '应交税费', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (44, '2231', '应付利息', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (45, '2232', '应付股利', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (46, '2241', '其他应付款', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (47, '2401', '递延收益', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (48, '2501', '长期借款', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (49, '2502', '应付债券', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (50, '2701', '长期应付款', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (51, '2702', '未确认融资费用', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (52, '2711', '专项应付款', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (53, '2801', '预计负债', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (54, '2901', '递延所得税负债', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (55, '4001', '实收资本', 'EQUITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (56, '4002', '资本公积', 'EQUITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (57, '4101', '盈余公积', 'EQUITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (58, '4103', '本年利润', 'EQUITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (59, '4104', '利润分配', 'EQUITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (60, '5001', '生产成本', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (61, '5101', '制造费用', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (62, '5201', '劳务成本', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (63, '5301', '研发支出', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (64, '6001', '主营业务收入', 'INCOME', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (65, '6051', '其他业务收入', 'INCOME', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (66, '6101', '公允价值变动损益', 'INCOME', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (67, '6111', '投资收益', 'INCOME', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (68, '6301', '营业外收入', 'INCOME', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (69, '6401', '主营业务成本', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (70, '6402', '其他业务成本', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (71, '6403', '税金及附加', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (72, '6601', '销售费用', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (73, '6602', '管理费用', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (74, '6603', '财务费用', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (75, '6701', '资产减值损失', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (76, '6711', '营业外支出', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (77, '6801', '所得税费用', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (78, '6901', '以前年度损益调整', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (79, '1000', '资产', 'ASSET', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (80, '2000', '负债', 'LIABILITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (81, '3000', '所有者权益', 'EQUITY', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (82, '4000', '收入', 'INCOME', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (83, '5000', '支出', 'EXPENSE', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_account` VALUES (84, '1100', '货币资金', 'ASSET', 79, NULL, NULL, NULL, NULL, 0);

-- ----------------------------
-- Table structure for fin_bill
-- ----------------------------
DROP TABLE IF EXISTS `fin_bill`;
CREATE TABLE `fin_bill`  (
  `bill_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '账单ID',
  `bill_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '账单编号',
  `bill_date` date NOT NULL COMMENT '账单日期',
  `due_date` date NULL DEFAULT NULL COMMENT '到期日期',
  `vendor_id` bigint(20) NOT NULL COMMENT '供应商ID（外键 -> fin_owner.owner_id）',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'DRAFT' COMMENT '状态：DRAFT(草稿), OPEN(开放), PAID(已支付), CANCELLED(取消)',
  `commodity_id` bigint(20) NULL DEFAULT NULL COMMENT '币种ID（外键 -> fin_commodity.commodity_id）',
  `total_amount` decimal(18, 2) NOT NULL COMMENT '账单金额（含税）',
  `tax_amount` decimal(18, 2) NULL DEFAULT 0.00 COMMENT '税额',
  `net_amount` decimal(18, 2) NOT NULL COMMENT '不含税金额',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '备注',
  `posted` tinyint(4) NULL DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
  `trans_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`bill_id`) USING BTREE,
  UNIQUE INDEX `uk_bill_no`(`bill_no` ASC) USING BTREE,
  INDEX `idx_vendor_id`(`vendor_id` ASC) USING BTREE,
  INDEX `idx_bill_date`(`bill_date` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_trans_id`(`trans_id` ASC) USING BTREE,
  INDEX `fk_bill_commodity`(`commodity_id` ASC) USING BTREE,
  CONSTRAINT `fk_bill_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_bill_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_bill_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '账单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_bill
-- ----------------------------
INSERT INTO `fin_bill` VALUES (1, '001', '2025-12-23', NULL, 2, 'POSTED', NULL, 1110.00, 0.00, 1110.00, '', 1, 5, NULL, NULL, NULL, 0);
INSERT INTO `fin_bill` VALUES (2, '0201', '2025-12-23', NULL, 2, 'DRAFT', NULL, 50000.00, 0.00, 50000.00, '', 0, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_bill` VALUES (3, 'BILL20240915001', '2024-09-15', '2024-10-15', 15, 'OPEN', 1, 12500.00, 1625.00, 10875.00, '高性能笔记本电脑采购 - 已逾期', 1, 37, NULL, '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0);
INSERT INTO `fin_bill` VALUES (4, 'BILL20241020002', '2024-10-20', '2024-12-20', 16, 'OPEN', 1, 18500.00, 2405.00, 16095.00, '办公家具采购', 1, 38, NULL, '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0);
INSERT INTO `fin_bill` VALUES (5, 'BILL20240930003', '2024-09-30', '2024-10-30', 17, 'OPEN', 1, 8500.00, 1105.00, 7395.00, '办公室租金 - 已逾期', 1, 39, NULL, '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0);
INSERT INTO `fin_bill` VALUES (6, 'BILL20241105004', '2024-11-05', '2024-12-05', 18, 'OPEN', 1, 3200.00, 416.00, 2784.00, '电费', 1, 40, NULL, '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0);
INSERT INTO `fin_bill` VALUES (7, 'BILL20241120005', '2024-11-20', '2024-12-20', 19, 'OPEN', 1, 12500.00, 1625.00, 10875.00, 'AWS/阿里云服务器续费', 1, 41, NULL, '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0);
INSERT INTO `fin_bill` VALUES (8, 'BILL20241010006', '2024-10-10', '2024-11-10', 15, 'OPEN', 1, 28500.00, 3705.00, 24795.00, '原材料采购 - 已逾期', 1, 42, NULL, '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0);
INSERT INTO `fin_bill` VALUES (9, 'BILL20241115007', '2024-11-15', '2024-12-15', 16, 'OPEN', 1, 15200.00, 1976.00, 13224.00, '原材料采购', 1, 43, NULL, '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0);
INSERT INTO `fin_bill` VALUES (10, 'BILL20241128008', '2024-11-28', '2025-01-28', 17, 'OPEN', 1, 36800.00, 4784.00, 32016.00, '高性能笔记本电脑采购', 1, 44, NULL, '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0);
INSERT INTO `fin_bill` VALUES (11, 'BILL20241130009', '2024-11-30', '2024-12-30', 18, 'OPEN', 1, 8500.00, 1105.00, 7395.00, '办公室租金', 1, 45, NULL, '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0);
INSERT INTO `fin_bill` VALUES (12, 'BILL20241201010', '2024-12-01', '2025-01-01', 19, 'OPEN', 1, 21500.00, 2795.00, 18705.00, '原材料采购', 1, 46, NULL, '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0);

-- ----------------------------
-- Table structure for fin_bill_item
-- ----------------------------
DROP TABLE IF EXISTS `fin_bill_item`;
CREATE TABLE `fin_bill_item`  (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '条目ID',
  `bill_id` bigint(20) NOT NULL COMMENT '账单ID（外键 -> fin_bill.bill_id）',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '项目描述',
  `expense_account_id` bigint(20) NOT NULL COMMENT '费用/资产科目ID（外键 -> fin_account.account_id）',
  `quantity` decimal(18, 6) NULL DEFAULT 1.000000 COMMENT '数量',
  `unit_price` decimal(18, 6) NOT NULL COMMENT '单价',
  `amount` decimal(18, 2) NOT NULL COMMENT '金额',
  `tax_rate` decimal(5, 2) NULL DEFAULT 0.00 COMMENT '税率（百分比）',
  `tax_amount` decimal(18, 2) NULL DEFAULT 0.00 COMMENT '税额',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`item_id`) USING BTREE,
  INDEX `idx_bill_id`(`bill_id` ASC) USING BTREE,
  INDEX `idx_expense_account_id`(`expense_account_id` ASC) USING BTREE,
  CONSTRAINT `fk_bill_item_account` FOREIGN KEY (`expense_account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_bill_item_bill` FOREIGN KEY (`bill_id`) REFERENCES `fin_bill` (`bill_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '账单条目表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_bill_item
-- ----------------------------
INSERT INTO `fin_bill_item` VALUES (1, 1, '123', 12, 111.000000, 10.000000, 1110.00, 0.00, 0.00, NULL, NULL, NULL, 0);
INSERT INTO `fin_bill_item` VALUES (2, 2, '学生', 12, 1.000000, 50000.000000, 50000.00, 0.00, 0.00, NULL, NULL, NULL, 0);
INSERT INTO `fin_bill_item` VALUES (3, 3, '高性能笔记本电脑', 24, 2.000000, 5437.500000, 10875.00, 13.00, 1625.00, NULL, '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0);
INSERT INTO `fin_bill_item` VALUES (4, 4, '办公家具', 24, 1.000000, 16095.000000, 16095.00, 13.00, 2405.00, NULL, '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0);
INSERT INTO `fin_bill_item` VALUES (5, 5, '办公室租金', 73, 1.000000, 7395.000000, 7395.00, 13.00, 1105.00, NULL, '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0);
INSERT INTO `fin_bill_item` VALUES (6, 6, '电费', 73, 1.000000, 2784.000000, 2784.00, 13.00, 416.00, NULL, '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0);
INSERT INTO `fin_bill_item` VALUES (7, 7, 'AWS/阿里云服务器续费', 73, 1.000000, 10875.000000, 10875.00, 13.00, 1625.00, NULL, '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0);
INSERT INTO `fin_bill_item` VALUES (8, 8, '原材料采购', 14, 100.000000, 247.950000, 24795.00, 13.00, 3705.00, NULL, '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0);
INSERT INTO `fin_bill_item` VALUES (9, 9, '原材料采购', 14, 50.000000, 264.480000, 13224.00, 13.00, 1976.00, NULL, '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0);
INSERT INTO `fin_bill_item` VALUES (10, 10, '高性能笔记本电脑', 24, 3.000000, 10672.000000, 32016.00, 13.00, 4784.00, NULL, '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0);
INSERT INTO `fin_bill_item` VALUES (11, 11, '办公室租金', 73, 1.000000, 7395.000000, 7395.00, 13.00, 1105.00, NULL, '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0);
INSERT INTO `fin_bill_item` VALUES (12, 12, '原材料采购', 14, 75.000000, 249.400000, 18705.00, 13.00, 2795.00, NULL, '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0);

-- ----------------------------
-- Table structure for fin_commodity
-- ----------------------------
DROP TABLE IF EXISTS `fin_commodity`;
CREATE TABLE `fin_commodity`  (
  `commodity_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '币种ID',
  `commodity_code` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '币种代码，如CNY, USD, EUR',
  `commodity_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '币种名称，如人民币、美元、欧元',
  `commodity_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'CURRENCY' COMMENT '币种类型：CURRENCY(货币), STOCK(股票), MUTUAL(基金)',
  `fraction` int(11) NULL DEFAULT 2 COMMENT '小数位数',
  `enabled` tinyint(4) NULL DEFAULT 1 COMMENT '是否启用：0-禁用，1-启用',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`commodity_id`) USING BTREE,
  UNIQUE INDEX `uk_commodity_code`(`commodity_code` ASC) USING BTREE,
  INDEX `idx_commodity_type`(`commodity_type` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '币种表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_commodity
-- ----------------------------
INSERT INTO `fin_commodity` VALUES (1, 'CNY', '人民币', 'CURRENCY', 2, 1, NULL, NULL, NULL, 0);
INSERT INTO `fin_commodity` VALUES (2, 'USD', '美元', 'CURRENCY', 2, 1, NULL, NULL, NULL, 0);
INSERT INTO `fin_commodity` VALUES (3, 'EUR', '欧元', 'CURRENCY', 2, 1, NULL, NULL, NULL, 0);
INSERT INTO `fin_commodity` VALUES (4, 'GBP', '英镑', 'CURRENCY', 2, 1, NULL, NULL, NULL, 0);
INSERT INTO `fin_commodity` VALUES (5, 'JPY', '日元', 'CURRENCY', 0, 1, NULL, NULL, NULL, 0);

-- ----------------------------
-- Table structure for fin_credit_note
-- ----------------------------
DROP TABLE IF EXISTS `fin_credit_note`;
CREATE TABLE `fin_credit_note`  (
  `credit_note_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '冲销单据ID',
  `credit_note_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '冲销单据编号',
  `credit_note_date` date NOT NULL COMMENT '冲销单据日期',
  `original_doc_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '原单据类型：INVOICE(发票), BILL(账单)',
  `original_doc_id` bigint(20) NOT NULL COMMENT '原单据ID',
  `owner_id` bigint(20) NOT NULL COMMENT '业务实体ID（客户或供应商）',
  `amount` decimal(18, 2) NOT NULL COMMENT '冲销金额',
  `reason` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '原因',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '备注',
  `posted` tinyint(4) NULL DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
  `trans_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`credit_note_id`) USING BTREE,
  UNIQUE INDEX `uk_credit_note_no`(`credit_note_no` ASC) USING BTREE,
  INDEX `idx_original_doc`(`original_doc_type` ASC, `original_doc_id` ASC) USING BTREE,
  INDEX `idx_owner_id`(`owner_id` ASC) USING BTREE,
  INDEX `idx_credit_note_date`(`credit_note_date` ASC) USING BTREE,
  INDEX `idx_trans_id`(`trans_id` ASC) USING BTREE,
  CONSTRAINT `fk_credit_note_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '冲销单据表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_credit_note
-- ----------------------------

-- ----------------------------
-- Table structure for fin_customer
-- ----------------------------
DROP TABLE IF EXISTS `fin_customer`;
CREATE TABLE `fin_customer`  (
  `customer_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '客户ID',
  `owner_id` bigint(20) NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
  `credit_limit` decimal(18, 2) NULL DEFAULT NULL COMMENT '信用额度',
  `customer_level` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '客户等级',
  `industry` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '客户行业',
  PRIMARY KEY (`customer_id`) USING BTREE,
  UNIQUE INDEX `uk_owner_id`(`owner_id` ASC) USING BTREE,
  CONSTRAINT `fk_customer_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '客户表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_customer
-- ----------------------------
INSERT INTO `fin_customer` VALUES (1, 5, 500000.00, 'A', '科技服务');
INSERT INTO `fin_customer` VALUES (2, 6, 300000.00, 'B', '商贸流通');
INSERT INTO `fin_customer` VALUES (3, 7, 800000.00, 'A', '电子制造');
INSERT INTO `fin_customer` VALUES (4, 8, 200000.00, 'C', '贸易批发');
INSERT INTO `fin_customer` VALUES (5, 9, 400000.00, 'B', '软件服务');
INSERT INTO `fin_customer` VALUES (6, 10, 1000000.00, 'A', '综合实业');
INSERT INTO `fin_customer` VALUES (7, 11, 350000.00, 'B', '物流运输');
INSERT INTO `fin_customer` VALUES (8, 12, 150000.00, 'C', '文化传媒');
INSERT INTO `fin_customer` VALUES (9, 13, 600000.00, 'A', '建筑工程');
INSERT INTO `fin_customer` VALUES (10, 14, 450000.00, 'B', '新材料');

-- ----------------------------
-- Table structure for fin_employee
-- ----------------------------
DROP TABLE IF EXISTS `fin_employee`;
CREATE TABLE `fin_employee`  (
  `employee_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '员工ID',
  `owner_id` bigint(20) NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
  `employee_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '员工编号',
  `department` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '部门',
  `position` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '职位',
  `hire_date` date NULL DEFAULT NULL COMMENT '入职日期',
  PRIMARY KEY (`employee_id`) USING BTREE,
  UNIQUE INDEX `uk_owner_id`(`owner_id` ASC) USING BTREE,
  UNIQUE INDEX `uk_employee_no`(`employee_no` ASC) USING BTREE,
  CONSTRAINT `fk_employee_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '员工表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_employee
-- ----------------------------
INSERT INTO `fin_employee` VALUES (1, 20, 'E2024001', '财务部', '会计', '2023-01-15');
INSERT INTO `fin_employee` VALUES (2, 21, 'E2024002', '销售部', '销售经理', '2022-06-20');
INSERT INTO `fin_employee` VALUES (3, 22, 'E2024003', '技术部', '软件工程师', '2023-03-10');
INSERT INTO `fin_employee` VALUES (4, 23, 'E2024004', '人事部', '人事专员', '2022-09-01');
INSERT INTO `fin_employee` VALUES (5, 24, 'E2024005', '市场部', '市场专员', '2023-05-12');

-- ----------------------------
-- Table structure for fin_entry
-- ----------------------------
DROP TABLE IF EXISTS `fin_entry`;
CREATE TABLE `fin_entry`  (
  `entry_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分录ID',
  `trans_id` bigint(20) NOT NULL COMMENT '关联的交易ID（外键 -> fin_transaction.trans_id）',
  `account_id` bigint(20) NOT NULL COMMENT '关联的科目ID（外键 -> fin_account.account_id）',
  `debit_amount` decimal(18, 2) NULL DEFAULT 0.00 COMMENT '借方金额',
  `credit_amount` decimal(18, 2) NULL DEFAULT 0.00 COMMENT '贷方金额',
  `memo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分录备注/摘要',
  `owner_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的业务实体ID（可选）',
  `owner_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '业务实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`entry_id`) USING BTREE,
  INDEX `idx_trans_id`(`trans_id` ASC) USING BTREE,
  INDEX `idx_account_id`(`account_id` ASC) USING BTREE,
  INDEX `idx_owner`(`owner_id` ASC, `owner_type` ASC) USING BTREE,
  CONSTRAINT `fk_entry_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_entry_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '分录表（参考 GnuCash Entry）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_entry
-- ----------------------------

-- ----------------------------
-- Table structure for fin_expense_claim
-- ----------------------------
DROP TABLE IF EXISTS `fin_expense_claim`;
CREATE TABLE `fin_expense_claim`  (
  `claim_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '报销单ID',
  `claim_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '报销单编号',
  `claim_date` date NOT NULL COMMENT '报销日期',
  `employee_id` bigint(20) NOT NULL COMMENT '员工ID（外键 -> fin_owner.owner_id）',
  `total_amount` decimal(18, 2) NOT NULL COMMENT '报销总金额',
  `approval_status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'PENDING' COMMENT '审批状态：PENDING(待审批), APPROVED(已审批), REJECTED(已拒绝), POSTED(已过账)',
  `approver_id` bigint(20) NULL DEFAULT NULL COMMENT '审批人ID',
  `approval_date` date NULL DEFAULT NULL COMMENT '审批时间',
  `approval_comment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '审批意见',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '备注',
  `posted` tinyint(4) NULL DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
  `trans_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`claim_id`) USING BTREE,
  UNIQUE INDEX `uk_claim_no`(`claim_no` ASC) USING BTREE,
  INDEX `idx_employee_id`(`employee_id` ASC) USING BTREE,
  INDEX `idx_approval_status`(`approval_status` ASC) USING BTREE,
  INDEX `idx_claim_date`(`claim_date` ASC) USING BTREE,
  INDEX `idx_trans_id`(`trans_id` ASC) USING BTREE,
  CONSTRAINT `fk_expense_claim_employee` FOREIGN KEY (`employee_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_expense_claim_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '员工报销单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_expense_claim
-- ----------------------------
INSERT INTO `fin_expense_claim` VALUES (1, 'EXP20241012001', '2024-10-12', 21, 2850.00, 'PENDING', NULL, NULL, NULL, '差旅费报销 - 草稿状态（未提交）', 0, NULL, NULL, '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0);
INSERT INTO `fin_expense_claim` VALUES (2, 'EXP20241018002', '2024-10-18', 21, 850.00, 'PENDING', NULL, NULL, NULL, '业务招待费报销 - 草稿状态（未提交）', 0, NULL, NULL, '2024-10-18 14:30:00', '2024-10-18 14:30:00', 0);
INSERT INTO `fin_expense_claim` VALUES (3, 'EXP20241025003', '2024-10-25', 22, 3200.00, 'PENDING', NULL, NULL, NULL, '差旅费报销 - 待审核（已提交给经理）', 0, NULL, NULL, '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0);
INSERT INTO `fin_expense_claim` VALUES (4, 'EXP20241102004', '2024-11-02', 22, 2800.00, 'PENDING', NULL, NULL, NULL, '办公采购报销 - 待审核（已提交给经理）', 0, NULL, NULL, '2024-11-02 11:20:00', '2024-11-02 11:20:00', 0);
INSERT INTO `fin_expense_claim` VALUES (5, 'EXP20241108005', '2024-11-08', 23, 2450.00, 'APPROVED', 20, '2024-11-08', '已审核，待支付', '差旅费报销 - 已审核待支付', 0, 57, NULL, '2024-11-08 08:30:00', '2024-11-08 15:00:00', 0);
INSERT INTO `fin_expense_claim` VALUES (6, 'EXP20241115006', '2024-11-15', 24, 1200.00, 'APPROVED', 20, '2024-11-15', '已审核，待支付', '业务招待费报销 - 已审核待支付', 0, 58, NULL, '2024-11-15 09:45:00', '2024-11-15 16:30:00', 0);
INSERT INTO `fin_expense_claim` VALUES (7, 'EXP20241028007', '2024-10-28', 20, 580.00, 'APPROVED', 20, '2024-10-28', '已审核并支付', '办公采购报销 - 已支付', 1, 59, NULL, '2024-10-28 10:00:00', '2024-10-28 17:00:00', 0);
INSERT INTO `fin_expense_claim` VALUES (8, 'EXP20241122008', '2024-11-22', 21, 1950.00, 'APPROVED', 20, '2024-11-22', '已审核并支付', '差旅费报销 - 已支付', 1, 60, NULL, '2024-11-22 08:20:00', '2024-11-22 18:00:00', 0);

-- ----------------------------
-- Table structure for fin_expense_claim_item
-- ----------------------------
DROP TABLE IF EXISTS `fin_expense_claim_item`;
CREATE TABLE `fin_expense_claim_item`  (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '明细ID',
  `claim_id` bigint(20) NOT NULL COMMENT '报销单ID（外键 -> fin_expense_claim.claim_id）',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '费用描述',
  `expense_account_id` bigint(20) NOT NULL COMMENT '费用科目ID（外键 -> fin_account.account_id）',
  `amount` decimal(18, 2) NOT NULL COMMENT '金额',
  `attachment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '发票/单据附件',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`item_id`) USING BTREE,
  INDEX `idx_claim_id`(`claim_id` ASC) USING BTREE,
  INDEX `idx_expense_account_id`(`expense_account_id` ASC) USING BTREE,
  CONSTRAINT `fk_expense_claim_item_account` FOREIGN KEY (`expense_account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_expense_claim_item_claim` FOREIGN KEY (`claim_id`) REFERENCES `fin_expense_claim` (`claim_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '员工报销明细表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_expense_claim_item
-- ----------------------------
INSERT INTO `fin_expense_claim_item` VALUES (1, 1, '往返高铁票', 73, 1200.00, '高铁票发票.jpg', NULL, '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (2, 1, '酒店住宿费', 73, 1500.00, '酒店发票.jpg', NULL, '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (3, 1, '市内交通', 73, 150.00, '出租车发票.jpg', NULL, '2024-10-12 09:00:00', '2024-10-12 09:00:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (4, 2, '客户宴请', 73, 650.00, '餐厅发票.jpg', NULL, '2024-10-18 14:30:00', '2024-10-18 14:30:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (5, 2, '咖啡会议', 73, 200.00, '咖啡店小票.jpg', NULL, '2024-10-18 14:30:00', '2024-10-18 14:30:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (6, 3, '往返高铁票', 73, 1500.00, '高铁票发票.jpg', NULL, '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (7, 3, '酒店住宿费', 73, 1600.00, '酒店发票.jpg', NULL, '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (8, 3, '市内交通', 73, 100.00, '出租车发票.jpg', NULL, '2024-10-25 10:15:00', '2024-10-25 10:15:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (9, 4, '测试手机', 73, 2800.00, '手机发票.jpg', NULL, '2024-11-02 11:20:00', '2024-11-02 11:20:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (10, 5, '往返高铁票', 73, 1100.00, '高铁票发票.jpg', NULL, '2024-11-08 08:30:00', '2024-11-08 08:30:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (11, 5, '酒店住宿费', 73, 1200.00, '酒店发票.jpg', NULL, '2024-11-08 08:30:00', '2024-11-08 08:30:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (12, 5, '市内交通', 73, 150.00, '出租车发票.jpg', NULL, '2024-11-08 08:30:00', '2024-11-08 08:30:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (13, 6, '客户宴请', 73, 900.00, '餐厅发票.jpg', NULL, '2024-11-15 09:45:00', '2024-11-15 09:45:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (14, 6, '咖啡会议', 73, 300.00, '咖啡店小票.jpg', NULL, '2024-11-15 09:45:00', '2024-11-15 09:45:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (15, 7, '专业书籍', 73, 580.00, '书店发票.jpg', NULL, '2024-10-28 10:00:00', '2024-10-28 10:00:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (16, 8, '往返高铁票', 73, 900.00, '高铁票发票.jpg', NULL, '2024-11-22 08:20:00', '2024-11-22 08:20:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (17, 8, '酒店住宿费', 73, 950.00, '酒店发票.jpg', NULL, '2024-11-22 08:20:00', '2024-11-22 08:20:00', 0);
INSERT INTO `fin_expense_claim_item` VALUES (18, 8, '市内交通', 73, 100.00, '出租车发票.jpg', NULL, '2024-11-22 08:20:00', '2024-11-22 08:20:00', 0);

-- ----------------------------
-- Table structure for fin_invoice
-- ----------------------------
DROP TABLE IF EXISTS `fin_invoice`;
CREATE TABLE `fin_invoice`  (
  `invoice_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '发票ID',
  `invoice_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '发票编号',
  `invoice_date` date NOT NULL COMMENT '发票日期',
  `due_date` date NULL DEFAULT NULL COMMENT '到期日期',
  `customer_id` bigint(20) NOT NULL COMMENT '客户ID（外键 -> fin_owner.owner_id）',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'DRAFT' COMMENT '状态：DRAFT(草稿), OPEN(开放), PAID(已支付), CANCELLED(取消)',
  `commodity_id` bigint(20) NULL DEFAULT NULL COMMENT '币种ID（外键 -> fin_commodity.commodity_id）',
  `total_amount` decimal(18, 2) NOT NULL COMMENT '发票金额（含税）',
  `tax_amount` decimal(18, 2) NULL DEFAULT 0.00 COMMENT '税额',
  `net_amount` decimal(18, 2) NOT NULL COMMENT '不含税金额',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '备注',
  `posted` tinyint(4) NULL DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
  `trans_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
  `shipping_status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'NOT_SENT' COMMENT '邮寄状态：NOT_SENT(未邮寄), SENT(已邮寄), DELIVERED(已送达)',
  `tracking_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '快递单号/追踪号',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`invoice_id`) USING BTREE,
  UNIQUE INDEX `uk_invoice_no`(`invoice_no` ASC) USING BTREE,
  INDEX `idx_customer_id`(`customer_id` ASC) USING BTREE,
  INDEX `idx_invoice_date`(`invoice_date` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE,
  INDEX `idx_trans_id`(`trans_id` ASC) USING BTREE,
  INDEX `fk_invoice_commodity`(`commodity_id` ASC) USING BTREE,
  CONSTRAINT `fk_invoice_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_invoice_customer` FOREIGN KEY (`customer_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_invoice_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '发票表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_invoice
-- ----------------------------
INSERT INTO `fin_invoice` VALUES (1, '001', '2025-12-23', NULL, 3, 'VALIDATED', NULL, 50.00, 0.00, 50.00, '', 0, NULL, 'NOT_SENT', NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_invoice` VALUES (2, 'INV20241001001', '2024-10-05', '2024-11-04', 5, 'DRAFT', 1, 12500.00, 1625.00, 10875.00, '软件开发服务费 - 草稿', 0, NULL, 'NOT_SENT', NULL, NULL, '2024-10-05 10:00:00', '2024-10-05 10:00:00', 0);
INSERT INTO `fin_invoice` VALUES (3, 'INV20241015002', '2024-10-15', '2024-11-14', 6, 'DRAFT', 1, 8500.00, 1105.00, 7395.00, '年度维护费 - 草稿', 0, NULL, 'NOT_SENT', NULL, NULL, '2024-10-15 14:30:00', '2024-10-15 14:30:00', 0);
INSERT INTO `fin_invoice` VALUES (4, 'INV20241102003', '2024-11-02', '2024-12-02', 7, 'OPEN', 1, 28500.00, 3705.00, 24795.00, '咨询服务 - 已过账未支付', 1, 29, 'NOT_SENT', NULL, NULL, '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0);
INSERT INTO `fin_invoice` VALUES (5, 'INV20241118004', '2024-11-18', '2024-12-18', 8, 'OPEN', 1, 15200.00, 1976.00, 13224.00, '软件开发服务费 - 已过账未支付', 1, 30, 'NOT_SENT', NULL, NULL, '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0);
INSERT INTO `fin_invoice` VALUES (6, 'INV20241125005', '2024-11-25', '2024-12-25', 9, 'OPEN', 1, 36800.00, 4784.00, 32016.00, '年度维护费 - 已过账未支付', 1, 31, 'NOT_SENT', NULL, NULL, '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0);
INSERT INTO `fin_invoice` VALUES (7, 'INV20240910006', '2024-09-10', '2024-10-10', 10, 'PAID', 1, 42000.00, 5460.00, 36540.00, '咨询服务 - 已支付', 1, 32, 'NOT_SENT', NULL, NULL, '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0);
INSERT INTO `fin_invoice` VALUES (8, 'INV20240922007', '2024-09-22', '2024-10-22', 11, 'PAID', 1, 18500.00, 2405.00, 16095.00, '软件开发服务费 - 已支付', 1, 33, 'NOT_SENT', NULL, NULL, '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0);
INSERT INTO `fin_invoice` VALUES (9, 'INV20241008008', '2024-10-08', '2024-11-07', 12, 'PAID', 1, 9800.00, 1274.00, 8526.00, '年度维护费 - 已支付', 1, 34, 'NOT_SENT', NULL, NULL, '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0);
INSERT INTO `fin_invoice` VALUES (10, 'INV20241028009', '2024-10-28', '2024-11-27', 13, 'PAID', 1, 32500.00, 4225.00, 28275.00, '咨询服务 - 已支付', 1, 35, 'NOT_SENT', NULL, NULL, '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0);
INSERT INTO `fin_invoice` VALUES (11, 'INV20241112010', '2024-11-12', '2024-12-12', 14, 'PAID', 1, 21500.00, 2795.00, 18705.00, '软件开发服务费 - 已支付', 1, 36, 'NOT_SENT', NULL, NULL, '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0);

-- ----------------------------
-- Table structure for fin_invoice_item
-- ----------------------------
DROP TABLE IF EXISTS `fin_invoice_item`;
CREATE TABLE `fin_invoice_item`  (
  `item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '条目ID',
  `invoice_id` bigint(20) NOT NULL COMMENT '发票ID（外键 -> fin_invoice.invoice_id）',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '项目描述',
  `income_account_id` bigint(20) NOT NULL COMMENT '收入科目ID（外键 -> fin_account.account_id）',
  `quantity` decimal(18, 6) NULL DEFAULT 1.000000 COMMENT '数量',
  `unit_price` decimal(18, 6) NOT NULL COMMENT '单价',
  `amount` decimal(18, 2) NOT NULL COMMENT '金额',
  `tax_rate` decimal(5, 2) NULL DEFAULT 0.00 COMMENT '税率（百分比）',
  `tax_amount` decimal(18, 2) NULL DEFAULT 0.00 COMMENT '税额',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`item_id`) USING BTREE,
  INDEX `idx_invoice_id`(`invoice_id` ASC) USING BTREE,
  INDEX `idx_income_account_id`(`income_account_id` ASC) USING BTREE,
  CONSTRAINT `fk_invoice_item_account` FOREIGN KEY (`income_account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_invoice_item_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `fin_invoice` (`invoice_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '发票条目表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_invoice_item
-- ----------------------------
INSERT INTO `fin_invoice_item` VALUES (1, 1, '销售笔', 64, 10.000000, 5.000000, 50.00, 0.00, 0.00, NULL, NULL, NULL, 0);
INSERT INTO `fin_invoice_item` VALUES (2, 2, '软件开发服务费', 64, 1.000000, 10875.000000, 10875.00, 13.00, 1625.00, NULL, '2024-10-05 10:00:00', '2024-10-05 10:00:00', 0);
INSERT INTO `fin_invoice_item` VALUES (3, 3, '年度维护费', 64, 1.000000, 7395.000000, 7395.00, 13.00, 1105.00, NULL, '2024-10-15 14:30:00', '2024-10-15 14:30:00', 0);
INSERT INTO `fin_invoice_item` VALUES (4, 4, '咨询服务', 64, 1.000000, 24795.000000, 24795.00, 13.00, 3705.00, NULL, '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0);
INSERT INTO `fin_invoice_item` VALUES (5, 5, '软件开发服务费', 64, 1.000000, 13224.000000, 13224.00, 13.00, 1976.00, NULL, '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0);
INSERT INTO `fin_invoice_item` VALUES (6, 6, '年度维护费', 64, 1.000000, 32016.000000, 32016.00, 13.00, 4784.00, NULL, '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0);
INSERT INTO `fin_invoice_item` VALUES (7, 7, '咨询服务', 64, 1.000000, 36540.000000, 36540.00, 13.00, 5460.00, NULL, '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0);
INSERT INTO `fin_invoice_item` VALUES (8, 8, '软件开发服务费', 64, 1.000000, 16095.000000, 16095.00, 13.00, 2405.00, NULL, '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0);
INSERT INTO `fin_invoice_item` VALUES (9, 9, '年度维护费', 64, 1.000000, 8526.000000, 8526.00, 13.00, 1274.00, NULL, '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0);
INSERT INTO `fin_invoice_item` VALUES (10, 10, '咨询服务', 64, 1.000000, 28275.000000, 28275.00, 13.00, 4225.00, NULL, '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0);
INSERT INTO `fin_invoice_item` VALUES (11, 11, '软件开发服务费', 64, 1.000000, 18705.000000, 18705.00, 13.00, 2795.00, NULL, '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0);

-- ----------------------------
-- Table structure for fin_owner
-- ----------------------------
DROP TABLE IF EXISTS `fin_owner`;
CREATE TABLE `fin_owner`  (
  `owner_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '业务实体ID',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '实体名称',
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '实体代码/编号',
  `account_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的往来科目ID（外键 -> fin_account.account_id）',
  `owner_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)',
  `contact_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '联系人姓名',
  `contact_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '联系电话',
  `contact_email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '联系邮箱',
  `address` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '地址',
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '备注',
  `enabled` tinyint(4) NULL DEFAULT 1 COMMENT '是否启用：0-禁用，1-启用',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`owner_id`) USING BTREE,
  INDEX `idx_account_id`(`account_id` ASC) USING BTREE,
  INDEX `idx_owner_type`(`owner_type` ASC) USING BTREE,
  INDEX `idx_code`(`code` ASC) USING BTREE,
  CONSTRAINT `fk_owner_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '业务实体表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_owner
-- ----------------------------
INSERT INTO `fin_owner` VALUES (1, '1', '1', 5, 'CUSTOMER', '1', '1', '2', '2', NULL, 1, NULL, NULL, NULL, 1);
INSERT INTO `fin_owner` VALUES (2, '中南大学商学院', '1101', 40, 'VENDOR', '10', '123456', '123456', '123456', NULL, 1, NULL, NULL, NULL, 1);
INSERT INTO `fin_owner` VALUES (3, '11', '123', 6, 'CUSTOMER', '1', '2', '3', '1', NULL, 1, NULL, NULL, NULL, 1);
INSERT INTO `fin_owner` VALUES (4, '1', '1', 46, 'EMPLOYEE', NULL, '2', '3', '12', NULL, 1, NULL, NULL, NULL, 1);
INSERT INTO `fin_owner` VALUES (5, '上海智联科技有限公司', 'CUST001', 6, 'CUSTOMER', '张经理', '13800138001', 'zhang@zhilian-tech.com', '上海市浦东新区张江高科技园区科苑路399号', '主要客户，信用良好', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (6, '北京创新商贸有限公司', 'CUST002', 6, 'CUSTOMER', '李总', '13900139002', 'li@chuangxin-trade.com', '北京市朝阳区建国路88号SOHO现代城A座1205室', '长期合作客户', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (7, '深圳华强电子股份有限公司', 'CUST003', 6, 'CUSTOMER', '王主任', '13700137003', 'wang@huaqiang-elec.com', '深圳市福田区华强北路1002号华强广场A座15层', '电子产品批发商', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (8, '广州美达贸易行', 'CUST004', 6, 'CUSTOMER', '陈经理', '13600136004', 'chen@meida-trade.com', '广州市天河区天河路123号天河城广场B座8楼', '服装贸易', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (9, '杭州西湖软件科技有限公司', 'CUST005', 6, 'CUSTOMER', '刘总监', '13500135005', 'liu@xihu-soft.com', '杭州市西湖区文三路259号昌地火炬大厦2号楼10层', '软件服务商', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (10, '成都天府实业集团有限公司', 'CUST006', 6, 'CUSTOMER', '赵副总', '13400134006', 'zhao@tianfu-group.com', '成都市锦江区天府大道中段666号', '大型企业客户', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (11, '武汉长江物流有限公司', 'CUST007', 6, 'CUSTOMER', '孙经理', '13300133007', 'sun@changjiang-logistics.com', '武汉市江汉区建设大道568号新世界国贸大厦I座20层', '物流服务', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (12, '西安古都文化传媒有限公司', 'CUST008', 6, 'CUSTOMER', '周总', '13200132008', 'zhou@gudu-media.com', '西安市雁塔区高新路88号', '文化传媒', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (13, '南京金陵建筑装饰工程有限公司', 'CUST009', 6, 'CUSTOMER', '吴经理', '13100131009', 'wu@jinling-construction.com', '南京市建邺区江东中路369号新华报业传媒广场1号楼', '建筑装饰', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (14, '天津滨海新材料科技有限公司', 'CUST010', 6, 'CUSTOMER', '郑主任', '13000130010', 'zheng@binhai-newmat.com', '天津市滨海新区经济技术开发区第三大街51号', '新材料研发', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (15, '北京办公用品供应中心', 'SUPP001', 40, 'VENDOR', '马采购', '13800138111', 'ma@office-supply.com', '北京市海淀区中关村大街1号海龙大厦8层', '办公用品供应商，质量可靠', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (16, '深圳电子元器件批发市场', 'SUPP002', 40, 'VENDOR', '黄经理', '13900139112', 'huang@electronics-wholesale.com', '深圳市福田区华强北电子市场A区3楼', '电子元器件批发', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (17, '上海化工原料有限公司', 'SUPP003', 40, 'VENDOR', '徐总', '13700137113', 'xu@chemical-materials.com', '上海市嘉定区安亭镇墨玉路185号', '化工原料供应商', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (18, '顺丰速运有限公司', 'SUPP004', 40, 'VENDOR', '客服部', '400-111-1111', 'service@sf-express.com', '深圳市福田区益田路6009号新世界中心', '快递物流服务', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (19, '广州设备租赁服务有限公司', 'SUPP005', 40, 'VENDOR', '林经理', '13600136115', 'lin@equipment-lease.com', '广州市越秀区环市东路339号广东国际大厦A座', '设备租赁服务', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (20, '张三', 'EMP001', 10, 'EMPLOYEE', '张三', '13800138221', 'zhangsan@company.com', '北京市朝阳区', '财务部员工', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (21, '李四', 'EMP002', 10, 'EMPLOYEE', '李四', '13900139222', 'lisi@company.com', '上海市浦东新区', '销售部员工', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (22, '王五', 'EMP003', 10, 'EMPLOYEE', '王五', '13700137223', 'wangwu@company.com', '广州市天河区', '技术部员工', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (23, '赵六', 'EMP004', 10, 'EMPLOYEE', '赵六', '13600136224', 'zhaoliu@company.com', '深圳市南山区', '人事部员工', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);
INSERT INTO `fin_owner` VALUES (24, '钱七', 'EMP005', 10, 'EMPLOYEE', '钱七', '13500135225', 'qianqi@company.com', '杭州市西湖区', '市场部员工', 1, NULL, '2025-12-24 16:07:51', '2025-12-24 16:07:51', 0);

-- ----------------------------
-- Table structure for fin_payment
-- ----------------------------
DROP TABLE IF EXISTS `fin_payment`;
CREATE TABLE `fin_payment`  (
  `payment_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '支付ID',
  `payment_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '支付编号',
  `payment_date` date NOT NULL COMMENT '支付日期',
  `payment_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '支付类型：RECEIPT(收款), PAYMENT(付款)',
  `owner_id` bigint(20) NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
  `account_id` bigint(20) NOT NULL COMMENT '支付账户ID（外键 -> fin_account.account_id）',
  `commodity_id` bigint(20) NULL DEFAULT NULL COMMENT '币种ID（外键 -> fin_commodity.commodity_id）',
  `amount` decimal(18, 2) NOT NULL COMMENT '支付金额',
  `memo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '备注',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'CLEARED' COMMENT '状态：CLEARED(已清算), RECONCILED(已对账), VOID(作废)',
  `posted` tinyint(4) NULL DEFAULT 0 COMMENT '是否已过账：0-未过账，1-已过账',
  `trans_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的交易ID（过账后生成，外键 -> fin_transaction.trans_id）',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`payment_id`) USING BTREE,
  UNIQUE INDEX `uk_payment_no`(`payment_no` ASC) USING BTREE,
  INDEX `idx_owner_id`(`owner_id` ASC) USING BTREE,
  INDEX `idx_account_id`(`account_id` ASC) USING BTREE,
  INDEX `idx_payment_date`(`payment_date` ASC) USING BTREE,
  INDEX `idx_payment_type`(`payment_type` ASC) USING BTREE,
  INDEX `idx_trans_id`(`trans_id` ASC) USING BTREE,
  INDEX `fk_payment_commodity`(`commodity_id` ASC) USING BTREE,
  CONSTRAINT `fk_payment_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_payment_commodity` FOREIGN KEY (`commodity_id`) REFERENCES `fin_commodity` (`commodity_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_payment_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_payment_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '支付表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_payment
-- ----------------------------

-- ----------------------------
-- Table structure for fin_payment_allocation
-- ----------------------------
DROP TABLE IF EXISTS `fin_payment_allocation`;
CREATE TABLE `fin_payment_allocation`  (
  `allocation_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分配ID',
  `payment_id` bigint(20) NOT NULL COMMENT '支付ID（外键 -> fin_payment.payment_id）',
  `document_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '单据类型：INVOICE(发票), BILL(账单)',
  `document_id` bigint(20) NOT NULL COMMENT '单据ID',
  `amount` decimal(18, 2) NOT NULL COMMENT '分配金额',
  `previous_unpaid_amount` decimal(18, 2) NOT NULL COMMENT '分配前未结清金额',
  `remaining_unpaid_amount` decimal(18, 2) NOT NULL COMMENT '分配后未结清金额',
  `allocation_status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '分配状态：PARTIAL(部分), FULL(全额)',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`allocation_id`) USING BTREE,
  INDEX `idx_payment_id`(`payment_id` ASC) USING BTREE,
  INDEX `idx_document`(`document_type` ASC, `document_id` ASC) USING BTREE,
  CONSTRAINT `fk_allocation_payment` FOREIGN KEY (`payment_id`) REFERENCES `fin_payment` (`payment_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '支付分配表（Lot Tracking）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_payment_allocation
-- ----------------------------

-- ----------------------------
-- Table structure for fin_split
-- ----------------------------
DROP TABLE IF EXISTS `fin_split`;
CREATE TABLE `fin_split`  (
  `split_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '分录ID',
  `trans_id` bigint(20) NOT NULL COMMENT '凭证ID（外键）',
  `account_id` bigint(20) NOT NULL COMMENT '科目ID（外键）',
  `direction` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '借贷方向：DEBIT(借), CREDIT(贷)',
  `amount` decimal(18, 2) NOT NULL COMMENT '金额',
  `memo` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分录备注/摘要',
  `owner_id` bigint(20) NULL DEFAULT NULL COMMENT '关联的业务实体ID（可选）',
  `owner_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '业务实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)',
  `id` bigint(20) NULL DEFAULT NULL COMMENT '主键ID（BaseEntity）',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int(11) NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  PRIMARY KEY (`split_id`) USING BTREE,
  INDEX `idx_trans_id`(`trans_id` ASC) USING BTREE,
  INDEX `idx_account_id`(`account_id` ASC) USING BTREE,
  INDEX `idx_direction`(`direction` ASC) USING BTREE,
  INDEX `idx_owner`(`owner_id` ASC, `owner_type` ASC) USING BTREE,
  CONSTRAINT `fk_split_account` FOREIGN KEY (`account_id`) REFERENCES `fin_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_split_trans` FOREIGN KEY (`trans_id`) REFERENCES `fin_transaction` (`trans_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '凭证分录表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_split
-- ----------------------------
INSERT INTO `fin_split` VALUES (1, 3, 1, 'DEBIT', 1000.00, '管理费用-办公费', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (2, 3, 2, 'CREDIT', 1000.00, '银行存款', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (3, 4, 1, 'DEBIT', 400.00, '', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (4, 4, 13, 'CREDIT', 400.00, '', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (5, 5, 40, 'CREDIT', 1110.00, '应付账款 - 账单：001', 2, 'VENDOR', NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (6, 5, 12, 'DEBIT', 1110.00, '123', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (7, 6, 60, 'DEBIT', 1000.00, '', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (8, 6, 1, 'CREDIT', 1000.00, '报销单付款：EXP20251224002', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (9, 7, 2, 'DEBIT', 500000.00, '期初余额-银行存款', NULL, NULL, NULL, '2025-12-24 16:12:30', '2025-12-24 16:12:30', 0);
INSERT INTO `fin_split` VALUES (10, 7, 1, 'DEBIT', 20000.00, '期初余额-库存现金', NULL, NULL, NULL, '2025-12-24 16:12:30', '2025-12-24 16:12:30', 0);
INSERT INTO `fin_split` VALUES (11, 7, 6, 'DEBIT', 15000.00, '期初余额-应收账款', NULL, NULL, NULL, '2025-12-24 16:12:30', '2025-12-24 16:12:30', 0);
INSERT INTO `fin_split` VALUES (12, 7, 14, 'DEBIT', 25000.00, '期初余额-库存商品', NULL, NULL, NULL, '2025-12-24 16:12:30', '2025-12-24 16:12:30', 0);
INSERT INTO `fin_split` VALUES (13, 7, 24, 'DEBIT', 80000.00, '期初余额-固定资产', NULL, NULL, NULL, '2025-12-24 16:12:30', '2025-12-24 16:12:30', 0);
INSERT INTO `fin_split` VALUES (14, 7, 55, 'CREDIT', 640000.00, '期初余额-实收资本', NULL, NULL, NULL, '2025-12-24 16:12:30', '2025-12-24 16:12:30', 0);
INSERT INTO `fin_split` VALUES (15, 8, 2, 'DEBIT', 34386.00, '收到客户货款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (16, 8, 64, 'CREDIT', 34386.00, '收到客户货款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (17, 9, 73, 'DEBIT', 327.00, '支付办公用品费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (18, 9, 2, 'CREDIT', 327.00, '支付办公用品费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (19, 10, 72, 'DEBIT', 25935.00, '计提员工工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (20, 10, 42, 'CREDIT', 25935.00, '计提员工工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (21, 11, 2, 'DEBIT', 27109.00, '收到销售回款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (22, 11, 64, 'CREDIT', 27109.00, '收到销售回款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (23, 12, 73, 'DEBIT', 1524.00, '支付水电费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (24, 12, 2, 'CREDIT', 1524.00, '支付水电费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (25, 13, 2, 'DEBIT', 42068.00, '收到项目款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (26, 13, 64, 'CREDIT', 42068.00, '收到项目款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (27, 14, 72, 'DEBIT', 46125.00, '计提管理人员工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (28, 14, 42, 'CREDIT', 46125.00, '计提管理人员工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (29, 15, 73, 'DEBIT', 1517.00, '支付差旅费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (30, 15, 2, 'CREDIT', 1517.00, '支付差旅费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (31, 16, 2, 'DEBIT', 7101.00, '收到服务费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (32, 16, 64, 'CREDIT', 7101.00, '收到服务费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (33, 17, 73, 'DEBIT', 428.00, '支付通讯费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (34, 17, 2, 'CREDIT', 428.00, '支付通讯费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (35, 18, 72, 'DEBIT', 44552.00, '计提销售人员工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (36, 18, 42, 'CREDIT', 44552.00, '计提销售人员工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (37, 19, 2, 'DEBIT', 43550.00, '收到预收款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (38, 19, 64, 'CREDIT', 43550.00, '收到预收款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (39, 20, 73, 'DEBIT', 1055.00, '支付租赁费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (40, 20, 2, 'CREDIT', 1055.00, '支付租赁费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (41, 21, 2, 'DEBIT', 42921.00, '收到客户货款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (42, 21, 64, 'CREDIT', 42921.00, '收到客户货款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (43, 22, 73, 'DEBIT', 1024.00, '支付维修费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (44, 22, 2, 'CREDIT', 1024.00, '支付维修费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (45, 23, 72, 'DEBIT', 36283.00, '计提技术人员工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (46, 23, 42, 'CREDIT', 36283.00, '计提技术人员工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (47, 24, 2, 'DEBIT', 9815.00, '收到销售回款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (48, 24, 64, 'CREDIT', 9815.00, '收到销售回款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (49, 25, 73, 'DEBIT', 327.00, '支付咨询费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (50, 25, 2, 'CREDIT', 327.00, '支付咨询费', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (51, 26, 2, 'DEBIT', 18861.00, '收到项目款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (52, 26, 64, 'CREDIT', 18861.00, '收到项目款', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (53, 27, 72, 'DEBIT', 41067.00, '计提员工工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (54, 27, 42, 'CREDIT', 41067.00, '计提员工工资', NULL, NULL, NULL, '2025-12-24 16:22:52', '2025-12-24 16:22:52', 0);
INSERT INTO `fin_split` VALUES (55, 28, 24, 'DEBIT', 1000.00, '', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (56, 28, 2, 'CREDIT', 1000.00, '', NULL, NULL, NULL, NULL, NULL, 0);
INSERT INTO `fin_split` VALUES (57, 29, 6, 'DEBIT', 28500.00, '应收账款 - 客户发票', 7, 'CUSTOMER', NULL, '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0);
INSERT INTO `fin_split` VALUES (58, 29, 64, 'CREDIT', 28500.00, '主营业务收入 - 咨询服务', NULL, NULL, NULL, '2024-11-02 09:15:00', '2024-11-02 09:15:00', 0);
INSERT INTO `fin_split` VALUES (59, 30, 6, 'DEBIT', 15200.00, '应收账款 - 客户发票', 8, 'CUSTOMER', NULL, '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0);
INSERT INTO `fin_split` VALUES (60, 30, 64, 'CREDIT', 15200.00, '主营业务收入 - 软件开发服务费', NULL, NULL, NULL, '2024-11-18 11:20:00', '2024-11-18 11:20:00', 0);
INSERT INTO `fin_split` VALUES (61, 31, 6, 'DEBIT', 36800.00, '应收账款 - 客户发票', 9, 'CUSTOMER', NULL, '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0);
INSERT INTO `fin_split` VALUES (62, 31, 64, 'CREDIT', 36800.00, '主营业务收入 - 年度维护费', NULL, NULL, NULL, '2024-11-25 15:45:00', '2024-11-25 15:45:00', 0);
INSERT INTO `fin_split` VALUES (63, 32, 6, 'DEBIT', 42000.00, '应收账款 - 客户发票', 10, 'CUSTOMER', NULL, '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0);
INSERT INTO `fin_split` VALUES (64, 32, 64, 'CREDIT', 42000.00, '主营业务收入 - 咨询服务', NULL, NULL, NULL, '2024-09-10 08:30:00', '2024-09-10 08:30:00', 0);
INSERT INTO `fin_split` VALUES (65, 33, 6, 'DEBIT', 18500.00, '应收账款 - 客户发票', 11, 'CUSTOMER', NULL, '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0);
INSERT INTO `fin_split` VALUES (66, 33, 64, 'CREDIT', 18500.00, '主营业务收入 - 软件开发服务费', NULL, NULL, NULL, '2024-09-22 13:15:00', '2024-09-22 13:15:00', 0);
INSERT INTO `fin_split` VALUES (67, 34, 6, 'DEBIT', 9800.00, '应收账款 - 客户发票', 12, 'CUSTOMER', NULL, '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0);
INSERT INTO `fin_split` VALUES (68, 34, 64, 'CREDIT', 9800.00, '主营业务收入 - 年度维护费', NULL, NULL, NULL, '2024-10-08 16:20:00', '2024-10-08 16:20:00', 0);
INSERT INTO `fin_split` VALUES (69, 35, 6, 'DEBIT', 32500.00, '应收账款 - 客户发票', 13, 'CUSTOMER', NULL, '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0);
INSERT INTO `fin_split` VALUES (70, 35, 64, 'CREDIT', 32500.00, '主营业务收入 - 咨询服务', NULL, NULL, NULL, '2024-10-28 10:50:00', '2024-10-28 10:50:00', 0);
INSERT INTO `fin_split` VALUES (71, 36, 6, 'DEBIT', 21500.00, '应收账款 - 客户发票', 14, 'CUSTOMER', NULL, '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0);
INSERT INTO `fin_split` VALUES (72, 36, 64, 'CREDIT', 21500.00, '主营业务收入 - 软件开发服务费', NULL, NULL, NULL, '2024-11-12 14:00:00', '2024-11-12 14:00:00', 0);
INSERT INTO `fin_split` VALUES (73, 37, 24, 'DEBIT', 12500.00, '固定资产 - 笔记本电脑', NULL, NULL, NULL, '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0);
INSERT INTO `fin_split` VALUES (74, 37, 40, 'CREDIT', 12500.00, '应付账款 - 供应商账单', 15, 'VENDOR', NULL, '2024-09-15 09:00:00', '2024-09-15 09:00:00', 0);
INSERT INTO `fin_split` VALUES (75, 38, 24, 'DEBIT', 18500.00, '固定资产 - 办公家具', NULL, NULL, NULL, '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0);
INSERT INTO `fin_split` VALUES (76, 38, 40, 'CREDIT', 18500.00, '应付账款 - 供应商账单', 16, 'VENDOR', NULL, '2024-10-20 10:30:00', '2024-10-20 10:30:00', 0);
INSERT INTO `fin_split` VALUES (77, 39, 73, 'DEBIT', 8500.00, '管理费用 - 办公室租金', NULL, NULL, NULL, '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0);
INSERT INTO `fin_split` VALUES (78, 39, 40, 'CREDIT', 8500.00, '应付账款 - 供应商账单', 17, 'VENDOR', NULL, '2024-09-30 11:00:00', '2024-09-30 11:00:00', 0);
INSERT INTO `fin_split` VALUES (79, 40, 73, 'DEBIT', 3200.00, '管理费用 - 电费', NULL, NULL, NULL, '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0);
INSERT INTO `fin_split` VALUES (80, 40, 40, 'CREDIT', 3200.00, '应付账款 - 供应商账单', 18, 'VENDOR', NULL, '2024-11-05 08:45:00', '2024-11-05 08:45:00', 0);
INSERT INTO `fin_split` VALUES (81, 41, 73, 'DEBIT', 12500.00, '管理费用 - 服务器续费', NULL, NULL, NULL, '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0);
INSERT INTO `fin_split` VALUES (82, 41, 40, 'CREDIT', 12500.00, '应付账款 - 供应商账单', 19, 'VENDOR', NULL, '2024-11-20 15:20:00', '2024-11-20 15:20:00', 0);
INSERT INTO `fin_split` VALUES (83, 42, 14, 'DEBIT', 28500.00, '库存商品 - 原材料', NULL, NULL, NULL, '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0);
INSERT INTO `fin_split` VALUES (84, 42, 40, 'CREDIT', 28500.00, '应付账款 - 供应商账单', 15, 'VENDOR', NULL, '2024-10-10 13:30:00', '2024-10-10 13:30:00', 0);
INSERT INTO `fin_split` VALUES (85, 43, 14, 'DEBIT', 15200.00, '库存商品 - 原材料', NULL, NULL, NULL, '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0);
INSERT INTO `fin_split` VALUES (86, 43, 40, 'CREDIT', 15200.00, '应付账款 - 供应商账单', 16, 'VENDOR', NULL, '2024-11-15 09:15:00', '2024-11-15 09:15:00', 0);
INSERT INTO `fin_split` VALUES (87, 44, 24, 'DEBIT', 36800.00, '固定资产 - 笔记本电脑', NULL, NULL, NULL, '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0);
INSERT INTO `fin_split` VALUES (88, 44, 40, 'CREDIT', 36800.00, '应付账款 - 供应商账单', 17, 'VENDOR', NULL, '2024-11-28 10:00:00', '2024-11-28 10:00:00', 0);
INSERT INTO `fin_split` VALUES (89, 45, 73, 'DEBIT', 8500.00, '管理费用 - 办公室租金', NULL, NULL, NULL, '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0);
INSERT INTO `fin_split` VALUES (90, 45, 40, 'CREDIT', 8500.00, '应付账款 - 供应商账单', 18, 'VENDOR', NULL, '2024-11-30 11:00:00', '2024-11-30 11:00:00', 0);
INSERT INTO `fin_split` VALUES (91, 46, 14, 'DEBIT', 21500.00, '库存商品 - 原材料', NULL, NULL, NULL, '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0);
INSERT INTO `fin_split` VALUES (92, 46, 40, 'CREDIT', 21500.00, '应付账款 - 供应商账单', 19, 'VENDOR', NULL, '2024-12-01 14:30:00', '2024-12-01 14:30:00', 0);
INSERT INTO `fin_split` VALUES (93, 47, 2, 'DEBIT', 28500.00, '银行存款 - 收到客户货款', NULL, NULL, NULL, '2024-11-05 10:30:00', '2024-11-05 10:30:00', 0);
INSERT INTO `fin_split` VALUES (94, 47, 6, 'CREDIT', 28500.00, '应收账款 - 核销发票', 7, 'CUSTOMER', NULL, '2024-11-05 10:30:00', '2024-11-05 10:30:00', 0);
INSERT INTO `fin_split` VALUES (95, 48, 1, 'DEBIT', 15200.00, '库存现金 - 收到客户货款', NULL, NULL, NULL, '2024-11-20 14:15:00', '2024-11-20 14:15:00', 0);
INSERT INTO `fin_split` VALUES (96, 48, 6, 'CREDIT', 15200.00, '应收账款 - 核销发票', 8, 'CUSTOMER', NULL, '2024-11-20 14:15:00', '2024-11-20 14:15:00', 0);
INSERT INTO `fin_split` VALUES (97, 49, 2, 'DEBIT', 36800.00, '银行存款 - 收到客户货款', NULL, NULL, NULL, '2024-11-28 16:45:00', '2024-11-28 16:45:00', 0);
INSERT INTO `fin_split` VALUES (98, 49, 6, 'CREDIT', 36800.00, '应收账款 - 核销发票', 9, 'CUSTOMER', NULL, '2024-11-28 16:45:00', '2024-11-28 16:45:00', 0);
INSERT INTO `fin_split` VALUES (99, 50, 2, 'DEBIT', 1250.00, '银行存款 - 利息收入', NULL, NULL, NULL, '2024-10-15 09:00:00', '2024-10-15 09:00:00', 0);
INSERT INTO `fin_split` VALUES (100, 50, 67, 'CREDIT', 1250.00, '投资收益 - 银行利息收入', NULL, NULL, NULL, '2024-10-15 09:00:00', '2024-10-15 09:00:00', 0);
INSERT INTO `fin_split` VALUES (101, 51, 2, 'DEBIT', 8500.00, '银行存款 - 收到退税', NULL, NULL, NULL, '2024-11-10 11:20:00', '2024-11-10 11:20:00', 0);
INSERT INTO `fin_split` VALUES (102, 51, 68, 'CREDIT', 8500.00, '营业外收入 - 收到退税', NULL, NULL, NULL, '2024-11-10 11:20:00', '2024-11-10 11:20:00', 0);
INSERT INTO `fin_split` VALUES (103, 52, 40, 'DEBIT', 12500.00, '应付账款 - 核销账单', 15, 'VENDOR', NULL, '2024-10-20 10:00:00', '2024-10-20 10:00:00', 0);
INSERT INTO `fin_split` VALUES (104, 52, 2, 'CREDIT', 12500.00, '银行存款 - 支付供应商货款', NULL, NULL, NULL, '2024-10-20 10:00:00', '2024-10-20 10:00:00', 0);
INSERT INTO `fin_split` VALUES (105, 53, 40, 'DEBIT', 18500.00, '应付账款 - 核销账单', 16, 'VENDOR', NULL, '2024-11-01 14:30:00', '2024-11-01 14:30:00', 0);
INSERT INTO `fin_split` VALUES (106, 53, 2, 'CREDIT', 18500.00, '银行存款 - 支付供应商货款', NULL, NULL, NULL, '2024-11-01 14:30:00', '2024-11-01 14:30:00', 0);
INSERT INTO `fin_split` VALUES (107, 54, 40, 'DEBIT', 8500.00, '应付账款 - 核销账单', 17, 'VENDOR', NULL, '2024-11-05 16:00:00', '2024-11-05 16:00:00', 0);
INSERT INTO `fin_split` VALUES (108, 54, 1, 'CREDIT', 8500.00, '库存现金 - 支付供应商货款', NULL, NULL, NULL, '2024-11-05 16:00:00', '2024-11-05 16:00:00', 0);
INSERT INTO `fin_split` VALUES (109, 55, 74, 'DEBIT', 50.00, '财务费用 - 银行转账手续费', NULL, NULL, NULL, '2024-10-25 09:30:00', '2024-10-25 09:30:00', 0);
INSERT INTO `fin_split` VALUES (110, 55, 2, 'CREDIT', 50.00, '银行存款 - 支付银行手续费', NULL, NULL, NULL, '2024-10-25 09:30:00', '2024-10-25 09:30:00', 0);
INSERT INTO `fin_split` VALUES (111, 56, 73, 'DEBIT', 120.00, '管理费用 - 快递费', NULL, NULL, NULL, '2024-11-15 15:20:00', '2024-11-15 15:20:00', 0);
INSERT INTO `fin_split` VALUES (112, 56, 1, 'CREDIT', 120.00, '库存现金 - 支付快递费', NULL, NULL, NULL, '2024-11-15 15:20:00', '2024-11-15 15:20:00', 0);
INSERT INTO `fin_split` VALUES (113, 57, 73, 'DEBIT', 2450.00, '管理费用 - 差旅费', NULL, NULL, NULL, '2024-11-08 15:00:00', '2024-11-08 15:00:00', 0);
INSERT INTO `fin_split` VALUES (114, 57, 46, 'CREDIT', 2450.00, '其他应付款 - 员工报销', 23, 'EMPLOYEE', NULL, '2024-11-08 15:00:00', '2024-11-08 15:00:00', 0);
INSERT INTO `fin_split` VALUES (115, 58, 73, 'DEBIT', 1200.00, '管理费用 - 业务招待费', NULL, NULL, NULL, '2024-11-15 16:30:00', '2024-11-15 16:30:00', 0);
INSERT INTO `fin_split` VALUES (116, 58, 46, 'CREDIT', 1200.00, '其他应付款 - 员工报销', 24, 'EMPLOYEE', NULL, '2024-11-15 16:30:00', '2024-11-15 16:30:00', 0);
INSERT INTO `fin_split` VALUES (117, 59, 73, 'DEBIT', 580.00, '管理费用 - 办公费', NULL, NULL, NULL, '2024-10-28 17:00:00', '2024-10-28 17:00:00', 0);
INSERT INTO `fin_split` VALUES (118, 59, 2, 'CREDIT', 580.00, '银行存款 - 支付员工报销', NULL, NULL, NULL, '2024-10-28 17:00:00', '2024-10-28 17:00:00', 0);
INSERT INTO `fin_split` VALUES (119, 60, 73, 'DEBIT', 1950.00, '管理费用 - 差旅费', NULL, NULL, NULL, '2024-11-22 18:00:00', '2024-11-22 18:00:00', 0);
INSERT INTO `fin_split` VALUES (120, 60, 2, 'CREDIT', 1950.00, '银行存款 - 支付员工报销', NULL, NULL, NULL, '2024-11-22 18:00:00', '2024-11-22 18:00:00', 0);

-- ----------------------------
-- Table structure for fin_transaction
-- ----------------------------
DROP TABLE IF EXISTS `fin_transaction`;
CREATE TABLE `fin_transaction`  (
  `trans_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '凭证ID',
  `voucher_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '凭证号，如V20241201001',
  `currency_id` bigint(20) NULL DEFAULT NULL COMMENT '币种ID',
  `trans_date` date NOT NULL COMMENT '交易日期',
  `enter_date` datetime NULL DEFAULT NULL COMMENT '录入时间',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '凭证摘要/描述',
  `creator_id` bigint(20) NULL DEFAULT NULL COMMENT '创建人ID',
  `status` int(11) NULL DEFAULT 0 COMMENT '状态：0-草稿，1-已审核',
  PRIMARY KEY (`trans_id`) USING BTREE,
  UNIQUE INDEX `uk_voucher_no`(`voucher_no` ASC) USING BTREE,
  INDEX `idx_trans_date`(`trans_date` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '凭证主表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_transaction
-- ----------------------------
INSERT INTO `fin_transaction` VALUES (3, 'V20251220001', NULL, '2024-12-20', '2025-12-20 20:32:18', '购买办公用品', NULL, 1);
INSERT INTO `fin_transaction` VALUES (4, 'V20251220002', NULL, '2025-12-20', '2025-12-20 21:53:37', '采购', NULL, 1);
INSERT INTO `fin_transaction` VALUES (5, 'V20251223001', NULL, '2025-12-23', '2025-12-23 20:49:29', '账单过账：001', NULL, 1);
INSERT INTO `fin_transaction` VALUES (6, 'V20251224001', NULL, '2025-12-24', '2025-12-24 15:25:55', '报销单过账：EXP20251224002', NULL, 1);
INSERT INTO `fin_transaction` VALUES (7, 'OPEN20240101001', 1, '2024-01-01', '2025-12-24 16:12:30', '期初余额', NULL, 1);
INSERT INTO `fin_transaction` VALUES (8, 'V20251012001', 1, '2025-10-12', '2025-12-24 16:22:52', '收到客户货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (9, 'V20251012002', 1, '2025-10-12', '2025-12-24 16:22:52', '支付办公用品费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (10, 'V20251211003', 1, '2025-12-11', '2025-12-24 16:22:52', '计提员工工资', NULL, 1);
INSERT INTO `fin_transaction` VALUES (11, 'V20251106004', 1, '2025-11-06', '2025-12-24 16:22:52', '收到销售回款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (12, 'V20251009005', 1, '2025-10-09', '2025-12-24 16:22:52', '支付水电费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (13, 'V20251205006', 1, '2025-12-05', '2025-12-24 16:22:52', '收到项目款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (14, 'V20251112007', 1, '2025-11-12', '2025-12-24 16:22:52', '计提管理人员工资', NULL, 1);
INSERT INTO `fin_transaction` VALUES (15, 'V20251216008', 1, '2025-12-16', '2025-12-24 16:22:52', '支付差旅费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (16, 'V20251113009', 1, '2025-11-13', '2025-12-24 16:22:52', '收到服务费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (17, 'V20251008010', 1, '2025-10-08', '2025-12-24 16:22:52', '支付通讯费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (18, 'V20251130011', 1, '2025-11-30', '2025-12-24 16:22:52', '计提销售人员工资', NULL, 1);
INSERT INTO `fin_transaction` VALUES (19, 'V20251110012', 1, '2025-11-10', '2025-12-24 16:22:52', '收到预收款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (20, 'V20251012013', 1, '2025-10-12', '2025-12-24 16:22:52', '支付租赁费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (21, 'V20251218014', 1, '2025-12-18', '2025-12-24 16:22:52', '收到客户货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (22, 'V20251224015', 1, '2025-12-24', '2025-12-24 16:22:52', '支付维修费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (23, 'V20251116016', 1, '2025-11-16', '2025-12-24 16:22:52', '计提技术人员工资', NULL, 1);
INSERT INTO `fin_transaction` VALUES (24, 'V20251223017', 1, '2025-12-23', '2025-12-24 16:22:52', '收到销售回款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (25, 'V20251111018', 1, '2025-11-11', '2025-12-24 16:22:52', '支付咨询费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (26, 'V20251213019', 1, '2025-12-13', '2025-12-24 16:22:52', '收到项目款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (27, 'V20251212020', 1, '2025-12-12', '2025-12-24 16:22:52', '计提员工工资', NULL, 1);
INSERT INTO `fin_transaction` VALUES (28, 'V20251224016', NULL, '2025-12-24', '2025-12-24 17:03:23', '购买铅笔', NULL, 1);
INSERT INTO `fin_transaction` VALUES (29, 'V20241102001', 1, '2024-11-02', '2024-11-02 09:15:00', '销售发票 INV20241102003 - 咨询服务', NULL, 1);
INSERT INTO `fin_transaction` VALUES (30, 'V20241118002', 1, '2024-11-18', '2024-11-18 11:20:00', '销售发票 INV20241118004 - 软件开发服务费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (31, 'V20241125003', 1, '2024-11-25', '2024-11-25 15:45:00', '销售发票 INV20241125005 - 年度维护费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (32, 'V20240910004', 1, '2024-09-10', '2024-09-10 08:30:00', '销售发票 INV20240910006 - 咨询服务', NULL, 1);
INSERT INTO `fin_transaction` VALUES (33, 'V20240922005', 1, '2024-09-22', '2024-09-22 13:15:00', '销售发票 INV20240922007 - 软件开发服务费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (34, 'V20241008006', 1, '2024-10-08', '2024-10-08 16:20:00', '销售发票 INV20241008008 - 年度维护费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (35, 'V20241028007', 1, '2024-10-28', '2024-10-28 10:50:00', '销售发票 INV20241028009 - 咨询服务', NULL, 1);
INSERT INTO `fin_transaction` VALUES (36, 'V20241112008', 1, '2024-11-12', '2024-11-12 14:00:00', '销售发票 INV20241112010 - 软件开发服务费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (37, 'V20240915009', 1, '2024-09-15', '2024-09-15 09:00:00', '采购账单 BILL20240915001 - 高性能笔记本电脑', NULL, 1);
INSERT INTO `fin_transaction` VALUES (38, 'V20241020010', 1, '2024-10-20', '2024-10-20 10:30:00', '采购账单 BILL20241020002 - 办公家具', NULL, 1);
INSERT INTO `fin_transaction` VALUES (39, 'V20240930011', 1, '2024-09-30', '2024-09-30 11:00:00', '采购账单 BILL20240930003 - 办公室租金', NULL, 1);
INSERT INTO `fin_transaction` VALUES (40, 'V20241105012', 1, '2024-11-05', '2024-11-05 08:45:00', '采购账单 BILL20241105004 - 电费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (41, 'V20241120013', 1, '2024-11-20', '2024-11-20 15:20:00', '采购账单 BILL20241120005 - AWS/阿里云服务器续费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (42, 'V20241010014', 1, '2024-10-10', '2024-10-10 13:30:00', '采购账单 BILL20241010006 - 原材料采购', NULL, 1);
INSERT INTO `fin_transaction` VALUES (43, 'V20241115015', 1, '2024-11-15', '2024-11-15 09:15:00', '采购账单 BILL20241115007 - 原材料采购', NULL, 1);
INSERT INTO `fin_transaction` VALUES (44, 'V20241128016', 1, '2024-11-28', '2024-11-28 10:00:00', '采购账单 BILL20241128008 - 高性能笔记本电脑', NULL, 1);
INSERT INTO `fin_transaction` VALUES (45, 'V20241130017', 1, '2024-11-30', '2024-11-30 11:00:00', '采购账单 BILL20241130009 - 办公室租金', NULL, 1);
INSERT INTO `fin_transaction` VALUES (46, 'V20241201018', 1, '2024-12-01', '2024-12-01 14:30:00', '采购账单 BILL20241201010 - 原材料采购', NULL, 1);
INSERT INTO `fin_transaction` VALUES (47, 'V20241105001', 1, '2024-11-05', '2024-11-05 10:30:00', '收款单 RP20241105001 - 收到深圳华强电子股份有限公司货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (48, 'V20241120002', 1, '2024-11-20', '2024-11-20 14:15:00', '收款单 RP20241120002 - 收到广州美达贸易行货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (49, 'V20241128003', 1, '2024-11-28', '2024-11-28 16:45:00', '收款单 RP20241128003 - 收到杭州西湖软件科技有限公司货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (50, 'V20241015004', 1, '2024-10-15', '2024-10-15 09:00:00', '收款单 RP20241015004 - 银行利息收入', NULL, 1);
INSERT INTO `fin_transaction` VALUES (51, 'V20241110005', 1, '2024-11-10', '2024-11-10 11:20:00', '收款单 RP20241110005 - 收到退税', NULL, 1);
INSERT INTO `fin_transaction` VALUES (52, 'V20241020001', 1, '2024-10-20', '2024-10-20 10:00:00', '付款单 RP20241020001 - 支付北京办公用品供应中心货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (53, 'V20241101002', 1, '2024-11-01', '2024-11-01 14:30:00', '付款单 RP20241101002 - 支付深圳电子元器件批发市场货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (54, 'V20241105003', 1, '2024-11-05', '2024-11-05 16:00:00', '付款单 RP20241105003 - 支付上海化工原料有限公司货款', NULL, 1);
INSERT INTO `fin_transaction` VALUES (55, 'V20241025004', 1, '2024-10-25', '2024-10-25 09:30:00', '付款单 RP20241025004 - 支付银行转账手续费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (56, 'V20241115005', 1, '2024-11-15', '2024-11-15 15:20:00', '付款单 RP20241115005 - 支付快递费', NULL, 1);
INSERT INTO `fin_transaction` VALUES (57, 'V20241108001', 1, '2024-11-08', '2024-11-08 15:00:00', '报销单 EXP20241108005 - 差旅费（已审核待支付）', NULL, 1);
INSERT INTO `fin_transaction` VALUES (58, 'V20241115002', 1, '2024-11-15', '2024-11-15 16:30:00', '报销单 EXP20241115006 - 业务招待费（已审核待支付）', NULL, 1);
INSERT INTO `fin_transaction` VALUES (59, 'V20241028003', 1, '2024-10-28', '2024-10-28 17:00:00', '报销单 EXP20241028007 - 办公采购（已支付）', NULL, 1);
INSERT INTO `fin_transaction` VALUES (60, 'V20241122004', 1, '2024-11-22', '2024-11-22 18:00:00', '报销单 EXP20241122008 - 差旅费（已支付）', NULL, 1);

-- ----------------------------
-- Table structure for fin_vendor
-- ----------------------------
DROP TABLE IF EXISTS `fin_vendor`;
CREATE TABLE `fin_vendor`  (
  `vendor_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '供应商ID',
  `owner_id` bigint(20) NOT NULL COMMENT '业务实体ID（外键 -> fin_owner.owner_id）',
  `vendor_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '供应商类型',
  `vendor_level` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '供应商等级',
  `payment_terms` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '付款条件（如：30天、60天）',
  PRIMARY KEY (`vendor_id`) USING BTREE,
  UNIQUE INDEX `uk_owner_id`(`owner_id` ASC) USING BTREE,
  CONSTRAINT `fk_vendor_owner` FOREIGN KEY (`owner_id`) REFERENCES `fin_owner` (`owner_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '供应商表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of fin_vendor
-- ----------------------------
INSERT INTO `fin_vendor` VALUES (1, 15, '办公用品', 'A', '30天');
INSERT INTO `fin_vendor` VALUES (2, 16, '电子元器件', 'A', '60天');
INSERT INTO `fin_vendor` VALUES (3, 17, '原材料', 'B', '45天');
INSERT INTO `fin_vendor` VALUES (4, 18, '物流服务', 'A', '月结');
INSERT INTO `fin_vendor` VALUES (5, 19, '设备租赁', 'B', '30天');

-- ----------------------------
-- Table structure for sys_menu
-- ----------------------------
DROP TABLE IF EXISTS `sys_menu`;
CREATE TABLE `sys_menu`  (
  `id` bigint(20) NOT NULL COMMENT '菜单ID',
  `menu_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '菜单名称',
  `parent_id` bigint(20) NULL DEFAULT 0 COMMENT '父菜单ID（0表示顶级菜单）',
  `order_num` int(11) NULL DEFAULT 0 COMMENT '显示顺序',
  `path` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '路由地址（Vue前端用）',
  `perms` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '权限标识（如：finance:voucher:add）',
  `icon` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '菜单图标',
  `menu_type` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'M' COMMENT '类型：M目录 C菜单 F按钮',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` tinyint(4) NULL DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_parent_id`(`parent_id` ASC) USING BTREE,
  INDEX `idx_perms`(`perms` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '系统菜单/权限表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_menu
-- ----------------------------
INSERT INTO `sys_menu` VALUES (1, '凭证管理', 0, 1, '/voucher', NULL, 'Document', 'M', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (2, '录入凭证', 1, 1, '/voucher/add', 'finance:voucher:add', NULL, 'C', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (3, '查询凭证', 1, 2, '/voucher/query', 'finance:voucher:query', NULL, 'C', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (4, '审核凭证', 1, 3, '/voucher/audit', 'finance:voucher:audit', NULL, 'F', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (5, '科目管理', 0, 2, '/accounts', 'finance:account:list', 'List', 'C', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (6, '新增科目', 5, 1, NULL, 'finance:account:add', NULL, 'F', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (7, '编辑科目', 5, 2, NULL, 'finance:account:edit', NULL, 'F', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (8, '删除科目', 5, 3, NULL, 'finance:account:delete', NULL, 'F', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (9, '财务报表', 0, 3, '/reports', NULL, 'TrendCharts', 'M', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (10, '试算平衡表', 9, 1, '/reports/trial-balance', 'finance:report:trial-balance', NULL, 'C', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (11, '资产负债表', 9, 2, '/reports/balance-sheet', 'finance:report:balance-sheet', NULL, 'C', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_menu` VALUES (12, '现金流量表', 9, 3, '/reports/cash-flow', 'finance:report:cash-flow', NULL, 'C', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);

-- ----------------------------
-- Table structure for sys_role
-- ----------------------------
DROP TABLE IF EXISTS `sys_role`;
CREATE TABLE `sys_role`  (
  `id` bigint(20) NOT NULL COMMENT '角色ID',
  `role_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色名称（如：财务主管）',
  `role_key` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色权限字符串（如：finance_manager）',
  `role_sort` int(11) NULL DEFAULT 0 COMMENT '显示顺序',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '备注',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` tinyint(4) NULL DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_role_key`(`role_key` ASC) USING BTREE,
  INDEX `idx_role_name`(`role_name` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '系统角色表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_role
-- ----------------------------
INSERT INTO `sys_role` VALUES (1, '超级管理员', 'admin', 1, '拥有所有权限', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role` VALUES (2, '财务主管', 'finance_manager', 2, '财务部门主管', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role` VALUES (3, '普通会计', 'accountant', 3, '普通财务人员', '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);

-- ----------------------------
-- Table structure for sys_role_menu
-- ----------------------------
DROP TABLE IF EXISTS `sys_role_menu`;
CREATE TABLE `sys_role_menu`  (
  `id` bigint(20) NOT NULL COMMENT '关联ID',
  `role_id` bigint(20) NOT NULL COMMENT '角色ID',
  `menu_id` bigint(20) NOT NULL COMMENT '菜单ID',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` tinyint(4) NULL DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_role_menu`(`role_id` ASC, `menu_id` ASC) USING BTREE,
  INDEX `idx_role_id`(`role_id` ASC) USING BTREE,
  INDEX `idx_menu_id`(`menu_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '角色菜单关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_role_menu
-- ----------------------------
INSERT INTO `sys_role_menu` VALUES (1, 1, 1, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (2, 1, 2, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (3, 1, 3, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (4, 1, 4, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (5, 1, 5, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (6, 1, 6, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (7, 1, 7, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (8, 1, 8, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (9, 1, 9, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (10, 1, 10, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (11, 1, 11, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);
INSERT INTO `sys_role_menu` VALUES (12, 1, 12, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);

-- ----------------------------
-- Table structure for sys_user
-- ----------------------------
DROP TABLE IF EXISTS `sys_user`;
CREATE TABLE `sys_user`  (
  `id` bigint(20) NOT NULL COMMENT '用户ID',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户名',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码（BCrypt加密，至少60字符）',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '昵称/真实姓名',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '手机号',
  `status` tinyint(4) NULL DEFAULT 1 COMMENT '状态：1正常 0停用',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` tinyint(4) NULL DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '系统用户表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user
-- ----------------------------
INSERT INTO `sys_user` VALUES (1, 'admin', '$2a$10$q9swzrjWjhdxksuDZwF3Su2l4sOWNuCKGHZ0vhk2f0LRtO2qoWkIm', '系统管理员', 'admin@kylin.com', '13800138000', 1, '2025-12-24 17:26:08', '2025-12-24 18:15:30', 0);

-- ----------------------------
-- Table structure for sys_user_role
-- ----------------------------
DROP TABLE IF EXISTS `sys_user_role`;
CREATE TABLE `sys_user_role`  (
  `id` bigint(20) NOT NULL COMMENT '关联ID',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `role_id` bigint(20) NOT NULL COMMENT '角色ID',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` tinyint(4) NULL DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_role`(`user_id` ASC, `role_id` ASC) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE,
  INDEX `idx_role_id`(`role_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户角色关联表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sys_user_role
-- ----------------------------
INSERT INTO `sys_user_role` VALUES (1, 1, 1, '2025-12-24 17:26:08', '2025-12-24 17:26:08', 0);

SET FOREIGN_KEY_CHECKS = 1;
