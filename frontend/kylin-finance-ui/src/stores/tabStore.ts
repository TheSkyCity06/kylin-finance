import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { RouteLocationNormalized } from 'vue-router'

export interface TabItem {
  id: string
  title: string
  path: string
  component?: string
  closable?: boolean
  active?: boolean
}

export const useTabStore = defineStore('tab', () => {
  const tabs = ref<TabItem[]>([])
  const activeTabId = ref<string>('')

  // 添加 Tab
  const addTab = (tab: TabItem) => {
    // 检查是否已存在
    const existingTab = tabs.value.find(t => t.path === tab.path)
    if (existingTab) {
      // 如果已存在，激活它
      setActiveTab(existingTab.id)
      return
    }

    // 设置新 Tab 为激活状态
    tab.active = true
    tabs.value.forEach(t => t.active = false)
    
    tabs.value.push(tab)
    activeTabId.value = tab.id
  }

  // 移除 Tab
  const removeTab = (tabId: string) => {
    const index = tabs.value.findIndex(t => t.id === tabId)
    if (index === -1) return

    const removedTab = tabs.value[index]
    tabs.value.splice(index, 1)

    // 如果移除的是当前激活的 Tab，激活相邻的 Tab
    if (removedTab.active && tabs.value.length > 0) {
      const newActiveIndex = Math.min(index, tabs.value.length - 1)
      setActiveTab(tabs.value[newActiveIndex].id)
    }
  }

  // 设置激活 Tab
  const setActiveTab = (tabId: string) => {
    tabs.value.forEach(t => {
      t.active = t.id === tabId
    })
    activeTabId.value = tabId
  }

  // 关闭其他 Tab
  const closeOthers = (tabId: string) => {
    tabs.value = tabs.value.filter(t => t.id === tabId)
    setActiveTab(tabId)
  }

  // 关闭所有 Tab
  const closeAll = () => {
    tabs.value = []
    activeTabId.value = ''
  }

  // 获取当前激活的 Tab
  const activeTab = computed(() => {
    return tabs.value.find(t => t.id === activeTabId.value)
  })

  return {
    tabs,
    activeTabId,
    activeTab,
    addTab,
    removeTab,
    setActiveTab,
    closeOthers,
    closeAll
  }
})
