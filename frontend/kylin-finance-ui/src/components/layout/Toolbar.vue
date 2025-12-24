<template>
  <div class="toolbar">
    <div class="toolbar-group">
      <el-button
        size="small"
        :icon="DocumentAdd"
        @click="handleSave"
        title="保存 (Ctrl+S)"
        :disabled="!contextStore.canUseVoucherActions"
      >
        保存
      </el-button>
      <el-button
        size="small"
        :icon="Check"
        @click="handlePost"
        title="过账"
        :disabled="!contextStore.canUseVoucherActions || !hasSelection"
      >
        过账
      </el-button>
      <el-button
        size="small"
        :icon="RefreshLeft"
        @click="handleReverse"
        title="反向凭证"
        :disabled="!contextStore.canUseVoucherActions"
      >
        反向
      </el-button>
    </div>

    <div class="toolbar-group">
      <el-button
        size="small"
        :icon="Calendar"
        @click="handleGoToToday"
        title="跳至今日"
      >
        今日
      </el-button>
      <el-button
        size="small"
        :icon="Search"
        @click="handleSearch"
        title="搜索"
      >
        搜索
      </el-button>
    </div>

    <div class="toolbar-group">
      <el-button
        size="small"
        :icon="Printer"
        @click="handlePrint"
        title="打印"
        :disabled="!hasSelection"
      >
        打印
      </el-button>
      <el-button
        size="small"
        :icon="Setting"
        @click="handleSettings"
        title="设置"
      >
        设置
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  DocumentAdd,
  Check,
  RefreshLeft,
  Calendar,
  Search,
  Printer,
  Setting
} from '@element-plus/icons-vue'
import { useTabStore } from '@/stores/tabStore'
import { useContextStore } from '@/stores/contextStore'

const tabStore = useTabStore()
const contextStore = useContextStore()
const hasSelection = ref(false) // 是否有选中的项目（凭证、发票等）

// 保存
const handleSave = (event?: MouseEvent) => {
  console.log('[Toolbar] 保存按钮被点击', { 
    event, 
    activeTab: tabStore.activeTab, 
    activeTabId: tabStore.activeTabId,
    canUseVoucherActions: contextStore.canUseVoucherActions,
    currentContext: contextStore.currentContext
  })
  
  // 检查是否在凭证编辑器中
  if (!contextStore.canUseVoucherActions) {
    console.warn('[Toolbar] 当前不在凭证编辑器，无法保存')
    ElMessage.warning('请在凭证编辑页面使用此功能')
    return
  }
  
  // 触发当前 Tab 的保存事件
  const activeTab = tabStore.activeTab
  if (activeTab) {
    console.log('[Toolbar] 分发 toolbar-save 事件', { tabId: activeTab.id, path: activeTab.path })
    window.dispatchEvent(new CustomEvent('toolbar-save', { detail: { tabId: activeTab.id, path: activeTab.path } }))
  } else {
    console.warn('[Toolbar] 没有激活的 Tab，无法保存')
    ElMessage.warning('请先打开需要保存的页面')
  }
}

// 过账
const handlePost = (event?: MouseEvent) => {
  console.log('[Toolbar] 过账按钮被点击', { 
    event, 
    hasSelection: hasSelection.value, 
    activeTabId: tabStore.activeTabId,
    canUseVoucherActions: contextStore.canUseVoucherActions,
    currentContext: contextStore.currentContext
  })
  
  // 检查是否在凭证编辑器中
  if (!contextStore.canUseVoucherActions) {
    console.warn('[Toolbar] 当前不在凭证编辑器，无法过账')
    ElMessage.warning('请在凭证编辑页面使用此功能')
    return
  }
  
  if (!hasSelection.value) {
    ElMessage.warning('请先选择要过账的项目')
    return
  }
  
  const activeTab = tabStore.activeTab
  if (activeTab) {
    console.log('[Toolbar] 分发 toolbar-post 事件', { tabId: activeTab.id })
    window.dispatchEvent(new CustomEvent('toolbar-post', { detail: { tabId: activeTab.id, path: activeTab.path } }))
  } else {
    console.warn('[Toolbar] 没有激活的 Tab，无法过账')
    ElMessage.warning('请先打开需要过账的页面')
  }
}

