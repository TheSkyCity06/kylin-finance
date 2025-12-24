import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

/**
 * 页面上下文类型
 * 参考 GnuCash 的交互逻辑，不同页面有不同的工具栏状态
 */
export type PageContext = 
  | 'Dashboard'           // 仪表板
  | 'VoucherEditor'      // 凭证编辑器（录入/编辑凭证）
  | 'VoucherQuery'       // 凭证查询
  | 'AccountManagement'  // 科目管理
  | 'Report'             // 报表页面
  | 'Document'           // 单据管理
  | 'Master'             // 基础档案
  | 'Fund'               // 资金管理
  | 'Other'              // 其他页面

export const useContextStore = defineStore('context', () => {
  const currentContext = ref<PageContext>('Dashboard')

  /**
   * 根据路由路径判断页面上下文
   */
  const setContextFromRoute = (path: string) => {
    console.log('[ContextStore] 更新上下文', { path })
    
    if (path === '/' || path === '/dashboard') {
      currentContext.value = 'Dashboard'
    } else if (path.startsWith('/voucher/add') || path.startsWith('/voucher/edit')) {
      currentContext.value = 'VoucherEditor'
    } else if (path.startsWith('/voucher/query') || path.startsWith('/voucher/quick-entry')) {
      currentContext.value = 'VoucherQuery'
    } else if (path.startsWith('/accounts')) {
      currentContext.value = 'AccountManagement'
    } else if (path.startsWith('/reports')) {
      currentContext.value = 'Report'
    } else if (path.startsWith('/document') || path.startsWith('/payment/workflow')) {
      currentContext.value = 'Document'
    } else if (path.startsWith('/master')) {
      currentContext.value = 'Master'
    } else if (path.startsWith('/fund')) {
      currentContext.value = 'Fund'
    } else {
      currentContext.value = 'Other'
    }
    
    console.log('[ContextStore] 上下文已更新为', currentContext.value)
  }

  /**
   * 判断是否在凭证编辑器中
   */
  const isVoucherEditor = computed(() => {
    return currentContext.value === 'VoucherEditor'
  })

  /**
   * 判断是否在仪表板
   */
  const isDashboard = computed(() => {
    return currentContext.value === 'Dashboard'
  })

  /**
   * 判断工具栏的保存/过账/反向按钮是否应该启用
   */
  const canUseVoucherActions = computed(() => {
    return currentContext.value === 'VoucherEditor'
  })

  return {
    currentContext,
    isVoucherEditor,
    isDashboard,
    canUseVoucherActions,
    setContextFromRoute
  }
})

