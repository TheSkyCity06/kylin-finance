# 部署文档更新说明

## 📅 更新日期
2024-12-20

## 🔄 主要更新内容

### 1. 数据库脚本目录结构重组

**变更前：**
- 所有数据库脚本位于 `database/` 根目录
- 初始化脚本：`database/init.sql`

**变更后：**
- 数据库脚本已按功能模块重新组织：
  ```
  database/
  ├── schema/                    # 数据库表结构脚本
  │   ├── init.sql              # 主初始化脚本（核心财务表，必需）
  │   ├── rbac_tables.sql       # RBAC权限管理表（可选）
  │   ├── biz_expense_claim.sql # 费用报销业务表（可选）
  │   └── biz_receipt_payment.sql # 收付款业务表（可选）
  ├── scripts/                  # 数据库维护脚本
  │   ├── fix_password_field.sql
  │   └── test_idempotent.sql
  └── seeds/                     # 测试数据和种子数据（仅开发/测试环境）
      ├── mock_data.sql
      ├── voucher_mock_data.sql
      └── ...
  ```

### 2. Docker Compose 配置更新

**变更内容：**
- `docker-compose.yml` 中的数据库初始化脚本路径已更新：
  ```yaml
  # 变更前
  - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
  
  # 变更后
  - ./database/schema/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
  ```

### 3. 文档更新清单

以下文档已更新以反映新的数据库目录结构：

#### ✅ 已更新文档

1. **`docs/DEPLOYMENT_MANUAL.md`** - 部署操作手册
   - ✅ 更新数据库初始化脚本路径
   - ✅ 添加数据库目录结构说明
   - ✅ 添加可选模块导入说明
   - ✅ 更新所有相关命令示例

2. **`docs/DEPLOYMENT_README.md`** - 部署文档总览
   - ✅ 添加数据库脚本目录结构说明

3. **`docker-compose.yml`** - Docker Compose 配置
   - ✅ 更新数据库初始化脚本路径

#### 📝 需要手动检查的文档

以下文档可能包含旧的路径引用，建议检查：

1. **`README.md`** - 项目主 README
   - 检查快速开始部分的数据库初始化命令

2. **`start.sh`** / **`start.bat`** - 启动脚本
   - 检查数据库脚本路径引用

3. **其他项目文档**
   - 检查是否有其他文档引用了旧的数据库路径

## 🚀 迁移指南

### 对于新部署

直接使用新的目录结构，按照更新后的文档操作即可。

### 对于已有部署

如果您的项目已经部署，且使用了旧的数据库脚本路径：

1. **无需迁移数据库数据**
   - 数据库表结构不受影响
   - 只需更新部署脚本和文档中的路径引用

2. **更新部署脚本**
   - 检查并更新所有引用 `database/init.sql` 的脚本
   - 更新为 `database/schema/init.sql`

3. **更新 Docker 配置**
   - 如果使用 Docker 部署，更新 `docker-compose.yml` 中的路径

## 📋 数据库初始化最佳实践

### 生产环境

```bash
# 1. 导入核心财务表（必需）
mysql -u kylin_app -p kylin_finance < database/schema/init.sql

# 2. 根据需要导入可选模块
mysql -u kylin_app -p kylin_finance < database/schema/rbac_tables.sql
mysql -u kylin_app -p kylin_finance < database/schema/biz_expense_claim.sql
mysql -u kylin_app -p kylin_finance < database/schema/biz_receipt_payment.sql
```

### 开发/测试环境

```bash
# 1. 导入核心表
mysql -u kylin_app -p kylin_finance < database/schema/init.sql

# 2. 导入所有业务表
mysql -u kylin_app -p kylin_finance < database/schema/rbac_tables.sql
mysql -u kylin_app -p kylin_finance < database/schema/biz_expense_claim.sql
mysql -u kylin_app -p kylin_finance < database/schema/biz_receipt_payment.sql

# 3. 导入测试数据（可选）
mysql -u kylin_app -p kylin_finance < database/seeds/mock_data.sql
```

## ⚠️ 注意事项

1. **Docker 部署**
   - `docker-compose.yml` 已自动配置导入 `database/schema/init.sql`
   - 如需导入其他模块，需要手动执行或修改 Docker 配置

2. **脚本执行顺序**
   - 必须先执行 `init.sql`（核心表）
   - 其他脚本可以按需执行，顺序不限

3. **向后兼容**
   - 如果您的代码中硬编码了旧的路径，需要更新
   - 建议使用相对路径或环境变量配置

## 🔍 验证更新

更新后，请验证以下内容：

- [ ] Docker Compose 可以正常启动并初始化数据库
- [ ] 手动部署时，数据库初始化脚本可以正常执行
- [ ] 所有文档中的路径引用已更新
- [ ] 部署脚本中的路径引用已更新

## 📞 问题反馈

如果发现文档或配置有遗漏或错误，请：
1. 提交 Issue
2. 或直接修改并提交 Pull Request

---

**更新完成时间：** 2024-12-20  
**更新人员：** DevOps Team