// 反向凭证
const handleReverse = (event?: MouseEvent) => {
  console.log('[Toolbar] 反向按钮被点击', { 
    event, 
    activeTabId: tabStore.activeTabId,
    canUseVoucherActions: contextStore.canUseVoucherActions,
    currentContext: contextStore.currentContext
  })
  
  // 检查是否在凭证编辑器中
  if (!contextStore.canUseVoucherActions) {
    console.warn('[Toolbar] 当前不在凭证编辑器，无法反向')
    ElMessage.warning('请在凭证编辑页面使用此功能')
    return
  }
  
  const activeTab = tabStore.activeTab
  if (activeTab) {
    console.log('[Toolbar] 分发 toolbar-reverse 事件', { tabId: activeTab.id })
    window.dispatchEvent(new CustomEvent('toolbar-reverse', { detail: { tabId: activeTab.id, path: activeTab.path } }))
  } else {
    console.warn('[Toolbar] 没有激活的 Tab，无法反向')
    ElMessage.warning('请先打开需要反向的页面')
  }
}

// 跳至今日
const handleGoToToday = (event?: MouseEvent) => {
  console.log('[Toolbar] 今日按钮被点击', { event })
  window.dispatchEvent(new CustomEvent('toolbar-goto-today'))
}

// 搜索
const handleSearch = (event?: MouseEvent) => {
  console.log('[Toolbar] 搜索按钮被点击', { event })
  window.dispatchEvent(new CustomEvent('toolbar-search'))
}

// 打印
const handlePrint = (event?: MouseEvent) => {
  console.log('[Toolbar] 打印按钮被点击', { event, hasSelection: hasSelection.value, activeTabId: tabStore.activeTabId })
  
  if (!hasSelection.value) {
    ElMessage.warning('请先选择要打印的项目')
    return
  }
  
  const activeTab = tabStore.activeTab
  if (activeTab) {
    console.log('[Toolbar] 分发 toolbar-print 事件', { tabId: activeTab.id })
    window.dispatchEvent(new CustomEvent('toolbar-print', { detail: { tabId: activeTab.id, path: activeTab.path } }))
  } else {
    console.warn('[Toolbar] 没有激活的 Tab，无法打印')
    ElMessage.warning('请先打开需要打印的页面')
  }
}

// 监听选中变化事件（支持多种事件类型）
const handleSelectionChange = (event: CustomEvent) => {
  const selectedCount = event.detail?.selectedCount || 0
  const previousValue = hasSelection.value
  hasSelection.value = selectedCount > 0
  console.log('[Toolbar] 选中状态变化', { 
    eventType: event.type, 
    selectedCount, 
    hasSelection: hasSelection.value,
    previousValue,
    detail: event.detail 
  })
}

onMounted(() => {
  // 监听多种选中变化事件
  window.addEventListener('invoice-selection-change', handleSelectionChange as EventListener)
  window.addEventListener('voucher-selection-change', handleSelectionChange as EventListener)
  window.addEventListener('document-selection-change', handleSelectionChange as EventListener)
  
  console.log('[Toolbar] 组件已挂载，开始监听选中变化事件')
})

onUnmounted(() => {
  window.removeEventListener('invoice-selection-change', handleSelectionChange as EventListener)
  window.removeEventListener('voucher-selection-change', handleSelectionChange as EventListener)
  window.removeEventListener('document-selection-change', handleSelectionChange as EventListener)
  
  console.log('[Toolbar] 组件已卸载，移除事件监听器')
})

// 设置
const handleSettings = (event?: MouseEvent) => {
  console.log('[Toolbar] 设置按钮被点击', { event })
  window.dispatchEvent(new CustomEvent('toolbar-settings'))
}
</script>

<style scoped lang="scss">
.toolbar {
  display: flex;
  align-items: center;
  padding: 4px 8px;
  background-color: #f5f5f5;
  border-bottom: 1px solid #d0d0d0;
  gap: 8px;
  height: 32px;
  position: relative;
  z-index: 100;
  flex-shrink: 0;
  pointer-events: auto;

  .toolbar-group {
    display: flex;
    gap: 4px;
    padding-right: 8px;
    border-right: 1px solid #d0d0d0;
    pointer-events: auto;

    &:last-child {
      border-right: none;
    }

    :deep(.el-button) {
      font-size: 11px;
      padding: 4px 10px;
      height: 24px;
      color: #333;
      background-color: #fff;
      border-color: #d0d0d0;
      pointer-events: auto;
      cursor: pointer;

      &:hover {
        background-color: #f0f0f0;
        border-color: #c0c0c0;
      }

      &:disabled {
        pointer-events: none;
        cursor: not-allowed;
      }

      .el-icon {
        font-size: 12px;
      }
    }
  }
}
</style>
