<template>
  <div class="tab-bar">
    <div class="tabs-container">
      <div
        v-for="tab in tabs"
        :key="tab.id"
        :class="['tab-item', { active: tab.active }]"
        @click="handleTabClick(tab.id)"
        @contextmenu.prevent="handleContextMenu($event, tab.id)"
      >
        <span class="tab-title">{{ tab.title }}</span>
        <el-icon
          v-if="tab.closable"
          class="tab-close"
          @click.stop="handleCloseTab(tab.id)"
        >
          <Close />
        </el-icon>
      </div>
    </div>

    <!-- 右键菜单 -->
    <el-dropdown
      ref="contextMenuRef"
      trigger="contextmenu"
      @command="handleContextCommand"
    >
      <div style="display: none"></div>
      <template #dropdown>
        <el-dropdown-menu>
          <el-dropdown-item :command="{ action: 'close', tabId: contextTabId }">
            关闭
          </el-dropdown-item>
          <el-dropdown-item :command="{ action: 'closeOthers', tabId: contextTabId }">
            关闭其他
          </el-dropdown-item>
          <el-dropdown-item :command="{ action: 'closeAll' }">
            关闭所有
          </el-dropdown-item>
        </el-dropdown-menu>
      </template>
    </el-dropdown>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Close } from '@element-plus/icons-vue'
import { useTabStore } from '@/stores/tabStore'
import { useRouter } from 'vue-router'

const tabStore = useTabStore()
const router = useRouter()
const contextMenuRef = ref()
const contextTabId = ref('')

const tabs = computed(() => tabStore.tabs)

// Tab 点击
const handleTabClick = (tabId: string) => {
  tabStore.setActiveTab(tabId)
  const tab = tabStore.tabs.find(t => t.id === tabId)
  if (tab) {
    router.push(tab.path)
  }
}

// 关闭 Tab
const handleCloseTab = (tabId: string) => {
  const tab = tabStore.tabs.find(t => t.id === tabId)
  if (tab) {
    tabStore.removeTab(tabId)
    
    // 如果关闭后没有激活的 Tab，跳转到首页
    if (!tabStore.activeTab && tabStore.tabs.length === 0) {
      router.push('/dashboard')
    } else if (tabStore.activeTab) {
      router.push(tabStore.activeTab.path)
    }
  }
}

// 右键菜单
const handleContextMenu = (event: MouseEvent, tabId: string) => {
  contextTabId.value = tabId
}

// 右键菜单命令
const handleContextCommand = (command: { action: string; tabId?: string }) => {
  if (command.action === 'close' && command.tabId) {
    handleCloseTab(command.tabId)
  } else if (command.action === 'closeOthers' && command.tabId) {
    tabStore.closeOthers(command.tabId)
    const tab = tabStore.tabs.find(t => t.id === command.tabId)
    if (tab) {
      router.push(tab.path)
    }
  } else if (command.action === 'closeAll') {
    tabStore.closeAll()
    router.push('/dashboard')
  }
}
</script>

<style scoped lang="scss">
.tab-bar {
  background-color: #e8e8e8;
  border-bottom: 1px solid #d0d0d0;
  display: flex;
  align-items: center;
  height: 32px;
  overflow-x: auto;
  overflow-y: hidden;
  position: relative;
  z-index: 90;
  flex-shrink: 0;

  &::-webkit-scrollbar {
    height: 4px;
  }

  &::-webkit-scrollbar-thumb {
    background-color: #c0c0c0;
    border-radius: 2px;
  }

  .tabs-container {
    display: flex;
    align-items: center;
    height: 100%;
    min-width: 100%;
  }

  .tab-item {
    display: flex;
    align-items: center;
    padding: 4px 12px;
    height: 28px;
    background-color: #f0f0f0;
    border: 1px solid #d0d0d0;
    border-bottom: none;
    border-radius: 4px 4px 0 0;
    margin-right: 2px;
    cursor: pointer;
    font-size: 11px;
    color: #666;
    white-space: nowrap;
    min-width: 100px;
    max-width: 200px;
    transition: all 0.2s;

    &:hover {
      background-color: #f5f5f5;
    }

    &.active {
      background-color: #fff;
      color: #333;
      font-weight: 500;
      border-bottom: 1px solid #fff;
      margin-bottom: -1px;
    }

    .tab-title {
      flex: 1;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .tab-close {
      margin-left: 6px;
      font-size: 12px;
      opacity: 0.6;
      transition: opacity 0.2s;

      &:hover {
        opacity: 1;
        color: #f56c6c;
      }
    }
  }
}
</style>
