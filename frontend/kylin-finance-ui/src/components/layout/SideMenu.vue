<template>
  <div class="side-menu">
    <div class="menu-header">
      <h3>麒麟财务</h3>
      <!-- 用户信息和登出按钮 -->
      <div class="user-section">
        <el-dropdown @command="handleUserCommand" trigger="click">
          <div class="user-info">
            <el-icon class="user-icon"><UserFilled /></el-icon>
            <span class="username">{{ username || '用户' }}</span>
            <el-icon class="dropdown-icon"><ArrowDown /></el-icon>
          </div>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="logout" divided>
                <el-icon><SwitchButton /></el-icon>
                <span style="margin-left: 8px">退出登录</span>
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </div>
    <el-menu
      :default-active="activeMenu"
      class="menu"
      @select="handleMenuSelect"
      mode="vertical"
    >
      <el-menu-item index="/dashboard">
        <el-icon><House /></el-icon>
        <span>仪表板</span>
      </el-menu-item>

      <el-sub-menu index="voucher">
        <template #title>
          <el-icon><Document /></el-icon>
          <span>凭证管理</span>
        </template>
        <el-menu-item index="/voucher/add">录入凭证</el-menu-item>
        <el-menu-item index="/voucher/query">查询凭证</el-menu-item>
        <el-menu-item index="/voucher/quick-entry">快捷录入</el-menu-item>
      </el-sub-menu>

      <el-menu-item index="/accounts">
        <el-icon><List /></el-icon>
        <span>科目管理</span>
      </el-menu-item>

      <el-sub-menu index="master">
        <template #title>
          <el-icon><UserFilled /></el-icon>
          <span>基础档案</span>
        </template>
        <el-menu-item index="/master/customer">客户列表</el-menu-item>
        <el-menu-item index="/master/vendor">供应商列表</el-menu-item>
        <el-menu-item index="/master/employee">员工管理</el-menu-item>
      </el-sub-menu>

      <el-sub-menu index="document">
        <template #title>
          <el-icon><Files /></el-icon>
          <span>商业单据</span>
        </template>
        <el-menu-item index="/document/invoice-list">销售发票</el-menu-item>
        <el-menu-item index="/document/bill-list">采购账单</el-menu-item>
        <el-menu-item index="/document/manage">单据管理</el-menu-item>
        <el-menu-item index="/payment/workflow">支付核销</el-menu-item>
      </el-sub-menu>

      <el-sub-menu index="fund">
        <template #title>
          <el-icon><Money /></el-icon>
          <span>资金管理</span>
        </template>
        <el-menu-item index="/fund/payment">收付款单</el-menu-item>
        <el-menu-item index="/fund/expense">报销单管理</el-menu-item>
      </el-sub-menu>

      <el-sub-menu index="reports">
        <template #title>
          <el-icon><TrendCharts /></el-icon>
          <span>财务报表</span>
        </template>
        <el-menu-item index="/reports/trial-balance">试算平衡表</el-menu-item>
        <el-menu-item index="/reports/balance-sheet">资产负债表</el-menu-item>
        <el-menu-item index="/reports/cash-flow">现金流量表</el-menu-item>
      </el-sub-menu>
    </el-menu>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useTabStore } from '@/stores/tabStore'
import { useAuthStore } from '@/stores/authStore'
import {
  House,
  Document,
  List,
  TrendCharts,
  Files,
  UserFilled,
  Money,
  ArrowDown,
  SwitchButton
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const tabStore = useTabStore()
const authStore = useAuthStore()

const activeMenu = computed(() => route.path)
const username = ref<string>('')

// 从 localStorage 获取记住的用户名
onMounted(() => {
  const rememberedUsername = localStorage.getItem('rememberedUsername')
  if (rememberedUsername) {
    username.value = rememberedUsername
  } else {
    // 如果没有记住的用户名，尝试从 token 中解析（这里简化处理，实际可以从用户信息接口获取）
    username.value = '用户'
  }
})

// 处理用户下拉菜单命令
const handleUserCommand = async (command: string) => {
  if (command === 'logout') {
    try {
      await ElMessageBox.confirm(
        '确定要退出登录吗？',
        '提示',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )
      
      // 执行登出
      authStore.logout()
      
      // 清除所有 Tab
      tabStore.closeAll()
      
      // 跳转到登录页
      router.push('/login')
      
      ElMessage.success('已退出登录')
    } catch {
      // 用户取消，不做任何操作
    }
  }
}

const handleMenuSelect = (index: string) => {
  const routeMap: Record<string, { title: string; component?: string }> = {
    '/dashboard': { title: '仪表板' },
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

  const routeInfo = routeMap[index]
  if (routeInfo) {
    tabStore.addTab({
      id: `tab-${index}`,
      title: routeInfo.title,
      path: index,
      component: routeInfo.component,
      closable: true
    })
  }

  router.push(index)
}
</script>

<style scoped lang="scss">
.side-menu {
  background-color: #f5f5f5;
  border-right: 1px solid #d0d0d0;
  height: 100%;
  display: flex;
  flex-direction: column;

  .menu-header {
    padding: 8px 12px;
    background-color: #e8e8e8;
    border-bottom: 1px solid #d0d0d0;
    text-align: center;

    h3 {
      margin: 0 0 8px 0;
      font-size: 13px;
      font-weight: 600;
      color: #333;
    }

    .user-section {
      margin-top: 8px;
      padding-top: 8px;
      border-top: 1px solid #d0d0d0;

      .user-info {
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 4px 8px;
        cursor: pointer;
        border-radius: 4px;
        transition: background-color 0.2s;
        font-size: 11px;
        color: #333;

        &:hover {
          background-color: #d0d0d0;
        }

        .user-icon {
          font-size: 14px;
          margin-right: 4px;
          color: #409eff;
        }

        .username {
          flex: 1;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
          max-width: 80px;
        }

        .dropdown-icon {
          font-size: 10px;
          margin-left: 4px;
          color: #909399;
        }
      }
    }
  }

  .menu {
    flex: 1;
    border-right: none;
    background-color: #f5f5f5;
    font-size: 11px;

    :deep(.el-menu-item),
    :deep(.el-sub-menu__title) {
      height: 32px;
      line-height: 32px;
      padding-left: 12px !important;
      font-size: 11px;
      color: #333;

      &:hover {
        background-color: #e8e8e8;
      }
    }

    :deep(.el-menu-item.is-active) {
      background-color: #e0f0ff;
      color: #409eff;
    }

    :deep(.el-icon) {
      font-size: 14px;
      margin-right: 6px;
    }
  }
}
</style>
