# Kylin Finance (麒麟财务管理系统)

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Java](https://img.shields.io/badge/Java-17-orange.svg)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.0-brightgreen.svg)
![Vue](https://img.shields.io/badge/Vue-3.4.19-4FC08D.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1.svg)

一个基于 Spring Boot 和 Vue 3 的企业级财务管理系统，实现了复式记账、凭证管理、报表分析等核心功能。

[功能特性](#功能特性) • [快速开始](#快速开始) • [技术栈](#技术栈) • [项目结构](#项目结构)

</div>

---

## 📖 项目简介

Kylin Finance（麒麟财务管理系统）是一个现代化的财务管理系统，采用前后端分离架构，严格遵循复式记账原则，提供完整的财务管理解决方案。系统支持凭证录入与审核、科目管理、多维度财务报表生成、JWT安全认证等功能，适用于中小企业的日常财务管理需求。

## ✨ 功能特性

### 🔐 安全认证
- JWT Token 身份验证
- 用户登录/登出管理
- 安全的 API 接口保护

### 📝 凭证管理
- **凭证录入**：支持多借多贷分录，实时借贷平衡校验
- **凭证查询**：多条件筛选（日期范围、状态、凭证号等），分页展示
- **凭证审核**：凭证审核流程，确保数据准确性
- **自动编号**：系统自动生成唯一凭证号

### 🌳 科目管理
- **树形结构**：支持无限层级的科目树形管理
- **科目类型**：支持资产、负债、所有者权益、收入、费用五大类科目
- **数据校验**：科目代码唯一性校验，删除前使用情况检查

### 💰 核算功能
- **余额计算**：支持指定日期的科目余额计算
- **试算平衡表**：自动生成试算平衡表，验证会计分录正确性
- **期初期末余额**：自动计算期初余额、本期发生额、期末余额

### 📊 财务报表
- **资产负债表**：自动生成资产负债表，反映企业财务状况
- **现金流量表**：生成现金流量表，分析现金流向
- **报表导出**：支持 Excel 格式导出

### 💼 业务单据管理
- **发票管理**：销售发票录入、查询、核销
- **采购单据**：采购单据管理
- **费用报销**：费用报销申请与审批流程
- **收付款管理**：收付款单据录入与核销

## 🛠 技术栈

### Backend
- **框架**：Spring Boot 3.2.0
- **ORM**：MyBatis-Plus 3.5.7
- **数据库**：MySQL 8.0+
- **Java 版本**：JDK 17
- **构建工具**：Maven 3.6+
- **安全**：JWT Token 认证
- **工具**：Lombok, Jackson

### Frontend
- **框架**：Vue 3.4.19 (Composition API)
- **语言**：TypeScript 5.4.0
- **UI 组件库**：Element Plus 2.7.1
- **状态管理**：Pinia 2.1.7
- **路由**：Vue Router 4.3.0
- **HTTP 客户端**：Axios 1.6.7
- **构建工具**：Vite 5.2.8
- **代码规范**：ESLint, Prettier

### Tools
- **开发工具**：Cursor, IntelliJ IDEA
- **版本控制**：Git
- **数据库管理**：MySQL Workbench

## 📁 项目结构

```
kylin-finance/
├── admin/                    # 用户权限管理模块
│   ├── controller/          # 控制器层
│   ├── service/             # 服务层
│   ├── mapper/              # 数据访问层
│   └── entity/              # 实体类
├── application/              # 应用启动模块
│   └── src/main/resources/
│       └── application.yml  # 应用配置文件
├── common/                   # 公共模块
│   ├── entity/              # 实体基类
│   └── util/                # 工具类
├── finance/                  # 财务核心模块
│   ├── controller/          # 财务控制器
│   ├── service/             # 业务逻辑层
│   ├── mapper/              # MyBatis Mapper
│   ├── entity/              # 财务实体类
│   └── dto/                 # 数据传输对象
├── frontend/                 # 前端项目
│   └── kylin-finance-ui/    # Vue 3 前端应用
│       ├── src/
│       │   ├── api/         # API 接口封装
│       │   ├── components/  # 公共组件
│       │   ├── router/      # 路由配置
│       │   ├── stores/      # Pinia 状态管理
│       │   ├── views/       # 页面组件
│       │   └── utils/       # 工具函数
│       └── package.json
├── database/                 # 数据库脚本
│   ├── schema/              # 数据库表结构脚本
│   │   ├── init.sql        # 主初始化脚本（核心财务表）
│   │   ├── rbac_tables.sql # RBAC权限管理表
│   │   └── *.sql           # 其他业务表脚本
│   ├── scripts/            # 数据库维护脚本
│   └── seeds/              # 测试数据和种子数据
├── docs/                     # 项目文档
├── pom.xml                   # Maven 父 POM
└── README.md                 # 项目说明文档
```

## 🚀 快速开始

### 环境要求

在开始之前，请确保您的开发环境已安装以下软件：

- **JDK**：17 或更高版本
- **Maven**：3.6 或更高版本
- **Node.js**：18 或更高版本
- **MySQL**：8.0 或更高版本
- **npm/yarn/pnpm**：Node.js 包管理器

### 1. 克隆项目

```bash
git clone https://github.com/your-username/kylin-finance.git
cd kylin-finance
```

### 2. 数据库初始化

#### 2.1 创建数据库

```sql
CREATE DATABASE kylin_finance DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 2.2 执行初始化脚本

```bash
# 导入核心财务表（必需）
mysql -u root -p kylin_finance < database/schema/init.sql

# 根据需要导入可选模块
mysql -u root -p kylin_finance < database/schema/rbac_tables.sql
mysql -u root -p kylin_finance < database/schema/biz_expense_claim.sql
mysql -u root -p kylin_finance < database/schema/biz_receipt_payment.sql
```

或者使用 MySQL Workbench 等工具导入 `database/schema/init.sql` 文件。

**注意：** 数据库脚本已重新组织，详细说明请参考 [部署文档](docs/DEPLOYMENT_UPDATES.md)。

### 3. 后端配置与启动

#### 3.1 配置数据库连接

编辑 `application/src/main/resources/application.yml` 文件，修改数据库连接信息：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/kylin_finance?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true
    username: root          # 修改为您的数据库用户名
    password: your_password # 修改为您的数据库密码
```

#### 3.2 编译并启动后端

```bash
# 编译项目
mvn clean install

# 启动后端服务
cd application
mvn spring-boot:run
```

后端服务启动成功后，访问地址：`http://localhost:8080`

### 4. 前端配置与启动

#### 4.1 安装依赖

```bash
cd frontend/kylin-finance-ui
npm install
```

#### 4.2 启动前端开发服务器

```bash
npm run dev
```

前端服务启动成功后，访问地址：`http://localhost:5173`

### 5. 访问系统

- **前端界面**：http://localhost:5173
- **后端 API**：http://localhost:8080
- **API 文档**：http://localhost:8080/swagger-ui.html（如果已配置 Swagger）

## 📸 项目截图

<!-- 请在此处添加项目截图 -->
<!-- 
![仪表板](docs/screenshots/dashboard.png)
![凭证录入](docs/screenshots/voucher-entry.png)
![财务报表](docs/screenshots/reports.png)
-->

## 🔧 开发指南

### 后端开发

```bash
# 编译项目
mvn clean compile

# 运行测试
mvn test

# 打包项目
mvn clean package -DskipTests
```

### 前端开发

```bash
# 进入前端目录
cd frontend/kylin-finance-ui

# 启动开发服务器
npm run dev

# 类型检查
npm run type-check

# 代码检查与修复
npm run lint

# 构建生产版本
npm run build

# 预览生产版本
npm run preview
```

## 📚 核心设计理念

### 1. 复式记账法

系统严格遵循复式记账原则：
- 每笔交易必须至少包含一借一贷
- 借方金额总和必须等于贷方金额总和
- 系统自动校验借贷平衡，确保数据准确性

### 2. 科目类型与余额计算

- **资产类、费用类**：余额 = 借方 - 贷方（余额在借方）
- **负债类、权益类、收入类**：余额 = 贷方 - 借方（余额在贷方）

### 3. 会计恒等式

```
资产 + 费用 = 负债 + 所有者权益 + 收入
```

### 4. 凭证状态管理

- **0 - 草稿**：可以修改、删除
- **1 - 已审核**：不能修改、删除，参与核算和报表计算

## 📖 API 文档

### 凭证管理

- `POST /finance/voucher/add` - 录入凭证
- `POST /finance/voucher/query` - 查询凭证（分页）
- `PUT /finance/voucher/update` - 更新凭证
- `DELETE /finance/voucher/delete/{transId}` - 删除凭证
- `POST /finance/voucher/audit/{transId}` - 审核凭证

### 科目管理

- `GET /finance/account/tree` - 获取科目树
- `POST /finance/account/add` - 添加科目
- `PUT /finance/account/update` - 更新科目
- `DELETE /finance/account/delete/{accountId}` - 删除科目

### 核算功能

- `GET /finance/accounting/balance/{accountId}` - 计算科目余额
- `GET /finance/accounting/trialBalance` - 生成试算平衡表

### 财务报表

- `GET /finance/report/balanceSheet` - 生成资产负债表
- `GET /finance/report/cashFlow` - 生成现金流量表

详细的 API 文档请参考 [API 示例文档](docs/API_EXAMPLES.md)。

## 📚 文档与指南 (Documentation)

项目提供了详细的文档和指南，帮助您更好地理解和使用系统：

- [前端开发指南](./docs/frontend-guide.md) - Vue 3 前端开发完整指南，包含组件开发规范、API 接口说明、性能优化等
- [RBAC 权限模块说明](./docs/rbac-module.md) - 基于 RBAC 的权限管理系统使用指南，包含 JWT 认证、权限校验等
- [GnuCash 集成文档](./docs/gnucash-integration.md) - GnuCash 风格商业单据流转逻辑实现说明
- [API 示例文档](./docs/API_EXAMPLES.md) - API 接口使用示例
- [部署文档](./docs/DEPLOYMENT_MANUAL.md) - 生产环境部署指南
- [安全加固指南](./docs/SECURITY_HARDENING.md) - 系统安全配置建议

## 🤝 贡献指南

我们欢迎所有形式的贡献！如果您想为项目做出贡献，请遵循以下步骤：

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📝 许可证

本项目采用 [MIT License](LICENSE) 许可证。

## 🙏 致谢

感谢所有为本项目做出贡献的开发者和用户！

## 📮 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [Issue](https://github.com/your-username/kylin-finance/issues)
- 发送邮件至：your-email@example.com

---

<div align="center">

**如果这个项目对您有帮助，请给我们一个 ⭐ Star！**

Made with ❤️ by Kylin Finance Team

</div>
