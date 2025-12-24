# 前端使用指南

## 项目概述

麒麟财务管理系统前端基于 Vue 3 + TypeScript + Element Plus 构建，提供了现代化的财务管理界面。

## 技术架构

- **前端框架**: Vue 3 (Composition API)
- **开发语言**: TypeScript
- **UI组件库**: Element Plus
- **状态管理**: Pinia
- **路由管理**: Vue Router 4
- **HTTP客户端**: Axios
- **构建工具**: Vite
- **代码检查**: ESLint

## 快速启动

### 1. 环境要求

- Node.js 18+
- npm 或 yarn 或 pnpm

### 2. 安装依赖

```bash
# 进入前端目录
cd frontend/kylin-finance-ui

# 安装依赖
npm install
```

### 3. 启动开发服务器

```bash
npm run dev
```

访问地址：`http://localhost:5173`

### 4. 构建生产版本

```bash
npm run build
```

## 页面功能详解

### 1. 仪表板 (Dashboard)

**功能特性：**
- 显示关键财务指标
- 快速操作入口
- 最近凭证概览

**主要组件：**
- 统计卡片：总凭证数、科目总数、总资产、净利润
- 快捷按钮：录入凭证、生成报表等
- 最近凭证列表：显示最新的凭证信息

### 2. 凭证管理

#### 2.1 录入凭证

**操作步骤：**
1. 选择交易日期
2. 输入凭证摘要
3. 添加分录（科目、借贷方向、金额、摘要）
4. 系统自动校验借贷平衡
5. 保存凭证

**关键特性：**
- 实时借贷平衡校验
- 支持多借多贷分录
- 科目下拉选择（支持搜索）
- 自动生成凭证号

#### 2.2 查询凭证

**查询条件：**
- 凭证号
- 日期范围
- 审核状态

**功能特性：**
- 分页显示
- 凭证详情查看
- 凭证修改/删除（草稿状态）
- 凭证审核

### 3. 科目管理

**功能特性：**
- 树形结构展示科目
- 科目增删改查
- 科目代码唯一性验证
- 科目类型管理

**科目类型：**
- 资产类 (ASSET)
- 负债类 (LIABILITY)
- 所有者权益 (EQUITY)
- 收入类 (INCOME)
- 支出类 (EXPENSE)

### 4. 财务报表

#### 4.1 试算平衡表

**功能：**
- 验证会计分录的正确性
- 显示期初余额、本期发生额、期末余额
- 自动计算借贷合计
- 平衡性检查

#### 4.2 资产负债表

**功能：**
- 反映企业财务状况
- 显示资产、负债、所有者权益
- 自动计算各类别合计
- 平衡性验证

#### 4.3 现金流量表

**功能：**
- 显示现金流入流出情况
- 分为经营、投资、筹资活动
- 计算现金净增加额
- 显示期初期末现金余额

## API接口说明

### 基础配置

```typescript
// API基础路径
const BASE_URL = '/api'

// 请求拦截器配置
// 响应拦截器配置
```

### 主要接口

#### 凭证接口
```typescript
// 录入凭证
POST /api/finance/voucher/add

// 查询凭证
POST /api/finance/voucher/query

// 更新凭证
PUT /api/finance/voucher/update

// 删除凭证
DELETE /api/finance/voucher/delete/{id}

// 审核凭证
POST /api/finance/voucher/audit/{id}
```

#### 科目接口
```typescript
// 获取科目树
GET /api/finance/account/tree

// 添加科目
POST /api/finance/account/add

// 更新科目
PUT /api/finance/account/update

// 删除科目
DELETE /api/finance/account/delete/{id}
```

#### 核算接口
```typescript
// 计算科目余额
GET /api/finance/accounting/balance/{accountId}

// 生成试算平衡表
GET /api/finance/accounting/trialBalance
```

#### 报表接口
```typescript
// 生成资产负债表
GET /api/finance/report/balanceSheet

// 生成现金流量表
GET /api/finance/report/cashFlow
```

