-- ==========================================
-- 麒麟财务管理系统 - 模拟数据插入脚本
-- ==========================================
-- 用途：为测试UI填充真实的业务数据
-- 包含：10个客户、5个供应商、5个员工
--
-- 使用方法：
-- 1. 确保已执行 database/init.sql 初始化数据库和科目数据
-- 2. 执行此脚本：mysql -u root -p kylin_finance < database/mock_data.sql
-- 3. 脚本使用 INSERT IGNORE，可安全重复执行，不会产生重复数据
--
-- 数据说明：
-- - 客户代码：CUST001-CUST010
-- - 供应商代码：SUPP001-SUPP005
-- - 员工代码：EMP001-EMP005
-- - 所有数据使用中文，符合中国商业环境
-- ==========================================

USE kylin_finance;

-- ==========================================
-- 1. 获取关联科目ID（用于业务实体关联）
-- ==========================================
SET @receivable_account_id = (SELECT account_id FROM fin_account WHERE account_code = '1122' LIMIT 1); -- 应收账款
SET @payable_account_id = (SELECT account_id FROM fin_account WHERE account_code = '2202' LIMIT 1); -- 应付账款
SET @other_receivable_account_id = (SELECT account_id FROM fin_account WHERE account_code = '1221' LIMIT 1); -- 其他应收款

-- 如果科目不存在，使用NULL（允许为空）
SET @receivable_account_id = IFNULL(@receivable_account_id, NULL);
SET @payable_account_id = IFNULL(@payable_account_id, NULL);
SET @other_receivable_account_id = IFNULL(@other_receivable_account_id, NULL);

