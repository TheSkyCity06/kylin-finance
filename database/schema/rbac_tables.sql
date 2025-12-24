-- ==========================================
-- RBAC 权限管理系统 - 数据库表结构
-- ==========================================

-- 1. 系统用户表
CREATE TABLE IF NOT EXISTS `sys_user` (
    `id` BIGINT NOT NULL COMMENT '用户ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(255) NOT NULL COMMENT '密码（BCrypt加密）',
    `nickname` VARCHAR(50) COMMENT '昵称/真实姓名',
    `email` VARCHAR(100) COMMENT '邮箱',
    `phone` VARCHAR(20) COMMENT '手机号',
    `status` TINYINT DEFAULT 1 COMMENT '状态：1正常 0停用',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统用户表';

-- 2. 系统角色表
CREATE TABLE IF NOT EXISTS `sys_role` (
    `id` BIGINT NOT NULL COMMENT '角色ID',
    `role_name` VARCHAR(50) NOT NULL COMMENT '角色名称（如：财务主管）',
    `role_key` VARCHAR(50) NOT NULL COMMENT '角色权限字符串（如：finance_manager）',
    `role_sort` INT DEFAULT 0 COMMENT '显示顺序',
    `remark` VARCHAR(500) COMMENT '备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_key` (`role_key`),
    KEY `idx_role_name` (`role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统角色表';

-- 3. 系统菜单/权限表
CREATE TABLE IF NOT EXISTS `sys_menu` (
    `id` BIGINT NOT NULL COMMENT '菜单ID',
    `menu_name` VARCHAR(50) NOT NULL COMMENT '菜单名称',
    `parent_id` BIGINT DEFAULT 0 COMMENT '父菜单ID（0表示顶级菜单）',
    `order_num` INT DEFAULT 0 COMMENT '显示顺序',
    `path` VARCHAR(200) COMMENT '路由地址（Vue前端用）',
    `perms` VARCHAR(100) COMMENT '权限标识（如：finance:voucher:add）',
    `icon` VARCHAR(50) COMMENT '菜单图标',
    `menu_type` CHAR(1) DEFAULT 'M' COMMENT '类型：M目录 C菜单 F按钮',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_perms` (`perms`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统菜单/权限表';

-- 4. 用户角色关联表（多对多）
CREATE TABLE IF NOT EXISTS `sys_user_role` (
    `id` BIGINT NOT NULL COMMENT '关联ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `role_id` BIGINT NOT NULL COMMENT '角色ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_role` (`user_id`, `role_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_role_id` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色关联表';

-- 5. 角色菜单关联表（多对多）
CREATE TABLE IF NOT EXISTS `sys_role_menu` (
    `id` BIGINT NOT NULL COMMENT '关联ID',
    `role_id` BIGINT NOT NULL COMMENT '角色ID',
    `menu_id` BIGINT NOT NULL COMMENT '菜单ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `is_deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除：0未删除 1已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_menu` (`role_id`, `menu_id`),
    KEY `idx_role_id` (`role_id`),
    KEY `idx_menu_id` (`menu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色菜单关联表';

-- ==========================================
-- 初始化数据（可选）
-- ==========================================

-- 插入默认管理员用户（密码：123456，BCrypt加密后：'$2a$10$7JB720yubVSZv5w56jne.O7wOvJjd.yjH6w.H6w.H6w'）
INSERT INTO `sys_user` (`id`, `username`, `password`, `nickname`, `email`, `phone`, `status`) 
VALUES (1, 'admin', '$2a$10$7JB720yubVSZv5w56jne.O7wOvJjd.yjH6w.H6w.H6w', '系统管理员', 'admin@kylin.com', '13800138000', 1)
ON DUPLICATE KEY UPDATE `username`=`username`;

-- 插入默认角色
INSERT INTO `sys_role` (`id`, `role_name`, `role_key`, `role_sort`, `remark`) 
VALUES 
(1, '超级管理员', 'admin', 1, '拥有所有权限'),
(2, '财务主管', 'finance_manager', 2, '财务部门主管'),
(3, '普通会计', 'accountant', 3, '普通财务人员')
ON DUPLICATE KEY UPDATE `role_name`=`role_name`;

-- 插入默认菜单权限
INSERT INTO `sys_menu` (`id`, `menu_name`, `parent_id`, `order_num`, `path`, `perms`, `icon`, `menu_type`) 
VALUES 
(1, '凭证管理', 0, 1, '/voucher', NULL, 'Document', 'M'),
(2, '录入凭证', 1, 1, '/voucher/add', 'finance:voucher:add', NULL, 'C'),
(3, '查询凭证', 1, 2, '/voucher/query', 'finance:voucher:query', NULL, 'C'),
(4, '审核凭证', 1, 3, '/voucher/audit', 'finance:voucher:audit', NULL, 'F'),
(5, '科目管理', 0, 2, '/accounts', 'finance:account:list', 'List', 'C'),
(6, '新增科目', 5, 1, NULL, 'finance:account:add', NULL, 'F'),
(7, '编辑科目', 5, 2, NULL, 'finance:account:edit', NULL, 'F'),
(8, '删除科目', 5, 3, NULL, 'finance:account:delete', NULL, 'F'),
(9, '财务报表', 0, 3, '/reports', NULL, 'TrendCharts', 'M'),
(10, '试算平衡表', 9, 1, '/reports/trial-balance', 'finance:report:trial-balance', NULL, 'C'),
(11, '资产负债表', 9, 2, '/reports/balance-sheet', 'finance:report:balance-sheet', NULL, 'C'),
(12, '现金流量表', 9, 3, '/reports/cash-flow', 'finance:report:cash-flow', NULL, 'C')
ON DUPLICATE KEY UPDATE `menu_name`=`menu_name`;

-- 关联管理员用户和角色
INSERT INTO `sys_user_role` (`id`, `user_id`, `role_id`) 
VALUES (1, 1, 1)
ON DUPLICATE KEY UPDATE `user_id`=`user_id`;

-- 关联管理员角色和所有菜单权限
INSERT INTO `sys_role_menu` (`id`, `role_id`, `menu_id`) 
VALUES 
(1, 1, 1), (2, 1, 2), (3, 1, 3), (4, 1, 4),
(5, 1, 5), (6, 1, 6), (7, 1, 7), (8, 1, 8),
(9, 1, 9), (10, 1, 10), (11, 1, 11), (12, 1, 12)
ON DUPLICATE KEY UPDATE `role_id`=`role_id`;