## 组件开发规范

### 1. 文件命名

```
组件文件: PascalCase (AddVoucher.vue)
工具文件: camelCase (apiClient.ts)
样式文件: kebab-case (account-tree.scss)
```

### 2. 组件结构

```vue
<template>
  <!-- 模板内容 -->
</template>

<script setup lang="ts">
// 导入语句
// 类型定义
// 响应式数据
// 计算属性
// 生命周期钩子
// 方法定义
</script>

<style scoped>
/* 样式定义 */
</style>
```

### 3. TypeScript 类型定义

```typescript
// 接口定义
interface User {
  id: number
  name: string
  email: string
}

// 枚举定义
enum AccountType {
  ASSET = 'ASSET',
  LIABILITY = 'LIABILITY'
}

// API 响应类型
interface ApiResponse<T> {
  code: number
  msg: string
  data: T
}
```

## 样式规范

### 1. CSS 变量

```css
:root {
  --primary-color: #409EFF;
  --success-color: #67C23A;
  --warning-color: #E6A23C;
  --danger-color: #F56C6C;
  --text-primary: #303133;
  --text-regular: #606266;
  --text-secondary: #909399;
}
```

### 2. 响应式设计

```css
/* 移动端适配 */
@media (max-width: 768px) {
  .container {
    padding: 10px;
  }
}

/* 平板适配 */
@media (min-width: 769px) and (max-width: 1024px) {
  .container {
    padding: 15px;
  }
}

/* 桌面端 */
@media (min-width: 1025px) {
  .container {
    padding: 20px;
  }
}
```

## 错误处理

### 1. API 错误处理

```typescript
try {
  const response = await api.call()
  // 处理成功响应
} catch (error) {
  ElMessage.error('操作失败：' + error.message)
}
```

### 2. 表单验证

```typescript
const rules = {
  name: [
    { required: true, message: '请输入名称', trigger: 'blur' },
    { min: 2, max: 20, message: '长度在 2 到 20 个字符', trigger: 'blur' }
  ]
}
```

## 性能优化

### 1. 组件懒加载

```typescript
const routes = [
  {
    path: '/voucher/add',
    component: () => import('@/views/voucher/AddVoucher.vue')
  }
]
```

### 2. 数据缓存

```typescript
// 使用 computed 缓存计算结果
const totalAmount = computed(() => {
  return items.value.reduce((sum, item) => sum + item.amount, 0)
})
```

### 3. 列表虚拟化

对于大量数据的列表，考虑使用虚拟滚动：

```vue
<el-virtualized-list
  :data="largeList"
  :item-size="50"
>
  <template #default="{ item }">
    <div>{{ item.name }}</div>
  </template>
</el-virtualized-list>
```

## 测试策略

### 1. 单元测试

```typescript
// 使用 Vitest 进行单元测试
import { describe, it, expect } from 'vitest'

describe('AccountService', () => {
  it('should calculate balance correctly', () => {
    // 测试逻辑
  })
})
```

### 2. E2E 测试

```typescript
// 使用 Playwright 进行端到端测试
test('should create voucher successfully', async ({ page }) => {
  // 测试流程
})
```

## 部署指南

### 1. Nginx 配置

```nginx
server {
    listen 80;
    server_name finance.example.com;

    location / {
        root /path/to/dist;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2. Docker 部署

```dockerfile
FROM nginx:alpine
COPY dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## 常见问题

### Q: 开发服务器启动失败

A: 检查端口是否被占用，或尝试更换端口：

```bash
npm run dev -- --port 3000
```

### Q: API 请求失败

A: 检查后端服务是否启动，以及代理配置是否正确。

### Q: 样式不生效

A: 确保使用了 scoped 样式，且类名不冲突。

## 更新日志

### v1.0.0 (2024-12-20)

- ✅ 完成基础财务管理功能
- ✅ 实现凭证录入和管理
- ✅ 实现科目树形管理
- ✅ 实现财务报表生成
- ✅ 支持响应式布局

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证。

