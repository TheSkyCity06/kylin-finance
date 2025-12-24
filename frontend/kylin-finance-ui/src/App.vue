<template>
  <div id="app">
    <!-- 登录页不使用布局，直接渲染 -->
    <router-view v-if="isLoginPage" />
    <!-- 其他页面使用主布局 -->
    <MainLayout v-else />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import MainLayout from '@/components/layout/MainLayout.vue'

const route = useRoute()

// 判断是否为登录页
const isLoginPage = computed(() => route.path === '/login' || route.meta.hidden === true)
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

#app {
  width: 100vw;
  height: 100vh;
  overflow: hidden;
}

body {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  font-size: 12px;
  color: #333;
  background-color: #f5f5f5;
}
</style>
