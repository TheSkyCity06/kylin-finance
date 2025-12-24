<template>
  <div class="tab-view">
    <router-view v-slot="{ Component, route }">
      <keep-alive :include="keepAliveComponents">
        <component :is="Component" :key="route.path" />
      </keep-alive>
    </router-view>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useTabStore } from '@/stores/tabStore'

const tabStore = useTabStore()

// 需要 keep-alive 的组件列表
const keepAliveComponents = computed(() => {
  return tabStore.tabs
    .filter(tab => tab.component)
    .map(tab => tab.component!)
})
</script>

<style scoped lang="scss">
.tab-view {
  flex: 1;
  overflow: auto;
  background-color: #fff;
  padding: 8px;
  position: relative;
  z-index: 1;
}
</style>