-- ==========================================
-- 2. 插入客户数据 (Customers)
-- ==========================================
-- 先插入 fin_owner 表（使用 INSERT IGNORE 避免重复插入）
INSERT IGNORE INTO `fin_owner` (
    `name`, `code`, `account_id`, `owner_type`, 
    `contact_name`, `contact_phone`, `contact_email`, `address`, `notes`, `enabled`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
-- 客户1
('上海智联科技有限公司', 'CUST001', @receivable_account_id, 'CUSTOMER', 
 '张经理', '13800138001', 'zhang@zhilian-tech.com', '上海市浦东新区张江高科技园区科苑路399号', '主要客户，信用良好', 1,
 NOW(), NOW(), 0),
-- 客户2
('北京创新商贸有限公司', 'CUST002', @receivable_account_id, 'CUSTOMER',
 '李总', '13900139002', 'li@chuangxin-trade.com', '北京市朝阳区建国路88号SOHO现代城A座1205室', '长期合作客户', 1,
 NOW(), NOW(), 0),
-- 客户3
('深圳华强电子股份有限公司', 'CUST003', @receivable_account_id, 'CUSTOMER',
 '王主任', '13700137003', 'wang@huaqiang-elec.com', '深圳市福田区华强北路1002号华强广场A座15层', '电子产品批发商', 1,
 NOW(), NOW(), 0),
-- 客户4
('广州美达贸易行', 'CUST004', @receivable_account_id, 'CUSTOMER',
 '陈经理', '13600136004', 'chen@meida-trade.com', '广州市天河区天河路123号天河城广场B座8楼', '服装贸易', 1,
 NOW(), NOW(), 0),
-- 客户5
('杭州西湖软件科技有限公司', 'CUST005', @receivable_account_id, 'CUSTOMER',
 '刘总监', '13500135005', 'liu@xihu-soft.com', '杭州市西湖区文三路259号昌地火炬大厦2号楼10层', '软件服务商', 1,
 NOW(), NOW(), 0),
-- 客户6
('成都天府实业集团有限公司', 'CUST006', @receivable_account_id, 'CUSTOMER',
 '赵副总', '13400134006', 'zhao@tianfu-group.com', '成都市锦江区天府大道中段666号', '大型企业客户', 1,
 NOW(), NOW(), 0),
-- 客户7
('武汉长江物流有限公司', 'CUST007', @receivable_account_id, 'CUSTOMER',
 '孙经理', '13300133007', 'sun@changjiang-logistics.com', '武汉市江汉区建设大道568号新世界国贸大厦I座20层', '物流服务', 1,
 NOW(), NOW(), 0),
-- 客户8
('西安古都文化传媒有限公司', 'CUST008', @receivable_account_id, 'CUSTOMER',
 '周总', '13200132008', 'zhou@gudu-media.com', '西安市雁塔区高新路88号', '文化传媒', 1,
 NOW(), NOW(), 0),
-- 客户9
('南京金陵建筑装饰工程有限公司', 'CUST009', @receivable_account_id, 'CUSTOMER',
 '吴经理', '13100131009', 'wu@jinling-construction.com', '南京市建邺区江东中路369号新华报业传媒广场1号楼', '建筑装饰', 1,
 NOW(), NOW(), 0),
-- 客户10
('天津滨海新材料科技有限公司', 'CUST010', @receivable_account_id, 'CUSTOMER',
 '郑主任', '13000130010', 'zheng@binhai-newmat.com', '天津市滨海新区经济技术开发区第三大街51号', '新材料研发', 1,
 NOW(), NOW(), 0);

-- 插入 fin_customer 表（通过code关联）
INSERT INTO `fin_customer` (`owner_id`, `credit_limit`, `customer_level`, `industry`)
SELECT o.owner_id, 
       CASE o.code
           WHEN 'CUST001' THEN 500000.00
           WHEN 'CUST002' THEN 300000.00
           WHEN 'CUST003' THEN 800000.00
           WHEN 'CUST004' THEN 200000.00
           WHEN 'CUST005' THEN 400000.00
           WHEN 'CUST006' THEN 1000000.00
           WHEN 'CUST007' THEN 350000.00
           WHEN 'CUST008' THEN 150000.00
           WHEN 'CUST009' THEN 600000.00
           WHEN 'CUST010' THEN 450000.00
       END AS credit_limit,
       CASE o.code
           WHEN 'CUST001' THEN 'A'
           WHEN 'CUST002' THEN 'B'
           WHEN 'CUST003' THEN 'A'
           WHEN 'CUST004' THEN 'C'
           WHEN 'CUST005' THEN 'B'
           WHEN 'CUST006' THEN 'A'
           WHEN 'CUST007' THEN 'B'
           WHEN 'CUST008' THEN 'C'
           WHEN 'CUST009' THEN 'A'
           WHEN 'CUST010' THEN 'B'
       END AS customer_level,
       CASE o.code
           WHEN 'CUST001' THEN '科技服务'
           WHEN 'CUST002' THEN '商贸流通'
           WHEN 'CUST003' THEN '电子制造'
           WHEN 'CUST004' THEN '贸易批发'
           WHEN 'CUST005' THEN '软件服务'
           WHEN 'CUST006' THEN '综合实业'
           WHEN 'CUST007' THEN '物流运输'
           WHEN 'CUST008' THEN '文化传媒'
           WHEN 'CUST009' THEN '建筑工程'
           WHEN 'CUST010' THEN '新材料'
       END AS industry
FROM fin_owner o
WHERE o.owner_type = 'CUSTOMER' 
  AND o.code IN ('CUST001', 'CUST002', 'CUST003', 'CUST004', 'CUST005', 
                 'CUST006', 'CUST007', 'CUST008', 'CUST009', 'CUST010')
  AND o.is_deleted = 0
  AND NOT EXISTS (SELECT 1 FROM fin_customer c WHERE c.owner_id = o.owner_id);

-- ==========================================
-- 3. 插入供应商数据 (Suppliers/Vendors)
-- ==========================================
-- 先插入 fin_owner 表（使用 INSERT IGNORE 避免重复插入）
INSERT IGNORE INTO `fin_owner` (
    `name`, `code`, `account_id`, `owner_type`,
    `contact_name`, `contact_phone`, `contact_email`, `address`, `notes`, `enabled`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
-- 供应商1 - 办公用品
('北京办公用品供应中心', 'SUPP001', @payable_account_id, 'VENDOR',
 '马采购', '13800138111', 'ma@office-supply.com', '北京市海淀区中关村大街1号海龙大厦8层', '办公用品供应商，质量可靠', 1,
 NOW(), NOW(), 0),
-- 供应商2 - 电子产品
('深圳电子元器件批发市场', 'SUPP002', @payable_account_id, 'VENDOR',
 '黄经理', '13900139112', 'huang@electronics-wholesale.com', '深圳市福田区华强北电子市场A区3楼', '电子元器件批发', 1,
 NOW(), NOW(), 0),
-- 供应商3 - 原材料
('上海化工原料有限公司', 'SUPP003', @payable_account_id, 'VENDOR',
 '徐总', '13700137113', 'xu@chemical-materials.com', '上海市嘉定区安亭镇墨玉路185号', '化工原料供应商', 1,
 NOW(), NOW(), 0),
-- 供应商4 - 物流服务
('顺丰速运有限公司', 'SUPP004', @payable_account_id, 'VENDOR',
 '客服部', '400-111-1111', 'service@sf-express.com', '深圳市福田区益田路6009号新世界中心', '快递物流服务', 1,
 NOW(), NOW(), 0),
-- 供应商5 - 设备租赁
('广州设备租赁服务有限公司', 'SUPP005', @payable_account_id, 'VENDOR',
 '林经理', '13600136115', 'lin@equipment-lease.com', '广州市越秀区环市东路339号广东国际大厦A座', '设备租赁服务', 1,
 NOW(), NOW(), 0);

-- 插入 fin_vendor 表（通过code关联）
INSERT INTO `fin_vendor` (`owner_id`, `vendor_type`, `vendor_level`, `payment_terms`)
SELECT o.owner_id,
       CASE o.code
           WHEN 'SUPP001' THEN '办公用品'
           WHEN 'SUPP002' THEN '电子元器件'
           WHEN 'SUPP003' THEN '原材料'
           WHEN 'SUPP004' THEN '物流服务'
           WHEN 'SUPP005' THEN '设备租赁'
       END AS vendor_type,
       CASE o.code
           WHEN 'SUPP001' THEN 'A'
           WHEN 'SUPP002' THEN 'A'
           WHEN 'SUPP003' THEN 'B'
           WHEN 'SUPP004' THEN 'A'
           WHEN 'SUPP005' THEN 'B'
       END AS vendor_level,
       CASE o.code
           WHEN 'SUPP001' THEN '30天'
           WHEN 'SUPP002' THEN '60天'
           WHEN 'SUPP003' THEN '45天'
           WHEN 'SUPP004' THEN '月结'
           WHEN 'SUPP005' THEN '30天'
       END AS payment_terms
FROM fin_owner o
WHERE o.owner_type = 'VENDOR'
  AND o.code IN ('SUPP001', 'SUPP002', 'SUPP003', 'SUPP004', 'SUPP005')
  AND o.is_deleted = 0
  AND NOT EXISTS (SELECT 1 FROM fin_vendor v WHERE v.owner_id = o.owner_id);

-- ==========================================
-- 4. 插入员工数据 (Employees)
-- ==========================================
-- 先插入 fin_owner 表（使用 INSERT IGNORE 避免重复插入）
INSERT IGNORE INTO `fin_owner` (
    `name`, `code`, `account_id`, `owner_type`,
    `contact_name`, `contact_phone`, `contact_email`, `address`, `notes`, `enabled`,
    `create_time`, `update_time`, `is_deleted`
) VALUES
-- 员工1
('张三', 'EMP001', @other_receivable_account_id, 'EMPLOYEE',
 '张三', '13800138221', 'zhangsan@company.com', '北京市朝阳区', '财务部员工', 1,
 NOW(), NOW(), 0),
-- 员工2
('李四', 'EMP002', @other_receivable_account_id, 'EMPLOYEE',
 '李四', '13900139222', 'lisi@company.com', '上海市浦东新区', '销售部员工', 1,
 NOW(), NOW(), 0),
-- 员工3
('王五', 'EMP003', @other_receivable_account_id, 'EMPLOYEE',
 '王五', '13700137223', 'wangwu@company.com', '广州市天河区', '技术部员工', 1,
 NOW(), NOW(), 0),
-- 员工4
('赵六', 'EMP004', @other_receivable_account_id, 'EMPLOYEE',
 '赵六', '13600136224', 'zhaoliu@company.com', '深圳市南山区', '人事部员工', 1,
 NOW(), NOW(), 0),
-- 员工5
('钱七', 'EMP005', @other_receivable_account_id, 'EMPLOYEE',
 '钱七', '13500135225', 'qianqi@company.com', '杭州市西湖区', '市场部员工', 1,
 NOW(), NOW(), 0);

-- 插入 fin_employee 表（通过code关联）
INSERT INTO `fin_employee` (`owner_id`, `employee_no`, `department`, `position`, `hire_date`)
SELECT o.owner_id,
       CASE o.code
           WHEN 'EMP001' THEN 'E2024001'
           WHEN 'EMP002' THEN 'E2024002'
           WHEN 'EMP003' THEN 'E2024003'
           WHEN 'EMP004' THEN 'E2024004'
           WHEN 'EMP005' THEN 'E2024005'
       END AS employee_no,
       CASE o.code
           WHEN 'EMP001' THEN '财务部'
           WHEN 'EMP002' THEN '销售部'
           WHEN 'EMP003' THEN '技术部'
           WHEN 'EMP004' THEN '人事部'
           WHEN 'EMP005' THEN '市场部'
       END AS department,
       CASE o.code
           WHEN 'EMP001' THEN '会计'
           WHEN 'EMP002' THEN '销售经理'
           WHEN 'EMP003' THEN '软件工程师'
           WHEN 'EMP004' THEN '人事专员'
           WHEN 'EMP005' THEN '市场专员'
       END AS position,
       CASE o.code
           WHEN 'EMP001' THEN '2023-01-15'
           WHEN 'EMP002' THEN '2022-06-20'
           WHEN 'EMP003' THEN '2023-03-10'
           WHEN 'EMP004' THEN '2022-09-01'
           WHEN 'EMP005' THEN '2023-05-12'
       END AS hire_date
FROM fin_owner o
WHERE o.owner_type = 'EMPLOYEE'
  AND o.code IN ('EMP001', 'EMP002', 'EMP003', 'EMP004', 'EMP005')
  AND o.is_deleted = 0
  AND NOT EXISTS (SELECT 1 FROM fin_employee e WHERE e.owner_id = o.owner_id);

-- ==========================================
-- 5. 验证数据插入结果
-- ==========================================
SELECT '客户数据' AS '数据类型', COUNT(*) AS '数量' FROM fin_owner WHERE owner_type = 'CUSTOMER' AND is_deleted = 0
UNION ALL
SELECT '供应商数据', COUNT(*) FROM fin_owner WHERE owner_type = 'VENDOR' AND is_deleted = 0
UNION ALL
SELECT '员工数据', COUNT(*) FROM fin_owner WHERE owner_type = 'EMPLOYEE' AND is_deleted = 0;

-- 显示插入的客户列表
SELECT '客户列表' AS '信息';
SELECT o.code AS '客户代码', o.name AS '客户名称', o.contact_name AS '联系人', 
       o.contact_phone AS '联系电话', c.customer_level AS '客户等级', c.credit_limit AS '信用额度'
FROM fin_owner o
LEFT JOIN fin_customer c ON o.owner_id = c.owner_id
WHERE o.owner_type = 'CUSTOMER' AND o.is_deleted = 0
ORDER BY o.code;

-- 显示插入的供应商列表
SELECT '供应商列表' AS '信息';
SELECT o.code AS '供应商代码', o.name AS '供应商名称', o.contact_name AS '联系人',
       o.contact_phone AS '联系电话', v.vendor_type AS '供应商类型', v.payment_terms AS '付款条件'
FROM fin_owner o
LEFT JOIN fin_vendor v ON o.owner_id = v.owner_id
WHERE o.owner_type = 'VENDOR' AND o.is_deleted = 0
ORDER BY o.code;

-- 显示插入的员工列表
SELECT '员工列表' AS '信息';
SELECT e.employee_no AS '员工编号', o.name AS '员工姓名', e.department AS '部门',
       e.position AS '职位', e.hire_date AS '入职日期', o.contact_phone AS '联系电话'
FROM fin_owner o
LEFT JOIN fin_employee e ON o.owner_id = e.owner_id
WHERE o.owner_type = 'EMPLOYEE' AND o.is_deleted = 0
ORDER BY e.employee_no;

