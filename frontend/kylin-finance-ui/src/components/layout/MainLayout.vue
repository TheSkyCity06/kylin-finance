<template>
  <div class="gnucash-layout">
    <!-- 左侧菜单 -->
    <div class="left-menu">
      <SideMenu />
    </div>

    <!-- 左侧科目树 -->
    <div class="left-sidebar">
      <AccountTree />
    </div>

    <!-- 右侧主内容区 -->
    <div class="main-content">
      <!-- Tab 栏 -->
      <TabBar />

      <!-- 工具栏 -->
      <Toolbar />

      <!-- Tab 内容视图 -->
      <TabView />
    </div>
  </div>
</template>

<script setup lang="ts">
import SideMenu from './SideMenu.vue'
import AccountTree from './AccountTree.vue'
import TabBar from './TabBar.vue'
import Toolbar from './Toolbar.vue'
import TabView from './TabView.vue'
import { onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useTabStore } from '@/stores/tabStore'
import { useContextStore } from '@/stores/contextStore'

const router = useRouter()
const route = useRoute()
const tabStore = useTabStore()
const contextStore = useContextStore()

// 路由变化时自动添加 Tab 并更新上下文
onMounted(() => {
  // 初始化当前路由的上下文
  contextStore.setContextFromRoute(route.path)
  
  // 初始化当前路由的 Tab
  addTabForRoute(route)

  // 监听路由变化
  router.afterEach((to) => {
    // 更新上下文
    contextStore.setContextFromRoute(to.path)
    // 添加 Tab
    addTabForRoute(to)
  })
})

// 根据路由添加 Tab
const addTabForRoute = (route: any) => {
  // Dashboard 不需要 Tab，直接显示
  if (route.path === '/' || route.path === '/dashboard') {
    // 清除所有 Tab，显示 Dashboard
    if (tabStore.tabs.length > 0) {
      tabStore.closeAll()
    }
    return
  }

  const routeMap: Record<string, { title: string; component?: string }> = {
    '/voucher/add': { title: '录入凭证', component: 'AddVoucher' },
    '/voucher/query': { title: '查询凭证', component: 'QueryVoucher' },
    '/voucher/quick-entry': { title: '快捷录入', component: 'QuickEntryRegister' },
    '/accounts': { title: '科目管理', component: 'AccountManagement' },
    '/master/customer': { title: '客户列表', component: 'CustomerList' },
    '/master/vendor': { title: '供应商列表', component: 'VendorList' },
    '/master/employee': { title: '员工管理', component: 'EmployeeList' },
    '/document/invoice-list': { title: '销售发票', component: 'InvoiceList' },
    '/document/bill-list': { title: '采购账单', component: 'BillList' },
    '/document/manage': { title: '单据管理', component: 'BusinessDocumentManager' },
    '/payment/workflow': { title: '支付核销', component: 'PaymentWorkflow' },
    '/fund/payment': { title: '收付款单', component: 'PaymentList' },
    '/fund/expense': { title: '报销单管理', component: 'ExpenseClaimList' },
    '/reports/trial-balance': { title: '试算平衡表', component: 'TrialBalance' },
    '/reports/balance-sheet': { title: '资产负债表', component: 'BalanceSheet' },
    '/reports/cash-flow': { title: '现金流量表', component: 'CashFlow' }
  }

  const routeInfo = routeMap[route.path]
  if (routeInfo) {
    tabStore.addTab({
      id: `tab-${route.path}`,
      title: routeInfo.title,
      path: route.path,
      component: routeInfo.component,
      closable: true
    })
  }
}
</script>

<style scoped lang="scss">
.gnucash-layout {
  display: flex;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
  background-color: #f5f5f5;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  font-size: 12px;

  .left-menu {
    width: 160px;
    flex-shrink: 0;
    background-color: #f5f5f5;
    border-right: 1px solid #d0d0d0;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    position: relative;
    z-index: 10;
  }

  .left-sidebar {
    width: 280px;
    min-width: 200px;
    max-width: 400px;
    flex-shrink: 0;
    background-color: #f5f5f5;
    border-right: 1px solid #d0d0d0;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    position: relative;
    z-index: 10;
  }

  .main-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    background-color: #fff;
    position: relative;
  }
}

// 全局紧凑样式
:deep(.el-button) {
  font-size: 11px;
  padding: 4px 10px;
  height: 24px;
}

:deep(.el-input__inner) {
  font-size: 11px;
  height: 24px;
}

:deep(.el-table) {
  font-size: 11px;

  th {
    padding: 6px 8px;
    font-weight: 500;
  }

  td {
    padding: 4px 8px;
  }
}

:deep(.el-card) {
  .el-card__header {
    padding: 8px 12px;
    font-size: 12px;
  }

  .el-card__body {
    padding: 12px;
  }
}
</style>
