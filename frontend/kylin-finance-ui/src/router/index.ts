import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/Login.vue'),
      meta: { 
        requiresAuth: false,
        hidden: true  // 标记为隐藏路由，不使用主布局
      }
    },
    {
      path: '/',
      redirect: '/dashboard'
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('@/views/Dashboard.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/voucher/add',
      name: 'voucher-add',
      component: () => import('@/views/voucher/AddVoucher.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/voucher/query',
      name: 'voucher-query',
      component: () => import('@/views/voucher/QueryVoucher.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/accounts',
      name: 'accounts',
      component: () => import('@/views/accounts/AccountManagement.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/reports/trial-balance',
      name: 'trial-balance',
      component: () => import('@/views/reports/TrialBalance.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/reports/balance-sheet',
      name: 'balance-sheet',
      component: () => import('@/views/reports/BalanceSheet.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/reports/cash-flow',
      name: 'cash-flow',
      component: () => import('@/views/reports/CashFlow.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/voucher/quick-entry',
      name: 'quick-entry',
      component: () => import('@/views/voucher/QuickEntryRegister.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/invoice',
      name: 'business-document',
      component: () => import('@/views/document/BusinessDocumentManager.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/payment/workflow',
      name: 'payment-workflow',
      component: () => import('@/views/payment/PaymentWorkflow.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/master/customer',
      name: 'customer-list',
      component: () => import('@/views/master/CustomerList.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/master/vendor',
      name: 'vendor-list',
      component: () => import('@/views/master/VendorList.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/master/employee',
      name: 'employee-list',
      component: () => import('@/views/master/EmployeeList.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/invoice-list',
      name: 'invoice-list',
      component: () => import('@/views/document/InvoiceList.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/invoice/:id',
      name: 'invoice-detail',
      component: () => import('@/views/document/AddInvoice.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/invoice/add',
      name: 'invoice-add',
      component: () => import('@/views/document/AddInvoice.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/bill-list',
      name: 'bill-list',
      component: () => import('@/views/document/BillList.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/bill/:id',
      name: 'bill-detail',
      component: () => import('@/views/document/AddBill.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/bill/add',
      name: 'bill-add',
      component: () => import('@/views/document/AddBill.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/document/manage',
      name: 'document-manage',
      component: () => import('@/views/document/BusinessDocumentManager.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/fund/payment',
      name: 'payment-list',
      component: () => import('@/views/fund/PaymentList.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/fund/expense',
      name: 'expense-claim-list',
      component: () => import('@/views/fund/ExpenseClaimList.vue'),
      meta: { requiresAuth: true }
    }
  ]
})

// 白名单路由（不需要登录即可访问）
const whiteList = ['/login']

// 全局前置守卫
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  // 检查是否已登录（从 localStorage 和 store 中检查 token）
  const isAuthenticated = authStore.isAuthenticated()
  
  // 情况1：如果访问的是登录页
  if (to.path === '/login') {
    // 如果已登录，重定向到首页（避免已登录用户再次看到登录页）
    if (isAuthenticated) {
      next('/dashboard')
      return
    }
    // 如果未登录，允许访问登录页
    next()
    return
  }
  
  // 情况2：如果访问的是白名单路由，直接放行
  if (whiteList.includes(to.path)) {
    next()
    return
  }
  
  // 情况3：如果需要认证但未登录，跳转到登录页
  if (to.meta.requiresAuth && !isAuthenticated) {
    next({
      path: '/login',
      query: { redirect: to.fullPath } // 保存原始路径，登录后可以跳转回去
    })
    return
  }
  
  // 情况4：其他情况正常放行（已登录用户访问需要认证的页面）
  next()
})

export default router
