# 麒麟财务管理系统前端

基于 Vue 3 + TypeScript + Element Plus 的现代化财务管理系统前端。

## 功能特性

- 🎨 现代化UI设计，响应式布局
- 📊 财务仪表板，数据可视化
- 📝 凭证录入和管理
- 🔍 凭证查询和筛选
- 🌳 科目树形管理
- 📈 财务报表生成
- 💰 试算平衡表
- 💼 资产负债表
- 💵 现金流量表

## 技术栈

- **Vue 3**: 渐进式JavaScript框架
- **TypeScript**: 类型安全的JavaScript超集
- **Element Plus**: Vue 3企业级UI组件库
- **Vue Router**: 官方路由管理器
- **Pinia**: Vue状态管理库
- **Axios**: HTTP客户端
- **Vite**: 下一代前端构建工具

## 快速开始

### 安装依赖

```bash
cd frontend/kylin-finance-ui
npm install
```

### 开发环境运行

```bash
npm run dev
```

### 构建生产版本

```bash
npm run build
```

### 预览生产版本

```bash
npm run preview
```

## 项目结构

```
src/
├── api/              # API接口封装
├── router/           # 路由配置
├── types/            # TypeScript类型定义
├── views/            # 页面组件
│   ├── voucher/      # 凭证管理页面
│   ├── accounts/     # 科目管理页面
│   └── reports/      # 财务报表页面
├── App.vue           # 根组件
└── main.ts           # 入口文件
```

## 主要页面

### 仪表板 (Dashboard)
- 财务数据概览
- 快捷操作入口
- 最近凭证展示

### 凭证管理
- **录入凭证**: 支持多借多贷，实时借贷平衡校验
- **查询凭证**: 条件筛选、分页展示、详情查看

### 科目管理
- 树形结构展示科目
- 科目增删改查
- 科目类型管理

### 财务报表
- **试算平衡表**: 验证会计分录正确性
- **资产负债表**: 反映财务状况
- **现金流量表**: 反映现金流向

## API接口

前端通过RESTful API与后端通信：

- 凭证管理: `/api/finance/voucher/*`
- 科目管理: `/api/finance/account/*`
- 核算功能: `/api/finance/accounting/*`
- 财务报表: `/api/finance/report/*`

## 开发规范

### 命名规范
- 组件: PascalCase (如 `AddVoucher.vue`)
- 文件: kebab-case (如 `account-management.vue`)
- 变量: camelCase

### 代码风格
- 使用ESLint进行代码检查
- 使用Prettier进行代码格式化
- 遵循Vue 3 Composition API最佳实践

### 提交规范
- feat: 新功能
- fix: 修复bug
- docs: 文档更新
- style: 代码格式调整
- refactor: 代码重构

## 浏览器支持

- Chrome 70+
- Firefox 70+
- Safari 12+
- Edge 79+

## 许可证

MIT License
